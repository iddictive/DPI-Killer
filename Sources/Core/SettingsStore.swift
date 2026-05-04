import Cocoa
import Foundation

final class SettingsStore {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard
    private let managedArgumentKeys: Set<String> = [
        "--default-ttl",
        "--def-ttl",
        "--https-split-mode",
        "--https-split-pos",
        "--https-fake-count",
        "--https-chunk-size",
        "--https-disorder",
        "--listen-addr",
        "--dns-addr",
        "--dns-mode",
        "--dns-https-url",
        "-p",
        "--port",
        "--auto",
        "--split",
        "--disorder",
        "--fake",
        "--ttl",
        "--tlsrec"
    ]
    private let managedFlagsWithoutValues: Set<String> = [
        "--https-disorder"
    ]
    private let perEngineManualArgsKeys: [BypassEngine: String] = [
        .ciadpi: "manualArgs.ciadpi",
        .spoofdpi: "manualArgs.spoofdpi"
    ]
    private let backendSelectionKey = "backendSelection"

    var binaryPath: String {
        get {
            if let stored = defaults.string(forKey: "binaryPath") {
                return resolvedBinaryPath(fromStored: stored)
            }
            return detectBestBinaryPath()
        }
        set { defaults.set(newValue, forKey: "binaryPath") }
    }

    var customArgs: String {
        get { defaults.string(forKey: "customArgs") ?? "--system-proxy" }
        set { defaults.set(newValue, forKey: "customArgs") }
    }

    var defaultTTL: String {
        get { defaults.string(forKey: "defaultTTL") ?? "128" }
        set { defaults.set(newValue, forKey: "defaultTTL") }
    }

    var splitMode: String {
        get { defaults.string(forKey: "splitMode") ?? "random" }
        set { defaults.set(newValue, forKey: "splitMode") }
    }

    var httpsDisorder: Bool {
        get { defaults.object(forKey: "httpsDisorder") == nil ? true : defaults.bool(forKey: "httpsDisorder") }
        set { defaults.set(newValue, forKey: "httpsDisorder") }
    }

    var httpsFakeCount: String {
        get { defaults.string(forKey: "httpsFakeCount") ?? "0" }
        set { defaults.set(newValue, forKey: "httpsFakeCount") }
    }

    var httpsChunkSize: String {
        get { defaults.string(forKey: "httpsChunkSize") ?? "20" }
        set { defaults.set(newValue, forKey: "httpsChunkSize") }
    }

    var localPort: String {
        get { defaults.string(forKey: "localPort") ?? "8080" }
        set { defaults.set(newValue, forKey: "localPort") }
    }

    var dnsAddr: String {
        get { defaults.string(forKey: "dnsAddr") ?? "8.8.8.8:53" }
        set { defaults.set(newValue, forKey: "dnsAddr") }
    }

    var dnsMode: String {
        get { defaults.string(forKey: "dnsMode") ?? "udp" }
        set { defaults.set(newValue, forKey: "dnsMode") }
    }

    var dnsHttpsUrl: String {
        get { defaults.string(forKey: "dnsHttpsUrl") ?? "https://dns.google/dns-query" }
        set { defaults.set(newValue, forKey: "dnsHttpsUrl") }
    }

    var autoUpdate: Bool {
        get { defaults.object(forKey: "autoUpdate") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoUpdate") }
    }

    var autoDownload: Bool {
        get { defaults.object(forKey: "autoDownload") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "autoDownload") }
    }

    var disableIpv6: Bool {
        get { defaults.bool(forKey: "disableIpv6") }
        set {
            defaults.set(newValue, forKey: "disableIpv6")
            applyIpv6Settings(newValue)
        }
    }

