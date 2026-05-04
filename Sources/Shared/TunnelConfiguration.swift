import Foundation

enum TunnelProxyMode: String {
    case http
    case socks
}

struct TunnelConfiguration {
    let backendName: String
    let localPort: Int
    let proxyMode: TunnelProxyMode

    init(backendName: String, localPort: Int, proxyMode: TunnelProxyMode) {
        self.backendName = backendName
        self.localPort = localPort
        self.proxyMode = proxyMode
    }

    init?(providerConfiguration: [String: Any]?) {
        guard
            let providerConfiguration,
            let backendName = providerConfiguration["backendName"] as? String,
            let localPort = providerConfiguration["localPort"] as? Int,
            let proxyModeRaw = providerConfiguration["proxyMode"] as? String,
            let proxyMode = TunnelProxyMode(rawValue: proxyModeRaw)
        else {
            return nil
        }

        self.init(backendName: backendName, localPort: localPort, proxyMode: proxyMode)
    }

    func providerDictionary() -> [String: NSObject] {
        [
            "backendName": backendName as NSString,
            "localPort": NSNumber(value: localPort),
            "proxyMode": proxyMode.rawValue as NSString
        ]
    }
}
