import Cocoa
import Darwin
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
    private(set) var activePort: Int?
    private var didBecomeReady = false
    private var internalRestartInProgress = false

    // MARK: - Dual mode state (spoofdpi HTTP + ciadpi SOCKS together)
    private(set) var activeCiadpiPort: Int?
    private var isDualMode = false
    private var dualProcesses: [BypassEngine: Process] = [:]
    private var dualPipes: [BypassEngine: Pipe] = [:]
    private var dualPorts: [BypassEngine: Int] = [:]
    private var dualReadyEngines: Set<BypassEngine> = []
    private var dualStartupOutput: [BypassEngine: [String]] = [:]
    private let dualOutputLock = NSLock()
    private var dualRestarting: Set<BypassEngine> = []

    private var currentEngine: BypassEngine {
        SettingsStore.shared.currentEngine()
    }

    var isUsingProxyFallback: Bool {
        forceSystemProxyOverride && isRunning
    }

    var proxyPort: Int {
        activePort ?? preferredLocalPort()
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

    private func start(
        forceSystemProxy: Bool,
        attemptedBPFRepair: Bool = false,
        completion: @escaping (Bool, String?) -> Void
    ) {
        forceSystemProxyOverride = forceSystemProxy
        if SettingsStore.shared.backendSelection == .dual {
            startDual(forceSystemProxy: forceSystemProxy, attemptedBPFRepair: attemptedBPFRepair, completion: completion)
            return
        }
        if isRunning {
            stop()
        }
        isRunning = false
        didBecomeReady = false
        wasRunningBeforeDisconnect = true
        shouldRestoreAfterDisconnect = false

        let binaryPath = SettingsStore.shared.binaryPath
        let engine = SettingsStore.shared.currentEngine(for: binaryPath)
        let preferredPort = preferredLocalPort()
        AppLogger.log("[Manager] Starting with binary: \(binaryPath)")
        guard FileManager.default.fileExists(atPath: binaryPath) else {
            completion(false, "NOT_INSTALLED")
            return
        }
        guard let port = availableLocalPort(preferredPort: preferredPort) else {
            completion(false, L10n.shared.noAvailableLocalPort)
            return
        }
        if port != preferredPort {
            AppLogger.log("[Manager] Preferred port \(preferredPort) is busy. Using \(port).")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = SettingsStore.shared.launchArguments(for: binaryPath, port: port)

        let pipe = Pipe()
        let startupOutputLock = NSLock()
        var startupOutputLines: [String] = []
        let captureStartupOutput: (String) -> Void = { text in
            let lines = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !lines.isEmpty else { return }

            startupOutputLock.lock()
            startupOutputLines.append(contentsOf: lines)
            if startupOutputLines.count > 12 {
                startupOutputLines.removeFirst(startupOutputLines.count - 12)
            }
            startupOutputLock.unlock()
        }
        let capturedStartupOutput: () -> String = {
            startupOutputLock.lock()
            defer { startupOutputLock.unlock() }
            return startupOutputLines.joined(separator: "\n")
        }
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
                captureStartupOutput(str)
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
                let unexpected = self.wasRunningBeforeDisconnect && !self.internalRestartInProgress && self.didBecomeReady
                self.resetBackendState()
                (NSApp.delegate as? AppDelegate)?.refreshUI()
                if unexpected {
                    self.handleUnexpectedBackendExit()
                }
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
                        let output = capturedStartupOutput()
                        if self.shouldAttemptBPFRepair(engine: engine, output: output, attempted: attemptedBPFRepair) {
                            AppLogger.log("[Manager] SpoofDPI needs BPF access. Attempting environment repair...")
                            self.repairBPFAccess { repairSuccess, repairError in
                                guard repairSuccess else {
                                    completion(
                                        false,
                                        self.backendStartupFailureMessage(
                                            base: repairError ?? L10n.shared.backendExitedEarly,
                                            output: output
                                        )
                                    )
                                    return
                                }
                                AppLogger.log("[Manager] BPF access repair completed. Restarting backend...")
                                self.start(forceSystemProxy: forceSystemProxy, attemptedBPFRepair: true, completion: completion)
                            }
                            return
                        }
                        completion(
                            false,
                            self.backendStartupFailureMessage(
                                base: L10n.shared.backendExitedEarly,
                                output: output
                            )
                        )
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
                        completion(
                            false,
                            self.backendStartupFailureMessage(
                                base: L10n.shared.backendStartTimeout,
                                output: capturedStartupOutput()
                            )
                        )
                        (NSApp.delegate as? AppDelegate)?.refreshUI()
                        return
                    }

                    self.maintenanceQueue.async { [weak self] in
                        guard let self else { return }
                        let passes = self.proxyPassesInternetCheck(engine: engine, port: port)
                        DispatchQueue.main.async {
                            guard self.process === process, process.isRunning else {
                                completion(false, L10n.shared.backendExitedEarly)
                                return
                            }
                            guard passes else {
                                self.stop()
                                completion(false, L10n.shared.proxyConnectivityFailed)
                                return
                            }
                            if forceSystemProxy || SettingsStore.shared.usesSystemProxy {
                                if let error = SystemProxyController.shared.apply(mode: engine.proxyMode, port: port) {
                                    self.stop()
                                    completion(false, error)
                                    return
                                }
                            }
                            self.markBackendReady(port: port, completion: completion)
                        }
                    }
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

    private func markBackendReady(port: Int, completion: @escaping (Bool, String?) -> Void) {
        isRunning = true
        activePort = port
        didBecomeReady = true
        startWatchdog()
        completion(true, nil)
        (NSApp.delegate as? AppDelegate)?.refreshUI()
    }

    private func proxyPassesInternetCheck(engine: BypassEngine, port: Int) -> Bool {
        let proxy = "\(engine.proxyMode == .socks ? "socks5h" : "http")://127.0.0.1:\(port)"
        for url in ["https://www.apple.com/library/test/success.html", "https://www.cloudflare.com/cdn-cgi/trace"] {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            task.arguments = ["--silent", "--show-error", "--fail", "--location", "--connect-timeout", "3", "--max-time", "7", "--noproxy", "", "--proxy", proxy, "--output", "/dev/null", url]
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            do {
                try task.run()
                task.waitUntilExit()
                if task.terminationStatus == 0 { return true }
            } catch {
                AppLogger.log("[Manager] Proxy check could not start: \(error.localizedDescription)")
            }
        }
        return false
    }

    func stop() {
        isRunning = false
        didBecomeReady = false
        internalRestartInProgress = false
        forceSystemProxyOverride = false
        wasRunningBeforeDisconnect = false
        shouldRestoreAfterDisconnect = false
        isConnectivityRestartInProgress = false
        activePort = nil
        activeCiadpiPort = nil
        isDualMode = false
        stopWatchdog()
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        disableSystemProxy()
        process?.terminate()
        process = nil
        stopDualProcesses()
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
    }

    func recoverEnvironment(completion: (() -> Void)? = nil) {
        maintenanceQueue.async {
            AppLogger.log("[Manager] Recovering environment after previous run...")
            self.disableSystemProxy()
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
            self?.checkServing()
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
        return getCPUUsage(for: proc)
    }

    private func getCPUUsage(for proc: Process) -> Double? {
        guard proc.isRunning else { return nil }
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
        guard isRunning else {
            highCpuStrikes = 0
            return
        }
        let cpu: Double?
        if isDualMode {
            cpu = dualProcesses.values.compactMap { getCPUUsage(for: $0) }.max()
        } else {
            cpu = getCPUUsage()
        }
        guard let cpu else {
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
        internalRestartInProgress = true
        disableSystemProxy()
        process?.terminate()
        process = nil
        stopDualProcesses()
        isRunning = false
        killOrphans()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.wasRunningBeforeDisconnect else { return }
            self.start(forceSystemProxy: self.forceSystemProxyOverride) { success, error in
                self.internalRestartInProgress = false
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
        internalRestartInProgress = true
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        disableSystemProxy()
        process?.terminate()
        process = nil
        stopDualProcesses()
        isRunning = false
        killOrphans()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.wasRunningBeforeDisconnect else { return }
            self.start(forceSystemProxy: self.forceSystemProxyOverride) { success, error in
                self.internalRestartInProgress = false
                completion(success, error)
            }
        }
    }

    private func resetBackendState() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        isRunning = false
        process = nil
        activePort = nil
        activeCiadpiPort = nil
        isDualMode = false
        stopDualProcesses()
        didBecomeReady = false
        stopWatchdog()
    }

    private func handleUnexpectedBackendExit() {
        AppLogger.log("[Manager] Backend exited after serving. Marking stopped.")
        disableSystemProxy()
        (NSApp.delegate as? AppDelegate)?.refreshUI()
        guard wasRunningBeforeDisconnect, SettingsStore.shared.autoReconnect else { return }
        if let lastRestart = lastRestartTime, Date().timeIntervalSince(lastRestart) < restartCooldown {
            AppLogger.log("[Manager] Restart cooldown active, not restarting dead backend.")
            return
        }
        lastRestartTime = Date()
        internalRestartInProgress = true
        AppLogger.log("[Manager] Restarting dead backend...")
        start(forceSystemProxy: forceSystemProxyOverride) { [weak self] success, error in
            self?.internalRestartInProgress = false
            if success {
                AppLogger.log("[Manager] Dead backend restarted.")
            } else {
                AppLogger.log("[Manager] Dead backend restart failed: \(error ?? "unknown error")")
            }
            (NSApp.delegate as? AppDelegate)?.refreshUI()
        }
    }

    private func checkServing() {
        if isDualMode {
            let snapshot = dualPorts
            guard isRunning, didBecomeReady, !snapshot.isEmpty else { return }
            maintenanceQueue.async { [weak self] in
                guard let self else { return }
                var dead: [BypassEngine] = []
                for (engine, port) in snapshot {
                    let alive = self.dualProcesses[engine]?.isRunning ?? false
                    if !alive || !self.isLocalPortReachable(port: port) {
                        dead.append(engine)
                    }
                }
                guard !dead.isEmpty else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.isRunning, self.isDualMode, self.didBecomeReady else { return }
                    for engine in dead {
                        guard let proc = self.dualProcesses[engine] else { continue }
                        AppLogger.log("[Watchdog] Dual backend \(engine.displayName) not serving. Recycling...")
                        proc.terminate()
                        self.dualBackendTerminated(engine: engine, process: proc)
                    }
                }
            }
            return
        }
        guard isRunning, didBecomeReady, let port = activePort else { return }
        maintenanceQueue.async { [weak self] in
            guard let self else { return }
            let reachable = self.isLocalPortReachable(port: port)
            let internetWorks = !SystemProxyController.shared.hasLease
                || (reachable && self.proxyPassesInternetCheck(engine: self.currentEngine, port: port))
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isRunning, self.didBecomeReady, self.activePort == port else { return }
                let alive = self.process?.isRunning ?? false
                guard !alive || !reachable || !internetWorks else { return }
                AppLogger.log("[Watchdog] Backend not serving (process alive: \(alive), port reachable: \(reachable), internet works: \(internetWorks)). Recycling...")
                self.disableSystemProxy()
                self.process?.terminate()
                self.resetBackendState()
                (NSApp.delegate as? AppDelegate)?.refreshUI()
                self.handleUnexpectedBackendExit()
            }
        }
    }

    private func killOrphans() {
        // Only processes started by this instance are terminated via Process.
    }

    func disableSystemProxy() {
        if !SystemProxyController.shared.restore() {
            AppLogger.log("[Manager] Failed to restore the saved system proxy configuration.")
        }
        let candidatePorts = Set([
            SettingsStore.shared.lastAppliedSystemProxyPort,
            SettingsStore.shared.lastAppliedDualCiadpiPort
        ].compactMap { $0 })
        let ports = candidatePorts.map(String.init).joined(separator: " ")
        guard !ports.isEmpty else { return }

        let script = """
        app_ports=(\(ports));

        owns_app_proxy() {
          local output="$1"
          local enabled server port
          enabled=$(printf '%s\\n' "$output" | awk -F': ' '/^Enabled:/ {print $2; exit}')
          server=$(printf '%s\\n' "$output" | awk -F': ' '/^Server:/ {print $2; exit}')
          port=$(printf '%s\\n' "$output" | awk -F': ' '/^Port:/ {print $2; exit}')
          [ "$enabled" = "Yes" ] || return 1
          [ "$server" = "127.0.0.1" ] || [ "$server" = "localhost" ] || return 1
          for app_port in "${app_ports[@]}"; do
            [ "$port" = "$app_port" ] && return 0
          done
          return 1
        }

        services=$(networksetup -listallnetworkservices | grep -v '^An asterisk' | grep -v '^\\*$');
        while IFS= read -r service; do
          [ -z "$service" ] && continue
          if owns_app_proxy "$(networksetup -getwebproxy "$service" 2>/dev/null)"; then
            networksetup -setwebproxystate "$service" off 2>/dev/null
          fi
          if owns_app_proxy "$(networksetup -getsecurewebproxy "$service" 2>/dev/null)"; then
            networksetup -setsecurewebproxystate "$service" off 2>/dev/null
          fi
          if owns_app_proxy "$(networksetup -getsocksfirewallproxy "$service" 2>/dev/null)"; then
            networksetup -setsocksfirewallproxystate "$service" off 2>/dev/null
          fi
        done <<< "$services"
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        try? process.run()
        process.waitUntilExit()
        SettingsStore.shared.lastAppliedSystemProxyPort = nil
        SettingsStore.shared.lastAppliedDualCiadpiPort = nil
    }

    // MARK: - Dual mode (spoofdpi HTTP plus ciadpi SOCKS together)

    private func stopDualProcesses() {
        for (_, proc) in dualProcesses {
            proc.terminationHandler = nil
            proc.terminate()
        }
        dualProcesses.removeAll()
        for (_, pipe) in dualPipes {
            pipe.fileHandleForReading.readabilityHandler = nil
        }
        dualPipes.removeAll()
        dualPorts.removeAll()
        dualReadyEngines.removeAll()
        dualRestarting.removeAll()
    }

    private func appendDualOutput(engine: BypassEngine, text: String) {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { return }
        dualOutputLock.lock()
        var stored = dualStartupOutput[engine] ?? []
        stored.append(contentsOf: lines)
        if stored.count > 12 {
            stored.removeFirst(stored.count - 12)
        }
        dualStartupOutput[engine] = stored
        dualOutputLock.unlock()
    }

    private func dualStartupOutputText() -> String {
        dualOutputLock.lock()
        defer { dualOutputLock.unlock() }
        var parts: [String] = []
        for engine in [BypassEngine.spoofdpi, BypassEngine.ciadpi] {
            if let lines = dualStartupOutput[engine], !lines.isEmpty {
                parts.append(engine.displayName + ":\n" + lines.joined(separator: "\n"))
            }
        }
        return parts.joined(separator: "\n")
    }

    private func shouldAttemptBPFRepairDual(output: String, attempted: Bool) -> Bool {
        guard !attempted else { return false }
        let normalized = output.lowercased()
        return normalized.contains("pcap")
            && normalized.contains("permission denied")
            && (normalized.contains("/dev/bpf") || normalized.contains("open pcap handle"))
    }

    private func availableLocalPortExcluding(preferredPort: Int, excluding: [Int]) -> Int? {
        let excluded = Set(excluding)
        let clampedPreferred = preferredPort.clamped(to: 1...65535)
        let upper = min(65535, clampedPreferred + 200)
        for port in clampedPreferred...upper where !excluded.contains(port) && isLocalPortAvailable(port: port) {
            return port
        }
        for port in 49152...65535 where !excluded.contains(port) && isLocalPortAvailable(port: port) {
            return port
        }
        return nil
    }

    private func startDual(
        forceSystemProxy: Bool,
        attemptedBPFRepair: Bool = false,
        completion: @escaping (Bool, String?) -> Void
    ) {
        forceSystemProxyOverride = forceSystemProxy
        process?.terminationHandler = nil
        process?.terminate()
        process = nil
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        stopDualProcesses()
        killOrphans()
        disableSystemProxy()
        isRunning = false
        didBecomeReady = false
        isDualMode = true
        activePort = nil
        activeCiadpiPort = nil
        stopWatchdog()
        wasRunningBeforeDisconnect = true
        shouldRestoreAfterDisconnect = false

        let binaries = SettingsStore.shared.dualBinaryPaths()
        let missing = binaries.filter { !FileManager.default.isExecutableFile(atPath: $0.path) }
        guard missing.isEmpty else {
            isDualMode = false
            completion(false, L10n.shared.dualMissingEngine(missing.map { $0.engine.displayName }.joined(separator: ", ")))
            return
        }
        if SettingsStore.shared.disableIpv6 {
            SettingsStore.shared.applyIpv6Preference()
        }
        let preferredPort = preferredLocalPort()
        guard let spoofPort = availableLocalPort(preferredPort: preferredPort) else {
            isDualMode = false
            completion(false, L10n.shared.noAvailableLocalPort)
            return
        }
        guard let ciaPort = availableLocalPortExcluding(preferredPort: preferredPort + 1, excluding: [spoofPort]) else {
            isDualMode = false
            completion(false, L10n.shared.noAvailableLocalPort)
            return
        }
        AppLogger.log("[Manager] Dual start: spoofdpi port \(spoofPort), ciadpi port \(ciaPort).")

        dualStartupOutput = [:]
        var launched: [(engine: BypassEngine, process: Process)] = []
        for binary in binaries {
            let port = binary.engine == .spoofdpi ? spoofPort : ciaPort
            guard let proc = launchDualBackend(engine: binary.engine, binaryPath: binary.path, port: port) else {
                stopDualProcesses()
                killOrphans()
                isDualMode = false
                completion(false, backendStartupFailureMessage(base: L10n.shared.backendExitedEarly, output: dualStartupOutputText()))
                return
            }
            launched.append((engine: binary.engine, process: proc))
        }

        let group = DispatchGroup()
        var readiness: [BypassEngine: Bool] = [:]
        let readinessLock = NSLock()
        for item in launched {
            let port = item.engine == .spoofdpi ? spoofPort : ciaPort
            group.enter()
            waitForBackendReady(engine: item.engine, process: item.process, port: port) { ready in
                readinessLock.lock()
                readiness[item.engine] = ready
                readinessLock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            guard self.isDualMode else { return }
            let live = launched.filter { item in
                readiness[item.engine] == true && item.process.isRunning && self.dualProcesses[item.engine].map({ $0 === item.process }) ?? false
            }.map { $0.engine }
            guard live.count == launched.count else {
                let output = self.dualStartupOutputText()
                let nothingServes = self.dualProcesses.values.allSatisfy({ !$0.isRunning })
                if nothingServes, self.shouldAttemptBPFRepairDual(output: output, attempted: attemptedBPFRepair) {
                    AppLogger.log("[Manager] Dual spoofdpi needs BPF access. Attempting environment repair...")
                    self.repairBPFAccess { repairSuccess, repairError in
                        guard repairSuccess else {
                            self.stopDualProcesses()
                            self.isDualMode = false
                            completion(false, self.backendStartupFailureMessage(base: repairError ?? L10n.shared.backendExitedEarly, output: output))
                            return
                        }
                        AppLogger.log("[Manager] BPF access repair completed. Restarting dual backend...")
                        self.startDual(forceSystemProxy: forceSystemProxy, attemptedBPFRepair: true, completion: completion)
                    }
                    return
                }
                for item in launched where !live.contains(item.engine) {
                    let current = self.dualProcesses[item.engine]
                    let isSame = current.map({ $0 === item.process }) ?? false
                    let replacementWarming = !isSame && (current?.isRunning ?? false)
                    if !replacementWarming {
                        self.restartDualSibling(item.engine)
                    }
                }
                let serving = [BypassEngine.spoofdpi, BypassEngine.ciadpi].filter({ self.dualProcesses[$0]?.isRunning ?? false })
                guard !serving.isEmpty else {
                    AppLogger.log("[Manager] Dual backend failed readiness.")
                    self.stopDualProcesses()
                    self.killOrphans()
                    self.isDualMode = false
                    self.disableSystemProxy()
                    completion(false, self.backendStartupFailureMessage(base: L10n.shared.backendStartTimeout, output: output))
                    (NSApp.delegate as? AppDelegate)?.refreshUI()
                    return
                }
                AppLogger.log("[Manager] Dual degraded: serving with partial backends.")
                self.isRunning = true
                self.didBecomeReady = true
                self.activePort = self.dualPorts[.spoofdpi]
                self.activeCiadpiPort = self.dualPorts[.ciadpi]
                self.dualReadyEngines = Set(serving)
                self.reapplyDualProxyIfNeeded()
                self.startWatchdog()
                completion(true, nil)
                (NSApp.delegate as? AppDelegate)?.refreshUI()
                return
            }
            self.isRunning = true
            self.didBecomeReady = true
            self.activePort = spoofPort
            self.activeCiadpiPort = ciaPort
            self.dualPorts = [.spoofdpi: spoofPort, .ciadpi: ciaPort]
            self.dualReadyEngines = [.spoofdpi, .ciadpi]
            let spoofProxy = forceSystemProxy || (SettingsStore.shared.selectedFlags(for: .spoofdpi).contains("--system-proxy") && !SettingsStore.shared.vpnModeEnabled)
            let ciaProxy = forceSystemProxy || (SettingsStore.shared.selectedFlags(for: .ciadpi).contains("--system-proxy") && !SettingsStore.shared.vpnModeEnabled)
            if spoofProxy || ciaProxy {
                self.enableDualSystemProxy(spoofPort: spoofPort, ciaPort: ciaPort, enableSpoof: spoofProxy, enableCia: ciaProxy)
            }
            self.startWatchdog()
            completion(true, nil)
            (NSApp.delegate as? AppDelegate)?.refreshUI()
        }
    }

    private func launchDualBackend(engine: BypassEngine, binaryPath: String, port: Int) -> Process? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = SettingsStore.shared.launchArguments(for: binaryPath, port: port)
        AppLogger.log("[Manager] Dual launching backend on port.")
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            guard let str = String(data: data, encoding: .utf8), !str.isEmpty else { return }
            self?.appendDualOutput(engine: engine, text: str)
            let shouldStore = LogStore.shared.shouldCaptureProcessLogs()
                || SettingsStore.shared.selectedFlags.contains("--debug")
            if shouldStore {
                LogStore.shared.append(str)
            }
        }
        process.terminationHandler = { [weak self, weak process] _ in
            DispatchQueue.main.async {
                guard let self, process != nil else { return }
                self.dualBackendTerminated(engine: engine, process: process)
            }
        }
        do {
            try process.run()
            dualProcesses[engine] = process
            dualPipes[engine] = pipe
            dualPorts[engine] = port
            return process
        } catch {
            AppLogger.log("[Manager] Dual launch failed.")
            pipe.fileHandleForReading.readabilityHandler = nil
            return nil
        }
    }

    private func dualBackendTerminated(engine: BypassEngine, process: Process?) {
        guard isDualMode else { return }
        guard let current = dualProcesses[engine] else { return }
        if let process, current !== process { return }
        dualProcesses[engine] = nil
        dualPipes[engine]?.fileHandleForReading.readabilityHandler = nil
        dualPipes[engine] = nil
        dualPorts.removeValue(forKey: engine)
        dualReadyEngines.remove(engine)
        if engine == .spoofdpi {
            activePort = dualPorts[.spoofdpi]
        } else {
            activeCiadpiPort = dualPorts[.ciadpi]
        }
        if dualProcesses.isEmpty {
            let unexpected = wasRunningBeforeDisconnect && !internalRestartInProgress && didBecomeReady
            activePort = nil
            activeCiadpiPort = nil
            isRunning = false
            didBecomeReady = false
            isDualMode = false
            stopWatchdog()
            (NSApp.delegate as? AppDelegate)?.refreshUI()
            if unexpected {
                handleUnexpectedBackendExit()
            }
            return
        }
        AppLogger.log("[Manager] Dual backend exited, sibling keeps serving.")
        self.reapplyDualProxyIfNeeded()
        (NSApp.delegate as? AppDelegate)?.refreshUI()
        guard wasRunningBeforeDisconnect, !internalRestartInProgress, didBecomeReady else { return }
        restartDualSibling(engine)
    }

    private func restartDualSibling(_ engine: BypassEngine) {
        guard SettingsStore.shared.autoReconnect else { return }
        guard !dualRestarting.contains(engine) else { return }
        if let lastRestart = lastRestartTime, Date().timeIntervalSince(lastRestart) < restartCooldown {
            AppLogger.log("[Manager] Restart cooldown active, sibling not restarted.")
            return
        }
        lastRestartTime = Date()
        dualRestarting.insert(engine)
        AppLogger.log("[Manager] Restarting dead dual backend.")
        let path = SettingsStore.shared.dualBinaryPaths().first(where: { $0.engine == engine })?.path ?? ""
        guard FileManager.default.isExecutableFile(atPath: path) else {
            dualRestarting.remove(engine)
            return
        }
        let preferred = engine == .spoofdpi ? preferredLocalPort() : preferredLocalPort() + 1
        guard let port = availableLocalPortExcluding(preferredPort: preferred, excluding: Array(dualPorts.values)) else {
            dualRestarting.remove(engine)
            AppLogger.log("[Manager] No free port for dual sibling restart.")
            return
        }
        guard let proc = launchDualBackend(engine: engine, binaryPath: path, port: port) else {
            dualRestarting.remove(engine)
            return
        }
        waitForBackendReady(engine: engine, process: proc, port: port) { [weak self] ready in
            DispatchQueue.main.async {
                guard let self else { return }
                self.dualRestarting.remove(engine)
                guard ready, proc.isRunning, self.isDualMode, self.dualProcesses[engine] === proc else {
                    AppLogger.log("[Manager] Restarted dual backend did not become ready.")
                    if self.dualProcesses[engine] === proc {
                        self.dualProcesses[engine] = nil
                        self.dualPorts.removeValue(forKey: engine)
                        self.dualReadyEngines.remove(engine)
                        proc.terminate()
                    }
                    self.reapplyDualProxyIfNeeded()
                    (NSApp.delegate as? AppDelegate)?.refreshUI()
                    return
                }
                self.dualPorts[engine] = port
                self.dualReadyEngines.insert(engine)
                if engine == .spoofdpi {
                    self.activePort = port
                } else {
                    self.activeCiadpiPort = port
                }
                self.reapplyDualProxyIfNeeded()
                AppLogger.log("[Manager] Dual backend restarted on new port.")
                (NSApp.delegate as? AppDelegate)?.refreshUI()
            }
        }
    }

    private func reapplyDualProxyIfNeeded() {
        let wantSpoof = SettingsStore.shared.selectedFlags(for: .spoofdpi).contains("--system-proxy") && !SettingsStore.shared.vpnModeEnabled
        let wantCia = SettingsStore.shared.selectedFlags(for: .ciadpi).contains("--system-proxy") && !SettingsStore.shared.vpnModeEnabled
        guard wantSpoof || wantCia else { return }
        let spoofUp = wantSpoof && (dualProcesses[.spoofdpi]?.isRunning ?? false)
        let ciaUp = wantCia && (dualProcesses[.ciadpi]?.isRunning ?? false)
        enableDualSystemProxy(
            spoofPort: dualPorts[.spoofdpi],
            ciaPort: dualPorts[.ciadpi],
            enableSpoof: spoofUp,
            enableCia: ciaUp,
            disableSpoof: wantSpoof && !spoofUp,
            disableCia: wantCia && !ciaUp
        )
    }

    private func proxyServiceNames() -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-listallnetworkservices"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("*") && !$0.hasPrefix("An asterisk") }
        } catch {
            return []
        }
    }

    private func runNetworkSetup(_ args: [String]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = args
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()
    }

    private func enableDualSystemProxy(spoofPort: Int?, ciaPort: Int?, enableSpoof: Bool, enableCia: Bool, disableSpoof: Bool = false, disableCia: Bool = false) {
        SettingsStore.shared.lastAppliedSystemProxyPort = enableSpoof ? spoofPort : nil
        SettingsStore.shared.lastAppliedDualCiadpiPort = enableCia ? ciaPort : nil
        for service in proxyServiceNames() {
            if enableSpoof, let spoofPort {
                runNetworkSetup(["-setwebproxy", service, "127.0.0.1", String(spoofPort), "off"])
                runNetworkSetup(["-setsecurewebproxy", service, "127.0.0.1", String(spoofPort), "off"])
                runNetworkSetup(["-setwebproxystate", service, "on"])
                runNetworkSetup(["-setsecurewebproxystate", service, "on"])
            } else if disableSpoof {
                runNetworkSetup(["-setwebproxystate", service, "off"])
                runNetworkSetup(["-setsecurewebproxystate", service, "off"])
            }
            if enableCia, let ciaPort {
                runNetworkSetup(["-setsocksfirewallproxy", service, "127.0.0.1", String(ciaPort), "off"])
                runNetworkSetup(["-setsocksfirewallproxystate", service, "on"])
            } else if disableCia {
                runNetworkSetup(["-setsocksfirewallproxystate", service, "off"])
            }
        }
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
        timeout: TimeInterval = 18.0,
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
                Thread.sleep(forTimeInterval: 0.05)
            }
            completion(false)
        }
    }

    private func backendStartupFailureMessage(base: String, output: String) -> String {
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOutput.isEmpty else { return base }
        return "\(base)\n\nBackend output:\n\(trimmedOutput)"
    }

    private func shouldAttemptBPFRepair(engine: BypassEngine, output: String, attempted: Bool) -> Bool {
        guard engine == .spoofdpi, !attempted else { return false }
        let normalizedOutput = output.lowercased()
        return normalizedOutput.contains("pcap")
            && normalizedOutput.contains("permission denied")
            && (normalizedOutput.contains("/dev/bpf") || normalizedOutput.contains("open pcap handle"))
    }

    private func repairBPFAccess(completion: @escaping (Bool, String?) -> Void) {
        let currentUser = NSUserName()
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>com.antigravity.DPIKiller.ChmodBPF</string>
          <key>ProgramArguments</key>
          <array>
            <string>/bin/sh</string>
            <string>-c</string>
            <string>/usr/bin/chgrp access_bpf /dev/bpf* 2&gt;/dev/null || true; /bin/chmod g+rw /dev/bpf* 2&gt;/dev/null || true</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
        </plist>
        """
        let script = """
        set -e
        user_name=\(shellQuoted(currentUser))
        group_name=access_bpf
        plist_path=/Library/LaunchDaemons/com.antigravity.DPIKiller.ChmodBPF.plist

        if ! /usr/sbin/dseditgroup -q -o read "$group_name" >/dev/null 2>&1; then
          /usr/sbin/dseditgroup -q -o create "$group_name"
        fi
        /usr/sbin/dseditgroup -q -o edit -a "$user_name" -t user "$group_name"

        /bin/cat > "$plist_path" <<'PLIST'
        \(plist)
        PLIST
        /usr/sbin/chown root:wheel "$plist_path"
        /bin/chmod 644 "$plist_path"

        /usr/bin/chgrp "$group_name" /dev/bpf* 2>/dev/null || true
        /bin/chmod g+rw /dev/bpf* 2>/dev/null || true
        /bin/chmod +a "$user_name allow read,write" /dev/bpf* 2>/dev/null || true

        /bin/launchctl bootout system "$plist_path" >/dev/null 2>&1 || true
        /bin/launchctl bootstrap system "$plist_path" >/dev/null 2>&1 || true
        /bin/launchctl kickstart -k system/com.antigravity.DPIKiller.ChmodBPF >/dev/null 2>&1 || true
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e",
            "do shell script \(appleScriptQuoted(script)) with administrator privileges"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            DispatchQueue.global(qos: .utility).async {
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        completion(true, nil)
                    } else {
                        completion(false, output?.isEmpty == false ? output : L10n.shared.backendExitedEarly)
                    }
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }

    private func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func appleScriptQuoted(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            + "\""
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
            case .waiting(_), .failed(_), .cancelled:
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

    private func preferredLocalPort() -> Int {
        (Int(SettingsStore.shared.localPort.trimmingCharacters(in: .whitespaces)) ?? 8080).clamped(to: 1...65535)
    }

    private func availableLocalPort(preferredPort: Int) -> Int? {
        if isLocalPortAvailable(port: preferredPort) {
            return preferredPort
        }

        let upperPreferredRange = min(65535, preferredPort + 200)
        if preferredPort < upperPreferredRange {
            for port in (preferredPort + 1)...upperPreferredRange where isLocalPortAvailable(port: port) {
                return port
            }
        }

        for port in 49152...65535 where isLocalPortAvailable(port: port) {
            return port
        }

        return nil
    }

    private func isLocalPortAvailable(port: Int) -> Bool {
        guard let rawPort = UInt16(exactly: port) else { return false }
        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFileDescriptor >= 0 else { return false }
        defer { close(socketFileDescriptor) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = rawPort.bigEndian
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                bind(socketFileDescriptor, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        if result != 0 {
            return false
        }
        return true
    }
}
