import Foundation

struct L10n {
    static let shared = L10n()
    let isRussian: Bool

    init() {
        let lang = Locale.preferredLanguages.first ?? "en"
        self.isRussian = lang.hasPrefix("ru")
    }

    var statusActive: String { isRussian ? "Статус: АКТИВЕН ✅" : "Status: ACTIVE ✅" }
    var statusPartial: String { isRussian ? "Статус: ТРЕБУЕТ ОПТИМИЗАЦИИ ⚠️" : "Status: NEEDS OPTIMIZATION ⚠️" }
    var statusStopped: String { isRussian ? "Статус: ОСТАНОВЛЕН ❌" : "Status: STOPPED ❌" }
    var networkOptimizationActive: String { isRussian ? "Оптимизация сети: применена ✅" : "Network Optimization: Applied ✅" }
    var networkOptimizationInactive: String { isRussian ? "Оптимизация сети: не применена ⚠️" : "Network Optimization: Not Applied ⚠️" }
    var start: String { isRussian ? "Запустить" : "Start" }
    var stop: String { isRussian ? "Остановить" : "Stop" }
    var settings: String { isRussian ? "Настройки..." : "Settings..." }
    var logs: String { isRussian ? "Логи" : "Logs" }
    var instructions: String { isRussian ? "Инструкции" : "Instructions" }
    var helpTitle: String { isRussian ? "Инструкция по использованию" : "User Guide & Instructions" }
    var quit: String { isRussian ? "Выйти" : "Quit" }

    var settingsTitle: String { isRussian ? "Расширенные настройки" : "Advanced Settings" }
    var backendModeTitle: String { isRussian ? "Движок:" : "Backend:" }
    var backendAuto: String { isRussian ? "Авто" : "Auto" }
    var backendCiadpi: String { isRussian ? "ciadpi" : "ciadpi" }
    var backendSpoofdpi: String { isRussian ? "spoofdpi" : "spoofdpi" }
    var backendCustom: String { isRussian ? "Custom" : "Custom" }
    var backendSummaryTitle: String { isRussian ? "Активный режим:" : "Resolved Mode:" }
    var backendPathHint: String { isRussian ? "Авто и фиксированные режимы сами подставляют путь. Ручное поле нужно только для custom." : "Auto and pinned modes resolve the path for you. Manual path is only needed for custom." }
    var backendMissingSuffix: String { isRussian ? "не найден" : "not found" }
    var binaryPathCustom: String { isRussian ? "Custom path:" : "Custom path:" }
    var binaryPath: String { isRussian ? "Путь к бинарнику:" : "Binary Path:" }
    var binaryPlaceholder: String { isRussian ? "Например: /usr/local/bin/ciadpi или /opt/homebrew/bin/spoofdpi" : "e.g. /usr/local/bin/ciadpi or /opt/homebrew/bin/spoofdpi" }
    var argumentsTitle: String { isRussian ? "Аргументы (флаги):" : "Arguments (Flags):" }
    var manualArgsTitle: String { isRussian ? "Доп. аргументы:" : "Manual Arguments:" }
    var manualArgsPlaceholder: String { isRussian ? "-p 8080 -window-size 10" : "-p 8080 -window-size 10" }
    var manualArgsPlaceholderCiadpi: String { isRussian ? "--fake -1 --ttl 8" : "--fake -1 --ttl 8" }
    var manualArgsPlaceholderSpoofdpi: String { isRussian ? "--enable-doh" : "--enable-doh" }
    var autoLaunchTitle: String { isRussian ? "Автозагрузка:" : "Auto Launch:" }
    var launchAtLogin: String { isRussian ? "Запускать при старте системы" : "Launch at system startup" }
    var saveAndRestart: String { isRussian ? "Сохранить и Перезапустить" : "Save & Restart" }

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
    var dnsDisabledForCiadpi: String { isRussian ? "DNS override работает только с spoofdpi." : "DNS override is available only with spoofdpi." }

    var descSystemProxy: String { isRussian ? "Использовать системный прокси" : "Use system-wide proxy" }
    var descSilent: String { isRussian ? "Скрыть баннер при запуске" : "Suppress startup banner" }
    var descIpv4Only: String { isRussian ? "Только IPv4 для DNS" : "IPv4 only for DNS" }
    var descDebug: String { isRussian ? "Режим отладки (info/debug)" : "Debug mode (info/debug)" }
    var descPolicyAuto: String { isRussian ? "Адаптивный обход для ciadpi" : "Adaptive bypass for ciadpi" }

