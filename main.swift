import Cocoa
import Foundation
import WebKit

// MARK: - Localization
struct L10n {
    static let shared = L10n()
    let isRussian: Bool
    
    init() {
        let lang = Locale.preferredLanguages.first ?? "en"
        self.isRussian = lang.hasPrefix("ru")
    }
    
    // Menu
    var statusActive: String { isRussian ? "Статус: АКТИВЕН ✅" : "Status: ACTIVE ✅" }
    var statusStopped: String { isRussian ? "Статус: ОСТАНОВЛЕН ❌" : "Status: STOPPED ❌" }
    var start: String { isRussian ? "Запустить" : "Start" }
    var stop: String { isRussian ? "Остановить" : "Stop" }
    var settings: String { isRussian ? "Настройки..." : "Settings..." }
    var logs: String { isRussian ? "Логи" : "Logs" }
    var instructions: String { isRussian ? "Инструкции" : "Instructions" }
    var helpTitle: String { isRussian ? "Инструкция по использованию" : "User Guide & Instructions" }
    var quit: String { isRussian ? "Выйти" : "Quit" }
    
    // Settings Window
    var settingsTitle: String { isRussian ? "Расширенные настройки" : "Advanced Settings" }
    var binaryPath: String { isRussian ? "Путь к бинарнику:" : "Binary Path:" }
    var binaryPlaceholder: String { isRussian ? "Например: /opt/homebrew/bin/spoofdpi" : "e.g. /opt/homebrew/bin/spoofdpi" }
    var argumentsTitle: String { isRussian ? "Аргументы (флаги):" : "Arguments (Flags):" }
    var manualArgsTitle: String { isRussian ? "Доп. аргументы:" : "Manual Arguments:" }
    var manualArgsPlaceholder: String { isRussian ? "-p 8080 -window-size 10" : "-p 8080 -window-size 10" }
    var autoLaunchTitle: String { isRussian ? "Автозагрузка:" : "Auto Launch:" }
    var launchAtLogin: String { isRussian ? "Запускать при старте системы" : "Launch at system startup" }
    var saveAndRestart: String { isRussian ? "Сохранить и Перезапустить" : "Save & Restart" }
    
    // Advanced App Settings
    var ttlTitle: String { isRussian ? "TTL пакетов:" : "Packet TTL:" }
    var ttlPlaceholder: String { isRussian ? "По умолч: 64" : "Default: 64" }
    var ttlInstruction: String { isRussian ? "Помогает обходить некоторые типы DPI." : "Helps bypass certain DPI types." }
    var windowSizeTitle: String { isRussian ? "Размер фрагментации (Window Size):" : "Fragmentation (Window Size):" }
    var windowSizePlaceholder: String { isRussian ? "По умолч: 0 (Выкл)" : "Default: 0 (Off)" }
    var windowSizeInstruction: String { isRussian ? "Измените, если блочит HTTPS." : "Adjust if HTTPS is blocked." }
    
    var portTitle: String { isRussian ? "Локальный порт:" : "Local Port:" }
    var portPlaceholder: String { isRussian ? "По умолч: 8080" : "Default: 8080" }

    var dnsTitle: String { isRussian ? "Настройки DNS:" : "DNS Settings:" }
    var dnsAddrTitle: String { isRussian ? "DNS Адрес:" : "DNS Address:" }
    var dnsModeTitle: String { isRussian ? "Режим DNS:" : "DNS Mode:" }
    var dnsHttpsTitle: String { isRussian ? "DoH URL:" : "DoH URL:" }

    
    // Flag Descriptions
    var descSystemProxy: String { isRussian ? "Использовать системный прокси" : "Use system-wide proxy" }
    var descSilent: String { isRussian ? "Скрыть баннер при запуске" : "Suppress startup banner" }
    var descIpv4Only: String { isRussian ? "Только IPv4 для DNS" : "IPv4 only for DNS" }
    var descDebug: String { isRussian ? "Режим отладки (info/debug)" : "Debug mode (info/debug)" }
    var descPolicyAuto: String { isRussian ? "Авто-детект заблокированных сайтов" : "Auto-detect blocked sites" }
    
    // Alerts/Installer
    var dependencyMissing: String { isRussian ? "Отсутствует зависимость" : "Dependency Missing" }
    var spoofDpiNeeded: String { isRussian ? "SpoofDPI не установлен. Установить через Homebrew?" : "SpoofDPI is not installed. Install via Homebrew?" }
    var install: String { isRussian ? "Установить" : "Install" }
    var installing: String { isRussian ? "Установка..." : "Installing..." }
    var pleaseWaitBrew: String { isRussian ? "Пожалуйста, подождите. Установка через brew может занять минуту." : "Please wait while we install spoofdpi via brew. This might take a minute." }
    var installComplete: String { isRussian ? "Установка завершена" : "Installation Complete" }
    var installSuccess: String { isRussian ? "SpoofDPI успешно установлен. Запуск сервиса..." : "SpoofDPI has been installed successfully. Starting service..." }
    var installFailed: String { isRussian ? "Ошибка установки" : "Installation Failed" }
    var installManual: String { isRussian ? "Неизвестная ошибка. Установите вручную: 'brew install spoofdpi'" : "Unknown error. Please install manually: 'brew install spoofdpi'" }
    var failedToStart: String { isRussian ? "Не удалось запустить" : "Failed to start" }
    var preparingBypass: String { isRussian ? "Подготовка обхода... ⚡️" : "Preparing your bypass... ⚡️" }
    var cancel: String { isRussian ? "Отмена" : "Cancel" }
    
