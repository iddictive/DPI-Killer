// Append this file to DPIKillerManager.swift in a disposable compile directory.
// Compile with these production files under Sources/ (Swift 5, macOS 13):
// Core/{SettingsStore,SettingsModels,BypassEngine,Localization,Logging}.swift,
// Services/{NetworkSettingsClient,NetworkHelperInstaller,SystemProxyController,
// Networking,BackendLogStream,BackendProcessConfiguration,CiadpiUpdater}.swift,
// Shared/NetworkSettingsProtocol.swift. Link Cocoa, Foundation, Network,
// ServiceManagement, SystemConfiguration and Security.
// main.swift supplies only these UI stubs, the unmodified Comparable extension
// from UI/AppTheme.swift, and runBackendHealthProbe():
// class ProbeSettingsWindow { func reportNetworkResult(success: Bool, error: String?) {} }
// class AppDelegate: NSObject { var settingsWindow: ProbeSettingsWindow?; func refreshUI() {} }
// The executable must be inside a fixture
// .app with a unique bundle identifier and the packaged ciadpi-binary beside it.
// Never use the production app identifier or an existing running backend.
import Cocoa
import Darwin

extension DPIKillerManager {
    fileprivate func probeServing() { checkServing() }
    fileprivate var probeStrikes: Int { servingFailureStrikes }
    fileprivate func probeReady(port: Int) -> Bool {
        isLocalPortReachable(port: port, engine: .ciadpi)
    }
}

func runBackendHealthProbe() {
    _ = NSApplication.shared
    let domain = Bundle.main.bundleIdentifier!
    precondition(domain.hasPrefix("local.dpikiller.health-probe."))
    let defaults = UserDefaults.standard
    defaults.removePersistentDomain(forName: domain)
    defer { defaults.removePersistentDomain(forName: domain) }
    let store = SettingsStore.shared
    store.networkSettingsMode = .manual
    store.systemProxyEnabled = false
    store.autoUpdate = false
    store.autoReconnect = true
    store.localPort = "29082"
    store.saveUserSelectedBinaryPath(store.managedCiadpiPath)
    let updater = CiadpiUpdater.shared
    let bundled = updater.bundledBinaryPath!
    precondition(store.binaryPath == bundled, "An old managed selection must use the bundled repair")
    precondition(updater.localStatus(selectedPath: bundled).managedPath == bundled)
    store.saveUserSelectedBinaryPath("/explicit/custom/ciadpi")
    precondition(store.binaryPath == "/explicit/custom/ciadpi", "Preserve explicit custom executables")
    store.saveUserSelectedBinaryPath(store.managedCiadpiPath)

    func wait(_ seconds: TimeInterval, until predicate: () -> Bool) {
        let end = Date().addingTimeInterval(seconds)
        while !predicate(), Date() < end {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }
        precondition(predicate(), "Timed out waiting for the native lifecycle")
    }

    let manager = DPIKillerManager.shared
    var started = false
    manager.start { success, error in
        precondition(success, error ?? "Startup failed")
        started = true
    }
    wait(20) { started }
    wait(5) { NetworkMonitor.shared.isConnected }
    let pid = manager.process!.processIdentifier
    let port = manager.activePort!
    precondition(manager.probeReady(port: port))
    for _ in 0..<4 {
        manager.probeServing()
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        precondition(manager.process?.processIdentifier == pid && manager.probeStrikes == 0)
    }
    print("PASS bundled upgrade, custom path, native SOCKS readiness and healthy PID retention")

    // Freeze only this fixture's child: the TCP listener stays open, but the
    // event loop cannot answer SOCKS. One failed check must not kill sessions.
    precondition(kill(pid, SIGSTOP) == 0)
    manager.probeServing()
    wait(4) { manager.probeStrikes == 1 }
    precondition(manager.process?.processIdentifier == pid)
    manager.probeServing()
    wait(4) { manager.probeStrikes == 2 }
    precondition(manager.process?.processIdentifier == pid)
    manager.probeServing()
    wait(15) {
        manager.isRunning && manager.process?.processIdentifier != pid && manager.activePort != nil
    }
    let replacement = manager.process!.processIdentifier
    precondition(manager.probeReady(port: manager.activePort!))
    precondition(kill(pid, 0) != 0 && errno == ESRCH)
    print("PASS two tolerated local failures; confirmed unresponsive child replaced and reaped")

    manager.fullCleanup()
    wait(4) { kill(replacement, 0) != 0 && errno == ESRCH }
    RunLoop.current.run(until: Date().addingTimeInterval(0.3))
    precondition(!manager.isRunning && manager.process == nil)
    precondition(!SystemProxyController.shared.hasLease)
    print("PASS explicit stop, no child resurrection and no system proxy lease")
}
