import Foundation
import ServiceManagement

/// Local development builds cannot register a bundled LaunchDaemon without
/// notarization. Install the same signed, fixed-operation helper through the
/// protected legacy launchd path after one native administrator confirmation.
enum NetworkHelperInstaller {
    static let executable = "/Library/PrivilegedHelperTools/" + NetworkSettingsIdentity.helperIdentifier
    static let plist = "/Library/LaunchDaemons/" + NetworkSettingsIdentity.launchDaemonPlistName
    static var isLocalBuild: Bool { Bundle.main.object(forInfoDictionaryKey: "DPIKillerLocalNetworkHelper") as? Bool == true }

    static var status: SMAppService.Status {
        SMAppService.statusForLegacyPlist(at: URL(fileURLWithPath: plist))
    }

    static func ensureInstalled() throws {
        let source = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/HelperTools/DPIKillerNetworkHelper").path
        let requirement = try NetworkSettingsIdentity.requirement(identifier: NetworkSettingsIdentity.helperIdentifier)
        if FileManager.default.fileExists(atPath: executable),
           FileManager.default.fileExists(atPath: plist),
           try run("/usr/bin/codesign", ["--verify", "--strict", "-R", "=" + requirement, executable]).status == 0,
           try run("/usr/bin/cmp", ["-s", source, executable]).status == 0,
           try run("/bin/launchctl", ["print", "system/" + NetworkSettingsIdentity.helperIdentifier]).status == 0 {
            return
        }
        let label = NetworkSettingsIdentity.helperIdentifier
        let configuration: [String: Any] = [
            "Label": label, "ProgramArguments": [executable], "UserName": "root",
            "MachServices": [label: true], "RunAtLoad": true
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: configuration, format: .xml, options: 0)
        let xml = String(decoding: data, as: UTF8.self)
        let script = """
        set -eu
        source=\(quote(source))
        target=\(quote(executable))
        daemon=\(quote(plist))
        requirement=\(quote("=" + requirement))
        label=\(quote(label))
        for directory in /Library/PrivilegedHelperTools /Library/LaunchDaemons; do
            [ ! -L "$directory" ] || exit 70
            /usr/bin/install -d -o root -g wheel -m 755 "$directory"
        done
        for file in "$target" "$daemon"; do
            [ ! -L "$file" ] || exit 70
            if [ -e "$file" ]; then
                [ "$(/usr/bin/stat -f %u "$file")" = 0 ] || exit 70
            fi
        done
        /usr/bin/codesign --verify --strict -R "$requirement" "$source"
        if [ -e "$target" ]; then
            /usr/bin/codesign --verify --strict -R "$requirement" "$target"
        fi
        if [ -e "$daemon" ]; then
            [ "$(/usr/libexec/PlistBuddy -c 'Print :Label' "$daemon")" = "$label" ] || exit 70
            [ "$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:0' "$daemon")" = "$target" ] || exit 70
        fi
        stage=$(/usr/bin/mktemp -d /Library/PrivilegedHelperTools/.DPIKillerNetworkHelper.XXXXXX)
        touched=0
        committed=0
        cleanup() {
            /bin/rm -f "$stage/helper" "$stage/daemon" "$stage/old-helper" "$stage/old-daemon"
            /bin/rmdir "$stage"
        }
        finish() {
            result=$?
            trap - EXIT
            if [ "$touched" = 1 ] && [ "$committed" = 0 ]; then
                /bin/launchctl bootout "system/$label" >/dev/null 2>&1 || true
                if [ -e "$stage/old-helper" ] && [ -e "$stage/old-daemon" ]; then
                    if ! /bin/cp -p "$stage/old-helper" "$target" || ! /bin/cp -p "$stage/old-daemon" "$daemon" || ! /bin/launchctl bootstrap system "$daemon"; then
                        /usr/bin/printf 'Helper recovery failed; previous signed files retained in %s\\n' "$stage" >&2
                        exit 72
                    fi
                else
                    /bin/rm -f "$target" "$daemon"
                fi
            fi
            cleanup
            exit "$result"
        }
        trap finish EXIT
        /usr/bin/install -o root -g wheel -m 755 "$source" "$stage/helper"
        /usr/bin/codesign --verify --strict -R "$requirement" "$stage/helper"
        /usr/bin/printf %s \(quote(xml)) > "$stage/daemon"
        /bin/chmod 644 "$stage/daemon"
        /usr/bin/plutil -lint "$stage/daemon"
        if [ -e "$target" ]; then /bin/cp -p "$target" "$stage/old-helper"; fi
        if [ -e "$daemon" ]; then /bin/cp -p "$daemon" "$stage/old-daemon"; fi
        touched=1
        if /bin/launchctl print "system/$label" >/dev/null 2>&1; then
            /bin/launchctl bootout "system/$label"
        fi
        /bin/mv -f "$stage/helper" "$target"
        /bin/mv -f "$stage/daemon" "$daemon"
        /bin/launchctl bootstrap system "$daemon"
        ready=0
        for attempt in 1 2 3 4 5 6 7 8 9 10; do
            if /bin/launchctl print "system/$label" | /usr/bin/grep -q 'state = running'; then ready=1; break; fi
            /bin/sleep 0.2
        done
        [ "$ready" = 1 ] || exit 71
        committed=1
        """
        let literal = "\"" + script.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n") + "\""
        AppLogger.log("[Helper] Installing signed network helper; waiting for native administrator confirmation.")
        let result = try run("/usr/bin/osascript", ["-e", "do shell script \(literal) with administrator privileges"])
        guard result.status == 0 else {
            throw NSError(domain: label, code: Int(result.status), userInfo: [NSLocalizedDescriptionKey: result.output])
        }
        AppLogger.log("[Helper] Signed network helper installed in the protected launchd directory.")
    }

    private static func quote(_ value: String) -> String { "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'" }

    private static func run(_ path: String, _ arguments: [String]) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