    // Updates
    var updateCheck: String { isRussian ? "Проверить обновления..." : "Check for Updates..." }
    var updateChecking: String { isRussian ? "Проверка обновлений..." : "Checking for updates..." }
    var updateAvailable: String { isRussian ? "Доступно обновление" : "Update Available" }
    var updateLatest: String { isRussian ? "У вас установлена последняя версия." : "You are on the latest version." }
    var updateFound: String { isRussian ? "Доступна новая версия %@. Хотите обновиться?" : "A new version %@ is available. Would you like to update?" }
    var updateDownload: String { isRussian ? "Скачать и установить" : "Download & Install" }
    var updateLater: String { isRussian ? "Позже" : "Later" }
    var updateDownloading: String { isRussian ? "Загрузка обновления..." : "Downloading update..." }
    var updateInstalling: String { isRussian ? "Установка обновления..." : "Installing update..." }
    var updateFailed: String { isRussian ? "Ошибка обновления" : "Update Failed" }
    var autoUpdateTitle: String { isRussian ? "Обновления:" : "Updates:" }
    var autoUpdateToggle: String { isRussian ? "Автоматически проверять обновления" : "Automatically check for updates" }
    var autoDownloadToggle: String { isRussian ? "Автоматически скачивать обновления" : "Automatically download updates" }
}

// MARK: - Settings Store
class SettingsStore {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard
    
    var binaryPath: String {
        get { defaults.string(forKey: "binaryPath") ?? autoDetectBinaryPath() }
        set { defaults.set(newValue, forKey: "binaryPath") }
    }
    
    var customArgs: String {
        get { defaults.string(forKey: "customArgs") ?? "--system-proxy" }
        set { defaults.set(newValue, forKey: "customArgs") }
    }
    
    var defaultTTL: String {
        get { defaults.string(forKey: "defaultTTL") ?? "" }
        set { defaults.set(newValue, forKey: "defaultTTL") }
    }
    
    var windowSize: String {
        get { defaults.string(forKey: "windowSize") ?? "" }
        set { defaults.set(newValue, forKey: "windowSize") }
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
        get { defaults.object(forKey: "autoDownload") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoDownload") }
    }
    
    var selectedFlags: Set<String> {
        let args = customArgs.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return Set(args.filter { $0.hasPrefix("-") && !$0.hasPrefix("--default-ttl") && !$0.hasPrefix("--window-size") && !$0.hasPrefix("--listen-addr") && !$0.hasPrefix("--dns-addr") && !$0.hasPrefix("--dns-mode") && !$0.hasPrefix("--dns-https-url") })
    }
    
    func updateArgs(with flags: Set<String>, manual: String, ttl: String, windowSize: String, port: String, dnsAddr: String, dnsMode: String, dnsHttpsUrl: String) {
        var uniqueFlags = flags.joined(separator: " ")
        if let ttlInt = Int(ttl), ttlInt > 0 {
            uniqueFlags += " --default-ttl \(ttlInt)"
        }
        if let windowInt = Int(windowSize), windowInt > 0 {
            uniqueFlags += " --window-size \(windowInt)"
        }
        
        let portToUse = port.trimmingCharacters(in: .whitespaces)
        if !portToUse.isEmpty && portToUse != "8080" {
            uniqueFlags += " --listen-addr 127.0.0.1:\(portToUse)"
        }

        if !dnsAddr.isEmpty && dnsAddr != "8.8.8.8:53" {
            uniqueFlags += " --dns-addr \(dnsAddr)"
        }

        if !dnsMode.isEmpty && dnsMode != "udp" {
            uniqueFlags += " --dns-mode \(dnsMode)"
        }

        if dnsMode == "doh" && !dnsHttpsUrl.isEmpty && dnsHttpsUrl != "https://dns.google/dns-query" {
            uniqueFlags += " --dns-https-url \(dnsHttpsUrl)"
        }
        
        // Strict filtering for manual arguments
        let manualParts = manual.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var cleanedParts: [String] = []
        var i = 0
        while i < manualParts.count {
            let part = manualParts[i]
            if part == "--default-ttl" || part == "--window-size" || part == "--listen-addr" || part == "--dns-addr" || part == "--dns-mode" || part == "--dns-https-url" {
                i += 2 // Skip flag and value
            } else if flags.contains(part) {
                i += 1 // Skip known flag
            } else if Int(part) != nil {
                i += 1 
            } else {
                cleanedParts.append(part)
                i += 1
            }
        }
        customArgs = "\(uniqueFlags) \(cleanedParts.joined(separator: " "))".trimmingCharacters(in: .whitespaces)
    }
    
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set {
            defaults.set(newValue, forKey: "launchAtLogin")
            toggleLaunchAtLogin(newValue)
        }
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
    
    private func autoDetectBinaryPath() -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let paths = [
            "/opt/homebrew/bin/spoofdpi",
            "/usr/local/bin/spoofdpi",
            "/usr/bin/spoofdpi",
            "\(homeDir)/.spoof-dpi/bin/spoofdpi",
            "\(homeDir)/.spoof-dpi/bin/spoof-dpi"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) { return path }
        }
        return "spoofdpi" // Fallback to PATH
    }
}

// MARK: - GitHub Auto-Update
class GitHubUpdater {
    static let shared = GitHubUpdater()
    private let repo = "iddictive/DPI-Killer"
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private var isChecking = false
    private var downloadTask: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?

