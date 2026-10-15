import Foundation

extension BypassEngine {
    /// SpoofDPI's PreferGo resolver bypasses macOS's native DNS service.
    /// Force the supported Go native resolver only for the System DNS mode.
    func processEnvironment(dnsMode: String, inheriting environment: [String: String] = ProcessInfo.processInfo.environment) -> [String: String] {
        guard self == .spoofdpi,
              ["system", "sys"].contains(dnsMode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) else {
            return environment
        }
        var result = environment
        var options = (result["GODEBUG"] ?? "").split(separator: ",").map(String.init)
        options.removeAll { $0.hasPrefix("netdns=") }
        options.append("netdns=cgo")
        result["GODEBUG"] = options.joined(separator: ",")
        return result
    }
}