    var dependencyMissing: String { isRussian ? "Отсутствует зависимость" : "Dependency Missing" }
    var spoofDpiNeeded: String { isRussian ? "Не найдены backend-движки. Установить поддерживаемые движки для macOS?" : "No DPI backends were found. Install the supported macOS backends?" }
    var install: String { isRussian ? "Установить" : "Install" }
    var installing: String { isRussian ? "Установка движков..." : "Installing backends..." }
    var pleaseWaitBrew: String { isRussian ? "Пожалуйста, подождите. Сборка ciadpi или fallback-установка могут занять минуту." : "Please wait while ciadpi is built or the fallback backend is installed. This might take a minute." }
    var installComplete: String { isRussian ? "Движки установлены" : "Backends Installed" }
    var installSuccess: String { isRussian ? "Поддерживаемые движки установлены. Запуск сервиса..." : "Supported backends were installed. Starting service..." }
    var installFailed: String { isRussian ? "Ошибка установки" : "Installation Failed" }
    var installManual: String { isRussian ? "Неизвестная ошибка. Установите ciadpi вручную и скачайте SpoofDPI из официального GitHub release." : "Unknown error. Please install ciadpi manually and download SpoofDPI from the official GitHub release." }
    var backendStartTimeout: String { isRussian ? "Backend не поднял локальный прокси вовремя." : "The backend did not start the local proxy in time." }
    var backendExitedEarly: String { isRussian ? "Backend завершился до готовности." : "The backend exited before becoming ready." }
    var failedToStart: String { isRussian ? "Не удалось запустить" : "Failed to start" }
    var preparingBypass: String { isRussian ? "Подготовка обхода... ⚡️" : "Preparing your bypass... ⚡️" }
    var cancel: String { isRussian ? "Отмена" : "Cancel" }

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
    var vpnModeToggle: String { isRussian ? "Системный VPN-режим" : "System VPN Mode" }
    var tipVPNMode: String { isRussian ? "Поднимает Packet Tunnel поверх локального backend-а вместо networksetup proxy." : "Starts a Packet Tunnel on top of the local backend instead of using networksetup proxy." }
    var vpnModeMissingBundle: String { isRussian ? "VPN-режим недоступен: tunnel extension не встроен в приложение." : "VPN mode is unavailable: the tunnel extension is not embedded in the app." }
    var vpnModeMissingSignature: String { isRussian ? "VPN-режим недоступен: приложению нужна подпись с Network Extension capability." : "VPN mode is unavailable: the app needs a signed build with the Network Extension capability." }
    var vpnModePermissionDenied: String { isRussian ? "VPN-режим заблокирован macOS: нужен корректно подписанный bundle и provisioning для Packet Tunnel." : "VPN mode is blocked by macOS: a properly signed bundle and provisioning for Packet Tunnel are required." }
    var vpnModeStartFailed: String { isRussian ? "Packet Tunnel не запустился." : "The Packet Tunnel failed to start." }
    var runtimeModeTitle: String { isRussian ? "Режим:" : "Mode:" }
    var runtimeModeVpn: String { isRussian ? "Packet Tunnel VPN" : "Packet Tunnel VPN" }
    var runtimeModeProxy: String { isRussian ? "Системный proxy" : "System Proxy" }
    var runtimeModeProxyFallback: String { isRussian ? "Proxy fallback" : "Proxy fallback" }
    var runtimeModeOff: String { isRussian ? "Остановлен" : "Stopped" }
    var vpnStatusReady: String { isRussian ? "VPN-контур доступен. При запуске будет использоваться Packet Tunnel." : "The VPN path is available. Packet Tunnel will be used on start." }
    var vpnStatusFallback: String { isRussian ? "Для этого билда VPN недоступен. При запуске будет использоваться proxy fallback." : "VPN is unavailable for this build. Proxy fallback will be used on start." }
    var vpnStatusDisabled: String { isRussian ? "Сейчас используется обычный proxy backend." : "The standard proxy backend is active." }
    var vpnStatusUnavailable: String { isRussian ? "Для этого билда Packet Tunnel недоступен. Нужна подписанная сборка с Network Extension entitlement." : "Packet Tunnel is unavailable for this build. A signed build with the Network Extension entitlement is required." }
    var vpnSystemExtensionApproval: String { isRussian ? "macOS запросил подтверждение системного расширения. Разрешите DPI Killer в Privacy & Security." : "macOS requires approval for the system extension. Allow DPI Killer in Privacy & Security." }
    var vpnSystemExtensionReboot: String { isRussian ? "Системное расширение активируется после перезагрузки macOS." : "The system extension will become active after restarting macOS." }
    var vpnSystemExtensionFailed: String { isRussian ? "Не удалось активировать системное расширение Packet Tunnel." : "Failed to activate the Packet Tunnel system extension." }

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

    var logsTitle: String { isRussian ? "Логи событий" : "Event Logs" }
    var clearLogs: String { isRussian ? "Очистить" : "Clear" }
    var copyLogs: String { isRussian ? "Копировать" : "Copy" }