    func checkForUpdates(manual: Bool = false) {
        if !manual && !SettingsStore.shared.autoUpdate { return }
        guard !isChecking else { return }
        isChecking = true
        
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("DPIKillerUpdater", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer { self?.isChecking = false }
            guard let data = data, error == nil else { 
                if manual {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = L10n.shared.updateFailed
                        alert.informativeText = error?.localizedDescription ?? "Network error."
                        alert.runModal()
                    }
                }
                return 
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    
                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    if self?.compareVersions(current: self?.currentVersion ?? "", latest: latestVersion) == true {
                        let assets = json["assets"] as? [[String: Any]]
                        let dmgAsset = assets?.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true })
                        let downloadUrl = dmgAsset?["browser_download_url"] as? String
                        
                        DispatchQueue.main.async {
                            if !manual && SettingsStore.shared.autoDownload, let dlUrl = downloadUrl, let url = URL(string: dlUrl) {
                                self?.startAutomatedUpdate(url: url)
                            } else {
                                self?.showUpdateAlert(version: latestVersion, downloadUrl: downloadUrl)
                            }
                        }
                    } else if manual {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = L10n.shared.updateLatest
                            alert.runModal()
                        }
                    }
                }
            } catch {
                print("Update check error: \(error)")
            }
        }.resume()
    }

    private func compareVersions(current: String, latest: String) -> Bool {
        return latest.compare(current, options: .numeric) == .orderedDescending
    }

    private func showUpdateAlert(version: String, downloadUrl: String?) {
        let alert = NSAlert()
        alert.messageText = L10n.shared.updateAvailable
        alert.informativeText = String(format: L10n.shared.updateFound, version)
        alert.addButton(withTitle: L10n.shared.updateDownload)
        alert.addButton(withTitle: L10n.shared.updateLater)
        
        if alert.runModal() == .alertFirstButtonReturn, let urlString = downloadUrl, let url = URL(string: urlString) {
            startAutomatedUpdate(url: url)
        }
    }

    private func startAutomatedUpdate(url: URL) {
        let progress = NSAlert()
        progress.messageText = L10n.shared.updateDownloading
        let indicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 200, height: 20))
        indicator.isIndeterminate = false
        indicator.minValue = 0
        indicator.maxValue = 1
        indicator.doubleValue = 0
        progress.accessoryView = indicator
        
        downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] localURL, _, error in
            DispatchQueue.main.async {
                self?.observation = nil
                if let localURL = localURL, error == nil {
                    // Copy to a permanent temp path
                    let tempPath = NSTemporaryDirectory() + "DPIKillerUpdate.dmg"
                    try? FileManager.default.removeItem(atPath: tempPath)
                    try? FileManager.default.copyItem(at: localURL, to: URL(fileURLWithPath: tempPath))
                    
                    progress.window.close()
                    self?.performInstallation(dmgPath: tempPath)
                } else {
                    let fail = NSAlert()
                    fail.messageText = L10n.shared.updateFailed
                    fail.informativeText = error?.localizedDescription ?? "Download failed."
                    fail.runModal()
                }
            }
        }
        
        observation = downloadTask?.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                indicator.doubleValue = progress.fractionCompleted
            }
        }
        
        downloadTask?.resume()
        progress.runModal()
    }

    private func performInstallation(dmgPath: String) {
        let installAlert = NSAlert()
        installAlert.messageText = L10n.shared.updateInstalling
        let indicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 200, height: 20))
        indicator.isIndeterminate = true
        indicator.startAnimation(nil)
        installAlert.accessoryView = indicator
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let script = """
            mkdir -p /tmp/dpi_killer_update
            hdiutil attach "\(dmgPath)" -mountpoint /tmp/dpi_killer_update -nobrowse -quiet
            # Force replace existing app
            rm -rf /Applications/DPIKiller.app
            cp -R /tmp/dpi_killer_update/DPIKiller.app /Applications/
            hdiutil detach /tmp/dpi_killer_update -quiet
            """
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", script]
            try? process.run()
            process.waitUntilExit()
            
            DispatchQueue.main.async {
                installAlert.window.close()
                if process.terminationStatus == 0 {
                    self?.relaunch()
                } else {
                    let fail = NSAlert()
                    fail.messageText = L10n.shared.updateFailed
                    fail.informativeText = "Could not copy the new version to /Applications."
                    fail.runModal()
                }
            }
        }
        installAlert.runModal()
    }

    private func relaunch() {
        let appPath = "/Applications/DPIKiller.app"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [appPath]
        try? process.run()
        NSApp.terminate(nil)
    }
}

// MARK: - Spoof Manager
class DPIKillerManager {
    static let shared = DPIKillerManager()
    private(set) var process: Process?
    private var installProcess: Process?
    private(set) var isRunning = false
    
    func start(completion: @escaping (Bool, String?) -> Void) {
        if isRunning { stop() }
        killOrphans() // Ensure clean state
        isRunning = false
        
        let binaryPath = SettingsStore.shared.binaryPath
        if !FileManager.default.fileExists(atPath: binaryPath) {
            completion(false, "NOT_INSTALLED")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        
        let rawArgs = SettingsStore.shared.customArgs
        let args = rawArgs.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        process.arguments = args
        
        
        // No pipe needed if we don't process logs - prevents deadlocks
        process.standardOutput = nil
        process.standardError = nil
        
        
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.process = nil
                (NSApp.delegate as? AppDelegate)?.refreshUI()
            }
        }
        
