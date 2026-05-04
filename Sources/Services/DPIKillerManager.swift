import Cocoa
import Foundation
import Network

final class DPIKillerManager {
    static let shared = DPIKillerManager()

    private(set) var process: Process?
    private var installProcess: Process?
    private(set) var isRunning = false
    private let maintenanceQueue = DispatchQueue(label: "com.iddictive.dpikiller.maintenance", qos: .utility)
    private let cleanupLock = NSLock()
    private var hasPerformedCleanup = false
    private var outputPipe: Pipe?
    private var watchdogTimer: DispatchSourceTimer?
    private var highCpuStrikes = 0
    private let maxStrikes = 5
    private let cpuThreshold = 400.0
    private let watchdogInterval: UInt64 = 30
    private var lastRestartTime: Date?
    private let restartCooldown: TimeInterval = 300
    private var forceSystemProxyOverride = false
    private var wasRunningBeforeDisconnect = false
    private var shouldRestoreAfterDisconnect = false
    private var isConnectivityRestartInProgress = false

    private var currentEngine: BypassEngine {
        SettingsStore.shared.currentEngine()
    }

    var isUsingProxyFallback: Bool {
        forceSystemProxyOverride && isRunning
    }

    init() {
        NetworkMonitor.shared.onConnectivityLost = { [weak self] in
            guard let self = self else { return }
            let wasActive = self.isRunning || self.process?.isRunning == true || self.wasRunningBeforeDisconnect
            guard wasActive else { return }
            self.shouldRestoreAfterDisconnect = true
            AppLogger.log("[Manager] Connectivity lost while backend was active. Marked for auto-restore.")
        }

        NetworkMonitor.shared.onConnectivityRestored = { [weak self] in
            guard let self = self else { return }
            guard SettingsStore.shared.autoReconnect, self.shouldRestoreAfterDisconnect else { return }
            guard !self.isConnectivityRestartInProgress else {
                AppLogger.log("[Manager] Connectivity restore is already in progress. Skipping duplicate restart.")
                return
            }
            self.isConnectivityRestartInProgress = true
            DispatchQueue.main.async {
                AppLogger.log("[Manager] Auto-restarting after network restoration...")
                self.restartAfterConnectivityRestoration { success, error in
                    if success {
                        AppLogger.log("[Manager] Auto-restart success.")
                    } else {
                        AppLogger.log("[Manager] Auto-restart failed: \(error ?? "unknown")")
                    }
                    self.isConnectivityRestartInProgress = false
                    (NSApp.delegate as? AppDelegate)?.refreshUI()
                }
            }
        }
        NetworkMonitor.shared.start()
    }

    func start(completion: @escaping (Bool, String?) -> Void) {
        start(forceSystemProxy: false, completion: completion)
    }

    func startProxyFallback(completion: @escaping (Bool, String?) -> Void) {
        start(forceSystemProxy: true, completion: completion)
    }

    private func start(forceSystemProxy: Bool, completion: @escaping (Bool, String?) -> Void) {
        forceSystemProxyOverride = forceSystemProxy
        if isRunning {
            stop()
        }
        killOrphans()
        isRunning = false
        wasRunningBeforeDisconnect = true
        shouldRestoreAfterDisconnect = false

        let binaryPath = SettingsStore.shared.binaryPath
        let engine = SettingsStore.shared.currentEngine(for: binaryPath)
        let port = (Int(SettingsStore.shared.localPort.trimmingCharacters(in: .whitespaces)) ?? 8080).clamped(to: 1...65535)
        AppLogger.log("[Manager] Starting with binary: \(binaryPath)")
        guard FileManager.default.fileExists(atPath: binaryPath) else {
            completion(false, "NOT_INSTALLED")
            return
        }
        if SettingsStore.shared.disableIpv6 {
            SettingsStore.shared.applyIpv6Preference()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = SettingsStore.shared.launchArguments(for: binaryPath)

        let pipe = Pipe()
        outputPipe = pipe
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                let shouldStore = LogStore.shared.shouldCaptureProcessLogs()
                    || SettingsStore.shared.selectedFlags.contains("--debug")
                if shouldStore {
                    LogStore.shared.append(str)
                }
            }
        }