    var diagTitle: String { isRussian ? "Диагностика связи" : "Connectivity Diagnostics" }
    var diagChecking: String { isRussian ? "Проверка..." : "Checking..." }
    var diagSuccess: String { isRussian ? "Обход работает! ✅" : "Bypass is working! ✅" }
    var diagFailed: String { isRussian ? "Обход не работает ❌" : "Bypass is failing ❌" }
    var diagNoProxy: String { isRussian ? "Прокси не запущен" : "Proxy is not running" }

    var disableIpv6: String { isRussian ? "Отключить IPv6 (рекомендуется)" : "Disable IPv6 (recommended)" }
    var ipv6Warning: String { isRussian ? "Предотвращает утечки трафика мимо прокси." : "Prevents traffic leakage bypassing the proxy." }

    var autoReconnect: String { isRussian ? "Авто-реконнект" : "Auto-reconnect" }
    var tipAutoReconnect: String { isRussian ? "Автоматически восстанавливать прокси при восстановлении WiFi." : "Automatically restore proxy when WiFi connection is restored." }

    var sectionCore: String { isRussian ? "Core" : "Core" }
    var sectionBackend: String { isRussian ? "Движок" : "Backend" }
    var sectionNetwork: String { isRussian ? "Network" : "Network" }
    var sectionDPI: String { isRussian ? "Bypass" : "Bypass" }
    var sectionDNS: String { isRussian ? "DNS" : "DNS" }
    var sectionApp: String { isRussian ? "App" : "App" }
    var sectionManual: String { isRussian ? "Manual" : "Manual" }
    var spoofdpiMaintenanceTitle: String { isRussian ? "SpoofDPI" : "SpoofDPI" }
    var spoofdpiSelectedPath: String { isRussian ? "Выбран:" : "Selected:" }
    var spoofdpiManagedPath: String { isRussian ? "Managed:" : "Managed:" }
    var spoofdpiVersionTitle: String { isRussian ? "Версия:" : "Version:" }
    var spoofdpiLatestTitle: String { isRussian ? "Последняя:" : "Latest:" }
    var spoofdpiCheck: String { isRussian ? "Проверить" : "Check" }
    var spoofdpiUpdate: String { isRussian ? "Обновить SpoofDPI" : "Update SpoofDPI" }
    var spoofdpiChecking: String { isRussian ? "Проверка SpoofDPI..." : "Checking SpoofDPI..." }
    var spoofdpiUpdating: String { isRussian ? "Обновление SpoofDPI..." : "Updating SpoofDPI..." }
    var spoofdpiReady: String { isRussian ? "SpoofDPI актуален." : "SpoofDPI is up to date." }
    var spoofdpiUpdateReady: String { isRussian ? "Доступно обновление SpoofDPI." : "SpoofDPI update is available." }
    var spoofdpiManagedMissing: String { isRussian ? "Managed SpoofDPI не установлен." : "Managed SpoofDPI is not installed." }
    var spoofdpiUpdated: String { isRussian ? "SpoofDPI обновлен." : "SpoofDPI was updated." }
    var spoofdpiCheckFailed: String { isRussian ? "Не удалось проверить SpoofDPI." : "Could not check SpoofDPI." }
    var spoofdpiUpdateFailed: String { isRussian ? "Не удалось обновить SpoofDPI." : "Could not update SpoofDPI." }
    var versionUnknown: String { isRussian ? "неизвестно" : "unknown" }

    var tipBinaryPath: String { isRussian ? "Полный путь к исполняемому файлу ciadpi или spoofdpi." : "Full path to the ciadpi or spoofdpi executable." }
    var tipLocalPort: String { isRussian ? "Порт, который будет слушать локальный прокси (1-65535)." : "Port for the local proxy (1-65535)." }
    var tipTTL: String { isRussian ? "Time To Live для пакетов. Помогает скрыть присутствие прокси (1-255)." : "Time To Live for packets. Helps hide proxy presence (1-255)." }
    var tipSplitMode: String { isRussian ? "Способ разделения HTTPS пакетов." : "Method for splitting HTTPS packets." }
    var tipFakeCount: String { isRussian ? "Количество фейковых пакетов для запутывания DPI (0-100)." : "Number of fake packets to confuse DPI (0-100)." }
    var tipChunkSize: String { isRussian ? "Размер фрагмента данных в байтах (1-1000)." : "Size of data fragments in bytes (1-1000)." }
    var tipDNSAddr: String { isRussian ? "Адрес DNS сервера (например, 8.8.8.8:53)." : "DNS server address (e.g. 8.8.8.8:53)." }
    var tipDNSSystem: String { isRussian ? "Использовать системные настройки DNS." : "Use system DNS settings." }
}