        do {
            try process.run()
            self.process = process
            self.isRunning = true
            completion(true, nil)
        } catch {
            self.isRunning = false
            completion(false, error.localizedDescription)
        }
    }
    
    func install(completion: @escaping (Bool, String?) -> Void) {
        let brewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        let brewPath = brewPaths.first { FileManager.default.fileExists(atPath: $0) }
        
        let process = Process()
        if let bp = brewPath {
            process.executableURL = URL(fileURLWithPath: bp)
            process.arguments = ["install", "spoofdpi"]
        } else {
            // Fallback to official shell script if no brew
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", "curl -fsSL https://raw.githubusercontent.com/xvzc/spoofdpi/main/install.sh | bash"]
        }
        
        self.installProcess = process
        
        do {
            try process.run()
            process.terminationHandler = { [weak self] proc in
                DispatchQueue.main.async {
                    self?.installProcess = nil
                    if proc.terminationStatus == 0 {
                        completion(true, nil)
                    } else {
                        completion(false, "Installation failed with exit code \(proc.terminationStatus)")
                    }
                }
            }
        } catch {
            self.installProcess = nil
            completion(false, error.localizedDescription)
        }
    }

    func cancelInstall() {
        installProcess?.terminate()
        installProcess = nil
    }

    func stop() {
        isRunning = false
        process?.terminate()
        process = nil
        killOrphans() // Double safety cleanup
        disableSystemProxy()
        (NSApp.delegate as? AppDelegate)?.refreshUI()
    }

    private func killOrphans() {
        let killer = Process()
        killer.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        killer.arguments = ["-9", "spoofdpi"]
        try? killer.run()
        killer.waitUntilExit()
    }

    func disableSystemProxy() {
        let script = "services=$(networksetup -listallnetworkservices | grep -v '*'); while IFS= read -r service; do networksetup -setwebproxystate \"$service\" off 2>/dev/null; networksetup -setsecurewebproxystate \"$service\" off 2>/dev/null; done <<< \"$services\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        try? process.run()
        process.waitUntilExit()
    }
}

// MARK: - Windows
struct ArgumentOption {
    let flag: String
    let description: String
}

class SettingsWindowController: NSWindowController {
    var pathField: NSTextField!
    var manualArgsField: NSTextField!
    var ttlField: NSTextField!
    var windowSizeField: NSTextField!
    var portField: NSTextField!
    var dnsAddrField: NSTextField!
    var dnsModeButton: NSPopUpButton!
    var dnsHttpsUrlField: NSTextField!
    var checkboxes: [NSButton] = []
    
