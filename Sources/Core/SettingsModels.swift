import Foundation

enum SettingsTab: String, CaseIterable, Identifiable {
    case backend
    case network
    case bypass
    case dns
    case app
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .backend:
            return L10n.shared.sectionBackend
        case .network:
            return L10n.shared.sectionNetwork
        case .bypass:
            return L10n.shared.sectionDPI
        case .dns:
            return L10n.shared.sectionDNS
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
        case .bypass:
            return "shield.lefthalf.filled"
        case .dns:
            return "globe"
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
                supportedFlags: ["--system-proxy", "--policy-auto"]
            )
        case .spoofdpi:
            return BackendCapability(
                engine: engine,
                proxyMode: .http,
                supportsDNS: true,
                supportsChunkSize: true,
                supportsSpoofdpiUpdate: true,
                supportedFlags: ["--system-proxy", "--silent", "--dns-ipv4-only", "--debug"]
            )
        }
    }
}

struct CommonSettings {
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
    var vpnModeEnabled: Bool
}

struct EngineSettings {
    var selectedFlags: Set<String>
    var manualArgs: String
}

struct SettingsDraft {
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
