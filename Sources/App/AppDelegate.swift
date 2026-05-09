import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum RuntimeStatus: Hashable {
        case stopped
        case runningUnoptimized
        case runningOptimized
    }

    var statusItem: NSStatusItem?
    var settingsWindow: SettingsWindowController?
    var helpWindow: HelpWindowController?
    var loadingWindow: LoadingWindowController?
    var speedTestWindow: SpeedTestWindowController?
    var logWindow: LogWindowController?

    private var iconCache: [RuntimeStatus: NSImage] = [:]
    private var lastRefreshTime: Date = .distantPast
    private let refreshThrottleInterval: TimeInterval = 0.5
    private var refreshPending = false
    private var signalSources: [DispatchSourceSignal] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupSignalHandlers()
        TunnelManager.shared.onStatusChange = { [weak self] in
            self?.refreshUI()
        }
        TunnelManager.shared.refresh()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshUI()

        if CommandLine.arguments.contains("--open-settings") {
            DispatchQueue.main.async { [weak self] in
                self?.showSettings()
            }
        }
        if CommandLine.arguments.contains("--open-speed-test") {
            DispatchQueue.main.async { [weak self] in
                self?.showSpeedTest()
            }
        }
        if CommandLine.arguments.contains("--open-logs") {
            DispatchQueue.main.async { [weak self] in
                self?.showLogs()
            }
        }
        if CommandLine.arguments.contains("--open-help") {
            DispatchQueue.main.async { [weak self] in
                self?.showHelp()
            }
        }

        if loadingWindow == nil {
            loadingWindow = LoadingWindowController()
        }
        loadingWindow?.updateStatus(L10n.shared.preparingBypass)
        loadingWindow?.showWithFade()

        DPIKillerManager.shared.recoverEnvironment { [weak self] in
            if !CommandLine.arguments.contains("--skip-update-check") {
                GitHubUpdater.shared.checkForUpdates()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.attemptStart()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        TunnelManager.shared.stop()
        DPIKillerManager.shared.fullCleanup()
    }

    func attemptStart() {
        startSelectedMode { [weak self] success, error in
            self?.loadingWindow?.closeWithFade {
                self?.loadingWindow = nil
                self?.refreshUI()
                if !success {
                    if error == "NOT_INSTALLED" {
                        self?.showInstallAlert()
                    } else {
                        self?.showStartupFailureAlert(error: error)
                    }
                }
            }
        }
    }

    private func showStartupFailureAlert(error: String?) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.shared.failedToStart
        alert.informativeText = userFacingStartupMessage(error)

        NSApp.activate(ignoringOtherApps: true)
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        showSettings()

        presentAlert(alert, attachedTo: settingsWindow?.window)
    }

    func refreshUI() {
        let now = Date()
        if now.timeIntervalSince(lastRefreshTime) < refreshThrottleInterval {
            if !refreshPending {
                refreshPending = true
                DispatchQueue.main.asyncAfter(deadline: .now() + refreshThrottleInterval) { [weak self] in
                    self?.refreshPending = false
                    self?.refreshUI()
                }
            }
            return
        }
        lastRefreshTime = now

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let button = self.statusItem?.button {
                let runtimeStatus = self.currentRuntimeStatus()
                if self.iconCache[runtimeStatus] == nil {
                    self.iconCache[runtimeStatus] = self.createStatusIcon(status: runtimeStatus)
                }
                button.image = self.iconCache[runtimeStatus]
                button.imagePosition = .imageOnly
            }
            self.setupMenu()
        }
    }

    @objc func toggle() {
        if isModeRunning() {
            TunnelManager.shared.stop()
            DPIKillerManager.shared.stop()
        } else {
            startSelectedMode { [weak self] success, error in
                if !success {
                    let alert = NSAlert()
                    alert.alertStyle = .warning
                    alert.messageText = L10n.shared.failedToStart
                    alert.informativeText = self?.userFacingStartupMessage(error) ?? L10n.shared.startupFailureInfo
                    NSApp.activate(ignoringOtherApps: true)
                    self?.presentAlert(alert)
                }
                self?.refreshUI()
            }
        }
        refreshUI()
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.showWindow(nil)
    }

    @objc func showHelp() {
        if helpWindow == nil {
            helpWindow = HelpWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        helpWindow?.showWindow(nil)
    }

    @objc func showSpeedTest() {
        if speedTestWindow == nil {
            speedTestWindow = SpeedTestWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        speedTestWindow?.showWindow(nil)
    }

    @objc func showLogs() {
        if logWindow == nil {
            logWindow = LogWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        logWindow?.showWindow(nil)
    }

    @objc func runDiagnostics() {
        if loadingWindow == nil {
            loadingWindow = LoadingWindowController()
        }
        loadingWindow?.updateStatus(L10n.shared.diagChecking)
        loadingWindow?.showWithFade()

        DiagnosticsManager.shared.checkBypass { [weak self] success, error in
            DispatchQueue.main.async {
                self?.loadingWindow?.closeWithFade {
                    self?.loadingWindow = nil
                    let alert = NSAlert()
                    alert.alertStyle = success ? .informational : .warning
                    alert.messageText = success ? L10n.shared.diagSuccess : L10n.shared.diagFailed
                    alert.informativeText = self?.userFacingDiagnosticsMessage(success: success, error: error) ?? ""
                    NSApp.activate(ignoringOtherApps: true)
                    self?.presentAlert(alert)
                }
            }
        }
    }

    @objc func checkUpdate() {
        GitHubUpdater.shared.checkForUpdates(manual: true)
    }

    @objc func applyNetworkOptimization() {
        SettingsStore.shared.applyMobileHotspotPreset()
        SettingsStore.shared.applyNetworkOptimization { [weak self] success, error in
            guard let self else { return }
            if success {
                if self.isModeRunning() {
                    self.restartRuntime()
                }
                self.refreshUI()
                return
            }

            self.refreshUI()
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = L10n.shared.fixHotspotFailed
            alert.informativeText = error ?? L10n.shared.startupFailureInfo
            self.presentAlert(alert)
        }
    }

    private func showInstallAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.shared.dependencyMissing
        alert.informativeText = L10n.shared.spoofDpiNeeded
        alert.addButton(withTitle: L10n.shared.install)
        alert.addButton(withTitle: L10n.shared.quit)

        presentAlert(alert, attachedTo: loadingWindow?.window ?? settingsWindow?.window) { response in
            if response == .alertFirstButtonReturn {
                self.performInstallation()
            } else {
                NSApp.terminate(nil)
            }
        }
    }

    private func performInstallation() {
        if loadingWindow == nil {
            loadingWindow = LoadingWindowController()
        }
        loadingWindow?.updateStatus(L10n.shared.installing, showCancel: true)
        loadingWindow?.setProgressIndeterminate(true)
        loadingWindow?.cancelHandler = { [weak self] in
            DPIKillerManager.shared.cancelInstall()
            self?.loadingWindow?.closeWithFade {
                self?.loadingWindow = nil
                self?.refreshUI()
            }
        }
        loadingWindow?.showWithFade()

        DPIKillerManager.shared.install { [weak self] success, error in
            if success {
                self?.loadingWindow?.updateStatus(L10n.shared.installComplete)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.loadingWindow?.closeWithFade {
                        self?.loadingWindow = nil
                        self?.refreshUI()
                        self?.attemptStart()
                    }
                }
            } else {
                self?.loadingWindow?.closeWithFade {
                    self?.loadingWindow = nil
                    self?.refreshUI()
                    let fail = NSAlert()
                    fail.alertStyle = .critical
                    fail.messageText = L10n.shared.installFailed
                    fail.informativeText = error ?? L10n.shared.installFailedInfo
                    self?.presentAlert(fail)
                }
            }
        }
    }

    private func createStatusIcon(status: RuntimeStatus) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        if let appIcon = DPISettingsAssets.appIcon() {
            appIcon.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1)
        } else {
            NSColor.secondaryLabelColor.set()
            NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 14, height: 14)).fill()
        }

        let dotRect = NSRect(x: 12.5, y: 1.0, width: 4.5, height: 4.5)
        NSColor.white.set()
        NSBezierPath(ovalIn: dotRect.insetBy(dx: -1, dy: -1)).fill()
        statusColor(for: status).set()
        NSBezierPath(ovalIn: dotRect).fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let runtimeStatus = currentRuntimeStatus()
        menu.addItem(disabledMenuItem(title: L10n.shared.menuRuntimeSection))
        menu.addItem(disabledMenuItem(title: statusTitle(for: runtimeStatus)))
        menu.addItem(disabledMenuItem(title: "\(L10n.shared.runtimeModeTitle) \(runtimeModeTitle())"))
        menu.addItem(disabledMenuItem(title: "\(L10n.shared.backendRuntimeTitle) \(backendRuntimeTitle())"))
        if SettingsStore.shared.isNetworkOptimizationApplied() {
            menu.addItem(disabledMenuItem(title: L10n.shared.networkOptimizationActive))
        } else {
            menu.addItem(actionMenuItem(title: L10n.shared.networkOptimizationApply, action: #selector(applyNetworkOptimization), key: ""))
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(actionMenuItem(title: isModeRunning() ? L10n.shared.stop : L10n.shared.start, action: #selector(toggle), key: "t"))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(disabledMenuItem(title: L10n.shared.menuToolsSection))
        menu.addItem(actionMenuItem(title: L10n.shared.settings, action: #selector(showSettings), key: ","))
        menu.addItem(actionMenuItem(title: L10n.shared.diagTitle, action: #selector(runDiagnostics), key: "d"))
        menu.addItem(actionMenuItem(title: L10n.shared.speedTest, action: #selector(showSpeedTest), key: "s"))
        menu.addItem(actionMenuItem(title: L10n.shared.logsTitle, action: #selector(showLogs), key: "l"))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(disabledMenuItem(title: L10n.shared.menuUpdateSection))
        menu.addItem(actionMenuItem(title: L10n.shared.updateCheck, action: #selector(checkUpdate), key: "u"))
        menu.addItem(actionMenuItem(title: L10n.shared.instructions, action: #selector(showHelp), key: "h"))

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: L10n.shared.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        quitItem.isEnabled = true
        menu.addItem(quitItem)
        statusItem?.menu = menu
    }

    private func disabledMenuItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func actionMenuItem(title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.isEnabled = true
        return item
    }

    private func presentAlert(
        _ alert: NSAlert,
        attachedTo preferredWindow: NSWindow? = nil,
        completion: ((NSApplication.ModalResponse) -> Void)? = nil
    ) {
        NSApp.activate(ignoringOtherApps: true)
        alert.icon = DPISettingsAssets.appIcon()
        if let window = preferredWindow ?? alertParentWindow() {
            alert.beginSheetModal(for: window) { response in
                completion?(response)
            }
        } else {
            let response = alert.runModal()
            completion?(response)
        }
    }

    private func setupSignalHandlers() {
        let signals = [SIGINT, SIGTERM]
        signalSources.removeAll()
        for signalNumber in signals {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler {
                DPIKillerManager.shared.fullCleanup()
                exit(0)
            }
            source.resume()
            signalSources.append(source)
        }
    }

    private func currentRuntimeStatus() -> RuntimeStatus {
        if SettingsStore.shared.vpnModeEnabled {
            if TunnelManager.shared.status == .connected, DPIKillerManager.shared.isRunning {
                return .runningOptimized
            }
            if DPIKillerManager.shared.isRunning || TunnelManager.shared.isActive {
                return .runningUnoptimized
            }
            return .stopped
        }

        guard DPIKillerManager.shared.isRunning else { return .stopped }
        return SettingsStore.shared.isNetworkOptimizationApplied() ? .runningOptimized : .runningUnoptimized
    }

    func restartRuntime() {
        TunnelManager.shared.stop()
        DPIKillerManager.shared.stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startSelectedMode { _, _ in
                self?.refreshUI()
            }
        }
    }

    private func isModeRunning() -> Bool {
        SettingsStore.shared.vpnModeEnabled ? TunnelManager.shared.isActive || DPIKillerManager.shared.isRunning : DPIKillerManager.shared.isRunning
    }

    private func startSelectedMode(completion: @escaping (Bool, String?) -> Void) {
        if SettingsStore.shared.vpnModeEnabled {
            if let issue = SystemExtensionManager.shared.availabilityIssue() {
                AppLogger.log("[App] VPN mode is unavailable for this build. Disabling the toggle and starting in proxy mode.")
                SettingsStore.shared.vpnModeEnabled = false
                DPIKillerManager.shared.start { success, error in
                    completion(success, error ?? issue)
                }
                return
            }

            SystemExtensionManager.shared.ensureActivated { activated, activationIssue, disableToggle in
                if !activated {
                    if disableToggle {
                        SettingsStore.shared.vpnModeEnabled = false
                    }
                    AppLogger.log("[App] System extension is not active. Starting in proxy mode.")
                    DPIKillerManager.shared.start { success, error in
                        completion(success, error ?? activationIssue)
                    }
                    return
                }

                DPIKillerManager.shared.start { success, error in
                    guard success else {
                        completion(false, error)
                        return
                    }
                    TunnelManager.shared.start { tunnelSuccess, tunnelError in
                        if !tunnelSuccess {
                            AppLogger.log("[App] VPN mode start failed. Falling back to system proxy mode.")
                            DPIKillerManager.shared.stop()
                            DPIKillerManager.shared.startProxyFallback { fallbackSuccess, fallbackError in
                                if fallbackSuccess {
                                    AppLogger.log("[App] Proxy fallback is active.")
                                    completion(true, nil)
                                } else {
                                    completion(false, tunnelError ?? fallbackError)
                                }
                            }
                            return
                        }
                        completion(true, nil)
                    }
                }
            }
        } else {
            DPIKillerManager.shared.start(completion: completion)
        }
    }

    private func statusTitle(for status: RuntimeStatus) -> String {
        switch status {
        case .stopped:
            return L10n.shared.statusStopped
        case .runningUnoptimized:
            return L10n.shared.statusPartial
        case .runningOptimized:
            return L10n.shared.statusActive
        }
    }

    private func runtimeModeTitle() -> String {
        if !isModeRunning() {
            return L10n.shared.runtimeModeOff
        }
        if SettingsStore.shared.vpnModeEnabled {
            if TunnelManager.shared.status == .connected {
                return L10n.shared.runtimeModeVpn
            }
            if DPIKillerManager.shared.isUsingProxyFallback {
                return L10n.shared.runtimeModeProxyFallback
            }
        }
        return L10n.shared.runtimeModeProxy
    }

    private func backendRuntimeTitle() -> String {
        SettingsStore.shared.resolvedEngine.displayName
    }

    private func alertParentWindow() -> NSWindow? {
        if let keyWindow = NSApp.keyWindow {
            return keyWindow
        }
        if let window = settingsWindow?.window {
            return window
        }
        if let window = loadingWindow?.window {
            return window
        }
        if let window = speedTestWindow?.window {
            return window
        }
        if let window = logWindow?.window {
            return window
        }
        return helpWindow?.window
    }

    private func userFacingStartupMessage(_ error: String?) -> String {
        guard let error,
              !error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return L10n.shared.startupFailureInfo
        }
        return error
    }

    private func userFacingDiagnosticsMessage(success: Bool, error: String?) -> String {
        if success {
            return L10n.shared.diagSuccessInfo
        }
        guard let error,
              !error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return L10n.shared.diagFailedInfo
        }
        if error.hasPrefix("Status code:") || error == "Unknown response" {
            return L10n.shared.diagFailedInfo
        }
        return error
    }

    private func statusColor(for status: RuntimeStatus) -> NSColor {
        switch status {
        case .stopped:
            return NSColor.systemRed
        case .runningUnoptimized:
            return NSColor.systemOrange
        case .runningOptimized:
            return NSColor.systemGreen
        }
    }

}