    let options = [
        ArgumentOption(flag: "--system-proxy", description: L10n.shared.descSystemProxy),
        ArgumentOption(flag: "--silent", description: L10n.shared.descSilent),
        ArgumentOption(flag: "--dns-ipv4-only", description: L10n.shared.descIpv4Only),
        ArgumentOption(flag: "--debug", description: L10n.shared.descDebug),
        ArgumentOption(flag: "--policy-auto", description: L10n.shared.descPolicyAuto)
    ]
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 850),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.center()
        window.title = L10n.shared.settingsTitle
        self.init(window: window)
        setupUI()
    }
    
    func setupUI() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 850))
        window?.contentView = view
        
        var currentY: CGFloat = 800
        
        let pathLabel = NSTextField(labelWithString: L10n.shared.binaryPath)
        pathLabel.font = .systemFont(ofSize: 13, weight: .bold)
        pathLabel.frame = NSRect(x: 20, y: currentY, width: 200, height: 20)
        view.addSubview(pathLabel)
        currentY -= 30
        
        pathField = NSTextField(frame: NSRect(x: 20, y: currentY, width: 410, height: 24))
        pathField.stringValue = SettingsStore.shared.binaryPath
        pathField.placeholderString = L10n.shared.binaryPlaceholder
        view.addSubview(pathField)
        currentY -= 45
        
        let flagsLabel = NSTextField(labelWithString: L10n.shared.argumentsTitle)
        flagsLabel.font = .systemFont(ofSize: 13, weight: .bold)
        flagsLabel.frame = NSRect(x: 20, y: currentY, width: 300, height: 20)
        view.addSubview(flagsLabel)
        currentY -= 25
        
        let selected = SettingsStore.shared.selectedFlags
        for option in options {
            let cb = NSButton(checkboxWithTitle: option.flag, target: nil, action: nil)
            cb.frame = NSRect(x: 20, y: currentY, width: 150, height: 20)
            cb.state = selected.contains(option.flag) ? .on : .off
            view.addSubview(cb)
            checkboxes.append(cb)
            
            let desc = NSTextField(labelWithString: "— \(option.description)")
            desc.font = .systemFont(ofSize: 11)
            desc.textColor = .secondaryLabelColor
            desc.frame = NSRect(x: 170, y: currentY, width: 260, height: 18)
            view.addSubview(desc)
            currentY -= 22
        }
        currentY -= 15
        
        let ttlLabel = NSTextField(labelWithString: L10n.shared.ttlTitle)
        ttlLabel.font = .systemFont(ofSize: 13, weight: .bold)
        ttlLabel.frame = NSRect(x: 20, y: currentY, width: 110, height: 20)
        view.addSubview(ttlLabel)
        
        ttlField = NSTextField(frame: NSRect(x: 135, y: currentY - 2, width: 80, height: 22))
        ttlField.stringValue = SettingsStore.shared.defaultTTL
        ttlField.placeholderString = L10n.shared.ttlPlaceholder
        view.addSubview(ttlField)
        
        let ttlInstr = NSTextField(labelWithString: "— \(L10n.shared.ttlInstruction)")
        ttlInstr.font = .systemFont(ofSize: 11); ttlInstr.textColor = .secondaryLabelColor
        ttlInstr.frame = NSRect(x: 220, y: currentY, width: 220, height: 18)
        view.addSubview(ttlInstr)
        currentY -= 32
        
        // Port Setting
        let pLabel = NSTextField(labelWithString: L10n.shared.portTitle)
        pLabel.font = .systemFont(ofSize: 13, weight: .bold)
        pLabel.frame = NSRect(x: 20, y: currentY, width: 110, height: 20)
        view.addSubview(pLabel)
        
        portField = NSTextField(frame: NSRect(x: 135, y: currentY - 2, width: 80, height: 22))
        portField.stringValue = SettingsStore.shared.localPort
        portField.placeholderString = L10n.shared.portPlaceholder
        view.addSubview(portField)
        currentY -= 35
        
        let wsLabel = NSTextField(labelWithString: L10n.shared.windowSizeTitle)
        wsLabel.font = .systemFont(ofSize: 13, weight: .bold)
        wsLabel.frame = NSRect(x: 20, y: currentY, width: 280, height: 20)
        view.addSubview(wsLabel)
        currentY -= 25
        
        windowSizeField = NSTextField(frame: NSRect(x: 20, y: currentY, width: 80, height: 22))
        windowSizeField.stringValue = SettingsStore.shared.windowSize
        windowSizeField.placeholderString = L10n.shared.windowSizePlaceholder
        view.addSubview(windowSizeField)
        
        let wsInstr = NSTextField(labelWithString: "— \(L10n.shared.windowSizeInstruction)")
        wsInstr.font = .systemFont(ofSize: 11); wsInstr.textColor = .secondaryLabelColor
        wsInstr.frame = NSRect(x: 105, y: currentY + 2, width: 330, height: 18)
        view.addSubview(wsInstr)
        currentY -= 40
        
        let loginLabel = NSTextField(labelWithString: L10n.shared.autoLaunchTitle)
        loginLabel.font = .systemFont(ofSize: 13, weight: .bold)
        loginLabel.frame = NSRect(x: 20, y: currentY, width: 300, height: 20)
        view.addSubview(loginLabel)
        currentY -= 25
        
        let loginCheckbox = NSButton(checkboxWithTitle: L10n.shared.launchAtLogin, target: self, action: #selector(toggleLoginItem))
        loginCheckbox.frame = NSRect(x: 20, y: currentY, width: 410, height: 20)
        loginCheckbox.state = SettingsStore.shared.launchAtLogin ? .on : .off
        view.addSubview(loginCheckbox)
        currentY -= 30
        
        let updateLabel = NSTextField(labelWithString: L10n.shared.autoUpdateTitle)
        updateLabel.font = .systemFont(ofSize: 13, weight: .bold)
        updateLabel.frame = NSRect(x: 20, y: currentY, width: 300, height: 20)
        view.addSubview(updateLabel)
        currentY -= 25
        
        let updateCheckbox = NSButton(checkboxWithTitle: L10n.shared.autoUpdateToggle, target: self, action: #selector(toggleUpdateItem))
        updateCheckbox.frame = NSRect(x: 20, y: currentY, width: 410, height: 20)
        updateCheckbox.state = SettingsStore.shared.autoUpdate ? .on : .off
        view.addSubview(updateCheckbox)
        currentY -= 22
        
        let downloadCheckbox = NSButton(checkboxWithTitle: L10n.shared.autoDownloadToggle, target: self, action: #selector(toggleDownloadItem))
        downloadCheckbox.frame = NSRect(x: 20, y: currentY, width: 410, height: 20)
        downloadCheckbox.state = SettingsStore.shared.autoDownload ? .on : .off
        downloadCheckbox.isEnabled = SettingsStore.shared.autoUpdate
        view.addSubview(downloadCheckbox)
        currentY -= 40

        // DNS Section
        let dnsLabel = NSTextField(labelWithString: L10n.shared.dnsTitle)
        dnsLabel.font = .systemFont(ofSize: 13, weight: .bold)
        dnsLabel.frame = NSRect(x: 20, y: currentY, width: 300, height: 20)
        view.addSubview(dnsLabel)
        currentY -= 30
        
        let daLabel = NSTextField(labelWithString: L10n.shared.dnsAddrTitle)
        daLabel.frame = NSRect(x: 20, y: currentY, width: 100, height: 20)
        view.addSubview(daLabel)
        dnsAddrField = NSTextField(frame: NSRect(x: 120, y: currentY - 2, width: 150, height: 22))
        dnsAddrField.stringValue = SettingsStore.shared.dnsAddr
        view.addSubview(dnsAddrField)
        currentY -= 30
        
        let dmLabel = NSTextField(labelWithString: L10n.shared.dnsModeTitle)
        dmLabel.frame = NSRect(x: 20, y: currentY, width: 100, height: 20)
        view.addSubview(dmLabel)
        dnsModeButton = NSPopUpButton(frame: NSRect(x: 120, y: currentY - 2, width: 100, height: 22), pullsDown: false)
        dnsModeButton.addItems(withTitles: ["udp", "doh", "sys"])
        dnsModeButton.selectItem(withTitle: SettingsStore.shared.dnsMode)
        view.addSubview(dnsModeButton)
        currentY -= 30
        
        let dhLabel = NSTextField(labelWithString: L10n.shared.dnsHttpsTitle)
        dhLabel.frame = NSRect(x: 20, y: currentY, width: 100, height: 20)
        view.addSubview(dhLabel)
        dnsHttpsUrlField = NSTextField(frame: NSRect(x: 120, y: currentY - 2, width: 310, height: 22))
        dnsHttpsUrlField.stringValue = SettingsStore.shared.dnsHttpsUrl
        view.addSubview(dnsHttpsUrlField)
        currentY -= 40
        
        let manualLabel = NSTextField(labelWithString: L10n.shared.manualArgsTitle)
        manualLabel.font = .systemFont(ofSize: 13, weight: .bold)
        manualLabel.frame = NSRect(x: 20, y: currentY, width: 300, height: 20)
        view.addSubview(manualLabel)
        currentY -= 30
        
        manualArgsField = NSTextField(frame: NSRect(x: 20, y: currentY, width: 410, height: 24))
        let allArgs = SettingsStore.shared.customArgs.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var manualParts: [String] = []
        var i = 0
        while i < allArgs.count {
            let arg = allArgs[i]
            if arg == "--default-ttl" || arg == "--window-size" || arg == "--listen-addr" || arg == "--dns-addr" || arg == "--dns-mode" || arg == "--dns-https-url" {
                i += 2 // skip flag AND its value
            } else if options.contains(where: { $0.flag == arg }) {
                i += 1 // skip the flag itself
            } else if Int(arg) != nil {
                i += 1 // skip standalone numbers (likely leaked values)
            } else {
                manualParts.append(arg)
                i += 1
            }
        }
        manualArgsField.stringValue = manualParts.joined(separator: " ")
        manualArgsField.placeholderString = L10n.shared.manualArgsPlaceholder
        view.addSubview(manualArgsField)
        currentY -= 45
        
        let saveButton = NSButton(title: L10n.shared.saveAndRestart, target: self, action: #selector(save))
        saveButton.frame = NSRect(x: 220, y: 20, width: 210, height: 32)
        saveButton.bezelStyle = .rounded
        view.addSubview(saveButton)
    }
    
    @objc func toggleLoginItem(_ sender: NSButton) {
        SettingsStore.shared.launchAtLogin = (sender.state == .on)
    }
    
    @objc func toggleDownloadItem(_ sender: NSButton) {
        SettingsStore.shared.autoDownload = (sender.state == .on)
    }
    
    @objc func toggleUpdateItem(_ sender: NSButton) {
        SettingsStore.shared.autoUpdate = (sender.state == .on)
    }
    
    @objc func save() {
        var flags = Set<String>()
        for (index, cb) in checkboxes.enumerated() {
            if cb.state == .on { flags.insert(options[index].flag) }
        }
        SettingsStore.shared.binaryPath = pathField.stringValue
        SettingsStore.shared.defaultTTL = ttlField.stringValue.trimmingCharacters(in: .whitespaces)
        SettingsStore.shared.windowSize = windowSizeField.stringValue.trimmingCharacters(in: .whitespaces)
        SettingsStore.shared.localPort = portField.stringValue.trimmingCharacters(in: .whitespaces)
        SettingsStore.shared.dnsAddr = dnsAddrField.stringValue.trimmingCharacters(in: .whitespaces)
        SettingsStore.shared.dnsMode = dnsModeButton.titleOfSelectedItem ?? "udp"
        SettingsStore.shared.dnsHttpsUrl = dnsHttpsUrlField.stringValue.trimmingCharacters(in: .whitespaces)
        SettingsStore.shared.updateArgs(with: flags, manual: manualArgsField.stringValue, 
                                        ttl: SettingsStore.shared.defaultTTL, 
                                        windowSize: SettingsStore.shared.windowSize, 
                                        port: SettingsStore.shared.localPort,
                                        dnsAddr: SettingsStore.shared.dnsAddr,
                                        dnsMode: SettingsStore.shared.dnsMode,
                                        dnsHttpsUrl: SettingsStore.shared.dnsHttpsUrl)
        
        if DPIKillerManager.shared.isRunning {
            DPIKillerManager.shared.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DPIKillerManager.shared.start { _, _ in 
                    (NSApp.delegate as? AppDelegate)?.refreshUI()
                }
            }
        }
        window?.close()
    }
}

// MARK: - Help Window

class HelpWindowController: NSWindowController {
    var webView: WKWebView!
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 600), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.center(); window.title = L10n.shared.helpTitle
        self.init(window: window); setupUI(); loadReadme()
    }
    func setupUI() {
        webView = WKWebView(frame: window!.contentView!.bounds)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        window?.contentView?.addSubview(webView)
    }
    func loadReadme() {
        guard let path = Bundle.main.path(forResource: "README", ofType: "md"), let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            webView.loadHTMLString("<html><body>\(L10n.shared.isRussian ? "Инструкция недоступна." : "Manual not available.")</body></html>", baseURL: nil)
            return
        }; let html = markdownToHTML(content)
        let styledHTML = "<html><head><style>body { font-family: -apple-system; font-size: 14px; line-height: 1.5; padding: 20px 40px; color: #333; } @media (prefers-color-scheme: dark) { body { color: #eee; } a { color: #4dabf7; } code { background: #333; } pre { background: #222; } } h1 { font-size: 24px; border-bottom: 1px solid #eee; } pre { background: #f8f9fa; padding: 12px; border-radius: 8px; overflow-x: auto; } code { background: #f4f4f4; padding: 2px 5px; border-radius: 4px; font-family: monospace; } img { max-width: 100%; border-radius: 8px; }</style></head><body>\(html)</body></html>"
        webView.loadHTMLString(styledHTML, baseURL: Bundle.main.resourceURL)
    }
    private func markdownToHTML(_ markdown: String) -> String {
        var result = ""; let lines = markdown.components(separatedBy: .newlines); var inCodeBlock = false; var codeContent = ""
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if inCodeBlock { 
                    result += "<pre><code>\(codeContent.trimmingCharacters(in: .whitespacesAndNewlines))</code></pre>\n"
                    codeContent = ""
                    inCodeBlock = false 
                } else { 
                    inCodeBlock = true 
                }
                continue
            }
            if inCodeBlock { 
                codeContent += line.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;") + "\n"
                continue 
            }
            if trimmed.isEmpty { result += "<br>\n"; continue }
            if trimmed.hasPrefix("<") { result += line + "\n"; continue }
            
            if line.hasPrefix("# ") { result += "<h1>\(processInline(String(line.dropFirst(2))))</h1>\n"; continue }
            if line.hasPrefix("## ") { result += "<h2>\(processInline(String(line.dropFirst(3))))</h2>\n"; continue }
            if line.hasPrefix("### ") { result += "<h3>\(processInline(String(line.dropFirst(4))))</h3>\n"; continue }
            if trimmed == "---" { result += "<hr>\n"; continue }
            if trimmed.hasPrefix("- ") { result += "<li>\(processInline(String(trimmed.dropFirst(2))))</li>\n"; continue }
            result += "<p>\(processInline(line))</p>\n"
        }
        return result
    }
    private func processInline(_ text: String) -> String {
        var p = text
        p = p.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "<b>$1</b>", options: .regularExpression)
        p = p.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)
        p = p.replacingOccurrences(of: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        return p
    }
}

