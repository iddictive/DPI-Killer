import Cocoa
import Foundation
import WebKit
import Network

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
    var splitModeTitle: String { isRussian ? "Режим разделения (Split Mode):" : "HTTPS Split Mode:" }
    var splitInstruction: String { isRussian ? "sni, random, chunk или none." : "sni, random, chunk or none." }
    var httpsDisorder: String { isRussian ? "Перемешивание (Disorder):" : "HTTPS Disorder:" }
    var httpsFakeCount: String { isRussian ? "Фейковые пакеты (Fake Count):" : "HTTPS Fake Count:" }
    var httpsChunkSize: String { isRussian ? "Размер чанка (Chunk Size):" : "HTTPS Chunk Size:" }
    var httpsChunkPlaceholder: String { isRussian ? "По умолч: 0" : "Default: 0" }
    var mobilePresetTitle: String { isRussian ? "Оптимизировать для хотспота (iPhone/Android)" : "Optimize for Mobile Hotspot (iPhone/Android)" }
    
    var portTitle: String { isRussian ? "Локальный порт:" : "Local Port:" }
    var portPlaceholder: String { isRussian ? "По умолч: 8080" : "Default: 8080" }

    var hotspotStatusTitle: String { isRussian ? "Состояние хотспота:" : "Hotspot Status:" }
    var hotspotStatusOptimized: String { isRussian ? "Оптимизировано ✅" : "Optimized ✅" }
    var hotspotStatusThrottled: String { isRussian ? "Ограничено провайдером ⚠️" : "Throttled by ISP ⚠️" }
    var fixHotspotButton: String { isRussian ? "Снять ограничения (Sudo)" : "Remove Limits (Sudo)" }
    var fixHotspotSuccess: String { isRussian ? "Настройки TTL успешно применены! 🚀" : "TTL settings applied successfully! 🚀" }
    var fixHotspotFailed: String { isRussian ? "Не удалось применить настройки." : "Failed to apply settings." }
    
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
    
    // Speed Test
    var speedTest: String { isRussian ? "Тест скорости" : "Speed Test" }
    var speedTestTitle: String { isRussian ? "Тестирование скорости" : "Speed Testing" }
    var startTest: String { isRussian ? "Начать тест" : "Start Test" }
    var stopTest: String { isRussian ? "Остановить" : "Stop Test" }
    var testingDownload: String { isRussian ? "Загрузка..." : "Downloading..." }
    var testingUpload: String { isRussian ? "Отдача..." : "Uploading..." }
    var testingPing: String { isRussian ? "Пинг..." : "Ping..." }
    var ping: String { isRussian ? "Пинг" : "Ping" }
    var download: String { isRussian ? "Загрузка" : "Download" }
    var upload: String { isRussian ? "Отдача" : "Upload" }
    var ms: String { isRussian ? "мс" : "ms" }
    var mbps: String { isRussian ? "Мбит/с" : "Mbps" }
    
    // Logs
    var logsTitle: String { isRussian ? "Логи событий" : "Event Logs" }
    var clearLogs: String { isRussian ? "Очистить" : "Clear" }
    var copyLogs: String { isRussian ? "Копировать" : "Copy" }
    
    // Diagnostics
    var diagTitle: String { isRussian ? "Диагностика связи" : "Connectivity Diagnostics" }
    var diagChecking: String { isRussian ? "Проверка..." : "Checking..." }
    var diagSuccess: String { isRussian ? "Обход работает! ✅" : "Bypass is working! ✅" }
    var diagFailed: String { isRussian ? "Обход не работает ❌" : "Bypass is failing ❌" }
    var diagNoProxy: String { isRussian ? "Прокси не запущен" : "Proxy is not running" }
    
    // IPv6
    var disableIpv6: String { isRussian ? "Отключить IPv6 (рекомендуется)" : "Disable IPv6 (recommended)" }
    var ipv6Warning: String { isRussian ? "Предотвращает утечки трафика мимо прокси." : "Prevents traffic leakage bypassing the proxy." }
    
    // Auto Reconnect
    var autoReconnect: String { isRussian ? "Авто-реконнект" : "Auto-reconnect" }
    var tipAutoReconnect: String { isRussian ? "Автоматически восстанавливать прокси при восстановлении WiFi." : "Automatically restore proxy when WiFi connection is restored." }

    // Sections
    var sectionCore: String { isRussian ? "📦 Основные настройки" : "📦 Core Settings" }
    var sectionNetwork: String { isRussian ? "🌐 Сеть и Прокси" : "🌐 Network & Proxy" }
    var sectionDPI: String { isRussian ? "🛡 Стратегия обхода" : "🛡 Bypass Strategy" }
    var sectionDNS: String { isRussian ? "🧬 Настройки DNS" : "🧬 DNS Settings" }
    var sectionApp: String { isRussian ? "📱 Поведение приложения" : "📱 App Behavior" }
    var sectionManual: String { isRussian ? "🛠 Дополнительные флаги" : "🛠 Manual Flags" }

    // Tooltips
    var tipBinaryPath: String { isRussian ? "Полный путь к исполняемому файлу spoofdpi." : "Full path to the spoofdpi executable." }
    var tipLocalPort: String { isRussian ? "Порт, который будет слушать локальный прокси (1-65535)." : "Port for the local proxy (1-65535)." }
    var tipTTL: String { isRussian ? "Time To Live для пакетов. Помогает скрыть присутствие прокси (1-255)." : "Time To Live for packets. Helps hide proxy presence (1-255)." }
    var tipSplitMode: String { isRussian ? "Способ разделения HTTPS пакетов." : "Method for splitting HTTPS packets." }
    var tipFakeCount: String { isRussian ? "Количество фейковых пакетов для запутывания DPI (0-100)." : "Number of fake packets to confuse DPI (0-100)." }
    var tipChunkSize: String { isRussian ? "Размер фрагмента данных в байтах (1-1000)." : "Size of data fragments in bytes (1-1000)." }
    var tipDNSAddr: String { isRussian ? "Адрес DNS сервера (например, 8.8.8.8:53)." : "DNS server address (e.g., 8.8.8.8:53)." }
    var tipDNSSystem: String { isRussian ? "Использовать системные настройки DNS." : "Use system DNS settings." }
}

// MARK: - Log Store (Circular Buffer)
class LogStore {
    static let shared = LogStore()
    private let maxLines = 1000
    private(set) var lines: [String] = []
    var onUpdate: (() -> Void)?
    
    private let queue = DispatchQueue(label: "com.iddictive.logstore", qos: .utility)
    
    // Throttling fields
    private var lastUpdate: Date = .distantPast
    private let throttleInterval: TimeInterval = 0.2 // 5Hz max refresh
    private var updatePending = false
    
