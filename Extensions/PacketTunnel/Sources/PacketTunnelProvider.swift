import Foundation
import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
    override func startTunnel(
        options: [String: NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let configuration = TunnelConfiguration(providerConfiguration: protocolConfiguration.providerConfiguration)
        else {
            completionHandler(NSError(domain: "DPIKillerTunnel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Missing tunnel configuration."
            ]))
            return
        }

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        let ipv4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.255"])
        ipv4.includedRoutes = []
        settings.ipv4Settings = ipv4

        let proxy = NEProxySettings()
        proxy.autoProxyConfigurationEnabled = true
        proxy.excludeSimpleHostnames = false
        proxy.matchDomains = [""]
        proxy.exceptionList = ["127.0.0.1", "localhost"]

        switch configuration.proxyMode {
        case .http:
            proxy.proxyAutoConfigurationJavaScript = """
            function FindProxyForURL(url, host) {
              if (host === "127.0.0.1" || host === "localhost") { return "DIRECT"; }
              return "PROXY 127.0.0.1:\(configuration.localPort); DIRECT";
            }
            """
        case .socks:
            proxy.proxyAutoConfigurationJavaScript = """
            function FindProxyForURL(url, host) {
              if (host === "127.0.0.1" || host === "localhost") { return "DIRECT"; }
              return "SOCKS5 127.0.0.1:\(configuration.localPort); DIRECT";
            }
            """
        }

        settings.proxySettings = proxy
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])

        setTunnelNetworkSettings(settings, completionHandler: completionHandler)
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        completionHandler?(nil)
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {}
}
