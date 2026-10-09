import Foundation

struct CiadpiUpdateStatus {
    let selectedPath: String
    let managedPath: String
    let selectedVersion: String?
    let managedVersion: String?
    let latestVersion: String?
    let sourceTarballURL: URL?

    var updateAvailable: Bool {
        guard let latestVersion else { return false }
        guard let managedVersion else { return true }
        return latestVersion.compare(managedVersion, options: .numeric) == .orderedDescending
    }
}

final class CiadpiUpdater {
    static let shared = CiadpiUpdater()

    private let repo = "hufrea/byedpi"
    private let userAgent = "DPIKillerCiadpiUpdater"

    private init() {}

    func localStatus(selectedPath: String) -> CiadpiUpdateStatus {
        let managedPath = SettingsStore.shared.managedCiadpiPath
        return CiadpiUpdateStatus(
            selectedPath: selectedPath,
            managedPath: managedPath,
            selectedVersion: version(at: selectedPath),
            managedVersion: version(at: managedPath),
            latestVersion: nil,
            sourceTarballURL: nil
        )
    }

    func checkStatus(selectedPath: String, completion: @escaping (Result<CiadpiUpdateStatus, Error>) -> Void) {
        let managedPath = SettingsStore.shared.managedCiadpiPath
        fetchLatestRelease { result in
            switch result {
            case .success(let release):
                completion(.success(CiadpiUpdateStatus(
                    selectedPath: selectedPath,
                    managedPath: managedPath,
                    selectedVersion: self.version(at: selectedPath),
                    managedVersion: self.version(at: managedPath),
                    latestVersion: release.version,
                    sourceTarballURL: release.sourceTarballURL
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func installLatest(completion: @escaping (Result<CiadpiUpdateStatus, Error>) -> Void) {
        fetchLatestRelease { result in
            switch result {
            case .success(let release):
                self.downloadBuildAndInstall(release: release, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchLatestRelease(completion: @escaping (Result<CiadpiRelease, Error>) -> Void) {
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
                      let tagName = json["tag_name"] as? String,
                      let tarball = json["tarball_url"] as? String,
                      let tarballURL = URL(string: tarball) else {
                    throw CiadpiUpdateError.invalidRelease
                }

                completion(.success(CiadpiRelease(
                    version: Self.displayVersion(fromTag: tagName),
                    sourceTarballURL: tarballURL
                )))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func downloadBuildAndInstall(release: CiadpiRelease, completion: @escaping (Result<CiadpiUpdateStatus, Error>) -> Void) {
        var request = URLRequest(url: release.sourceTarballURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        URLSession.shared.downloadTask(with: request) { localURL, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let localURL else {
                completion(.failure(CiadpiUpdateError.downloadFailed))
                return
            }

            do {
                try self.buildAndInstallArchive(at: localURL)
                let selectedPath = SettingsStore.shared.resolvedBinaryPath(for: .ciadpi)
                completion(.success(CiadpiUpdateStatus(
                    selectedPath: selectedPath,
                    managedPath: SettingsStore.shared.managedCiadpiPath,
                    selectedVersion: self.version(at: selectedPath),
                    managedVersion: self.version(at: SettingsStore.shared.managedCiadpiPath),
                    latestVersion: release.version,
                    sourceTarballURL: release.sourceTarballURL
                )))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func buildAndInstallArchive(at archiveURL: URL) throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let tar = Process()
        tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tar.arguments = ["-xzf", archiveURL.path, "--strip-components=1", "-C", tempDir.path]
        try tar.run()
        tar.waitUntilExit()
        guard tar.terminationStatus == 0 else {
            throw CiadpiUpdateError.extractFailed
        }

        let make = Process()
        make.executableURL = URL(fileURLWithPath: "/usr/bin/make")
        make.currentDirectoryURL = tempDir
        make.standardOutput = FileHandle.nullDevice
        make.standardError = FileHandle.nullDevice
        try make.run()
        make.waitUntilExit()
        guard make.terminationStatus == 0 else {
            throw CiadpiUpdateError.buildFailed
        }

        let binaryURL = tempDir.appendingPathComponent("ciadpi")
        guard fileManager.isExecutableFile(atPath: binaryURL.path) else {
            throw CiadpiUpdateError.binaryMissing
        }
        guard Self.smokeTestBinary(at: binaryURL.path) else {
            throw CiadpiUpdateError.buildFailed
        }

        let targetURL = URL(fileURLWithPath: SettingsStore.shared.managedCiadpiPath)
        let targetDir = targetURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)

        let stagedURL = targetDir.appendingPathComponent("ciadpi.new")
        try? fileManager.removeItem(at: stagedURL)
        try fileManager.copyItem(at: binaryURL, to: stagedURL)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: stagedURL.path)
        try? fileManager.removeItem(at: targetURL)
        try fileManager.moveItem(at: stagedURL, to: targetURL)
        clearQuarantine(at: targetURL)
    }

    /// Refuses to install a freshly built binary that cannot even print `--help`.
    /// Keeps the last working managed binary instead of swapping in a broken one.
    private static func smokeTestBinary(at path: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["--help"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return false }
            return output.contains("--split") || output.contains("--tlsrec")
        } catch {
            return false
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
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    private func clearQuarantine(at url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-d", "com.apple.quarantine", url.path]
        try? process.run()
    }

    private static func displayVersion(fromTag tagName: String) -> String {
        let version = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        let parts = version.split(separator: ".").map(String.init)
        if parts.count > 2, parts.first == "0" {
            return parts.dropFirst().joined(separator: ".")
        }
        return version
    }
}

private struct CiadpiRelease {
    let version: String
    let sourceTarballURL: URL
}

private enum CiadpiUpdateError: LocalizedError {
    case invalidRelease
    case downloadFailed
    case extractFailed
    case buildFailed
    case binaryMissing

    var errorDescription: String? {
        switch self {
        case .invalidRelease:
            return "Invalid ByeDPI release response."
        case .downloadFailed:
            return "Could not download ByeDPI source archive."
        case .extractFailed:
            return "Could not extract ByeDPI source archive."
        case .buildFailed:
            return "Could not build ciadpi from source."
        case .binaryMissing:
            return "ciadpi binary was not produced."
        }
    }
}
