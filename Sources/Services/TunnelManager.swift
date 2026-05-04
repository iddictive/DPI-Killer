import Foundation
import NetworkExtension

final class TunnelManager {
    static let shared = TunnelManager()

    private let providerBundleIdentifier = "com.antigravity.DPIKiller.PacketTunnel"
    private let localizedDescription = "DPI Killer VPN"
    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    private var lastPreflightError: String?
    var onStatusChange: (() -> Void)?

    deinit {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
    }

    var status: NEVPNStatus {
        manager?.connection.status ?? .invalid
    }

    var isActive: Bool {
        switch status {
        case .connected, .connecting, .reasserting:
            return true
        default:
            return false
        }
    }

    var availabilityIssue: String? {
        preflightError()
    }

    func refresh(completion: (() -> Void)? = nil) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            let manager = managers?.first { $0.localizedDescription == self?.localizedDescription } ?? managers?.first
            self?.installStatusObserver(for: manager)
            self?.manager = manager
            DispatchQueue.main.async {
                self?.onStatusChange?()
                completion?()
            }
        }
    }

    func start(completion: @escaping (Bool, String?) -> Void) {
        if let preflightError = preflightError() {
            AppLogger.log("[Tunnel] Preflight failed: \(preflightError)")
            completion(false, preflightError)
            return
        }

        let rawPort = Int(SettingsStore.shared.localPort.trimmingCharacters(in: .whitespaces)) ?? 8080
        let port = max(1, min(65535, rawPort))
        let engine = SettingsStore.shared.resolvedEngine
        let proxyMode: TunnelProxyMode = switch engine.proxyMode {
        case .http: .http
        case .socks: .socks
        }

        let configuration = TunnelConfiguration(
            backendName: engine.displayName,
            localPort: port,
            proxyMode: proxyMode
        )

        AppLogger.log("[Tunnel] Starting Packet Tunnel for \(engine.displayName) on port \(port) in \(proxyMode.rawValue.uppercased()) mode.")

        prepareManager(configuration: configuration) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .failure(error):
                    let message = self?.describe(error) ?? error.localizedDescription
                    AppLogger.log("[Tunnel] Prepare failed: \(message)")
                    completion(false, message)
                case let .success(manager):
                    do {
                        try manager.connection.startVPNTunnel()
                        AppLogger.log("[Tunnel] startVPNTunnel() dispatched.")
                        self?.waitForConnection(of: manager) { connected in
                            if connected {
                                completion(true, nil)
                            } else {
                                completion(false, L10n.shared.vpnModeStartFailed)
                            }
                        }
                    } catch {
                        let message = self?.describe(error) ?? error.localizedDescription
                        AppLogger.log("[Tunnel] startVPNTunnel() failed: \(message)")
                        completion(false, message)
                    }
                }
            }
        }
    }

    func stop() {
        AppLogger.log("[Tunnel] Stopping Packet Tunnel.")
        manager?.connection.stopVPNTunnel()
        onStatusChange?()
    }

    private func prepareManager(
        configuration: TunnelConfiguration,
        completion: @escaping (Result<NETunnelProviderManager, Error>) -> Void
    ) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error {
                AppLogger.log("[Tunnel] loadAllFromPreferences failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            let manager = managers?.first { $0.localizedDescription == self?.localizedDescription } ?? NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = self?.providerBundleIdentifier
            proto.serverAddress = self?.localizedDescription
            proto.providerConfiguration = configuration.providerDictionary()
            proto.disconnectOnSleep = false

            manager.localizedDescription = self?.localizedDescription
            manager.protocolConfiguration = proto
            manager.isEnabled = true

            manager.saveToPreferences { saveError in
                if let saveError {
                    AppLogger.log("[Tunnel] saveToPreferences failed: \(saveError.localizedDescription)")
                    completion(.failure(saveError))
                    return
                }

                manager.loadFromPreferences { loadError in
                    if let loadError {
                        AppLogger.log("[Tunnel] loadFromPreferences failed: \(loadError.localizedDescription)")
                        completion(.failure(loadError))
                        return
                    }

                    self?.manager = manager
                    self?.installStatusObserver(for: manager)
                    completion(.success(manager))
                }
            }
        }
    }

    private func installStatusObserver(for manager: NETunnelProviderManager?) {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
            self.statusObserver = nil
        }

        guard let connection = manager?.connection else { return }
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: connection,
            queue: .main
        ) { [weak self] _ in
            AppLogger.log("[Tunnel] Status changed to \(Self.describe(connection.status)).")
            self?.onStatusChange?()
        }
    }

    private func waitForConnection(of manager: NETunnelProviderManager, timeout: TimeInterval = 6.0, completion: @escaping (Bool) -> Void) {
        let deadline = Date().addingTimeInterval(timeout)

        func poll() {
            let status = manager.connection.status
            switch status {
            case .connected, .reasserting:
                AppLogger.log("[Tunnel] Packet Tunnel is connected.")
                completion(true)
            case .invalid, .disconnected:
                if Date() >= deadline {
                    AppLogger.log("[Tunnel] Packet Tunnel never became active. Final status: \(Self.describe(status)).")
                    completion(false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: poll)
                }
            case .connecting, .disconnecting:
                if Date() >= deadline {
                    AppLogger.log("[Tunnel] Packet Tunnel timed out in status \(Self.describe(status)).")
                    completion(false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: poll)
                }
            @unknown default:
                if Date() >= deadline {
                    AppLogger.log("[Tunnel] Packet Tunnel timed out in unknown status.")
                    completion(false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: poll)
                }
            }
        }

        poll()
    }

    private func preflightError() -> String? {
        if let lastPreflightError {
            return lastPreflightError
        }

        let extensionURL = bundledExtensionURL()
        guard let extensionURL else {
            lastPreflightError = L10n.shared.vpnModeMissingBundle
            return lastPreflightError
        }

        let appHasEntitlement = hasNetworkExtensionEntitlement(at: Bundle.main.bundleURL.path)
        let extensionHasEntitlement = hasNetworkExtensionEntitlement(at: extensionURL.path)

        guard appHasEntitlement, extensionHasEntitlement else {
            lastPreflightError = L10n.shared.vpnModeMissingSignature
            return lastPreflightError
        }

        lastPreflightError = nil
        return nil
    }

    private func hasNetworkExtensionEntitlement(at path: String) -> Bool {
        let output = run("/usr/bin/codesign", ["-d", "--entitlements", ":-", path], includeStderr: true)
        return output.contains("com.apple.developer.networking.networkextension")
            && (output.contains("packet-tunnel-provider-systemextension") || output.contains("packet-tunnel-provider"))
    }

    private func bundledExtensionURL() -> URL? {
        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent("Contents/Library/SystemExtensions/DPIKillerTunnel.systemextension"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns/DPIKillerTunnel.appex")
        ]

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func describe(_ error: Error) -> String {
        let nsError = error as NSError
        if (nsError.domain == NEVPNErrorDomain && nsError.code == 5) || (nsError.domain == "NEConfigurationErrorDomain" && nsError.code == 10) {
            return L10n.shared.vpnModePermissionDenied
        }
        if nsError.domain == NEVPNErrorDomain && nsError.code == 1 {
            return L10n.shared.vpnModeMissingBundle
        }
        return nsError.localizedDescription.isEmpty ? L10n.shared.vpnModeStartFailed : nsError.localizedDescription
    }

    private func run(_ launchPath: String, _ arguments: [String], includeStderr: Bool = false) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let stdout = Pipe()
        process.standardOutput = stdout
        if includeStderr {
            process.standardError = stdout
        } else {
            process.standardError = FileHandle.nullDevice
        }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func describe(_ status: NEVPNStatus) -> String {
        switch status {
        case .invalid: return "invalid"
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .reasserting: return "reasserting"
        case .disconnecting: return "disconnecting"
        @unknown default: return "unknown"
        }
    }
}
