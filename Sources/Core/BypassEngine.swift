import Foundation

enum ProxyMode {
    case http
    case socks
}

enum BackendSelection: String {
    case automatic
    case ciadpi
    case spoofdpi
    case dual
    case custom
}

enum BypassEngine: String {
    case ciadpi
    case spoofdpi

    init(binaryPath: String) {
        let normalized = URL(fileURLWithPath: binaryPath).lastPathComponent.lowercased()
        if normalized.contains("ciadpi") || normalized.contains("byedpi") {
            self = .ciadpi
        } else {
            self = .spoofdpi
        }
    }

    var displayName: String {
        switch self {
        case .ciadpi:
            return "ciadpi"
        case .spoofdpi:
            return "spoofdpi"
        }
    }

    var proxyMode: ProxyMode {
        switch self {
        case .ciadpi:
            return .socks
        case .spoofdpi:
            return .http
        }
    }

    var proxyDescription: String {
        switch proxyMode {
        case .http:
            return "HTTP"
        case .socks:
            return "SOCKS5"
        }
    }

    var processNames: [String] {
        switch self {
        case .ciadpi:
            return ["ciadpi"]
        case .spoofdpi:
            return ["spoofdpi", "spoof-dpi"]
        }
    }

    func sessionProxyDictionary(port: Int) -> [AnyHashable: Any] {
        switch proxyMode {
        case .http:
            return [
                kCFNetworkProxiesHTTPEnable: 1,
                kCFNetworkProxiesHTTPProxy: "127.0.0.1",
                kCFNetworkProxiesHTTPPort: port,
                kCFNetworkProxiesHTTPSEnable: 1,
                kCFNetworkProxiesHTTPSProxy: "127.0.0.1",
                kCFNetworkProxiesHTTPSPort: port
            ]
        case .socks:
            return [
                kCFNetworkProxiesSOCKSEnable: 1,
                kCFNetworkProxiesSOCKSProxy: "127.0.0.1",
                kCFNetworkProxiesSOCKSPort: port
            ]
        }
    }
}
