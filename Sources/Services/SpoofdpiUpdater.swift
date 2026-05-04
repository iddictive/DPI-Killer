import Foundation

struct SpoofdpiUpdateStatus {
    let selectedPath: String
    let managedPath: String
    let selectedVersion: String?
    let managedVersion: String?
    let latestVersion: String?
    let downloadURL: URL?

    var updateAvailable: Bool {
        guard let latestVersion else { return false }
        guard let managedVersion else { return true }
        return latestVersion.compare(managedVersion, options: .numeric) == .orderedDescending
    }
}

final class SpoofdpiUpdater {
    static let shared = SpoofdpiUpdater()

    private let repo = "xvzc/spoofdpi"
    private let userAgent = "DPIKillerSpoofdpiUpdater"

    private init() {}

    func localStatus(selectedPath: String) -> SpoofdpiUpdateStatus {
        let managedPath = SettingsStore.shared.managedSpoofdpiPath
        return SpoofdpiUpdateStatus(
            selectedPath: selectedPath,
            managedPath: managedPath,
            selectedVersion: version(at: selectedPath),
            managedVersion: version(at: managedPath),
            latestVersion: nil,
            downloadURL: nil
        )
    }

    func checkStatus(selectedPath: String, completion: @escaping (Result<SpoofdpiUpdateStatus, Error>) -> Void) {
        let managedPath = SettingsStore.shared.managedSpoofdpiPath
        fetchLatestRelease { result in
            switch result {
            case .success(let release):
                completion(.success(SpoofdpiUpdateStatus(
                    selectedPath: selectedPath,
                    managedPath: managedPath,
                    selectedVersion: self.version(at: selectedPath),
                    managedVersion: self.version(at: managedPath),
                    latestVersion: release.version,
                    downloadURL: release.downloadURL
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func installLatest(completion: @escaping (Result<SpoofdpiUpdateStatus, Error>) -> Void) {
        fetchLatestRelease { result in
            switch result {
            case .success(let release):
                self.downloadAndInstall(release: release, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func version(at path: String) -> String? {
        guard FileManager.default.isExecutableFile(atPath: path) else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            return Self.parseVersion(from: output)
        } catch {
            return nil
        }
    }

    private func fetchLatestRelease(completion: @escaping (Result<Release, Error>) -> Void) {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }

            do {
                guard let data,
                      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    throw UpdateError.invalidRelease
                }

                let suffix = self.assetSuffix()
                let assets = json["assets"] as? [[String: Any]] ?? []
                guard let asset = assets.first(where: {
                    ($0["name"] as? String)?.hasSuffix(suffix) == true
                }),
                    let urlString = asset["browser_download_url"] as? String,
                    let downloadURL = URL(string: urlString) else {
                    throw UpdateError.missingAsset(suffix)
                }

                completion(.success(Release(
                    version: tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v")),
                    downloadURL: downloadURL
                )))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func downloadAndInstall(release: Release, completion: @escaping (Result<SpoofdpiUpdateStatus, Error>) -> Void) {
        URLSession.shared.downloadTask(with: release.downloadURL) { localURL, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let localURL else {
                completion(.failure(UpdateError.downloadFailed))
                return
            }

            do {
                try self.installArchive(at: localURL)
                let selectedPath = SettingsStore.shared.binaryPath
                completion(.success(SpoofdpiUpdateStatus(
                    selectedPath: selectedPath,
                    managedPath: SettingsStore.shared.managedSpoofdpiPath,
                    selectedVersion: self.version(at: selectedPath),
                    managedVersion: self.version(at: SettingsStore.shared.managedSpoofdpiPath),
                    latestVersion: release.version,
                    downloadURL: release.downloadURL
                )))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func installArchive(at archiveURL: URL) throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let tar = Process()
        tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tar.arguments = ["-xzf", archiveURL.path, "-C", tempDir.path]
        try tar.run()
        tar.waitUntilExit()
        guard tar.terminationStatus == 0 else {
            throw UpdateError.extractFailed
        }

        guard let binaryURL = fileManager.enumerator(at: tempDir, includingPropertiesForKeys: nil)?
            .compactMap({ $0 as? URL })
            .first(where: { $0.lastPathComponent == "spoofdpi" }) else {
            throw UpdateError.binaryMissing
        }

        let targetURL = URL(fileURLWithPath: SettingsStore.shared.managedSpoofdpiPath)
        let targetDir = targetURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)

        let stagedURL = targetDir.appendingPathComponent("spoofdpi.new")
        try? fileManager.removeItem(at: stagedURL)
        try fileManager.copyItem(at: binaryURL, to: stagedURL)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: stagedURL.path)
        try? fileManager.removeItem(at: targetURL)
        try fileManager.moveItem(at: stagedURL, to: targetURL)
        clearQuarantine(at: targetURL)
    }

    private func clearQuarantine(at url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-d", "com.apple.quarantine", url.path]
        try? process.run()
    }

    private func assetSuffix() -> String {
        machineArch().contains("arm64") ? "darwin_arm64.tar.gz" : "darwin_x86_64.tar.gz"
    }

    private func machineArch() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/uname")
        process.arguments = ["-m"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
        } catch {
            return ""
        }
    }

    private static func parseVersion(from output: String) -> String? {
        let pattern = #"spoofdpi\s+(\d+\.\d+\.\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output) else {
            return nil
        }
        return String(output[range])
    }
}

private struct Release {
    let version: String
    let downloadURL: URL
}

private enum UpdateError: LocalizedError {
    case invalidRelease
    case missingAsset(String)
    case downloadFailed
    case extractFailed
    case binaryMissing

    var errorDescription: String? {
        switch self {
        case .invalidRelease:
            return "Invalid GitHub release response."
        case .missingAsset(let suffix):
            return "Missing SpoofDPI release asset for \(suffix)."
        case .downloadFailed:
            return "SpoofDPI download failed."
        case .extractFailed:
            return "Could not extract SpoofDPI archive."
        case .binaryMissing:
            return "SpoofDPI binary was not found in the archive."
        }
    }
}
