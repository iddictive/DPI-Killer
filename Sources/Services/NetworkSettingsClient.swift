import Foundation
import ServiceManagement

/// The GUI keeps its normal user privileges; only fixed network operations
/// cross the signed connection to the approved system helper.
final class NetworkSettingsClient {
    static let shared = NetworkSettingsClient()
    private let queue = DispatchQueue(label: "com.antigravity.DPIKiller.network-client")
    private let stateLock = NSLock()
    private let service = SMAppService.daemon(plistName: NetworkSettingsIdentity.launchDaemonPlistName)
    private var connection: NSXPCConnection?
    private var lease = false
    private var pending = false
    private var approvalTimer: DispatchSourceTimer?
    private var didOpenApproval = false
    var onReady: (() -> Void)?
    var onUnavailable: ((String) -> Void)?
    private var serviceStatus: SMAppService.Status {
        NetworkHelperInstaller.isLocalBuild ? NetworkHelperInstaller.status : service.status
    }

    let isSupported: Bool = {
        let helper = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/HelperTools/DPIKillerNetworkHelper")
        return Bundle.main.bundleIdentifier == NetworkSettingsIdentity.appIdentifier
            && FileManager.default.isExecutableFile(atPath: helper.path)
            && (try? NetworkSettingsIdentity.teamIdentifier()) != nil
    }()

    var hasLease: Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return lease
    }

    var needsApproval: Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return pending
    }

    var approvalMessage: String {
        L10n.shared.isRussian
            ? "Разреши DPI Killer в Настройках системы → Основные → Объекты входа. Это одно разрешение для сетевого помощника; локальный прокси продолжает работать."
            : "Allow DPI Killer in System Settings → General → Login Items. This approves the network helper once; the local proxy keeps running."
    }

    func openApprovalSettings() {
        DispatchQueue.main.async { SMAppService.openSystemSettingsLoginItems() }
    }

    func checkApproval() {
        queue.async {
            guard self.serviceStatus == .enabled else { return }
            self.approvalTimer?.cancel()
            self.approvalTimer = nil
            self.stateLock.lock()
            let wasPending = self.pending
            self.pending = false
            self.stateLock.unlock()
            if wasPending {
                AppLogger.log("[Helper] Native approval granted. Retrying the requested system proxy.")
                DispatchQueue.main.async { self.onReady?() }
            }
        }
    }

    func applyProxy(mode: ProxyMode, port: Int, legacyLease: Data?) -> NetworkSettingsResponse {
        request(enroll: true) { proxy, reply in
            proxy.applyProxy(mode: mode == .http ? "http" : "socks", port: port, legacyLease: legacyLease, reply: reply)
        }
    }

    func restoreProxy(legacyLease: Data?) -> NetworkSettingsResponse {
        request(enroll: legacyLease != nil) { proxy, reply in
            proxy.restoreProxy(legacyLease: legacyLease, reply: reply)
        }
    }

    func applyHotspotTTL() -> NetworkSettingsResponse {
        request(enroll: true) { proxy, reply in proxy.applyHotspotTTL(reply: reply) }
    }

    private func request(enroll: Bool, operation: (NetworkSettingsProtocol, @escaping (Data) -> Void) -> Void) -> NetworkSettingsResponse {
        queue.sync {
            if serviceStatus != .enabled, !enroll, !hasLease {
                return NetworkSettingsResponse(error: nil, hasLease: false, legacyLeaseImported: false, ttl: nil)
            }
            do {
                if NetworkHelperInstaller.isLocalBuild, serviceStatus != .requiresApproval {
                    try NetworkHelperInstaller.ensureInstalled()
                } else if serviceStatus == .notRegistered || serviceStatus == .notFound {
                    AppLogger.log("[Helper] Registering bundled network helper for native approval.")
                    try service.register()
                }
                guard serviceStatus == .enabled else {
                    if serviceStatus == .requiresApproval {
                        stateLock.lock(); pending = true; stateLock.unlock()
                        watchApproval()
                        if !didOpenApproval {
                            didOpenApproval = true
                            openApprovalSettings()
                        }
                        return failure(approvalMessage)
                    }
                    return failure("Network helper unavailable: service status=\(serviceStatus.rawValue).")
                }
                if connection == nil {
                    let client = NSXPCConnection(machServiceName: NetworkSettingsIdentity.machServiceName, options: .privileged)
                    client.remoteObjectInterface = NetworkSettingsIdentity.interface()
                    client.setCodeSigningRequirement(try NetworkSettingsIdentity.requirement(identifier: NetworkSettingsIdentity.helperIdentifier))
                    let disconnected: () -> Void = { [weak self, weak client] in
                        self?.queue.async {
                            guard let self, self.connection === client else { return }
                            self.connection = nil
                            self.stateLock.lock()
                            let hadLease = self.lease
                            self.lease = false
                            self.stateLock.unlock()
                            client?.invalidate()
                            AppLogger.log("[Helper] Network helper connection invalidated.")
                            if hadLease {
                                DispatchQueue.main.async {
                                    self.onUnavailable?("Network helper disconnected; restoring the requested proxy.")
                                    self.onReady?()
                                }
                            }
                        }
                    }
                    client.invalidationHandler = disconnected
                    client.interruptionHandler = disconnected
                    client.resume()
                    connection = client
                }
                let finished = DispatchSemaphore(value: 0)
                let resultLock = NSLock()
                var result: NetworkSettingsResponse?
                let complete: (NetworkSettingsResponse) -> Void = { response in
                    resultLock.lock()
                    guard result == nil else { resultLock.unlock(); return }
                    result = response
                    resultLock.unlock()
                    finished.signal()
                }
                guard let proxy = connection?.remoteObjectProxyWithErrorHandler({ error in
                    complete(self.failure("Network helper IPC failed: \(error.localizedDescription)"))
                }) as? NetworkSettingsProtocol else { return failure("Network helper interface unavailable.") }
                operation(proxy) { data in
                    complete((try? JSONDecoder().decode(NetworkSettingsResponse.self, from: data))
                             ?? self.failure("Network helper returned an invalid response."))
                }
                guard finished.wait(timeout: .now() + 10) == .success else {
                    // Keep the connection alive: a timed-out write may have
                    // committed. Reconcile through restore/status on retry.
                    return failure("Network helper request timed out; recovery state retained.")
                }
                resultLock.lock(); let response = result!; resultLock.unlock()
                stateLock.lock(); lease = response.hasLease; pending = false; stateLock.unlock()
                return response
            } catch {
                let native = error as NSError
                return failure("Network helper setup failed: \(native.localizedDescription) (\(native.domain) \(native.code), service status=\(serviceStatus.rawValue)).")
            }
        }
    }

    private func watchApproval() {
        guard approvalTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        var remaining = 90
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            guard let self else { timer.cancel(); return }
            remaining -= 1
            if self.serviceStatus == .enabled {
                self.checkApproval()
            } else if remaining <= 0 {
                timer.cancel()
                self.approvalTimer = nil
                AppLogger.log("[Helper] Approval still pending; rechecking when the app becomes active.")
            }
        }
        approvalTimer = timer
        timer.resume()
    }

    private func failure(_ message: String) -> NetworkSettingsResponse {
        AppLogger.log("[Helper] \(message)")
        return NetworkSettingsResponse(error: message, hasLease: hasLease, legacyLeaseImported: false, ttl: nil)
    }
}
