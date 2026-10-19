import CFNetwork
extension SystemProxyController {
    static func runLocalExclusionProbe() throws {
        let original = Endpoint(host: nil, port: nil, enabled: nil)
        func lease(_ exceptions: [String]?) -> Lease {
            Lease(serviceID: "fixture-service", port: 18080, prefixes: ["HTTP", "HTTPS"],
                  originals: ["HTTP": original, "HTTPS": original], originalExceptions: exceptions,
                  addedExceptions: localExceptions.filter { !(exceptions ?? []).contains($0) })
        }
        let endpoints: [String: Any] = ["HTTPEnable": 1, "HTTPProxy": "127.0.0.1", "HTTPPort": 18080,
                                        "HTTPSEnable": 1, "HTTPSProxy": "127.0.0.1", "HTTPSPort": 18080,
                                        "Unrelated": "retained"]
        for exceptions: [String]? in [nil, [], ["user.example", "*.local", "user.example"]] {
            var config = endpoints
            if let exceptions { config[exceptionsKey] = exceptions }
            let snapshot = lease(exceptions)
            precondition(snapshot.isValid)
            precondition(!hasLocalExceptions(config))
            addLocalExceptions(to: &config)
            precondition(hasLocalExceptions(config))
            let first = config as NSDictionary
            addLocalExceptions(to: &config)
            precondition(first.isEqual(to: config), "merge must be idempotent")
            precondition((config[exceptionsKey] as! [String]).prefix(exceptions?.count ?? 0) == (exceptions ?? [])[...])
            precondition(restoreOwnedEntries(snapshot, in: &config))
            precondition(config[exceptionsKey] as? [String] == exceptions, "original bypass list must survive exactly")
            precondition(config["Unrelated"] as? String == "retained")
            precondition(!restoreOwnedEntries(snapshot, in: &config), "repeat restore must be no-op")
        }
        let snapshot = lease(["user.example", "*.local"])
        var config = endpoints
        config[exceptionsKey] = snapshot.originalExceptions
        precondition(matchesAppliedLease(snapshot, prefixes: ["HTTP", "HTTPS"], port: 18080,
                                         serviceID: "fixture-service", configuration: config, active: config))
        precondition(!hasLocalExceptions(config), "existing active endpoint still requires repair")
        addLocalExceptions(to: &config)
        config[exceptionsKey] = (config[exceptionsKey] as! [String]) + ["later.example"]
        _ = restoreOwnedEntries(snapshot, in: &config)
        precondition(config[exceptionsKey] as? [String] == ["user.example", "*.local", "later.example"])
        var laterDuplicate = endpoints
        laterDuplicate[exceptionsKey] = snapshot.originalExceptions
        addLocalExceptions(to: &laterDuplicate)
        laterDuplicate[exceptionsKey] = (laterDuplicate[exceptionsKey] as! [String]) + ["later.example", "localhost", "localhost"]
        _ = restoreOwnedEntries(snapshot, in: &laterDuplicate)
        guard laterDuplicate[exceptionsKey] as? [String] == ["user.example", "*.local", "later.example", "localhost", "localhost"] else {
            print("FAIL restore removed later foreign occurrences of an owned exclusion")
            exit(1)
        }
        var foreign = endpoints
        addLocalExceptions(to: &foreign)
        for prefix in ["HTTP", "HTTPS"] { foreign["\(prefix)Proxy"] = "other.proxy" }
        let unchanged = foreign as NSDictionary
        precondition(!restoreOwnedEntries(snapshot, in: &foreign))
        precondition(unchanged.isEqual(to: foreign), "foreign endpoint and bypass list must remain unchanged")
        let oldData = Data(#"{"serviceID":"fixture-service","port":18080,"prefixes":["HTTP","HTTPS"],"originals":{"HTTP":{},"HTTPS":{}}}"#.utf8)
        let oldLease = try JSONDecoder().decode(Lease.self, from: oldData)
        precondition(oldLease.isValid && oldLease.addedExceptions == nil)
        var legacy = endpoints
        legacy[exceptionsKey] = ["legacy.example"]
        _ = restoreOwnedEntries(oldLease, in: &legacy)
        precondition(legacy[exceptionsKey] as? [String] == ["legacy.example"])
        var invalid = snapshot
        let invalidData = Data(#"{"serviceID":"fixture-service","port":18080,"prefixes":["HTTP"],"originals":{"HTTP":{}},"addedExceptions":["foreign.example"]}"#.utf8)
        invalid = try JSONDecoder().decode(Lease.self, from: invalidData)
        precondition(!invalid.isValid)
        for prefix in ["HTTP", "SOCKS"] {
            var routing: [String: Any] = ["\(prefix)Enable": 1, "\(prefix)Proxy": "127.0.0.1", "\(prefix)Port": 18080]
            addLocalExceptions(to: &routing)
            for (hosts, expected) in [(["localhost", "api.localhost", "printer.local", "127.42.1.2", "[::1]", "10.1.2.3", "172.16.0.1", "172.31.255.254", "192.168.1.2"], kCFProxyTypeNone as String),
                                      (["example.com", "8.8.8.8", "11.0.0.1", "172.15.255.254", "172.32.0.1", "192.169.0.1"], (prefix == "HTTP" ? kCFProxyTypeHTTP : kCFProxyTypeSOCKS) as String)] {
                for host in hosts {
                    let url = URL(string: "http://\(host)/")!
                    let proxies = CFNetworkCopyProxiesForURL(url as CFURL, routing as CFDictionary).takeRetainedValue() as! [[String: Any]]
                    precondition(proxies.first?[kCFProxyTypeKey as String] as? String == expected, "\(prefix) \(url): \(proxies)")
                }
            }
        }
        print("PASS source-owned ExceptionsList CFNetwork routing for HTTP/SOCKS: 30 local/public/boundary routes")
        print("PASS production merge/restore: nil, empty, user order/duplicates, idempotence, active endpoint repair eligibility, later additions and matching duplicates, foreign endpoints, old-lease decode, invalid ownership")
    }
}
try SystemProxyController.runLocalExclusionProbe()
