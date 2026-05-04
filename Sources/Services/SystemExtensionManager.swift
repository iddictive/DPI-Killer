import Foundation
import SystemExtensions

final class SystemExtensionManager: NSObject, OSSystemExtensionRequestDelegate {
    struct AvailabilityError: Error {
        let message: String
    }

    enum DeploymentMode {
        case appExtension
        case systemExtension
    }

    struct Availability {
        let mode: DeploymentMode
        let bundleURL: URL
    }

    static let shared = SystemExtensionManager()

    private let extensionIdentifier = "com.antigravity.DPIKiller.PacketTunnel"
    private let requestQueue = DispatchQueue.main
    private var pendingCompletions: [(Bool, String?, Bool) -> Void] = []
    private var requestInFlight = false

    func ensureActivated(completion: @escaping (Bool, String?, Bool) -> Void) {
        switch availability() {
        case let .failure(issue):
            completion(false, issue.message, true)
        case let .success(availability):
            switch availability.mode {
            case .appExtension:
                AppLogger.log("[SystemExtension] Development app extension signature detected. Activation is not required.")
                completion(true, nil, false)
            case .systemExtension:
                if isActivated() {
                    completion(true, nil, false)
                    return
                }

                pendingCompletions.append(completion)
                guard !requestInFlight else { return }
                requestInFlight = true

                AppLogger.log("[SystemExtension] Submitting activation request for \(extensionIdentifier).")
                let request = OSSystemExtensionRequest.activationRequest(
                    forExtensionWithIdentifier: extensionIdentifier,
                    queue: requestQueue
                )
                request.delegate = self
                OSSystemExtensionManager.shared.submitRequest(request)
            }
        }
    }

    func availabilityIssue() -> String? {
        if case let .failure(issue) = availability() {
            return issue.message
        }
        return nil
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        AppLogger.log("[SystemExtension] User approval is required.")
        resolveAll(success: false, message: L10n.shared.vpnSystemExtensionApproval, disableToggle: false)
    }

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        switch result {
        case .completed:
            AppLogger.log("[SystemExtension] Activation completed.")
            resolveAll(success: true, message: nil, disableToggle: false)
        case .willCompleteAfterReboot:
            AppLogger.log("[SystemExtension] Activation will complete after reboot.")
            resolveAll(success: false, message: L10n.shared.vpnSystemExtensionReboot, disableToggle: false)
        @unknown default:
            AppLogger.log("[SystemExtension] Activation finished with an unknown result.")
            resolveAll(success: false, message: L10n.shared.vpnSystemExtensionFailed, disableToggle: false)
        }
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        let nsError = error as NSError
        AppLogger.log("[SystemExtension] Activation failed: \(nsError.domain) \(nsError.code) \(nsError.localizedDescription)")
        resolveAll(success: false, message: nsError.localizedDescription.isEmpty ? L10n.shared.vpnSystemExtensionFailed : nsError.localizedDescription, disableToggle: false)
    }

    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        .replace
    }

    private func resolveAll(success: Bool, message: String?, disableToggle: Bool) {
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        requestInFlight = false
        completions.forEach { $0(success, message, disableToggle) }
    }

    private func availability() -> Result<Availability, AvailabilityError> {
        let appSignature = entitlementSignature(at: Bundle.main.bundleURL.path)

        if let url = appExtensionBundleURL() {
            let extensionSignature = entitlementSignature(at: url.path)
            if appSignature.contains(.appExtension), extensionSignature.contains(.appExtension) {
                return .success(Availability(mode: .appExtension, bundleURL: url))
            }
        }

        if let url = systemExtensionBundleURL() ?? appExtensionBundleURL() {
            let extensionSignature = entitlementSignature(at: url.path)
            if appSignature.contains(.systemExtension), extensionSignature.contains(.systemExtension) {
                return .success(Availability(mode: .systemExtension, bundleURL: url))
            }
        }

        if appExtensionBundleURL() == nil, systemExtensionBundleURL() == nil {
            return .failure(AvailabilityError(message: L10n.shared.vpnModeMissingBundle))
        }

        return .failure(AvailabilityError(message: L10n.shared.vpnModeMissingSignature))
    }

    private func isActivated() -> Bool {
        let output = run("/usr/bin/systemextensionsctl", ["list"])
        return output.contains(extensionIdentifier) && output.contains("[activated enabled]")
    }

    private func appExtensionBundleURL() -> URL? {
        let url = Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns/DPIKillerTunnel.appex")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func systemExtensionBundleURL() -> URL? {
        let url = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/SystemExtensions/DPIKillerTunnel.systemextension")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private enum EntitlementMode: Hashable {
        case appExtension
        case systemExtension
    }

    private func entitlementSignature(at path: String) -> Set<EntitlementMode> {
        let output = run("/usr/bin/codesign", ["-d", "--entitlements", ":-", path], includeStderr: true)
        guard output.contains("com.apple.developer.networking.networkextension") else {
            return []
        }

        var modes: Set<EntitlementMode> = []
        if output.contains("<string>packet-tunnel-provider-systemextension</string>") {
            modes.insert(.systemExtension)
        }
        if output.contains("<string>packet-tunnel-provider</string>") {
            modes.insert(.appExtension)
        }
        return modes
    }

    private func run(_ launchPath: String, _ arguments: [String], includeStderr: Bool = false) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = includeStderr ? pipe : FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