    func append(_ text: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let newLines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            if newLines.isEmpty { return }
            
            let timestamp = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withTime, .withColonSeparatorInTime])
            
            for line in newLines {
                self.lines.append("[\(timestamp)] \(line)")
            }
            
            if self.lines.count > self.maxLines {
                self.lines.removeFirst(self.lines.count - self.maxLines)
            }
            
            self.scheduleUpdate()
        }
    }

    private func scheduleUpdate() {
        dispatchPrecondition(condition: .onQueue(queue))
        
        guard !updatePending else { return }
        
        let now = Date()
        let timeSinceLast = now.timeIntervalSince(lastUpdate)
        
        if timeSinceLast >= throttleInterval {
            self.lastUpdate = now
            DispatchQueue.main.async { [weak self] in
                self?.onUpdate?()
                self?.queue.async { self?.updatePending = false }
            }
            updatePending = true
        } else {
            updatePending = true
            let delay = throttleInterval - timeSinceLast
            queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.lastUpdate = Date()
                DispatchQueue.main.async { [weak self] in
                    self?.onUpdate?()
                    self?.queue.async { self?.updatePending = false }
                }
            }
        }
    }
    
    func clear() {
        queue.async {
            self.lines.removeAll()
            DispatchQueue.main.async {
                self.onUpdate?()
            }
        }
    }
    
    func getAllLogs() -> String {
        return queue.sync {
            self.lines.joined(separator: "\n")
        }
    }
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
    
    private func applyIpv6Settings(_ disable: Bool) {
        let state = disable ? "off" : "on"
        let script = "services=$(networksetup -listallnetworkservices | grep -v '*'); while IFS= read -r service; do networksetup -setv6\(state) \"$service\" 2>/dev/null; done <<< \"$services\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]
        try? process.run()
    }
    
    var selectedFlags: Set<String> {
        let args = customArgs.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return Set(args.filter { $0.hasPrefix("-") && !$0.hasPrefix("--default-ttl") && !$0.hasPrefix("--https-chunk-size") && !$0.hasPrefix("--https-fake-count") && !$0.hasPrefix("--listen-addr") && !$0.hasPrefix("--dns-addr") && !$0.hasPrefix("--dns-mode") && !$0.hasPrefix("--dns-https-url") && !$0.hasPrefix("--https-split-mode") })
    }
    
    func updateArgs(with flags: Set<String>, manual: String, ttl: String, splitMode: String, splitPos: String, port: String, dnsAddr: String, dnsMode: String, dnsHttpsUrl: String) {
        var uniqueFlags = flags.joined(separator: " ")
        if let ttlInt = Int(ttl), ttlInt > 0 {
            uniqueFlags += " --default-ttl \(ttlInt)"
        }
        
        if !splitMode.isEmpty && splitMode != "sni" {
            uniqueFlags += " --https-split-mode \(splitMode)"
        }
        
        if let fakeCount = Int(SettingsStore.shared.httpsFakeCount), fakeCount > 0 {
            uniqueFlags += " --https-fake-count \(fakeCount)"
        }
        
        if let chunkSize = Int(SettingsStore.shared.httpsChunkSize), chunkSize > 0 {
            uniqueFlags += " --https-chunk-size \(chunkSize)"
        }
        
        if SettingsStore.shared.httpsDisorder {
            uniqueFlags += " --https-disorder"
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

        if dnsMode == "https" && !dnsHttpsUrl.isEmpty && dnsHttpsUrl != "https://dns.google/dns-query" {
            uniqueFlags += " --dns-https-url \(dnsHttpsUrl)"
        }
        
        // Strict filtering for manual arguments
        let manualParts = manual.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var cleanedParts: [String] = []
        var i = 0
        while i < manualParts.count {
            let part = manualParts[i]
            if part == "--default-ttl" || part == "--https-split-mode" || part == "--https-split-pos" || part == "--listen-addr" || part == "--dns-addr" || part == "--dns-mode" || part == "--dns-https-url" {
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
        let bundlePath = Bundle.main.path(forResource: "spoofdpi-binary", ofType: nil, inDirectory: "MacOS")
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let paths = [
            bundlePath,
            "/opt/homebrew/bin/spoofdpi",
            "/usr/local/bin/spoofdpi",
            "/usr/bin/spoofdpi",
            "\(homeDir)/.spoof-dpi/bin/spoofdpi",
            "\(homeDir)/.spoof-dpi/bin/spoof-dpi"
        ].compactMap { $0 }
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
        
        NSApp.activate(ignoringOtherApps: true)
        // Find the most appropriate window to show the sheet on
        let parentWindow = (NSApp.delegate as? AppDelegate)?.loadingWindow?.window ?? 
                          (NSApp.delegate as? AppDelegate)?.settingsWindow?.window
        
        if let window = parentWindow {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn, let urlString = downloadUrl, let url = URL(string: urlString) {
                    self.startAutomatedUpdate(url: url)
                }
            }
        } else {
            // Fallback to modal if no windows are available to avoid the "bottom-left" bug
            if alert.runModal() == .alertFirstButtonReturn, let urlString = downloadUrl, let url = URL(string: urlString) {
                self.startAutomatedUpdate(url: url)
            }
        }
    }

    private func startAutomatedUpdate(url: URL) {
        DispatchQueue.main.async {
            let appDelegate = NSApp.delegate as? AppDelegate
            if appDelegate?.loadingWindow == nil {
                appDelegate?.loadingWindow = LoadingWindowController()
            }
            appDelegate?.loadingWindow?.updateStatus(L10n.shared.updateDownloading)
            appDelegate?.loadingWindow?.showWithFade()
        }
        
        downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] localURL, _, error in
            DispatchQueue.main.async {
                self?.observation = nil
                if let localURL = localURL, error == nil {
                    let tempPath = NSTemporaryDirectory() + "DPIKillerUpdate.dmg"
                    try? FileManager.default.removeItem(atPath: tempPath)
                    try? FileManager.default.copyItem(at: localURL, to: URL(fileURLWithPath: tempPath))
                    self?.performInstallation(dmgPath: tempPath)
                } else {
                    let fail = NSAlert()
                    fail.messageText = L10n.shared.updateFailed
                    fail.informativeText = error?.localizedDescription ?? "Download failed."
                    fail.runModal()
                    (NSApp.delegate as? AppDelegate)?.loadingWindow?.closeWithFade {
                        (NSApp.delegate as? AppDelegate)?.loadingWindow = nil
                    }
                }
            }
        }
        
        observation = downloadTask?.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                (NSApp.delegate as? AppDelegate)?.loadingWindow?.updateProgress(progress.fractionCompleted)
            }
        }
        
        downloadTask?.resume()
    }

    private func performInstallation(dmgPath: String) {
        DispatchQueue.main.async {
            (NSApp.delegate as? AppDelegate)?.loadingWindow?.updateStatus(L10n.shared.updateInstalling)
            (NSApp.delegate as? AppDelegate)?.loadingWindow?.setProgressIndeterminate(true)
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let script = """
            mkdir -p /tmp/dpi_killer_update
            hdiutil attach "\(dmgPath)" -mountpoint /tmp/dpi_killer_update -nobrowse -quiet
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
                if process.terminationStatus == 0 {
                    self?.relaunch()
                } else {
                    let fail = NSAlert()
                    fail.messageText = L10n.shared.updateFailed
                    fail.informativeText = "Could not copy the new version to /Applications."
                    fail.runModal()
                    (NSApp.delegate as? AppDelegate)?.loadingWindow?.closeWithFade {
                        (NSApp.delegate as? AppDelegate)?.loadingWindow = nil
                    }
                }
            }
        }
    }

    private func relaunch() {
        let appPath = "/Applications/DPIKiller.app"
        let pid = ProcessInfo.processInfo.processIdentifier
        let script = "while kill -0 \(pid) 2>/dev/null; do sleep 0.1; done; open \"\(appPath)\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        try? process.run()
        NSApp.terminate(nil)
    }
}

// MARK: - Extensions
extension NSView {
    func fill(parent: NSView, padding: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: parent.topAnchor, constant: padding),
            self.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: padding),
            self.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -padding),
            self.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -padding)
        ])
    }
}

// MARK: - Spoof Manager
class DPIKillerManager {
    static let shared = DPIKillerManager()
    private(set) var process: Process?
    private var installProcess: Process?
    private(set) var isRunning = false
    
    private var outputPipe: Pipe?
    
    // MARK: CPU Watchdog
    private var watchdogTimer: DispatchSourceTimer?
    private var highCpuStrikes = 0
    private let maxStrikes = 3           // 3 consecutive checks before restart
    private let cpuThreshold = 150.0     // % CPU per-process threshold
    private let watchdogInterval: UInt64 = 30 // seconds between checks
    private var lastRestartTime: Date?
    private let restartCooldown: TimeInterval = 60 // min seconds between auto-restarts

    private var wasRunningBeforeDisconnect = false

    init() {
        NetworkMonitor.shared.onConnectivityRestored = { [weak self] in
            guard let self = self else { return }
            if SettingsStore.shared.autoReconnect && self.wasRunningBeforeDisconnect {
                print("[Manager] Auto-restarting after network restoration...")
                self.start { success, error in
                    if success {
                        print("[Manager] Auto-restart success.")
                    } else {
                        print("[Manager] Auto-restart failed: \(error ?? "unknown")")
                    }
                    (NSApp.delegate as? AppDelegate)?.refreshUI()
                }
            }
        }
        NetworkMonitor.shared.start()
    }
    
    func start(completion: @escaping (Bool, String?) -> Void) {
        if isRunning { stop() }
        killOrphans() // Ensure clean state
        isRunning = false
        wasRunningBeforeDisconnect = true // Mark that we intend to be running
        
        let binaryPath = SettingsStore.shared.binaryPath
        print("[Manager] Starting with binary: \(binaryPath)")
        if !FileManager.default.fileExists(atPath: binaryPath) {
            completion(false, "NOT_INSTALLED")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        
        let rawArgs = SettingsStore.shared.customArgs
        let args = rawArgs.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        process.arguments = args
        
        
        
        
        // Setup Pipe for async logging
        let pipe = Pipe()
        self.outputPipe = pipe
        process.standardOutput = pipe
        process.standardError = pipe
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                LogStore.shared.append(str)
            }
        }
        
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.process = nil
                self?.stopWatchdog()
                (NSApp.delegate as? AppDelegate)?.refreshUI()
            }
        }
        
        do {
            try process.run()
            self.process = process
            self.isRunning = true
            startWatchdog()
            completion(true, nil)
        } catch {
            self.isRunning = false
            completion(false, error.localizedDescription)
        }
    }
    
    // MARK: Watchdog lifecycle
    
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
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
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
            print("[Watchdog] High CPU detected: \(cpu)% (strike \(highCpuStrikes)/\(maxStrikes))")
            
            if highCpuStrikes >= maxStrikes {
                print("[Watchdog] CPU threshold exceeded for \(highCpuStrikes) consecutive checks. Auto-restarting spoofdpi...")
                DispatchQueue.main.async { [weak self] in
                    self?.restartDueToHighCPU()
                }
            }
        } else {
            if highCpuStrikes > 0 {
                print("[Watchdog] CPU back to normal: \(cpu)%. Resetting strikes.")
            }
            highCpuStrikes = 0
        }
    }
    
    private func restartDueToHighCPU() {
        // Cooldown check
        if let lastRestart = lastRestartTime, Date().timeIntervalSince(lastRestart) < restartCooldown {
            print("[Watchdog] Cooldown active, skipping restart.")
            return
        }
        
        lastRestartTime = Date()
        highCpuStrikes = 0
        
        // Stop current process
        stopWatchdog()
        process?.terminate()
        process = nil
        isRunning = false
        killOrphans()
        
        // Restart after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.start { success, error in
                if success {
                    print("[Watchdog] spoofdpi restarted successfully.")
                } else {
                    print("[Watchdog] Failed to restart spoofdpi: \(error ?? "unknown error")")
                }
                (NSApp.delegate as? AppDelegate)?.refreshUI()
            }
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
        wasRunningBeforeDisconnect = false // User manually stopped, don't auto-restart
        stopWatchdog()
        
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        
        process?.terminate()
        process = nil
        killOrphans() // Double safety cleanup
        disableSystemProxy()
        (NSApp.delegate as? AppDelegate)?.refreshUI()
    }

    func fullCleanup() {
        print("[Manager] Performing full cleanup...")
        stop()
        // Ensure IPv6 is restored to default (on)
        SettingsStore.shared.disableIpv6 = false
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

// MARK: - Network Monitor
class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private var lastPathStatus: NWPath.Status = .satisfied
    
    var onConnectivityRestored: (() -> Void)?
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let status = path.status
            print("[NetworkMonitor] Connection status: \(status)")
            
            // Если соединение восстановилось (было не satisfied, стало satisfied)
            if self.lastPathStatus != .satisfied && status == .satisfied {
                print("[NetworkMonitor] Connectivity restored. Notifying...")
                // Даем 2 секунды на стабилизацию интерфейса (получение IP и т.д.)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.onConnectivityRestored?()
                }
            }
            
            self.lastPathStatus = status
        }
    }
    
    func start() {
        monitor.start(queue: queue)
    }
    
    func stop() {
        monitor.cancel()
    }
}

// MARK: - Speed Test Manager
class SpeedTestManager: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    static let shared = SpeedTestManager()
    
    private var session: URLSession?
    private var downloadTask: URLSessionDownloadTask?
    private var uploadTask: URLSessionUploadTask?
    
    private var startTime: Date?
    private var totalBytesReceived: Int64 = 0
    private var totalBytesSent: Int64 = 0
    
    var onUpdate: ((Double, Double, Double) -> Void)? // Ping, Down, Up
    var onFinished: (() -> Void)?
    var onError: ((String) -> Void)?
    
    private var pingValue: Double = 0
    private var downloadValue: Double = 0
    private var uploadValue: Double = 0
    
    func startTest() {
        reset()
        measurePing()
    }
    
    func stopTest() {
        downloadTask?.cancel()
        uploadTask?.cancel()
        session?.invalidateAndCancel()
        onFinished?()
    }
    
    private func reset() {
        pingValue = 0; downloadValue = 0; uploadValue = 0
        totalBytesReceived = 0; totalBytesSent = 0
    }
    
    private func measurePing() {
        let url = URL(string: "https://speed.cloudflare.com/cdn-cgi/trace")!
        let start = Date()
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, error in
            if let error = error {
                self?.onError?(error.localizedDescription)
                return
            }
            self?.pingValue = Date().timeIntervalSince(start) * 1000
            self?.notify()
            self?.startDownload()
        }.resume()
    }
    
    private func startDownload() {
        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=50000000")!
        let config = URLSessionConfiguration.ephemeral
        if DPIKillerManager.shared.isRunning {
            let port = Int(SettingsStore.shared.localPort) ?? 8080
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable: 1,
                kCFNetworkProxiesHTTPProxy: "127.0.0.1",
                kCFNetworkProxiesHTTPPort: port,
                kCFNetworkProxiesHTTPSEnable: 1,
                kCFNetworkProxiesHTTPSProxy: "127.0.0.1",
                kCFNetworkProxiesHTTPSPort: port
            ]
        }
        let queue = OperationQueue()
        queue.name = "SpeedTestQueue"
        queue.maxConcurrentOperationCount = 1
        session = URLSession(configuration: config, delegate: self, delegateQueue: queue)
        startTime = Date()
        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let start = startTime else { return }
        let duration = Date().timeIntervalSince(start)
        if duration > 0 {
            downloadValue = (Double(totalBytesWritten) * 8) / (duration * 1_000_000) // Mbps
            notify()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        forceNotify()
        startUpload()
    }
    
    private func startUpload() {
        let url = URL(string: "https://speed.cloudflare.com/__up")!
        let data = Data(count: 10_000_000) // 10MB upload
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let config = URLSessionConfiguration.ephemeral
        if DPIKillerManager.shared.isRunning {
            let port = Int(SettingsStore.shared.localPort) ?? 8080
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable: 1,
                kCFNetworkProxiesHTTPProxy: "127.0.0.1",
                kCFNetworkProxiesHTTPPort: port,
                kCFNetworkProxiesHTTPSEnable: 1,
                kCFNetworkProxiesHTTPSProxy: "127.0.0.1",
                kCFNetworkProxiesHTTPSPort: port
            ]
        }
        
        let uploadSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        startTime = Date()
        uploadTask = uploadSession.uploadTask(with: request, from: data)
        uploadTask?.resume()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let start = startTime else { return }
        let duration = Date().timeIntervalSince(start)
        if duration > 0 {
            uploadValue = (Double(totalBytesSent) * 8) / (duration * 1_000_000) // Mbps
            notify()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onError?(error.localizedDescription)
        } else if task == uploadTask {
            forceNotify()
            onFinished?()
        }
    }
    
    private var lastNotifyTime: Date = .distantPast
    private let notifyThrottle: TimeInterval = 0.3 // ~3 updates per second

    private func notify() {
        let now = Date()
        if now.timeIntervalSince(lastNotifyTime) >= notifyThrottle {
            lastNotifyTime = now
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onUpdate?(self.pingValue, self.downloadValue, self.uploadValue)
            }
        }
    }
    
    func forceNotify() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onUpdate?(self.pingValue, self.downloadValue, self.uploadValue)
        }
    }
}

// MARK: - Diagnostics Manager
class DiagnosticsManager: NSObject {
    static let shared = DiagnosticsManager()
    
    func checkBypass(completion: @escaping (Bool, String?) -> Void) {
        guard DPIKillerManager.shared.isRunning else {
            completion(false, L10n.shared.diagNoProxy)
            return
        }
        
        let url = URL(string: "https://www.google.com")!
        let config = URLSessionConfiguration.ephemeral
        let port = Int(SettingsStore.shared.localPort) ?? 8080
        
        config.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPEnable: 1,
            kCFNetworkProxiesHTTPProxy: "127.0.0.1",
            kCFNetworkProxiesHTTPPort: port,
            kCFNetworkProxiesHTTPSEnable: 1,
            kCFNetworkProxiesHTTPSProxy: "127.0.0.1",
            kCFNetworkProxiesHTTPSPort: port
        ]
        
        // Timeout 5s
        config.timeoutIntervalForRequest = 5.0
        
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                // If it's 200, it's likely working. 
                // Redirects to auth pages/providers would result in different status codes or content.
                if httpResponse.statusCode == 200 {
                    completion(true, nil)
                } else {
                    completion(false, "Status code: \(httpResponse.statusCode)")
                }
            } else {
                completion(false, "Unknown response")
            }
        }
        task.resume()
    }
}

struct ArgumentOption {
    let flag: String
    let description: String
}

class SettingsWindowController: NSWindowController {
    var pathField: NSTextField!
    var manualArgsField: NSTextField!
    var ttlField: NSTextField!
    var splitModeButton: NSPopUpButton!
    var httpsDisorderButton: NSButton!
    var httpsFakeCountField: NSTextField!
    var httpsChunkSizeField: NSTextField!
    var portField: NSTextField!
    var dnsAddrField: NSTextField!
    var dnsModeButton: NSPopUpButton!
    var dnsHttpsUrlField: NSTextField!
    var hotspotStatusLabel: NSTextField!
    var hotspotFixButton: NSButton!
    var checkboxes: [NSButton] = []
    
    let options = [
        ArgumentOption(flag: "--system-proxy", description: L10n.shared.descSystemProxy),
        ArgumentOption(flag: "--silent", description: L10n.shared.descSilent),
        ArgumentOption(flag: "--dns-ipv4-only", description: L10n.shared.descIpv4Only),
        ArgumentOption(flag: "--debug", description: L10n.shared.descDebug),
        ArgumentOption(flag: "--policy-auto", description: L10n.shared.descPolicyAuto)
    ]
    
    convenience init() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        // Adaptive size: ~40% of screen width, bounded by reasonable min/max
        let width = max(520, min(800, screen.width * 0.4))
        let height = max(600, min(1000, screen.height * 0.7)) 
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .fullSizeContentView, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = L10n.shared.settingsTitle
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        self.init(window: window)
        setupUI()
    }
    
    private func createBox(title: String, spacing: CGFloat = 12) -> (NSBox, NSStackView) {
        let box = NSBox()
        box.titlePosition = .noTitle
        box.boxType = .custom
        box.borderWidth = 0
        box.cornerRadius = 12
        // Adaptive background (subtle transparent layer)
        box.fillColor = NSColor.textColor.withAlphaComponent(0.05)
        box.contentViewMargins = NSSize(width: 25, height: 20)
        
        let containerStack = NSStackView()
        containerStack.orientation = .vertical
        containerStack.alignment = .leading
        containerStack.spacing = spacing
        
        let headerLabel = NSTextField(labelWithString: title)
        headerLabel.font = .systemFont(ofSize: 13, weight: .bold)
        headerLabel.textColor = .labelColor
        containerStack.addArrangedSubview(headerLabel)
        
        box.contentView?.addSubview(containerStack)
        if let contentView = box.contentView {
            containerStack.fill(parent: contentView)
        }
        
        return (box, containerStack)
    }

    private func addRow(label: String, control: NSView, to stack: NSStackView, tooltip: String? = nil) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 10
        
        let lbl = NSTextField(labelWithString: label)
        lbl.font = .systemFont(ofSize: 12)
        lbl.textColor = .secondaryLabelColor
        lbl.alignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.widthAnchor.constraint(equalToConstant: 140).isActive = true
        
        control.translatesAutoresizingMaskIntoConstraints = false
        if let tooltip = tooltip { control.toolTip = tooltip }
        
        row.addArrangedSubview(lbl)
        row.addArrangedSubview(control)
        stack.addArrangedSubview(row)
    }

    private func addCheckboxRow(button: NSButton, to stack: NSStackView) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(equalToConstant: 140).isActive = true
        
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(button)
        stack.addArrangedSubview(row)
    }

    func setupUI() {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .sidebar
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        window?.contentView = visualEffectView
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(scrollView)
        
        // --- HEADER (Floating) ---
        let headerEffect = NSVisualEffectView()
        headerEffect.material = .titlebar
        headerEffect.blendingMode = .withinWindow
        headerEffect.state = .active
        headerEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(headerEffect)
        
        let headerContainer = NSView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerEffect.addSubview(headerContainer)
        
        let headerTitle = NSTextField(labelWithString: L10n.shared.settingsTitle)
        headerTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        headerTitle.textColor = .secondaryLabelColor
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerTitle)
        
        let headerSeparator = NSBox()
        headerSeparator.boxType = .separator
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerSeparator)
        
        // --- FOOTER (Floating) ---
        let footerEffect = NSVisualEffectView()
        footerEffect.material = .sidebar
        footerEffect.blendingMode = .withinWindow
        footerEffect.state = .active
        footerEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(footerEffect)
        
        let footerContainer = NSView()
        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        footerEffect.addSubview(footerContainer)
        
        let footerSeparator = NSBox()
        footerSeparator.boxType = .separator
        footerSeparator.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.addSubview(footerSeparator)
        
        let footerStack = NSStackView()
        footerStack.orientation = .horizontal
        footerStack.distribution = .fillEqually
        footerStack.spacing = 15
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.addSubview(footerStack)
        
        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView
        
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .centerX
        mainStack.distribution = .fill
        mainStack.spacing = 35
        mainStack.edgeInsets = NSEdgeInsets(top: 30, left: 0, bottom: 30, right: 0) // Horizontal spacing managed by internal constraints
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        // Helper to add a wide section (box) to the main stack safely
        func addSection(_ view: NSView) {
            mainStack.addArrangedSubview(view)
            // Center the subview with exactly 30pt margin on both sides based on stack width
            view.widthAnchor.constraint(equalTo: mainStack.widthAnchor, constant: -60).isActive = true
        }
        
        NSLayoutConstraint.activate([
            // Floating Header Constraints
            headerEffect.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            headerEffect.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            headerEffect.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            headerEffect.heightAnchor.constraint(equalToConstant: 40),
            
            headerContainer.topAnchor.constraint(equalTo: headerEffect.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: headerEffect.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: headerEffect.trailingAnchor),
            headerContainer.bottomAnchor.constraint(equalTo: headerEffect.bottomAnchor),
            
            headerTitle.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            headerTitle.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor, constant: 0),
            
            headerSeparator.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            headerSeparator.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            
            // Floating Footer Constraints
            footerEffect.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            footerEffect.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            footerEffect.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            footerEffect.heightAnchor.constraint(equalToConstant: 60),
            
            footerContainer.topAnchor.constraint(equalTo: footerEffect.topAnchor),
            footerContainer.leadingAnchor.constraint(equalTo: footerEffect.leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: footerEffect.trailingAnchor),
            footerContainer.bottomAnchor.constraint(equalTo: footerEffect.bottomAnchor),
            
            footerSeparator.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            footerSeparator.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            footerSeparator.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            
            footerStack.centerXAnchor.constraint(equalTo: footerContainer.centerXAnchor),
            footerStack.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
            footerStack.widthAnchor.constraint(equalTo: footerContainer.widthAnchor, constant: -60), // Match 30pt margins
            
            // ScrollView Constraints (between header and footer)
            scrollView.topAnchor.constraint(equalTo: headerEffect.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerEffect.topAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Fix: Let contentView match scrollView exactly, so mainStack's internal sizing centers it
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Re-pin trailing edge to ensure it stays in the scroll area
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // --- SECTION 1: CORE ---
        let (coreBox, coreStack) = createBox(title: L10n.shared.sectionCore)
        pathField = NSTextField()
        pathField.stringValue = SettingsStore.shared.binaryPath
        pathField.placeholderString = L10n.shared.binaryPlaceholder
        addRow(label: L10n.shared.binaryPath, control: pathField, to: coreStack, tooltip: L10n.shared.tipBinaryPath)
        addSection(coreBox)
        
        // --- SECTION 2: NETWORK ---
        let (netBox, netStack) = createBox(title: L10n.shared.sectionNetwork)
        
        let statusRow = NSStackView()
        statusRow.orientation = .horizontal
        statusRow.spacing = 10
        let statusTitle = NSTextField(labelWithString: L10n.shared.hotspotStatusTitle)
        statusTitle.font = .systemFont(ofSize: 12)
        hotspotStatusLabel = NSTextField(labelWithString: L10n.shared.diagChecking)
        hotspotStatusLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        statusRow.addArrangedSubview(statusTitle)
        statusRow.addArrangedSubview(hotspotStatusLabel)
        netStack.addArrangedSubview(statusRow)
        
        hotspotFixButton = NSButton(title: "🛠 \(L10n.shared.fixHotspotButton)", target: self, action: #selector(fixHotspotAction))
        hotspotFixButton.bezelStyle = .rounded
        hotspotFixButton.isHidden = true
        netStack.addArrangedSubview(hotspotFixButton)
        
        let presetBtn = NSButton(title: "⚡️ \(L10n.shared.mobilePresetTitle)", target: self, action: #selector(applyMobilePreset))
        presetBtn.bezelStyle = .rounded
        netStack.addArrangedSubview(presetBtn)
        
        portField = NSTextField()
        portField.stringValue = SettingsStore.shared.localPort
        portField.widthAnchor.constraint(equalToConstant: 100).isActive = true
        addRow(label: L10n.shared.portTitle, control: portField, to: netStack, tooltip: L10n.shared.tipLocalPort)
        addSection(netBox)
        
        updateHotspotStatus()
        
        // --- SECTION 3: DPI STRATEGY ---
        let (dpiBox, dpiStack) = createBox(title: L10n.shared.sectionDPI)
        let selected = SettingsStore.shared.selectedFlags
        for option in options {
            let cb = NSButton(checkboxWithTitle: option.flag, target: nil, action: nil)
            cb.state = selected.contains(option.flag) ? .on : .off
            checkboxes.append(cb)
            
            let row = NSStackView()
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 10
            
            // Standard Gutter Spacer
            let spacer = NSView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.widthAnchor.constraint(equalToConstant: 140).isActive = true
            row.addArrangedSubview(spacer)
            
            row.addArrangedSubview(cb)
            
            let desc = NSTextField(labelWithString: "— \(option.description)")
            desc.font = .systemFont(ofSize: 11)
            desc.textColor = .secondaryLabelColor
            row.addArrangedSubview(desc)
            
            dpiStack.addArrangedSubview(row)
        }
        
        ttlField = NSTextField()
        ttlField.stringValue = SettingsStore.shared.defaultTTL
        ttlField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        addRow(label: L10n.shared.ttlTitle, control: ttlField, to: dpiStack, tooltip: L10n.shared.tipTTL)
        
        splitModeButton = NSPopUpButton(frame: .zero, pullsDown: false)
        splitModeButton.addItems(withTitles: ["sni", "random", "chunk", "none"])
        splitModeButton.selectItem(withTitle: SettingsStore.shared.splitMode)
        addRow(label: L10n.shared.splitModeTitle, control: splitModeButton, to: dpiStack, tooltip: L10n.shared.tipSplitMode)
        
        // Disorder and Fake count row
        let disorderStack = NSStackView()
        disorderStack.orientation = .horizontal
        disorderStack.alignment = .centerY
        disorderStack.spacing = 10
        
        // Gutter Spacer for consistent horizontal alignment
        let disorderSpacer = NSView()
        disorderSpacer.translatesAutoresizingMaskIntoConstraints = false
        disorderSpacer.widthAnchor.constraint(equalToConstant: 140).isActive = true
        disorderStack.addArrangedSubview(disorderSpacer)
        
        httpsDisorderButton = NSButton(checkboxWithTitle: L10n.shared.httpsDisorder, target: nil, action: nil)
        httpsDisorderButton.state = SettingsStore.shared.httpsDisorder ? .on : .off
        disorderStack.addArrangedSubview(httpsDisorderButton)
        
        let flexibleSpacer = NSView()
        disorderStack.addArrangedSubview(flexibleSpacer)
        
        let fakeCountStack = NSStackView()
        fakeCountStack.orientation = .horizontal
        fakeCountStack.alignment = .centerY
        fakeCountStack.spacing = 8
        
        let fakeLabel = NSTextField(labelWithString: L10n.shared.httpsFakeCount)
        fakeLabel.font = .systemFont(ofSize: 12)
        httpsFakeCountField = NSTextField()
        httpsFakeCountField.stringValue = SettingsStore.shared.httpsFakeCount
        httpsFakeCountField.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        fakeCountStack.addArrangedSubview(fakeLabel)
        fakeCountStack.addArrangedSubview(httpsFakeCountField)
        disorderStack.addArrangedSubview(fakeCountStack)
        
        dpiStack.addArrangedSubview(disorderStack)
        
        httpsChunkSizeField = NSTextField()
        httpsChunkSizeField.stringValue = SettingsStore.shared.httpsChunkSize
        httpsChunkSizeField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        addRow(label: L10n.shared.httpsChunkSize, control: httpsChunkSizeField, to: dpiStack, tooltip: L10n.shared.tipChunkSize)
        addSection(dpiBox)
        
        // --- SECTION 4: DNS ---
        let (dnsBox, dnsStack) = createBox(title: L10n.shared.sectionDNS)
        dnsAddrField = NSTextField()
        dnsAddrField.stringValue = SettingsStore.shared.dnsAddr
        addRow(label: L10n.shared.dnsAddrTitle, control: dnsAddrField, to: dnsStack, tooltip: L10n.shared.tipDNSAddr)
        
        dnsModeButton = NSPopUpButton(frame: .zero, pullsDown: false)
        dnsModeButton.addItems(withTitles: ["udp", "https", "system"])
        dnsModeButton.selectItem(withTitle: SettingsStore.shared.dnsMode)
        addRow(label: L10n.shared.dnsModeTitle, control: dnsModeButton, to: dnsStack)
        
        dnsHttpsUrlField = NSTextField()
        dnsHttpsUrlField.stringValue = SettingsStore.shared.dnsHttpsUrl
        addRow(label: "DoH/DoT URL:", control: dnsHttpsUrlField, to: dnsStack)
        addSection(dnsBox)
        
        // --- SECTION 5: APP BEHAVIOR ---
        let (appBox, appStack) = createBox(title: L10n.shared.sectionApp, spacing: 5)
        let loginCb = NSButton(checkboxWithTitle: L10n.shared.launchAtLogin, target: self, action: #selector(toggleLoginItem))
        loginCb.state = SettingsStore.shared.launchAtLogin ? .on : .off
        addCheckboxRow(button: loginCb, to: appStack)
        
        let updateCb = NSButton(checkboxWithTitle: L10n.shared.autoUpdateToggle, target: self, action: #selector(toggleUpdateItem))
        updateCb.state = SettingsStore.shared.autoUpdate ? .on : .off
        addCheckboxRow(button: updateCb, to: appStack)
        
        let ipv6Cb = NSButton(checkboxWithTitle: L10n.shared.disableIpv6, target: self, action: #selector(toggleIpv6))
        ipv6Cb.state = SettingsStore.shared.disableIpv6 ? .on : .off
        addCheckboxRow(button: ipv6Cb, to: appStack)
        
        let reconnectCb = NSButton(checkboxWithTitle: L10n.shared.autoReconnect, target: self, action: #selector(toggleReconnect))
        reconnectCb.toolTip = L10n.shared.tipAutoReconnect
        reconnectCb.state = SettingsStore.shared.autoReconnect ? .on : .off
        addCheckboxRow(button: reconnectCb, to: appStack)
        
        addSection(appBox)
        
        // --- SECTION 6: MANUAL ---
        let (manualBox, manualStack) = createBox(title: L10n.shared.sectionManual)
        manualArgsField = NSTextField()
        let allArgs = SettingsStore.shared.customArgs.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var manualParts: [String] = []
        var i = 0
        while i < allArgs.count {
            let arg = allArgs[i]
            if ["--default-ttl", "--https-split-mode", "--listen-addr", "--dns-addr", "--dns-mode", "--dns-https-url", "--https-disorder", "--https-fake-count", "--https-chunk-size"].contains(arg) {
                i += 1 
                if i < allArgs.count && !allArgs[i].hasPrefix("-") { i += 1 }
            } else if options.contains(where: { $0.flag == arg }) {
                i += 1
            } else {
                manualParts.append(arg)
                i += 1
            }
        }
        manualArgsField.stringValue = manualParts.joined(separator: " ")
        manualArgsField.placeholderString = L10n.shared.manualArgsPlaceholder
        manualStack.addArrangedSubview(manualArgsField)
        manualArgsField.widthAnchor.constraint(equalTo: manualStack.widthAnchor).isActive = true
        addSection(manualBox)
        
        let cancelBtn = NSButton(title: L10n.shared.cancel, target: self, action: #selector(cancelAction))
        cancelBtn.bezelStyle = .rounded
        
        let saveButton = NSButton(title: L10n.shared.saveAndRestart, target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        
        footerStack.addArrangedSubview(cancelBtn)
        footerStack.addArrangedSubview(saveButton)
    }

    @objc func cancelAction() {
        self.window?.close()
    }
    
    @objc func applyMobilePreset() {
        ttlField.stringValue = "128"
        splitModeButton.selectItem(withTitle: "random")
        httpsChunkSizeField.stringValue = "20"
        httpsDisorderButton.state = .on
        httpsFakeCountField.stringValue = "0"
        
        // Visual feedback
        ttlField.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.2).cgColor
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1.0
            self.ttlField.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        if getSystemTTL() != 65 {
            fixHotspotAction()
        }
    }
    
    @objc func fixHotspotAction() {
        let script = "do shell script \"sysctl -w net.inet.ip.ttl=65 && sysctl -w net.inet6.ip6.hlim=65\" with administrator privileges"
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        if let err = error {
            print("AppleScript Error: \(err)")
            let alert = NSAlert()
            alert.messageText = L10n.shared.fixHotspotFailed
            alert.informativeText = "\(err["NSAppleScriptErrorMessage"] ?? "Unknown error")"
            alert.runModal()
        } else {
            updateHotspotStatus()
        }
    }
    
    func updateHotspotStatus() {
        let ttl = getSystemTTL()
        if ttl == 65 {
            hotspotStatusLabel.stringValue = L10n.shared.hotspotStatusOptimized
            hotspotStatusLabel.textColor = .systemGreen
            hotspotFixButton.isHidden = true
        } else {
            hotspotStatusLabel.stringValue = L10n.shared.hotspotStatusThrottled
            hotspotStatusLabel.textColor = .systemOrange
            hotspotFixButton.isHidden = false
        }
    }
    
    func getSystemTTL() -> Int {
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["-n", "net.inet.ip.ttl"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
               let val = Int(output) {
                return val
            }
        } catch {
            return 64
        }
        return 64
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
    
    @objc func toggleReconnect(_ sender: NSButton) {
        SettingsStore.shared.autoReconnect = (sender.state == .on)
    }
    
    @objc func toggleIpv6(_ sender: NSButton) {
        SettingsStore.shared.disableIpv6 = (sender.state == .on)
    }
    
    @objc func save() {
        var flags = Set<String>()
        for (index, cb) in checkboxes.enumerated() {
            if cb.state == .on { flags.insert(options[index].flag) }
        }
        
        // Clamping logic
        let rawPort = Int(portField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)) ?? 8080
        let clampedPort = min(max(rawPort, 1), 65535)
        
        let rawTTL = Int(ttlField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)) ?? 128
        let clampedTTL = min(max(rawTTL, 1), 255)
        
        let rawFakeCount = Int(httpsFakeCountField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)) ?? 0
        let clampedFakeCount = min(max(rawFakeCount, 0), 100)
        
        let rawChunkSize = Int(httpsChunkSizeField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)) ?? 100
        let clampedChunkSize = min(max(rawChunkSize, 1), 1000)

        SettingsStore.shared.binaryPath = pathField.stringValue
        SettingsStore.shared.defaultTTL = String(clampedTTL)
        SettingsStore.shared.splitMode = splitModeButton.titleOfSelectedItem ?? "sni"
        SettingsStore.shared.httpsDisorder = httpsDisorderButton.state == .on
        SettingsStore.shared.httpsFakeCount = String(clampedFakeCount)
        SettingsStore.shared.httpsChunkSize = String(clampedChunkSize)
        SettingsStore.shared.localPort = String(clampedPort)
        SettingsStore.shared.dnsAddr = dnsAddrField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
        SettingsStore.shared.dnsMode = dnsModeButton.titleOfSelectedItem ?? "udp"
        SettingsStore.shared.dnsHttpsUrl = dnsHttpsUrlField.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
        
        SettingsStore.shared.updateArgs(with: flags, manual: manualArgsField.stringValue, 
                                        ttl: SettingsStore.shared.defaultTTL, 
                                        splitMode: SettingsStore.shared.splitMode, 
                                        splitPos: "1", 
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
        self.window?.close()
    }
}

// MARK: - Speed Test Window
class SpeedTestWindowController: NSWindowController {
    private var pingLabel: NSTextField!
    private var downloadLabel: NSTextField!
    private var uploadLabel: NSTextField!
    private var progressIndicator: NSProgressIndicator!
    private var startButton: NSButton!
    
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 400),
                              styleMask: [.titled, .closable, .fullSizeContentView, .miniaturizable],
                              backing: .buffered, defer: false)
        window.center()
        window.title = L10n.shared.speedTest
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        let visualEffectView = NSVisualEffectView(frame: window!.contentView!.bounds)
        visualEffectView.material = .windowBackground
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.autoresizingMask = [.width, .height]
        window?.contentView = visualEffectView
        
        let titleLabel = NSTextField(labelWithString: L10n.shared.speedTestTitle)
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: 340, width: 600, height: 30)
        titleLabel.alignment = .center
        visualEffectView.addSubview(titleLabel)
        
        pingLabel = createValueLabel(title: L10n.shared.ping, unit: L10n.shared.ms, y: 260)
        downloadLabel = createValueLabel(title: L10n.shared.download, unit: L10n.shared.mbps, y: 220)
        uploadLabel = createValueLabel(title: L10n.shared.upload, unit: L10n.shared.mbps, y: 180)
        
        visualEffectView.addSubview(pingLabel)
        visualEffectView.addSubview(downloadLabel)
        visualEffectView.addSubview(uploadLabel)
        
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 120, y: 140, width: 400, height: 20))
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 100
        progressIndicator.doubleValue = 0
        progressIndicator.isDisplayedWhenStopped = true
        visualEffectView.addSubview(progressIndicator)
        
        startButton = NSButton(title: L10n.shared.startTest, target: self, action: #selector(startClicked))
        startButton.frame = NSRect(x: 220, y: 40, width: 200, height: 40)
        startButton.bezelStyle = .rounded
        startButton.controlSize = .large
        visualEffectView.addSubview(startButton)
    }
    
    private func createValueLabel(title: String, unit: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: "\(title): — \(unit)")
        label.frame = NSRect(x: 20, y: y, width: 600, height: 24)
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.alignment = .center
        return label
    }
    
    @objc private func startClicked() {
        if startButton.title == L10n.shared.startTest {
            startButton.title = L10n.shared.stopTest
            progressIndicator.startAnimation(nil)
            
            SpeedTestManager.shared.onUpdate = { [weak self] ping, down, up in
                DispatchQueue.main.async {
                    self?.pingLabel.stringValue = "\(L10n.shared.ping): \(Int(ping)) \(L10n.shared.ms)"
                    self?.downloadLabel.stringValue = "\(L10n.shared.download): \(String(format: "%.2f", down)) \(L10n.shared.mbps)"
                    self?.uploadLabel.stringValue = "\(L10n.shared.upload): \(String(format: "%.2f", up)) \(L10n.shared.mbps)"
                }
            }
            
            SpeedTestManager.shared.onFinished = { [weak self] in
                DispatchQueue.main.async {
                    self?.startButton.title = L10n.shared.startTest
                    self?.progressIndicator.stopAnimation(nil)
                }
            }
            
            SpeedTestManager.shared.onError = { [weak self] error in
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Error"
                    alert.informativeText = error
                    alert.runModal()
                    self?.startButton.title = L10n.shared.startTest
                    self?.progressIndicator.stopAnimation(nil)
                }
            }
            
            SpeedTestManager.shared.startTest()
        } else {
            SpeedTestManager.shared.stopTest()
        }
    }
}

// MARK: - Log Window
class LogWindowController: NSWindowController {
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 400),
                              styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.center()
        window.title = L10n.shared.logsTitle
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        self.init(window: window)
        setupUI()
        
        LogStore.shared.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.updateLogs()
            }
        }
        updateLogs()
    }
    
    private func setupUI() {
        let visualEffectView = NSVisualEffectView(frame: window!.contentView!.bounds)
        visualEffectView.material = .sidebar
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.autoresizingMask = [.width, .height]
        window?.contentView = visualEffectView
        
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 50, width: 640, height: 350))
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autoresizingMask = [.width, .height]
        
        textView = NSTextView(frame: scrollView.documentView?.bounds ?? scrollView.bounds)
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.autoresizingMask = [.width]
        textView.drawsBackground = false
        textView.textColor = .labelColor
        
        scrollView.documentView = textView
        visualEffectView.addSubview(scrollView)
        
        let bottomBar = NSView(frame: NSRect(x: 0, y: 0, width: 640, height: 50))
        bottomBar.autoresizingMask = [.width, .maxYMargin]
        visualEffectView.addSubview(bottomBar)
        
        let clearBtn = NSButton(title: L10n.shared.clearLogs, target: self, action: #selector(clearLogs))
        clearBtn.bezelStyle = .rounded
        clearBtn.frame = NSRect(x: 20, y: 10, width: 120, height: 32)
        bottomBar.addSubview(clearBtn)
        
        let copyBtn = NSButton(title: L10n.shared.copyLogs, target: self, action: #selector(copyLogs))
        copyBtn.bezelStyle = .rounded
        copyBtn.frame = NSRect(x: 150, y: 10, width: 120, height: 32)
        bottomBar.addSubview(copyBtn)
    }
    
    private func updateLogs() {
        let text = LogStore.shared.getAllLogs()
        let wasAtBottom = scrollView.verticalScroller?.floatValue ?? 1.0 > 0.95
        
        textView.string = text
        
        if wasAtBottom {
            textView.scrollToEndOfDocument(nil)
        }
    }
    
    @objc private func clearLogs() {
        LogStore.shared.clear()
    }
    
    @objc private func copyLogs() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(LogStore.shared.getAllLogs(), forType: .string)
    }
}

// MARK: - Help Window

class HelpWindowController: NSWindowController {
    var webView: WKWebView!
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 600), 
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.center()
        window.title = L10n.shared.helpTitle
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        self.init(window: window)
        setupUI()
        loadReadme()
    }
    func setupUI() {
        let visualEffectView = NSVisualEffectView(frame: window!.contentView!.bounds)
        visualEffectView.material = .sidebar
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.autoresizingMask = [.width, .height]
        window?.contentView = visualEffectView
        
        webView = WKWebView(frame: visualEffectView.bounds)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        visualEffectView.addSubview(webView)
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
    private var indicator: NSProgressIndicator?
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
        indicator = NSProgressIndicator(frame: NSRect(x: 100, y: 15, width: 140, height: 20)); indicator?.style = .bar; indicator?.isIndeterminate = true; indicator?.startAnimation(nil); container.addSubview(indicator!)
        cancelButton = NSButton(title: L10n.shared.cancel, target: self, action: #selector(cancelClicked)); cancelButton?.frame = NSRect(x: 120, y: 5, width: 100, height: 20); cancelButton?.bezelStyle = .recessed; cancelButton?.isHidden = true; container.addSubview(cancelButton!)
        window?.invalidateShadow()
    }
    func updateStatus(_ text: String, showCancel: Bool = false) { DispatchQueue.main.async { self.sublabel?.stringValue = text; self.cancelButton?.isHidden = !showCancel } }
    func updateProgress(_ value: Double) { DispatchQueue.main.async { self.indicator?.isIndeterminate = false; self.indicator?.doubleValue = value * 100 } }
    func setProgressIndeterminate(_ value: Bool) { DispatchQueue.main.async { self.indicator?.isIndeterminate = value; if value { self.indicator?.startAnimation(nil) } } }
    @objc func cancelClicked() { cancelHandler?() }
    func showWithFade() { 
        window?.alphaValue = 0
        window?.center() // Ensure it's centered before showing
        showWindow(nil)
        NSAnimationContext.runAnimationGroup { $0.duration = 0.4; window?.animator().alphaValue = 1.0 } 
    }
    func closeWithFade(completion: @escaping () -> Void) { 
        NSAnimationContext.runAnimationGroup({ $0.duration = 0.4; window?.animator().alphaValue = 0 }, completionHandler: completion) 
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: SettingsWindowController?
    var helpWindow: HelpWindowController?
    var loadingWindow: LoadingWindowController?
    var speedTestWindow: SpeedTestWindowController?
    var logWindow: LogWindowController?
    
    private var iconCache: [Bool: NSImage] = [:]
    private var lastRefreshTime: Date = .distantPast
    private let refreshThrottleInterval: TimeInterval = 0.5

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupSignalHandlers()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshUI()
        
        // Fail-safe: Restore settings on startup in case of previous crash
        DPIKillerManager.shared.fullCleanup()
        
        // Ensure only one instance of loadingWindow exists
        if loadingWindow == nil { loadingWindow = LoadingWindowController() }
        loadingWindow?.showWithFade()
        
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
                        let alert = NSAlert()
                        alert.messageText = L10n.shared.failedToStart
                        alert.informativeText = error ?? (L10n.shared.isRussian ? "Проверьте настройки." : "Check settings.")
                        NSApp.activate(ignoringOtherApps: true)
                        alert.beginSheetModal(for: self?.settingsWindow?.window ?? NSWindow()) { _ in
                            self?.showSettings()
                        }
                    }
                }
            }
        }
    }

    private func showInstallAlert() {
        let alert = NSAlert()
        alert.messageText = L10n.shared.dependencyMissing
        alert.informativeText = L10n.shared.spoofDpiNeeded
        alert.addButton(withTitle: L10n.shared.install)
        alert.addButton(withTitle: L10n.shared.quit)
        
        NSApp.activate(ignoringOtherApps: true)
        // Use an existing window or run modal as a fallback
        if let window = loadingWindow?.window ?? settingsWindow?.window {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn { self.performInstallation() } else { NSApp.terminate(nil) }
            }
        } else {
            if alert.runModal() == .alertFirstButtonReturn { performInstallation() } else { NSApp.terminate(nil) }
        }
    }

    private func performInstallation() {
        if loadingWindow == nil { loadingWindow = LoadingWindowController() }
        loadingWindow?.updateStatus(L10n.shared.installing, showCancel: true)
        loadingWindow?.setProgressIndeterminate(true)
        loadingWindow?.cancelHandler = { [weak self] in 
            DPIKillerManager.shared.cancelInstall()
            self?.loadingWindow?.closeWithFade { self?.loadingWindow = nil; self?.refreshUI() } 
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
                    if let error = error {
                        let f = NSAlert()
                        f.messageText = L10n.shared.installFailed
                        f.informativeText = error
                        NSApp.activate(ignoringOtherApps: true)
                        f.runModal()
                    }
                }
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
        menu.addItem(NSMenuItem(title: L10n.shared.diagTitle, action: #selector(runDiagnostics), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: L10n.shared.speedTest, action: #selector(showSpeedTest), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: L10n.shared.logsTitle, action: #selector(showLogs), keyEquivalent: "l"))
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
    @objc func showSpeedTest() { if speedTestWindow == nil { speedTestWindow = SpeedTestWindowController() }; NSApp.activate(ignoringOtherApps: true); speedTestWindow?.showWindow(nil) }
    @objc func showLogs() { if logWindow == nil { logWindow = LogWindowController() }; NSApp.activate(ignoringOtherApps: true); logWindow?.showWindow(nil) }
    
    @objc func runDiagnostics() {
        if loadingWindow == nil { loadingWindow = LoadingWindowController() }
        loadingWindow?.updateStatus(L10n.shared.diagChecking)
        loadingWindow?.showWithFade()
        
        DiagnosticsManager.shared.checkBypass { [weak self] success, error in
            DispatchQueue.main.async {
                self?.loadingWindow?.closeWithFade {
                    self?.loadingWindow = nil
                    let alert = NSAlert()
                    alert.messageText = success ? L10n.shared.diagSuccess : L10n.shared.diagFailed
                    alert.informativeText = error ?? ""
                    NSApp.activate(ignoringOtherApps: true)
                    alert.runModal()
                }
            }
        }
    }
    
    @objc func checkUpdate() { GitHubUpdater.shared.checkForUpdates(manual: true) }
    
    func applicationWillTerminate(_ notification: Notification) {
        DPIKillerManager.shared.fullCleanup()
    }

    private func setupSignalHandlers() {
        let signals = [SIGINT, SIGTERM]
        for sig in signals {
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler { 
                DPIKillerManager.shared.fullCleanup()
                exit(0) 
            }
            source.resume()
        }
    }
}

// Ensure cleanup on any exit
atexit {
    DPIKillerManager.shared.fullCleanup()
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

// MARK: - Extension for Clamping
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
