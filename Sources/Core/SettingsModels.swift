import Foundation

enum SettingsTab: String, CaseIterable, Identifiable {
    case backend
    case network
    case app
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .backend:
            return L10n.shared.sectionBackend
        case .network:
            return L10n.shared.sectionNetwork
        case .app:
            return L10n.shared.sectionApp
        case .manual:
            return L10n.shared.sectionManual
        }
    }

    var systemImage: String {
        switch self {
        case .backend:
            return "terminal"
        case .network:
            return "network"
        case .app:
            return "gearshape"
        case .manual:
            return "text.badge.plus"
        }
    }
}

enum SettingScope: Equatable {
    case common
    case engine(BypassEngine)
}

extension BypassEngine: Hashable {}

struct SettingSpec: Identifiable {
    let id: String
    let title: String
    let scope: SettingScope
    let supportedEngines: Set<BypassEngine>

    func isSupported(by engine: BypassEngine) -> Bool {
        supportedEngines.contains(engine)
    }
}

struct BackendCapability {
    let engine: BypassEngine
    let proxyMode: ProxyMode
    let supportsDNS: Bool
    let supportsChunkSize: Bool
    let supportsSpoofdpiUpdate: Bool
    let supportedFlags: Set<String>

    func supports(flag: String) -> Bool {
        supportedFlags.contains(flag)
    }

    static func forEngine(_ engine: BypassEngine) -> BackendCapability {
        switch engine {
        case .ciadpi:
            return BackendCapability(
                engine: engine,
                proxyMode: .socks,
                supportsDNS: false,
                supportsChunkSize: false,
                supportsSpoofdpiUpdate: false,
                supportedFlags: ["--policy-auto"]
            )
        case .spoofdpi:
            return BackendCapability(
                engine: engine,
                proxyMode: .http,
                supportsDNS: true,
                supportsChunkSize: true,
                supportsSpoofdpiUpdate: true,
                supportedFlags: ["--dns-ipv4-only", "--debug"]
            )
        }
    }
}

enum NetworkSettingsMode: String, CaseIterable, Identifiable {
    case helper, manual
    var id: String { rawValue }
    var title: String {
        switch self {
        case .helper: return L10n.shared.isRussian ? "Помощник" : "Helper"
        case .manual: return L10n.shared.isRussian ? "Напрямую" : "Direct"
        }
    }
    var detail: String {
        switch self {
        case .helper: return L10n.shared.isRussian ? "Встроенный помощник меняет системные настройки без повторных запросов. Требуется разрешить его фоновую работу в macOS." : "The bundled helper changes system settings without repeated prompts. Allow its background activity in macOS."
        case .manual: return L10n.shared.isRussian ? "Приложение меняет настройки напрямую. macOS может запрашивать пароль администратора при изменениях." : "The app changes settings directly. macOS may request administrator confirmation when settings change."
        }
    }
}

struct CommonSettings: Equatable {
    var localPort: String
    var defaultTTL: String
    var splitMode: String
    var httpsDisorder: Bool
    var httpsFakeCount: String
    var httpsChunkSize: String
    var dnsAddr: String
    var dnsMode: String
    var dnsHttpsUrl: String
    var launchAtLogin: Bool
    var autoUpdate: Bool
    var autoDownload: Bool
    var disableIpv6: Bool
    var autoReconnect: Bool
    var systemProxyEnabled: Bool
    var networkSettingsMode: NetworkSettingsMode = .helper
    var vpnClientCompatibilityEnabled: Bool
    var vpnModeEnabled: Bool
}

struct EngineSettings: Equatable {
    var selectedFlags: Set<String>
    var manualArgs: String
}

struct SettingsDraft: Equatable {
    var backendSelection: BackendSelection
    var customPath: String
    var common: CommonSettings
    var ciadpi: EngineSettings
    var spoofdpi: EngineSettings

    func engineSettings(for engine: BypassEngine) -> EngineSettings {
        switch engine {
        case .ciadpi:
            return ciadpi
        case .spoofdpi:
            return spoofdpi
        }
    }
}

enum SettingsPreset: String, CaseIterable, Identifiable {
    case balanced
    case hotspot
    case conservative

    var id: String { rawValue }

    var parameters: (ttl: String, split: String, disorder: Bool, fakes: String, chunk: String) {
        switch self {
        case .balanced: return ("128", "random", true, "0", "20")
        case .hotspot: return ("65", "random", true, "0", "20")
        case .conservative: return ("128", "sni", false, "0", "20")
        }
    }

    func summary(for engine: BypassEngine) -> String {
        let russian = L10n.shared.isRussian
        let splitting: String
        if self == .conservative {
            splitting = russian ? "Разбиение HTTPS у SNI, обычный порядок фрагментов." : "Split HTTPS at SNI; send fragments in their original order."
        } else {
            if engine == .ciadpi {
                splitting = russian ? "Адаптивное разбиение HTTPS, изменённый порядок фрагментов." : "Adaptive HTTPS splitting; send fragments out of order."
            } else {
                splitting = russian ? "Случайное разбиение HTTPS, изменённый порядок фрагментов." : "Random HTTPS splitting; send fragments out of order."
            }
        }
        if engine == .ciadpi {
            return splitting + (russian ? " TTL пакетов: \(parameters.ttl)." : " Packet TTL: \(parameters.ttl).")
        }
        if self != .conservative {
            return splitting + (russian ? " В SpoofDPI Balanced и Hotspot одинаковы; TTL Mac меняется через оптимизацию сети." : "Balanced and Hotspot are identical in SpoofDPI; change Mac TTL with network optimization.")
        }
        return splitting
    }

    var title: String {
        switch self {
        case .balanced:
            return "Balanced"
        case .hotspot:
            return "Hotspot"
        case .conservative:
            return "Conservative"
        }
    }
}
