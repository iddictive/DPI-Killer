import Foundation
import Security

@objc protocol NetworkSettingsProtocol {
    func applyProxy(mode: String, port: Int, legacyLease: Data?, reply: @escaping (Data) -> Void)
    func restoreProxy(legacyLease: Data?, reply: @escaping (Data) -> Void)
    func applyHotspotTTL(reply: @escaping (Data) -> Void)
    func status(reply: @escaping (Data) -> Void)
}

struct NetworkSettingsResponse: Codable {
    let error: String?
    let hasLease: Bool
    let legacyLeaseImported: Bool
    let ttl: Int?
}

enum NetworkSettingsIdentity {
    static let appIdentifier = "com.antigravity.DPIKiller"
    static let helperIdentifier = "com.antigravity.DPIKiller.NetworkHelper"
    static let machServiceName = helperIdentifier
    static let launchDaemonPlistName = helperIdentifier + ".plist"

    static func interface() -> NSXPCInterface {
        NSXPCInterface(with: NetworkSettingsProtocol.self)
    }

    static func teamIdentifier() throws -> String {
        var code: SecCode?
        try check(SecCodeCopySelf([], &code))
        guard let code else { throw identityError("Could not resolve this executable's signature.") }
        var staticCode: SecStaticCode?
        try check(SecCodeCopyStaticCode(code, [], &staticCode))
        guard let staticCode else { throw identityError("Could not inspect this executable's signature.") }
        var information: CFDictionary?
        try check(SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &information))
        guard let signing = information as? [String: Any],
              let team = signing[kSecCodeInfoTeamIdentifier as String] as? String,
              !team.isEmpty,
              team.unicodeScalars.allSatisfy({ (65...90).contains($0.value) || (48...57).contains($0.value) }) else {
            throw identityError("DPI Killer and its network helper require a valid Apple development or distribution signature.")
        }
        return team
    }

    static func requirement(identifier: String) throws -> String {
        guard identifier == appIdentifier || identifier == helperIdentifier else {
            throw identityError("Unknown network settings peer.")
        }
        let team = try teamIdentifier()
        let value = "anchor apple generic and identifier \"\(identifier)\" and certificate leaf[subject.OU] = \"\(team)\""
        var requirement: SecRequirement?
        try check(SecRequirementCreateWithString(value as CFString, [], &requirement))
        guard requirement != nil else { throw identityError("Invalid network settings signing requirement.") }
        return value
    }

    private static func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else {
            throw identityError("Could not verify code signing (\(status)).")
        }
    }

    private static func identityError(_ message: String) -> NSError {
        NSError(domain: machServiceName, code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
