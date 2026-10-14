import Foundation
import SystemConfiguration
import Security

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

        var isValid: Bool {
            !serviceID.isEmpty && (1...65535).contains(port)
                && !prefixes.isEmpty && Set(prefixes).count == prefixes.count
                && prefixes.allSatisfy { ["HTTP", "HTTPS", "SOCKS"].contains($0) && originals[$0] != nil }
        }
    }

    private static let enabledKeys = [
        kSCPropNetProxiesHTTPEnable as String,
        kSCPropNetProxiesHTTPSEnable as String,
        kSCPropNetProxiesSOCKSEnable as String,
        kSCPropNetProxiesProxyAutoConfigEnable as String,
        kSCPropNetProxiesProxyAutoDiscoveryEnable as String
    ]

    private let leaseKey = "systemProxyLease"
    private let lock = NSRecursiveLock()
    private let defaults: UserDefaults
    private let privileged: Bool
    private var authorization: AuthorizationRef?
    private var errorMessage: String?
    init(defaults: UserDefaults = .standard, privileged: Bool = false) {
        self.defaults = defaults
        self.privileged = privileged
    }

    private var usesNetworkHelper: Bool {
        #if DPIKILLER_NETWORK_HELPER
        return false
        #else
        return !privileged && SettingsStore.shared.networkSettingsMode == .helper && NetworkSettingsClient.shared.isSupported
        #endif
    }
    private(set) var lastError: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return errorMessage
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            errorMessage = newValue
        }
    }

    var hasLease: Bool {
        #if !DPIKILLER_NETWORK_HELPER
        if NetworkSettingsClient.shared.isSupported, NetworkSettingsClient.shared.hasLease { return true }
        #endif
        // UserDefaults reads are thread-safe. UI must not wait on the
        // transaction lock while macOS is showing an authorization prompt.
        return defaults.data(forKey: leaseKey) != nil
    }

    deinit {
        if let authorization { AuthorizationFree(authorization, []) }
    }

    func apply(mode: ProxyMode, port: Int) -> String? {
        #if !DPIKILLER_NETWORK_HELPER
        if usesNetworkHelper {
            let response = NetworkSettingsClient.shared.applyProxy(mode: mode, port: port, legacyLease: defaults.data(forKey: leaseKey))
            finishHelperResponse(response)
            return response.error
        }
        #endif
        lock.lock()
        defer { lock.unlock() }

        lastError = nil
        AppLogger.log("[Proxy] Apply requested: mode=\(mode), endpoint=127.0.0.1:\(port).")
        let prefixes = mode == .http ? ["HTTP", "HTTPS"] : ["SOCKS"]
        if isAlreadyApplied(prefixes: prefixes, port: port) {
            AppLogger.log("[Proxy] Requested system proxy is already saved and active; no network changes needed.")
            return nil
        }
        guard restore() else { return lastError ?? L10n.shared.systemProxyApplyFailed }
        guard (1...65535).contains(port) else { return failure("validate port", detail: "Invalid loopback port \(port)") }
        guard let store = SCDynamicStoreCreate(nil, "DPI Killer" as CFString, nil, nil),
              let serviceID = primaryService(in: store) else {
            return failure("resolve primary service", detail: L10n.shared.systemProxyUnavailable)
        }
        guard let preferences = authorizedPreferences(), SCPreferencesLock(preferences, false) else {
            return lastError ?? failure("lock preferences")
        }
        var preferencesLocked = true
        defer { if preferencesLocked { SCPreferencesUnlock(preferences) } }
        guard primaryService(in: store) == serviceID else {
            return failure("recheck primary service", detail: L10n.shared.systemProxyUnavailable)
        }
        guard let service = SCNetworkServiceCopy(preferences, serviceID as CFString),
              let proxy = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies),
              var configuration = SCNetworkProtocolGetConfiguration(proxy) as? [String: Any] else {
            return failure("read proxy configuration")
        }
        AppLogger.log("[Proxy] Preferences locked for service \(serviceID).")

        if let active = SCDynamicStoreCopyProxies(store) as? [String: Any],
           Self.enabledKeys.contains(where: { Self.number(active[$0]) == 1 }) {
            return failure("check active proxies", detail: L10n.shared.systemProxyConflict)
        }
        guard Self.enabledKeys.allSatisfy({ Self.number(configuration[$0]) != 1 }) else {
            return failure("check saved proxies", detail: L10n.shared.systemProxyConflict)
        }

        var originals: [String: Endpoint] = [:]
        for prefix in prefixes {
            originals[prefix] = Endpoint(
                host: configuration["\(prefix)Proxy"] as? String,
                port: Self.number(configuration["\(prefix)Port"]),
                enabled: Self.number(configuration["\(prefix)Enable"])
            )
        }
        let lease = Lease(serviceID: serviceID, port: port, prefixes: prefixes, originals: originals)
        guard let data = try? JSONEncoder().encode(lease) else {
            return failure("save recovery snapshot", detail: "Could not encode proxy lease")
        }
        defaults.set(data, forKey: leaseKey)
        guard defaults.synchronize(), defaults.data(forKey: leaseKey) == data else {
            return failure("save recovery snapshot", detail: "Could not persist the proxy recovery lease; network settings were not changed")
        }
        AppLogger.log("[Proxy] Recovery snapshot saved: service=\(serviceID), entries=\(prefixes.joined(separator: "/")).")

        for prefix in prefixes {
            configuration["\(prefix)Proxy"] = "127.0.0.1"
            configuration["\(prefix)Port"] = port
            configuration["\(prefix)Enable"] = 1
        }

        let error = write(configuration, proxy: proxy, preferences: preferences, operation: "apply")
        // Recovery needs its own session and lock after this transaction ends.
        SCPreferencesUnlock(preferences)
        preferencesLocked = false
        if let error {
            let recovered = restore()
            lastError = recovered ? error : error + " " + (lastError ?? L10n.shared.systemProxyApplyFailed)
            return lastError
        }
        guard waitForActive(configuration, prefixes: prefixes, serviceID: serviceID, restoring: false) else {
            let error = failure("verify active proxy", detail: L10n.shared.isRussian
                ? "macOS не активировал прокси. Повтори включение; подробности в логах."
                : "macOS did not activate the proxy. Try enabling it again; see logs for details.")
            let recovered = restore()
            lastError = recovered ? error : error + " " + (lastError ?? L10n.shared.systemProxyApplyFailed)
            return lastError
        }
        AppLogger.log("[Proxy] Active system proxy confirmed: service=\(serviceID), \(prefixes.joined(separator: "/")) 127.0.0.1:\(port).")
        return nil
    }

    @discardableResult
    func restore() -> Bool {
        #if !DPIKILLER_NETWORK_HELPER
        if usesNetworkHelper, !SettingsStore.shared.usesSystemProxy,
           !NetworkSettingsClient.shared.hasLease, !NetworkSettingsClient.shared.needsRecovery,
           defaults.data(forKey: leaseKey) == nil { return true }
        if usesNetworkHelper || (!privileged && NetworkSettingsClient.shared.hasLease) || (!privileged && NetworkSettingsClient.shared.needsRecovery) {
            if NetworkSettingsClient.shared.needsApproval, !NetworkSettingsClient.shared.hasLease,
               !NetworkSettingsClient.shared.needsRecovery, defaults.data(forKey: leaseKey) != nil {
                return restoreDirect()
            }
            let response = NetworkSettingsClient.shared.restoreProxy(legacyLease: defaults.data(forKey: leaseKey))
            finishHelperResponse(response)
            return response.error == nil
        }
        #endif
        return restoreDirect()
    }

    private func restoreDirect() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        lastError = nil
        guard let data = defaults.data(forKey: leaseKey) else { return true }
        guard let lease = try? JSONDecoder().decode(Lease.self, from: data), lease.isValid else {
            failure("read recovery snapshot", detail: "Invalid saved proxy lease; snapshot retained")
            return false
        }
        AppLogger.log("[Proxy] Restore requested: service=\(lease.serviceID), endpoint=127.0.0.1:\(lease.port).")
        guard let preferences = SCPreferencesCreate(nil, "DPI Killer" as CFString, nil) else {
            failure("open recovery preferences")
            return false
        }
        guard let service = SCNetworkServiceCopy(preferences, lease.serviceID as CFString) else {
            // Only a genuinely removed service makes this lease obsolete.
            guard let services = SCNetworkServiceCopyAll(preferences) as? [SCNetworkService],
                  !services.contains(where: { SCNetworkServiceGetServiceID($0) as String? == lease.serviceID }) else {
                failure("find recovery service")
                return false
            }
            defaults.removeObject(forKey: leaseKey)
            AppLogger.log("[Proxy] Recovery lease cleared: network service was removed.")
            return true
        }
        guard
              let proxy = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies),
              var configuration = SCNetworkProtocolGetConfiguration(proxy) as? [String: Any] else {
            failure("read recovery configuration")
            return false
        }

        let needsRestore = Self.restoreOwnedEntries(lease, in: &configuration)
        // A prior commit can succeed while activation fails. Retrying must still
        // activate the saved snapshot when the dynamic store has our old endpoint.
        let needsActivation = activeOwnedProxy(lease, differsFrom: configuration)
        if needsRestore || needsActivation {
            guard let authorized = authorizedPreferences(), SCPreferencesLock(authorized, false) else {
                if lastError == nil { failure("lock recovery preferences") }
                return false
            }
            defer { SCPreferencesUnlock(authorized) }
            // Re-read under the lock: another writer may have replaced our endpoint.
            guard let service = SCNetworkServiceCopy(authorized, lease.serviceID as CFString),
                  let proxy = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies),
                  var latest = SCNetworkProtocolGetConfiguration(proxy) as? [String: Any] else {
                failure("re-read recovery configuration")
                return false
            }
            let changed = Self.restoreOwnedEntries(lease, in: &latest)
            if (changed || activeOwnedProxy(lease, differsFrom: latest)),
               write(latest, proxy: proxy, preferences: authorized, operation: "restore") != nil {
                return false
            }
            configuration = latest
        }
        guard waitForActive(configuration, prefixes: lease.prefixes, serviceID: lease.serviceID, restoring: true, ownedPort: lease.port) else {
            failure("verify restored proxy", detail: L10n.shared.isRussian
                ? "macOS ещё не вернул сетевые настройки. Повтори выключение прокси; сохранённые настройки удержаны."
                : "macOS has not restored the network settings. Turn the proxy off again; the recovery snapshot was retained.")
            return false
        }
        defaults.removeObject(forKey: leaseKey)
        AppLogger.log("[Proxy] Restore confirmed; recovery lease cleared. Foreign endpoints preserved.")
        return true
    }

    private func authorizedPreferences() -> SCPreferences? {
        if privileged {
            guard geteuid() == 0 else {
                failure("validate helper privilege", detail: "Network helper is not running as root")
                return nil
            }
            return SCPreferencesCreate(nil, "DPI Killer Network Helper" as CFString, nil)
        }
        if authorization == nil {
            let status = AuthorizationCreate(nil, nil, [], &authorization)
            guard status == errAuthorizationSuccess, authorization != nil else {
                failure("create authorization", detail: "AuthorizationCreate OSStatus=\(status)")
                return nil
            }
        }
        guard let preferences = SCPreferencesCreateWithAuthorization(nil, "DPI Killer" as CFString, nil, authorization) else {
            failure("open authorized preferences")
            return nil
        }
        AppLogger.log("[Proxy] Authorized preferences session opened; macOS may request administrator approval.")
        return preferences
    }

    func importRecoveryLease(_ data: Data) -> String? {
        lock.lock(); defer { lock.unlock() }
        guard data.count <= 16 * 1024, let lease = try? JSONDecoder().decode(Lease.self, from: data), lease.isValid else {
            return failure("import recovery snapshot", detail: "Invalid legacy proxy snapshot")
        }
        if let existing = defaults.data(forKey: leaseKey) {
            guard existing == data else {
                return failure("import recovery snapshot", detail: "Network helper already owns a different recovery snapshot")
            }
            return nil
        }
        defaults.set(data, forKey: leaseKey)
        guard defaults.synchronize(), defaults.data(forKey: leaseKey) == data else {
            return failure("import recovery snapshot", detail: "Could not persist legacy proxy snapshot")
        }
        AppLogger.log("[Proxy] Legacy recovery snapshot imported and verified in the network helper.")
        return nil
    }

    #if !DPIKILLER_NETWORK_HELPER
    private func finishHelperResponse(_ response: NetworkSettingsResponse) {
        if response.legacyLeaseImported {
            defaults.removeObject(forKey: leaseKey)
            defaults.synchronize()
        }
        lastError = response.error
        if let error = response.error { AppLogger.log("[Proxy] Helper operation failed: \(error)") }
    }
    #endif

    private func isAlreadyApplied(prefixes: [String], port: Int) -> Bool {
        guard let data = defaults.data(forKey: leaseKey),
              let lease = try? JSONDecoder().decode(Lease.self, from: data),
              let store = SCDynamicStoreCreate(nil, "DPI Killer" as CFString, nil, nil),
              let serviceID = primaryService(in: store),
              let preferences = SCPreferencesCreate(nil, "DPI Killer" as CFString, nil),
              let service = SCNetworkServiceCopy(preferences, serviceID as CFString),
              let proxy = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies),
              let configuration = SCNetworkProtocolGetConfiguration(proxy) as? [String: Any],
              let active = SCDynamicStoreCopyProxies(store) as? [String: Any],
              primaryService(in: store) == serviceID else { return false }
        return Self.matchesAppliedLease(lease, prefixes: prefixes, port: port, serviceID: serviceID,
                                        configuration: configuration, active: active)
    }

    private static func matchesAppliedLease(_ lease: Lease, prefixes: [String], port: Int, serviceID: String,
                                            configuration: [String: Any], active: [String: Any]) -> Bool {
        guard lease.isValid, lease.prefixes == prefixes, lease.port == port, lease.serviceID == serviceID,
              prefixes.allSatisfy({ prefix in
                  number(configuration["\(prefix)Enable"]) == 1
                      && configuration["\(prefix)Proxy"] as? String == "127.0.0.1"
                      && number(configuration["\(prefix)Port"]) == port
              }), activeMatches(active, expected: configuration, prefixes: prefixes) else { return false }
        let ownedEnableKeys = Set(prefixes.map { "\($0)Enable" })
        return enabledKeys.filter { !ownedEnableKeys.contains($0) }.allSatisfy {
            number(configuration[$0]) != 1 && number(active[$0]) != 1
        }
    }

    private func write(_ configuration: [String: Any], proxy: SCNetworkProtocol, preferences: SCPreferences, operation: String) -> String? {
        guard SCNetworkProtocolSetConfiguration(proxy, configuration as CFDictionary) else { return failure("\(operation): set configuration") }
        AppLogger.log("[Proxy] \(operation): configuration staged.")
        guard SCPreferencesCommitChanges(preferences) else { return failure("\(operation): commit preferences") }
        AppLogger.log("[Proxy] \(operation): preferences committed.")
        guard SCPreferencesApplyChanges(preferences) else { return failure("\(operation): apply preferences") }
        AppLogger.log("[Proxy] \(operation): activation requested.")
        return nil
    }

    private func primaryService(in store: SCDynamicStore) -> String? {
        for family in ["IPv4", "IPv6"] {
            if let state = SCDynamicStoreCopyValue(store, "State:/Network/Global/\(family)" as CFString) as? [String: Any],
               let serviceID = state["PrimaryService"] as? String { return serviceID }
        }
        return nil
    }

    private func waitForActive(_ expected: [String: Any], prefixes: [String], serviceID: String, restoring: Bool, ownedPort: Int? = nil) -> Bool {
        guard let store = SCDynamicStoreCreate(nil, "DPI Killer" as CFString, nil, nil) else { return false }
        let deadline = Date().addingTimeInterval(2)
        repeat {
            guard primaryService(in: store) == serviceID else { return restoring }
            if let active = SCDynamicStoreCopyProxies(store) as? [String: Any] {
                if Self.activeMatches(active, expected: expected, prefixes: prefixes) { return true }
                // VPNs can project a different global proxy. Never undo or wait
                // on a foreign endpoint once our exact endpoint has disappeared.
                if restoring, let ownedPort, !prefixes.contains(where: { prefix in
                    Self.number(active["\(prefix)Enable"]) == 1
                        && active["\(prefix)Proxy"] as? String == "127.0.0.1"
                        && Self.number(active["\(prefix)Port"]) == ownedPort
                }) { return true }
            }
            Thread.sleep(forTimeInterval: 0.05)
        } while Date() < deadline
        AppLogger.log("[Proxy] Dynamic-store propagation timed out: service=\(serviceID), restoring=\(restoring).")
        return false
    }

    private func activeOwnedProxy(_ lease: Lease, differsFrom expected: [String: Any]) -> Bool {
        guard let store = SCDynamicStoreCreate(nil, "DPI Killer" as CFString, nil, nil),
              primaryService(in: store) == lease.serviceID,
              let active = SCDynamicStoreCopyProxies(store) as? [String: Any],
              !Self.activeMatches(active, expected: expected, prefixes: lease.prefixes) else { return false }
        return lease.prefixes.contains { prefix in
            Self.number(active["\(prefix)Enable"]) == 1
                && active["\(prefix)Proxy"] as? String == "127.0.0.1"
                && Self.number(active["\(prefix)Port"]) == lease.port
        }
    }

    private static func activeMatches(_ active: [String: Any], expected: [String: Any], prefixes: [String]) -> Bool {
        prefixes.allSatisfy { prefix in
            let enabled = number(expected["\(prefix)Enable"]) == 1
            guard enabled == (number(active["\(prefix)Enable"]) == 1) else { return false }
            return !enabled || (active["\(prefix)Proxy"] as? String == expected["\(prefix)Proxy"] as? String
                && number(active["\(prefix)Port"]) == number(expected["\(prefix)Port"]))
        }
    }

    private static func restoreOwnedEntries(_ lease: Lease, in configuration: inout [String: Any]) -> Bool {
        var changed = false
        for prefix in lease.prefixes {
            guard let original = lease.originals[prefix],
                  configuration["\(prefix)Proxy"] as? String == "127.0.0.1",
                  number(configuration["\(prefix)Port"]) == lease.port else { continue }
            guard original.host != configuration["\(prefix)Proxy"] as? String
                || original.port != number(configuration["\(prefix)Port"])
                || original.enabled != number(configuration["\(prefix)Enable"]) else { continue }
            set(original.host, for: "\(prefix)Proxy", in: &configuration)
            set(original.port, for: "\(prefix)Port", in: &configuration)
            set(original.enabled, for: "\(prefix)Enable", in: &configuration)
            changed = true
        }
        return changed
    }

    @discardableResult
    private func failure(_ stage: String, detail: String? = nil) -> String {
        let status = SCError()
        let diagnostic = detail ?? "SCError=\(status) \(String(cString: SCErrorString(status)))"
        AppLogger.log("[Proxy] Failed at \(stage): \(diagnostic). Recovery lease=\(hasLease).")
        let recovery: String
        if detail != nil {
            recovery = diagnostic
        } else if status == kSCStatusAccessError {
            recovery = L10n.shared.isRussian
                ? "Разреши изменение сети в запросе администратора macOS и повтори действие."
                : "Approve the macOS administrator request to change network settings, then try again."
        } else {
            recovery = L10n.shared.systemProxyApplyFailed + " " + diagnostic
        }
        lastError = recovery
        return recovery
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