        process.terminationHandler = { [weak self, weak process] _ in
            DispatchQueue.main.async {
                guard let self, let terminatedProcess = process else { return }
                guard self.process === terminatedProcess || self.process == nil else { return }
                self.outputPipe?.fileHandleForReading.readabilityHandler = nil
                self.outputPipe = nil
                self.isRunning = false
                self.process = nil
                self.stopWatchdog()
                (NSApp.delegate as? AppDelegate)?.refreshUI()
            }
        }

        do {
            try process.run()
            self.process = process
            waitForBackendReady(engine: engine, process: process, port: port) { [weak self] ready in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    guard self.process === process, process.isRunning else {
                        self.isRunning = false
                        completion(false, L10n.shared.backendExitedEarly)
                        return
                    }

                    guard ready else {
                        AppLogger.log("[Manager] Backend readiness timed out for \(engine.displayName) on port \(port).")
                        process.terminate()
                        self.outputPipe?.fileHandleForReading.readabilityHandler = nil
                        self.outputPipe = nil
                        self.process = nil
                        self.isRunning = false
                        self.disableSystemProxy()
                        completion(false, L10n.shared.backendStartTimeout)
                        (NSApp.delegate as? AppDelegate)?.refreshUI()
                        return
                    }

                    self.isRunning = true
                    if forceSystemProxy || (SettingsStore.shared.usesSystemProxy && !SettingsStore.shared.vpnModeEnabled) {
                        self.enableSystemProxy(for: engine)
                    }
                    self.startWatchdog()
                    completion(true, nil)
                    (NSApp.delegate as? AppDelegate)?.refreshUI()
                }
            }
        } catch {
            self.isRunning = false
            completion(false, error.localizedDescription)
        }
    }

    func install(completion: @escaping (Bool, String?) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", installScript()]

        installProcess = process

        do {
            try process.run()
            process.terminationHandler = { [weak self] proc in
                DispatchQueue.main.async {
                    self?.installProcess = nil
                    if proc.terminationStatus == 0 {
                        SettingsStore.shared.saveDetectedBinaryPath(SettingsStore.shared.detectBestBinaryPath())
                        completion(true, nil)
                    } else {
                        completion(false, "Installation failed with exit code \(proc.terminationStatus)")
                    }
                }
            }
        } catch {
            installProcess = nil
            completion(false, error.localizedDescription)
        }
    }

    func cancelInstall() {
        installProcess?.terminate()
        installProcess = nil
    }

    func stop() {
        isRunning = false
        forceSystemProxyOverride = false
        wasRunningBeforeDisconnect = false
        shouldRestoreAfterDisconnect = false
        isConnectivityRestartInProgress = false
        stopWatchdog()
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        process?.terminate()
        process = nil
        killOrphans()
        disableSystemProxy()
        (NSApp.delegate as? AppDelegate)?.refreshUI()
    }

    func fullCleanup() {
        cleanupLock.lock()
        if hasPerformedCleanup {
            cleanupLock.unlock()
            return
        }
        hasPerformedCleanup = true
        cleanupLock.unlock()

        AppLogger.log("[Manager] Performing full cleanup...")
        stop()
        SettingsStore.shared.restoreIpv6Defaults()
    }

    func recoverEnvironment(completion: (() -> Void)? = nil) {
        maintenanceQueue.async {
            AppLogger.log("[Manager] Recovering environment after previous run...")
            self.killOrphans()
            self.disableSystemProxy()
            SettingsStore.shared.restoreIpv6Defaults()
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    private func startWatchdog() {
        stopWatchdog()
        highCpuStrikes = 0
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + .seconds(Int(watchdogInterval)), repeating: .seconds(Int(watchdogInterval)))
        timer.setEventHandler { [weak self] in
            self?.checkCPU()
        }
        timer.resume()
        watchdogTimer = timer
    }

    private func stopWatchdog() {
        watchdogTimer?.cancel()
        watchdogTimer = nil
        highCpuStrikes = 0
    }

    private func getCPUUsage() -> Double? {
        guard let proc = process, proc.isRunning else { return nil }
        let pid = proc.processIdentifier
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-p", "\(pid)", "-o", "%cpu="]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               let cpu = Double(output) {
                return cpu
            }
        } catch {}
        return nil
    }

    private func checkCPU() {
        guard isRunning, let cpu = getCPUUsage() else {
            highCpuStrikes = 0
            return
        }
        if cpu > cpuThreshold {
            highCpuStrikes += 1
            AppLogger.log("[Watchdog] High CPU detected: \(cpu)% (strike \(highCpuStrikes)/\(maxStrikes))")
            if highCpuStrikes >= maxStrikes {
                AppLogger.log("[Watchdog] CPU threshold exceeded for \(highCpuStrikes) consecutive checks. Auto-restarting backend...")
                DispatchQueue.main.async { [weak self] in
                    self?.restartDueToHighCPU()
                }
            }
        } else {
            if highCpuStrikes > 0 {
                AppLogger.log("[Watchdog] CPU back to normal: \(cpu)%. Resetting strikes.")
            }
            highCpuStrikes = 0
        }
    }

    private func restartDueToHighCPU() {
        if let lastRestart = lastRestartTime, Date().timeIntervalSince(lastRestart) < restartCooldown {
            AppLogger.log("[Watchdog] Cooldown active, skipping restart.")
            return
        }

        lastRestartTime = Date()
        highCpuStrikes = 0
        stopWatchdog()
        process?.terminate()
        process = nil
        isRunning = false
        killOrphans()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.start(forceSystemProxy: self?.forceSystemProxyOverride ?? false) { success, error in
                if success {
                    AppLogger.log("[Watchdog] Backend restarted successfully.")
                } else {
                    AppLogger.log("[Watchdog] Failed to restart backend: \(error ?? "unknown error")")
                }
                (NSApp.delegate as? AppDelegate)?.refreshUI()
            }
        }
    }

    private func restartAfterConnectivityRestoration(completion: @escaping (Bool, String?) -> Void) {
        shouldRestoreAfterDisconnect = false
        highCpuStrikes = 0
        stopWatchdog()
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        process?.terminate()
        process = nil
        isRunning = false
        killOrphans()
        disableSystemProxy()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.start(forceSystemProxy: self?.forceSystemProxyOverride ?? false, completion: completion)
        }
    }

    private func killOrphans() {
        for processName in Set(currentEngine.processNames + BypassEngine.ciadpi.processNames + BypassEngine.spoofdpi.processNames) {
            let killer = Process()
            killer.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            killer.arguments = ["-9", processName]
            try? killer.run()
            killer.waitUntilExit()
        }
    }

    private func enableSystemProxy(for engine: BypassEngine) {
        let port = (Int(SettingsStore.shared.localPort.trimmingCharacters(in: .whitespaces)) ?? 8080).clamped(to: 1...65535)
        let script: String
        switch engine.proxyMode {
        case .http:
            script = """
            services=$(networksetup -listallnetworkservices | grep -v '^An asterisk' | grep -v '^\\*$');
            while IFS= read -r service; do
              [ -z "$service" ] && continue
              networksetup -setwebproxy "$service" 127.0.0.1 \(port) off 2>/dev/null
              networksetup -setsecurewebproxy "$service" 127.0.0.1 \(port) off 2>/dev/null
              networksetup -setwebproxystate "$service" on 2>/dev/null
              networksetup -setsecurewebproxystate "$service" on 2>/dev/null
              networksetup -setsocksfirewallproxystate "$service" off 2>/dev/null
            done <<< "$services"
            """
        case .socks:
            script = """
            services=$(networksetup -listallnetworkservices | grep -v '^An asterisk' | grep -v '^\\*$');
            while IFS= read -r service; do
              [ -z "$service" ] && continue
              networksetup -setsocksfirewallproxy "$service" 127.0.0.1 \(port) off 2>/dev/null
              networksetup -setsocksfirewallproxystate "$service" on 2>/dev/null
              networksetup -setwebproxystate "$service" off 2>/dev/null
              networksetup -setsecurewebproxystate "$service" off 2>/dev/null
            done <<< "$services"
            """
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        try? process.run()
        process.waitUntilExit()
    }

    func disableSystemProxy() {
        let script = """
        services=$(networksetup -listallnetworkservices | grep -v '^An asterisk' | grep -v '^\\*$');
        while IFS= read -r service; do
          [ -z "$service" ] && continue
          networksetup -setwebproxystate "$service" off 2>/dev/null
          networksetup -setsecurewebproxystate "$service" off 2>/dev/null
          networksetup -setsocksfirewallproxystate "$service" off 2>/dev/null
        done <<< "$services"
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        try? process.run()
        process.waitUntilExit()
    }

    private func installScript() -> String {
        let managedCiadpiPath = SettingsStore.shared.managedCiadpiPath
        let managedSpoofdpiPath = SettingsStore.shared.managedSpoofdpiPath
        let managedDir = URL(fileURLWithPath: managedCiadpiPath).deletingLastPathComponent().path
        return """
        set -e
        mkdir -p '\(managedDir)'

        if command -v cc >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
          tmpdir=$(mktemp -d)
          trap 'rm -rf "$tmpdir"' EXIT INT TERM
          cd "$tmpdir"
          curl -fsSL https://codeload.github.com/hufrea/byedpi/tar.gz/refs/heads/main | tar -xz --strip-components=1
          make >/dev/null
          install -m 755 ciadpi '\(managedCiadpiPath)'
        fi

        python3 <<'PY'
        import json
        import os
        import platform
        import shutil
        import tarfile
        import tempfile
        import urllib.request

        api_url = "https://api.github.com/repos/xvzc/spoofdpi/releases/latest"
        target = r"\(managedSpoofdpiPath)"
        arch = platform.machine().lower()
        suffix = "darwin_arm64.tar.gz" if arch in ("arm64", "aarch64") else "darwin_x86_64.tar.gz"

        with urllib.request.urlopen(api_url) as response:
            release = json.load(response)

        asset = next((item for item in release.get("assets", []) if item.get("name", "").endswith(suffix)), None)
        if asset is None:
            raise SystemExit(f"Missing SpoofDPI asset for {suffix}")

        with tempfile.TemporaryDirectory() as tmp:
            archive_path = os.path.join(tmp, "spoofdpi.tar.gz")
            urllib.request.urlretrieve(asset["browser_download_url"], archive_path)
            with tarfile.open(archive_path, "r:gz") as archive:
                member = next((m for m in archive.getmembers() if os.path.basename(m.name) == "spoofdpi"), None)
                if member is None:
                    raise SystemExit("spoofdpi binary not found in archive")
                archive.extract(member, tmp)
                extracted_path = os.path.join(tmp, member.name)
                os.makedirs(os.path.dirname(target), exist_ok=True)
                shutil.copy2(extracted_path, target)
                os.chmod(target, 0o755)
        PY

        if [ ! -x '\(managedCiadpiPath)' ] && [ ! -x '\(managedSpoofdpiPath)' ]; then
          echo 'No supported backends were installed.' >&2
          exit 1
        fi

        exit 0
        """
    }

    private func waitForBackendReady(
        engine: BypassEngine,
        process: Process,
        port: Int,
        timeout: TimeInterval = 6.0,
        completion: @escaping (Bool) -> Void
    ) {
        DispatchQueue.global(qos: .utility).async {
            let deadline = Date().addingTimeInterval(timeout)
            while Date() < deadline {
                if !process.isRunning {
                    completion(false)
                    return
                }
                if self.isLocalPortReachable(port: port) {
                    AppLogger.log("[Manager] \(engine.displayName) is ready on port \(port).")
                    completion(true)
                    return
                }
                Thread.sleep(forTimeInterval: 0.2)
            }
            completion(false)
        }
    }

    private func isLocalPortReachable(port: Int) -> Bool {
        guard let endpointPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return false }
        let semaphore = DispatchSemaphore(value: 0)
        let connection = NWConnection(host: "127.0.0.1", port: endpointPort, using: .tcp)
        let queue = DispatchQueue(label: "com.iddictive.dpikiller.readiness")
        var reachable = false

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                reachable = true
                semaphore.signal()
            case .failed(_), .cancelled:
                semaphore.signal()
            default:
                break
            }
        }

        connection.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + 1.0)
        connection.cancel()
        return reachable
    }
}
