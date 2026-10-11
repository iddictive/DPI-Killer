import Foundation
import SystemConfiguration

/// Owns only the proxy entries DPI Killer actually changes on the current
/// primary network service. The saved lease lets the next launch undo a crash.
final class SystemProxyController {
    static let shared = SystemProxyController()

    private struct Endpoint: Codable {
        let host: String?
        let port: Int?
        let enabled: Int?
    }

    private struct Lease: Codable {
        let serviceID: String
        let port: Int
        let prefixes: [String]
        let originals: [String: Endpoint]
    }

    private let leaseKey = "systemProxyLease"
    private let lock = NSRecursiveLock()
    private let defaults = UserDefaults.standard

    var hasLease: Bool { defaults.data(forKey: leaseKey) != nil }

    func apply(mode: ProxyMode, port: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }

        guard restore() else { return L10n.shared.systemProxyApplyFailed }
        guard let (preferences, serviceID, proxy) = currentPrimaryProxy(),
              var configuration = SCNetworkProtocolGetConfiguration(proxy) as? [String: Any] else {
            return L10n.shared.systemProxyUnavailable
        }

        let enabledKeys = [
            kSCPropNetProxiesHTTPEnable as String,
            kSCPropNetProxiesHTTPSEnable as String,
            kSCPropNetProxiesSOCKSEnable as String,
            kSCPropNetProxiesProxyAutoConfigEnable as String,
            kSCPropNetProxiesProxyAutoDiscoveryEnable as String
        ]
        if let store = SCDynamicStoreCreate(nil, "DPI Killer" as CFString, nil, nil),
           let active = SCDynamicStoreCopyProxies(store) as? [String: Any],
           enabledKeys.contains(where: { Self.number(active[$0]) == 1 }) {
            return L10n.shared.systemProxyConflict
        }
        guard enabledKeys.allSatisfy({ Self.number(configuration[$0]) != 1 }) else {
            return L10n.shared.systemProxyConflict
        }

        let prefixes = mode == .http ? ["HTTP", "HTTPS"] : ["SOCKS"]
        var originals: [String: Endpoint] = [:]
        for prefix in prefixes {
            originals[prefix] = Endpoint(
                host: configuration["\(prefix)Proxy"] as? String,
                port: Self.number(configuration["\(prefix)Port"]),
                enabled: Self.number(configuration["\(prefix)Enable"])
            )
        }
        let lease = Lease(serviceID: serviceID, port: port, prefixes: prefixes, originals: originals)
        guard let data = try? JSONEncoder().encode(lease) else { return L10n.shared.systemProxyApplyFailed }
        defaults.set(data, forKey: leaseKey)
        defaults.synchronize()

        for prefix in prefixes {
            configuration["\(prefix)Proxy"] = "127.0.0.1"
            configuration["\(prefix)Port"] = port
            configuration["\(prefix)Enable"] = 1
        }

        guard SCNetworkProtocolSetConfiguration(proxy, configuration as CFDictionary),
              SCPreferencesCommitChanges(preferences),
              SCPreferencesApplyChanges(preferences) else {
            _ = restore()
            return L10n.shared.systemProxyApplyFailed
        }
        return nil
    }

    @discardableResult
    func restore() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let data = defaults.data(forKey: leaseKey) else { return true }
        guard let lease = try? JSONDecoder().decode(Lease.self, from: data) else { return false }
        guard let preferences = SCPreferencesCreate(nil, "DPI Killer" as CFString, nil),
              let service = SCNetworkServiceCopy(preferences, lease.serviceID as CFString),
              let proxy = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies),
              var configuration = SCNetworkProtocolGetConfiguration(proxy) as? [String: Any] else {
            // The old service no longer exists, so it cannot retain our proxy.
            defaults.removeObject(forKey: leaseKey)
            return true
        }

        var changed = false
        for prefix in lease.prefixes {
            guard let original = lease.originals[prefix],
                  configuration["\(prefix)Proxy"] as? String == "127.0.0.1",
                  Self.number(configuration["\(prefix)Port"]) == lease.port else { continue }
            Self.set(original.host, for: "\(prefix)Proxy", in: &configuration)
            Self.set(original.port, for: "\(prefix)Port", in: &configuration)
            Self.set(original.enabled, for: "\(prefix)Enable", in: &configuration)
            changed = true
        }

        if changed {
            guard SCNetworkProtocolSetConfiguration(proxy, configuration as CFDictionary),
                  SCPreferencesCommitChanges(preferences),
                  SCPreferencesApplyChanges(preferences) else { return false }
        }
        defaults.removeObject(forKey: leaseKey)
        return true
    }

    private func currentPrimaryProxy() -> (SCPreferences, String, SCNetworkProtocol)? {
        guard let store = SCDynamicStoreCreate(nil, "DPI Killer" as CFString, nil, nil),
              let state = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
              let serviceID = state["PrimaryService"] as? String,
              let preferences = SCPreferencesCreate(nil, "DPI Killer" as CFString, nil),
              let service = SCNetworkServiceCopy(preferences, serviceID as CFString),
              let proxy = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies) else {
            return nil
        }
        return (preferences, serviceID, proxy)
    }

    private static func number(_ value: Any?) -> Int? {
        (value as? NSNumber)?.intValue
    }

    private static func set(_ value: Any?, for key: String, in configuration: inout [String: Any]) {
        if let value {
            configuration[key] = value
        } else {
            configuration.removeValue(forKey: key)
        }
    }
}
