import Foundation
import Darwin

/// All privileged work and lease ownership stay on this serial executor.
private final class NetworkSettingsServer: NSObject, NSXPCListenerDelegate {
    private let queue = DispatchQueue(label: NetworkSettingsIdentity.machServiceName)
    private let controller: SystemProxyController
    private let clientRequirement: String
    private var leaseOwner: UUID?
    private var liveConnections: Set<UUID> = []

    init(controller: SystemProxyController, clientRequirement: String) {
        self.controller = controller
        self.clientRequirement = clientRequirement
        super.init()
    }

    func recoverOnStartup() {
        queue.sync {
            if !controller.restore() {
                AppLogger.log("[NetworkHelper] Startup proxy recovery failed; lease retained.")
            }
        }
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        let token = UUID()
        queue.async { self.liveConnections.insert(token) }
        connection.setCodeSigningRequirement(clientRequirement)
        connection.exportedInterface = NetworkSettingsIdentity.interface()
        connection.exportedObject = NetworkSettingsSession(server: self, token: token)
        connection.invalidationHandler = { [weak self] in self?.disconnected(token) }
        connection.interruptionHandler = { [weak self] in self?.disconnected(token) }
        connection.resume()
        return true
    }

    func applyProxy(token: UUID, mode: String, port: Int, legacyLease: Data?, reply: @escaping (Data) -> Void) {
        queue.async {
            guard mode == "http" || mode == "socks", (1...65535).contains(port) else {
                self.respond(error: "Invalid proxy mode or loopback port.", reply: reply)
                return
            }
            guard self.canControl(token, reply: reply) else { return }
            let imported = self.importLease(legacyLease)
            guard imported.error == nil else {
                self.respond(error: imported.error, reply: reply)
                return
            }
            let error = self.controller.apply(mode: mode == "http" ? .http : .socks, port: port)
            self.leaseOwner = self.controller.hasLease ? token : nil
            self.respond(error: error, imported: imported.accepted, reply: reply)
        }
    }

    func restoreProxy(token: UUID, legacyLease: Data?, reply: @escaping (Data) -> Void) {
        queue.async {
            guard self.canControl(token, reply: reply) else { return }
            let imported = self.importLease(legacyLease)
            guard imported.error == nil else {
                self.respond(error: imported.error, reply: reply)
                return
            }
            let restored = self.controller.restore()
            self.leaseOwner = self.controller.hasLease ? token : nil
            self.respond(error: restored ? nil : self.controller.lastError ?? "Could not restore the system proxy.",
                         imported: imported.accepted, reply: reply)
        }
    }

    func applyHotspotTTL(token: UUID, reply: @escaping (Data) -> Void) {
        queue.async {
            guard self.liveConnections.contains(token) else {
                self.respond(error: "The network settings connection has closed.", reply: reply)
                return
            }
            var ttl: Int32 = 65
            let result = sysctlbyname("net.inet.ip.ttl", nil, nil, &ttl, MemoryLayout.size(ofValue: ttl))
            let error = result == 0 ? nil : "Could not apply hotspot TTL: \(String(cString: strerror(errno)))."
            if let error { AppLogger.log("[NetworkHelper] \(error)") }
            self.respond(error: error, reply: reply)
        }
    }

    func status(reply: @escaping (Data) -> Void) {
        queue.async {
            self.respond(error: self.controller.lastError, reply: reply)
        }
    }

    private func canControl(_ token: UUID, reply: @escaping (Data) -> Void) -> Bool {
        guard liveConnections.contains(token) else {
            respond(error: "The network settings connection has closed.", reply: reply)
            return false
        }
        guard leaseOwner == nil || leaseOwner == token else {
            respond(error: "Another DPI Killer connection owns the system proxy. Try again after it disconnects.", reply: reply)
            return false
        }
        return true
    }

    private func importLease(_ data: Data?) -> (accepted: Bool, error: String?) {
        guard let data else { return (false, nil) }
        guard data.count <= 64 * 1024 else { return (false, "The saved proxy recovery lease is too large.") }
        let error = controller.importRecoveryLease(data)
        return (error == nil, error)
    }

    private func disconnected(_ token: UUID) {
        queue.async {
            self.liveConnections.remove(token)
            guard self.leaseOwner == token else { return }
            self.leaseOwner = nil
            if !self.controller.restore() {
                AppLogger.log("[NetworkHelper] Client disconnected; proxy recovery failed and lease was retained.")
            }
        }
    }

    private func respond(error: String?, imported: Bool = false, reply: (Data) -> Void) {
        var ttl: Int32 = 0
        var size = MemoryLayout.size(ofValue: ttl)
        let ttlResult = sysctlbyname("net.inet.ip.ttl", &ttl, &size, nil, 0)
        let response = NetworkSettingsResponse(error: error, hasLease: controller.hasLease,
                                               legacyLeaseImported: imported, ttl: ttlResult == 0 ? Int(ttl) : nil)
        // This fixed primitive payload has no fallible custom encoders.
        guard let data = try? JSONEncoder().encode(response) else {
            reply(Data("{\"error\":\"Could not encode network settings status.\",\"hasLease\":true,\"legacyLeaseImported\":false}".utf8))
            return
        }
        reply(data)
    }
}

private final class NetworkSettingsSession: NSObject, NetworkSettingsProtocol {
    private let server: NetworkSettingsServer
    private let token: UUID

    init(server: NetworkSettingsServer, token: UUID) {
        self.server = server
        self.token = token
    }

    func applyProxy(mode: String, port: Int, legacyLease: Data?, reply: @escaping (Data) -> Void) {
        server.applyProxy(token: token, mode: mode, port: port, legacyLease: legacyLease, reply: reply)
    }

    func restoreProxy(legacyLease: Data?, reply: @escaping (Data) -> Void) {
        server.restoreProxy(token: token, legacyLease: legacyLease, reply: reply)
    }

    func applyHotspotTTL(reply: @escaping (Data) -> Void) { server.applyHotspotTTL(token: token, reply: reply) }
    func status(reply: @escaping (Data) -> Void) { server.status(reply: reply) }
}

guard getuid() == 0 else {
    AppLogger.log("[NetworkHelper] Refusing to run outside launchd root context.")
    exit(EXIT_FAILURE)
}

do {
    let requirement = try NetworkSettingsIdentity.requirement(identifier: NetworkSettingsIdentity.appIdentifier)
    let server = NetworkSettingsServer(controller: SystemProxyController(defaults: .standard, privileged: true),
                                       clientRequirement: requirement)
    server.recoverOnStartup()
    let listener = NSXPCListener(machServiceName: NetworkSettingsIdentity.machServiceName)
    listener.setConnectionCodeSigningRequirement(requirement)
    listener.delegate = server
    listener.resume()
    signal(SIGTERM, SIG_IGN)
    let termination = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .global(qos: .utility))
    termination.setEventHandler {
        server.recoverOnStartup()
        exit(EXIT_SUCCESS)
    }
    termination.resume()
    withExtendedLifetime((listener, server, termination)) { RunLoop.current.run() }
} catch {
    AppLogger.log("[NetworkHelper] Refusing unsigned or invalidly signed execution: \(error.localizedDescription)")
    exit(EXIT_FAILURE)
}