class LoadingWindowController: NSWindowController {
    private var sublabel: NSTextField?
    private var cancelButton: NSButton?
    var cancelHandler: (() -> Void)?
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 340, height: 180), styleMask: [.borderless], backing: .buffered, defer: false)
        window.center(); window.isOpaque = false; window.backgroundColor = .clear; window.level = .floating; window.hasShadow = true; window.isMovableByWindowBackground = true
        self.init(window: window); setupUI()
    }
    func setupUI() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 180))
        container.wantsLayer = true; container.layer?.cornerRadius = 32; container.layer?.masksToBounds = true; window?.contentView = container
        let visualEffect = NSVisualEffectView(frame: container.bounds); visualEffect.blendingMode = .behindWindow; visualEffect.material = .underWindowBackground; visualEffect.state = .active
        container.addSubview(visualEffect)
        if let icon = NSApp.applicationIconImage { let iconView = NSImageView(frame: NSRect(x: 130, y: 85, width: 80, height: 80)); iconView.image = icon; container.addSubview(iconView) }
        let label = NSTextField(labelWithString: "DPI Killer"); label.font = .systemFont(ofSize: 22, weight: .semibold); label.frame = NSRect(x: 0, y: 55, width: 340, height: 30); label.alignment = .center; container.addSubview(label)
        let sublabel = NSTextField(labelWithString: L10n.shared.preparingBypass); sublabel.font = .systemFont(ofSize: 13, weight: .medium); sublabel.textColor = .secondaryLabelColor
        sublabel.frame = NSRect(x: 0, y: 35, width: 340, height: 20); sublabel.alignment = .center; self.sublabel = sublabel; container.addSubview(sublabel)
        let indicator = NSProgressIndicator(frame: NSRect(x: 100, y: 15, width: 140, height: 20)); indicator.style = .bar; indicator.isIndeterminate = true; indicator.startAnimation(nil); container.addSubview(indicator)
        cancelButton = NSButton(title: L10n.shared.cancel, target: self, action: #selector(cancelClicked)); cancelButton?.frame = NSRect(x: 120, y: 5, width: 100, height: 20); cancelButton?.bezelStyle = .recessed; cancelButton?.isHidden = true; container.addSubview(cancelButton!)
        window?.invalidateShadow()
    }
    func updateStatus(_ text: String, showCancel: Bool = false) { DispatchQueue.main.async { self.sublabel?.stringValue = text; self.cancelButton?.isHidden = !showCancel } }
    @objc func cancelClicked() { cancelHandler?() }
    func showWithFade() { window?.alphaValue = 0; showWindow(nil); NSAnimationContext.runAnimationGroup { $0.duration = 0.4; window?.animator().alphaValue = 1.0 } }
    func closeWithFade(completion: @escaping () -> Void) { NSAnimationContext.runAnimationGroup({ $0.duration = 0.4; window?.animator().alphaValue = 0 }, completionHandler: completion) }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: SettingsWindowController?
    var helpWindow: HelpWindowController?
    var loadingWindow: LoadingWindowController?
    
    private var iconCache: [Bool: NSImage] = [:]
    private var lastRefreshTime: Date = .distantPast
    private let refreshThrottleInterval: TimeInterval = 0.5

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupSignalHandlers()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshUI()
        loadingWindow = LoadingWindowController(); loadingWindow?.showWithFade()
        GitHubUpdater.shared.checkForUpdates()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.attemptStart() }
    }

    func attemptStart() {
        DPIKillerManager.shared.start { [weak self] success, error in
            self?.loadingWindow?.closeWithFade {
                self?.loadingWindow = nil; self?.refreshUI()
                if !success {
                    if error == "NOT_INSTALLED" { self?.showInstallAlert() }
                    else {
                        let alert = NSAlert(); alert.messageText = L10n.shared.failedToStart; alert.informativeText = error ?? (L10n.shared.isRussian ? "Проверьте настройки." : "Check settings.")
                        NSApp.activate(ignoringOtherApps: true); alert.runModal(); self?.showSettings()
                    }
                }
            }
        }
    }

    private func showInstallAlert() {
        let alert = NSAlert(); alert.messageText = L10n.shared.dependencyMissing; alert.informativeText = L10n.shared.spoofDpiNeeded
        alert.addButton(withTitle: L10n.shared.install); alert.addButton(withTitle: L10n.shared.quit)
        NSApp.activate(ignoringOtherApps: true); if alert.runModal() == .alertFirstButtonReturn { performInstallation() } else { NSApp.terminate(nil) }
    }

    private func performInstallation() {
        if loadingWindow == nil { loadingWindow = LoadingWindowController() }
        loadingWindow?.updateStatus(L10n.shared.installing, showCancel: true)
        loadingWindow?.cancelHandler = { [weak self] in DPIKillerManager.shared.cancelInstall(); self?.loadingWindow?.closeWithFade { self?.loadingWindow = nil; self?.refreshUI() } }
        loadingWindow?.showWithFade()
        DPIKillerManager.shared.install { [weak self] success, error in
            self?.loadingWindow?.closeWithFade {
                self?.loadingWindow = nil; self?.refreshUI()
                if success { let s = NSAlert(); s.messageText = L10n.shared.installComplete; s.informativeText = L10n.shared.installSuccess; NSApp.activate(ignoringOtherApps: true); s.runModal(); self?.attemptStart() }
                else if error != nil { let f = NSAlert(); f.messageText = L10n.shared.installFailed; f.informativeText = error ?? L10n.shared.installManual; NSApp.activate(ignoringOtherApps: true); f.runModal() }
            }
        }
    }

    func refreshUI() {
        let now = Date()
        if now.timeIntervalSince(lastRefreshTime) < refreshThrottleInterval {
            DispatchQueue.main.asyncAfter(deadline: .now() + refreshThrottleInterval) { [weak self] in self?.refreshUI() }
            return
        }
        lastRefreshTime = now
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let button = self.statusItem?.button {
                let isRunning = DPIKillerManager.shared.isRunning
                if self.iconCache[isRunning] == nil { self.iconCache[isRunning] = self.createStatusIcon(isRunning: isRunning) }
                button.image = self.iconCache[isRunning]; button.imagePosition = .imageOnly
            }
            self.setupMenu()
        }
    }

    private func createStatusIcon(isRunning: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18); let image = NSImage(size: size); image.lockFocus()
        if let ai = NSApp.applicationIconImage { ai.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1.0) }
        else { NSColor.secondaryLabelColor.set(); NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 14, height: 14)).fill() }
        let dotRect = NSRect(x: 12.5, y: 1.0, width: 4.5, height: 4.5); NSColor.white.set(); NSBezierPath(ovalIn: dotRect.insetBy(dx: -1.0, dy: -1.0)).fill()
        if isRunning { NSColor.systemGreen.set() } else { NSColor.systemRed.set() }; NSBezierPath(ovalIn: dotRect).fill(); image.unlockFocus(); image.isTemplate = false; return image
    }

    func setupMenu() {
        let menu = NSMenu(); let status = DPIKillerManager.shared.isRunning ? L10n.shared.statusActive : L10n.shared.statusStopped
        menu.addItem(NSMenuItem(title: status, action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: DPIKillerManager.shared.isRunning ? L10n.shared.stop : L10n.shared.start, action: #selector(toggle), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: L10n.shared.settings, action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: L10n.shared.updateCheck, action: #selector(checkUpdate), keyEquivalent: "u"))
        menu.addItem(NSMenuItem(title: L10n.shared.instructions, action: #selector(showHelp), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.shared.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc func toggle() {
        if DPIKillerManager.shared.isRunning { DPIKillerManager.shared.stop() }
        else { DPIKillerManager.shared.start { [weak self] s, e in if !s { let a = NSAlert(); a.messageText = L10n.shared.failedToStart; a.informativeText = e ?? "Check settings."; NSApp.activate(ignoringOtherApps: true); a.runModal() }; self?.refreshUI() } }
        refreshUI()
    }

    @objc func showSettings() { if settingsWindow == nil { settingsWindow = SettingsWindowController() }; NSApp.activate(ignoringOtherApps: true); settingsWindow?.showWindow(nil) }
    @objc func showHelp() { if helpWindow == nil { helpWindow = HelpWindowController() }; NSApp.activate(ignoringOtherApps: true); helpWindow?.showWindow(nil) }
    @objc func checkUpdate() { GitHubUpdater.shared.checkForUpdates(manual: true) }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let p = DPIKillerManager.shared.process { p.terminate(); p.waitUntilExit() }
        DPIKillerManager.shared.stop()
    }

    private func setupSignalHandlers() {
        let signals = [SIGINT, SIGTERM]
        for sig in signals {
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler { DPIKillerManager.shared.stop(); exit(0) }
            source.resume()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