    var autoReconnect: Bool {
        get { defaults.object(forKey: "autoReconnect") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoReconnect") }
    }

    var vpnModeEnabled: Bool {
        get { defaults.object(forKey: "vpnModeEnabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "vpnModeEnabled") }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set {
            defaults.set(newValue, forKey: "launchAtLogin")
            toggleLaunchAtLogin(newValue)
        }
    }

    var selectedFlags: Set<String> {
        Set(argumentParts(from: customArgs).filter {
            $0.hasPrefix("-")
                && !managedArgumentKeys.contains($0)
        })
    }

    var resolvedEngine: BypassEngine {
        BypassEngine(binaryPath: binaryPath)
    }

    var backendSelection: BackendSelection {
        let stored = defaults.string(forKey: "binaryPath") ?? ""
        if let raw = defaults.string(forKey: backendSelectionKey),
           let selection = BackendSelection(rawValue: raw) {
            return selection
        }
        return inferredBackendSelection(from: stored)
    }

    private func inferredBackendSelection(from stored: String) -> BackendSelection {
        guard !stored.isEmpty else { return .automatic }
        if preferredCiadpiPaths().contains(stored) {
            return .ciadpi
        }
        if preferredSpoofDpiPaths().contains(stored) {
            return .spoofdpi
        }
        return .custom
    }

    var usesSystemProxy: Bool {
        selectedFlags.contains("--system-proxy")
    }

    func loadDraft() -> SettingsDraft {
        let common = CommonSettings(
            localPort: localPort,
            defaultTTL: defaultTTL,
            splitMode: splitMode,
            httpsDisorder: httpsDisorder,
            httpsFakeCount: httpsFakeCount,
            httpsChunkSize: httpsChunkSize,
            dnsAddr: dnsAddr,
            dnsMode: dnsMode,
            dnsHttpsUrl: dnsHttpsUrl,
            launchAtLogin: launchAtLogin,
            autoUpdate: autoUpdate,
            autoDownload: autoDownload,
            disableIpv6: disableIpv6,
            autoReconnect: autoReconnect,
            vpnModeEnabled: vpnModeEnabled
        )

        return SettingsDraft(
            backendSelection: backendSelection,
            customPath: binaryPath,
            common: common,
            ciadpi: engineSettings(for: .ciadpi),
            spoofdpi: engineSettings(for: .spoofdpi)
        )
    }

    func saveDraft(_ draft: SettingsDraft) {
        let resolvedPath = resolvedBinaryPath(
            for: draft.backendSelection,
            customPath: draft.customPath
        )
        let engine = currentEngine(for: resolvedPath)
        let engineSettings = draft.engineSettings(for: engine)

        applyBackendSelection(draft.backendSelection, customPath: draft.customPath)
        localPort = clampedString(draft.common.localPort, defaultValue: 8080, range: 1...65535)
        launchAtLogin = draft.common.launchAtLogin
        autoUpdate = draft.common.autoUpdate
        autoDownload = draft.common.autoDownload
        disableIpv6 = draft.common.disableIpv6
        autoReconnect = draft.common.autoReconnect
        vpnModeEnabled = draft.common.vpnModeEnabled

        defaultTTL = clampedString(draft.common.defaultTTL, defaultValue: 128, range: 1...255)
        splitMode = draft.common.splitMode.isEmpty ? "sni" : draft.common.splitMode
        httpsDisorder = draft.common.httpsDisorder
        httpsFakeCount = clampedString(draft.common.httpsFakeCount, defaultValue: 0, range: 0...100)
        httpsChunkSize = clampedString(draft.common.httpsChunkSize, defaultValue: 20, range: 1...1000)
        dnsAddr = draft.common.dnsAddr.trimmingCharacters(in: .whitespacesAndNewlines)
        dnsMode = draft.common.dnsMode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "udp"
            : draft.common.dnsMode.trimmingCharacters(in: .whitespacesAndNewlines)
        dnsHttpsUrl = draft.common.dnsHttpsUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        saveSelectedFlags(draft.ciadpi.selectedFlags, for: .ciadpi)
        saveSelectedFlags(draft.spoofdpi.selectedFlags, for: .spoofdpi)
        saveManualArgs(draft.ciadpi.manualArgs, for: .ciadpi)
        saveManualArgs(draft.spoofdpi.manualArgs, for: .spoofdpi)
        updateArgs(
            with: engineSettings.selectedFlags,
            manual: engineSettings.manualArgs,
            ttl: defaultTTL,
            splitMode: splitMode,
            splitPos: "1",
            port: localPort,
            dnsAddr: dnsAddr,
            dnsMode: dnsMode,
            dnsHttpsUrl: dnsHttpsUrl
        )
    }

    func commandPreview(for selection: BackendSelection? = nil, customPath: String? = nil) -> String {
        let resolvedPath: String
        if let selection {
            resolvedPath = resolvedBinaryPath(for: selection, customPath: customPath)
        } else if let customPath,
                  !customPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resolvedPath = customPath.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            resolvedPath = binaryPath
        }

        return ([resolvedPath] + launchArguments(for: resolvedPath))
            .map(shellEscaped)
            .joined(separator: " ")
    }

    func unsupportedManualArgs(_ manual: String, for engine: BypassEngine) -> [String] {
        let unsupported = unsupportedManualArgumentKeys(for: engine)
        return argumentParts(from: manual).filter { unsupported.contains($0) }
    }

    func duplicateManagedFlags(in manual: String) -> [String] {
        duplicateManagedArguments(in: manual)
    }

    func duplicateManagedArguments(in manual: String) -> [String] {
        let parts = argumentParts(from: manual)
        var duplicates: [String] = []
        var index = 0

        while index < parts.count {
            let part = parts[index]
            if managedFlagsWithoutValues.contains(part) || managedArgumentKeys.contains(part) || generatedManagedArgumentKeys.contains(part) {
                duplicates.append(part)
                index += 1
                if index < parts.count && !parts[index].hasPrefix("-") {
                    index += 1
                }
            } else {
                index += 1
            }
        }

        return duplicates
    }

    func selectedFlags(for engine: BypassEngine) -> Set<String> {
        let key = selectedFlagsKey(for: engine)
        if let stored = defaults.array(forKey: key) as? [String] {
            return Set(stored).intersection(BackendCapability.forEngine(engine).supportedFlags)
        }

        return Set(argumentParts(from: customArgs).filter {
            $0.hasPrefix("-")
                && !managedArgumentKeys.contains($0)
        })
        .intersection(BackendCapability.forEngine(engine).supportedFlags)
    }

    func saveSelectedFlags(_ flags: Set<String>, for engine: BypassEngine) {
        let supported = flags.intersection(BackendCapability.forEngine(engine).supportedFlags)
        defaults.set(supported.sorted(), forKey: selectedFlagsKey(for: engine))
    }

    func applyIpv6Preference() {
        applyIpv6Settings(disableIpv6)
    }

    func restoreIpv6Defaults() {
        applyIpv6Settings(false)
    }

    func updateArgs(
        with flags: Set<String>,
        manual: String,
        ttl: String,
        splitMode: String,
        splitPos: String,
        port: String,
        dnsAddr: String,
        dnsMode: String,
        dnsHttpsUrl: String
    ) {
        let manualParts = argumentParts(from: manual)
        var cleanedParts: [String] = []
        var index = 0
        while index < manualParts.count {
            let part = manualParts[index]
            if managedFlagsWithoutValues.contains(part) || flags.contains(part) {
                index += 1
            } else if managedArgumentKeys.contains(part) {
                index += 1
                if index < manualParts.count && !manualParts[index].hasPrefix("-") {
                    index += 1
                }
            } else {
                cleanedParts.append(part)
                index += 1
            }
        }

        let persistedFlags = flags.sorted()
        customArgs = (persistedFlags + cleanedParts).joined(separator: " ")
    }

    func currentEngine(for explicitPath: String? = nil) -> BypassEngine {
        BypassEngine(binaryPath: explicitPath ?? binaryPath)
    }

    func resolvedBinaryPath(for selection: BackendSelection, customPath: String? = nil) -> String {
        switch selection {
        case .automatic:
            return detectBestBinaryPath()
        case .ciadpi:
            return detectedPath(for: .ciadpi) ?? managedCiadpiPath
        case .spoofdpi:
            return detectedPath(for: .spoofdpi) ?? "/opt/homebrew/bin/spoofdpi"
        case .custom:
            let trimmed = customPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? binaryPath : trimmed
        }
    }

    var binaryPathWasUserSet: Bool {
        defaults.object(forKey: "binaryPathWasUserSet") as? Bool ?? false
    }

    func saveUserSelectedBinaryPath(_ path: String) {
        defaults.set(path, forKey: "binaryPath")
        defaults.set(true, forKey: "binaryPathWasUserSet")
    }

    func saveDetectedBinaryPath(_ path: String) {
        defaults.set(path, forKey: "binaryPath")
        defaults.set(false, forKey: "binaryPathWasUserSet")
    }

    func applyBackendSelection(_ selection: BackendSelection, customPath: String? = nil) {
        defaults.set(selection.rawValue, forKey: backendSelectionKey)
        switch selection {
        case .automatic:
            saveDetectedBinaryPath(resolvedBinaryPath(for: selection))
        case .ciadpi, .spoofdpi, .custom:
            saveUserSelectedBinaryPath(resolvedBinaryPath(for: selection, customPath: customPath))
        }
    }

    func detectedPath(for engine: BypassEngine) -> String? {
        let candidates: [String]
        switch engine {
        case .ciadpi:
            candidates = preferredCiadpiPaths()
        case .spoofdpi:
            candidates = preferredSpoofDpiPaths()
        }
        return candidates.first(where: { FileManager.default.fileExists(atPath: $0) })
    }

    func detectBestBinaryPath() -> String {
        let bundledCiadpi = preferredCiadpiPaths().first
        let bundledSpoofDpi = preferredSpoofDpiPaths().first
        let paths = [
            bundledCiadpi,
            bundledSpoofDpi,
        ].compactMap { $0 }
        for path in paths where FileManager.default.fileExists(atPath: path) {
            return path
        }
        return "ciadpi"
    }

    var managedCiadpiPath: String {
        let baseDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
            ?? "\(FileManager.default.homeDirectoryForCurrentUser.path)/Library/Application Support"
        return "\(baseDir)/DPI Killer/bin/ciadpi"
    }

    var managedSpoofdpiPath: String {
        let baseDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
            ?? "\(FileManager.default.homeDirectoryForCurrentUser.path)/Library/Application Support"
        return "\(baseDir)/DPI Killer/bin/spoofdpi"
    }

    private func resolvedBinaryPath(fromStored stored: String) -> String {
        guard !binaryPathWasUserSet else {
            return stored
        }
        guard currentEngine(for: stored) == .spoofdpi else {
            return stored
        }
        if let preferred = preferredCiadpiPaths().first(where: { FileManager.default.fileExists(atPath: $0) }) {
            return preferred
        }
        return stored
    }

    private func preferredCiadpiPaths() -> [String] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            Bundle.main.path(forResource: "ciadpi-binary", ofType: nil, inDirectory: "MacOS"),
            managedCiadpiPath,
            "/opt/homebrew/bin/ciadpi",
            "/usr/local/bin/ciadpi",
            "\(homeDir)/.local/bin/ciadpi"
        ].compactMap { $0 }
    }

    private func preferredSpoofDpiPaths() -> [String] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            Bundle.main.path(forResource: "spoofdpi-binary", ofType: nil, inDirectory: "MacOS"),
            managedSpoofdpiPath,
            "/opt/homebrew/bin/spoofdpi",
            "/usr/local/bin/spoofdpi",
            "/usr/bin/spoofdpi",
            "\(homeDir)/.spoof-dpi/bin/spoofdpi",
            "\(homeDir)/.spoof-dpi/bin/spoof-dpi"
        ].compactMap { $0 }
    }

    func manualArgsString(for explicitPath: String? = nil) -> String {
        let allArgs = argumentParts(from: customArgs)
        let engine = currentEngine(for: explicitPath)
        var manualParts: [String] = []
        var index = 0

        while index < allArgs.count {
            let arg = allArgs[index]
            if optionsFlags.contains(arg) || managedArgumentKeys.contains(arg) {
                index += 1
                if managedFlagsWithoutValues.contains(arg) {
                    continue
                }
                if index < allArgs.count && !allArgs[index].hasPrefix("-") {
                    index += 1
                }
                continue
            }

            if engine == .ciadpi, ["--silent", "--dns-ipv4-only", "--debug"].contains(arg) {
                index += 1
                continue
            }

            manualParts.append(arg)
            index += 1
        }

        return manualParts.joined(separator: " ")
    }

    func launchArguments(for explicitPath: String? = nil) -> [String] {
        let engine = currentEngine(for: explicitPath)
        let manualParts = argumentParts(from: manualArgsString(for: explicitPath))
        let flags = selectedFlags(for: engine)
        let port = (Int(localPort.trimmingCharacters(in: .whitespaces)) ?? 8080).clamped(to: 1...65535)
        let ttlValue = (Int(defaultTTL.trimmingCharacters(in: .whitespaces)) ?? 128).clamped(to: 1...255)
        let fakeCount = (Int(httpsFakeCount.trimmingCharacters(in: .whitespaces)) ?? 0).clamped(to: 0...100)
        let chunkSize = (Int(httpsChunkSize.trimmingCharacters(in: .whitespaces)) ?? 20).clamped(to: 1...1000)

        switch engine {
        case .spoofdpi:
            var args: [String] = []
            if spoofdpiSupportsHeadlessMode(binaryPath: explicitPath ?? binaryPath) {
                args.append("--no-tui")
            }
            if flags.contains("--silent") { args.append("--silent") }
            if flags.contains("--dns-ipv4-only") { args += ["--dns-qtype", "ipv4"] }
            if flags.contains("--debug") { args += ["--log-level", "debug"] }
            args += ["--default-fake-ttl", "\(ttlValue)"]
            if !splitMode.isEmpty && splitMode != "sni" {
                args += ["--https-split-mode", splitMode]
            }
            if httpsDisorder {
                args.append("--https-disorder")
            }
            if fakeCount > 0 {
                args += ["--https-fake-count", "\(fakeCount)"]
            }
            if chunkSize > 0 {
                args += ["--https-chunk-size", "\(chunkSize)"]
            }
            args += ["--listen-addr", "127.0.0.1:\(port)"]
            let normalizedDNSMode = dnsMode.trimmingCharacters(in: .whitespaces)
            let spoofDNSMode: String = switch normalizedDNSMode {
            case "", "udp": "udp"
            case "https", "doh": "https"
            case "system", "sys": "system"
            default: "udp"
            }
            let trimmedDNS = dnsAddr.trimmingCharacters(in: .whitespaces)
            if spoofDNSMode != "system", !trimmedDNS.isEmpty {
                args += ["--dns-addr", trimmedDNS]
            }
            args += ["--dns-mode", spoofDNSMode]
            let trimmedDoH = dnsHttpsUrl.trimmingCharacters(in: .whitespaces)
            if spoofDNSMode == "https", !trimmedDoH.isEmpty {
                args += ["--dns-https-url", trimmedDoH]
            }
            return args + manualParts
        case .ciadpi:
            var args: [String] = ["-p", "\(port)", "--def-ttl", "\(ttlValue)"]
            if flags.contains("--policy-auto") {
                args += ["--auto", "torst"]
            }
            switch splitMode {
            case "sni":
                args += ["--split", "1+s"]
            case "chunk":
                args += ["--tlsrec", "1+s"]
            case "random":
                if !args.contains("--auto") {
                    args += ["--auto", "torst"]
                }
                args += ["--tlsrec", "1+s"]
            default:
                break
            }
            if httpsDisorder {
                args += ["--disorder", "1"]
            }
            if fakeCount > 0 {
                args += ["--fake", "-1", "--ttl", "8"]
            }
            return args + manualParts
        }
    }

    private func engineSettings(for engine: BypassEngine) -> EngineSettings {
        EngineSettings(
            selectedFlags: selectedFlags(for: engine),
            manualArgs: storedManualArgs(for: engine)
        )
    }

    private func storedManualArgs(for engine: BypassEngine) -> String {
        if let key = perEngineManualArgsKeys[engine],
           let stored = defaults.string(forKey: key) {
            return stored
        }
        return manualArgsString(for: legacyMigrationPath(for: engine))
    }

    private func saveManualArgs(_ manualArgs: String, for engine: BypassEngine) {
        guard let key = perEngineManualArgsKeys[engine] else { return }
        defaults.set(manualArgs, forKey: key)
    }

    private func selectedFlagsKey(for engine: BypassEngine) -> String {
        "selectedFlags.\(engine.rawValue)"
    }

    private func legacyMigrationPath(for engine: BypassEngine) -> String {
        switch engine {
        case .ciadpi:
            return "ciadpi"
        case .spoofdpi:
            return "spoofdpi"
        }
    }

    private func argumentParts(from string: String) -> [String] {
        string.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }

    private func clampedString(_ value: String, defaultValue: Int, range: ClosedRange<Int>) -> String {
        let intValue = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? defaultValue
        return String(intValue.clamped(to: range))
    }

    private func unsupportedManualArgumentKeys(for engine: BypassEngine) -> Set<String> {
        switch engine {
        case .ciadpi:
            return [
                "--default-fake-ttl",
                "--https-split-mode",
                "--https-split-pos",
                "--https-fake-count",
                "--https-chunk-size",
                "--https-disorder",
                "--listen-addr",
                "--dns-addr",
                "--dns-mode",
                "--dns-https-url",
                "--dns-qtype",
                "--log-level",
                "--no-tui",
                "--silent",
                "--dns-ipv4-only",
                "--debug"
            ]
        case .spoofdpi:
            return [
                "-p",
                "--port",
                "--def-ttl",
                "--auto",
                "--split",
                "--disorder",
                "--fake",
                "--ttl",
                "--tlsrec",
                "--policy-auto"
            ]
        }
    }

    private var generatedManagedArgumentKeys: Set<String> {
        [
            "--default-fake-ttl",
            "--dns-qtype",
            "--log-level"
        ]
    }

    private func shellEscaped(_ value: String) -> String {
        let specialCharacters = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: "'\"\\$`!;|&<>()*?[]{}"))
        guard value.rangeOfCharacter(from: specialCharacters) != nil else {
            return value
        }
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func applyIpv6Settings(_ disable: Bool) {
        let state = disable ? "off" : "on"
        let script = "services=$(networksetup -listallnetworkservices | grep -v '*'); while IFS= read -r service; do networksetup -setv6\(state) \"$service\" 2>/dev/null; done <<< \"$services\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        try? process.run()
    }

    private func toggleLaunchAtLogin(_ enabled: Bool) {
        let appPath = Bundle.main.bundlePath
        let script: String
        if enabled {
            script = "tell application \"System Events\" to make login item at end with properties {path:\"\(appPath)\", hidden:false, name:\"DPI Killer\"}"
        } else {
            script = "tell application \"System Events\" to delete (every login item whose name is \"DPI Killer\")"
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    private var optionsFlags: Set<String> {
        ["--system-proxy", "--silent", "--dns-ipv4-only", "--debug", "--policy-auto", "--no-tui"]
    }

    private func spoofdpiSupportsHeadlessMode(binaryPath: String) -> Bool {
        guard FileManager.default.isExecutableFile(atPath: binaryPath) else { return false }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["--version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return false }
            let pattern = #"spoofdpi\s+(\d+)\.(\d+)\.(\d+)"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                  let majorRange = Range(match.range(at: 1), in: output),
                  let minorRange = Range(match.range(at: 2), in: output),
                  let major = Int(output[majorRange]),
                  let minor = Int(output[minorRange]) else {
                return false
            }
            return major > 1 || (major == 1 && minor >= 4)
        } catch {
            return false
        }
    }
}
