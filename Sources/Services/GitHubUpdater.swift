import Cocoa
import Foundation

final class GitHubUpdater {
    static let shared = GitHubUpdater()

    private let repo = "iddictive/DPI-Killer"
    private var isChecking = false
    private var isDownloading = false
    private var isInstalling = false
    private var isPresentingModal = false
    private var downloadTask: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?

    var currentVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return version.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "1.0.0"
    }

    private var targetAppPath: String {
        let bundlePath = Bundle.main.bundlePath
        let userAppsPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        if bundlePath.hasSuffix(".app") && (
            bundlePath.hasPrefix("/Applications/") ||
            bundlePath == "/Applications/DPIKiller.app" ||
            bundlePath.hasPrefix(userAppsPath + "/") ||
            bundlePath == "\(userAppsPath)/DPIKiller.app"
        ) {
            return bundlePath
        }
        return "/Applications/DPIKiller.app"
    }

    func checkForUpdates(manual: Bool = false) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.checkForUpdates(manual: manual)
            }
            return
        }

        if !manual && !SettingsStore.shared.autoUpdate { return }
        guard !isChecking, !isDownloading, !isInstalling, !isPresentingModal else { return }
        isChecking = true

        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("DPIKillerUpdater", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isChecking = false

                guard let data = data, error == nil,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    if manual {
                        self.showUpdateFailureAlert(informativeText: L10n.shared.updateCheckFailedInfo)
                    }
                    return
                }

                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let tagName = json["tag_name"] as? String,
                          !tagName.isEmpty else {
                        if manual {
                            self.showUpdateFailureAlert(informativeText: L10n.shared.updateCheckFailedInfo)
                        }
                        return
                    }

                    // Guard against draft or prerelease artifacts in stable updater
                    if let isDraft = json["draft"] as? Bool, isDraft { return }
                    if let isPrerelease = json["prerelease"] as? Bool, isPrerelease { return }

                    let cleanTag = tagName
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "^[vV]", with: "", options: .regularExpression)

                    guard self.parseVersionComponents(cleanTag) != nil else {
                        if manual {
                            self.showUpdateFailureAlert(informativeText: L10n.shared.updateCheckFailedInfo)
                        }
                        return
                    }

                    let latestVersion = cleanTag
                    let hasUpdate = self.isNewerVersion(latestVersion, than: self.currentVersion)
                    let assets = json["assets"] as? [[String: Any]]
                    let dmgAsset = assets?.first {
                        ($0["name"] as? String) == "DPIKiller.dmg"
                    }
                    let downloadUrl: String? = {
                        guard let rawUrl = dmgAsset?["browser_download_url"] as? String,
                              let url = URL(string: rawUrl),
                              url.scheme == "https",
                              url.host == "github.com",
                              url.path.hasPrefix("/\(self.repo)/releases/download/") else {
                            return nil
                        }
                        return rawUrl
                    }()

                    if hasUpdate {
                        if downloadUrl == nil {
                            if manual {
                                self.showUpdateFailureAlert(informativeText: L10n.shared.updateNoDownloadInfo)
                            }
                            return
                        }

                        if !manual {
                            if SettingsStore.shared.lastPromptedUpdateVersion == latestVersion {
                                return
                            }

                            if SettingsStore.shared.autoDownload,
                               let dlUrl = downloadUrl,
                               let url = URL(string: dlUrl) {
                                self.startAutomatedUpdate(url: url, version: latestVersion, isBackgroundDownload: true)
                            } else {
                                SettingsStore.shared.lastPromptedUpdateVersion = latestVersion
                                self.showUpdateAlert(version: latestVersion, downloadUrl: downloadUrl)
                            }
                        } else {
                            SettingsStore.shared.lastPromptedUpdateVersion = latestVersion
                            self.showUpdateAlert(version: latestVersion, downloadUrl: downloadUrl)
                        }
                    } else if manual {
                        self.showUpToDateAlert()
                    }
                } catch {
                    AppLogger.log("Update check error: \(error)")
                    if manual {
                        self.showUpdateFailureAlert(informativeText: L10n.shared.updateCheckFailedInfo)
                    }
                }
            }
        }.resume()
    }

    func isNewerVersion(_ latest: String, than current: String) -> Bool {
        guard let latestParts = parseVersionComponents(latest),
              let currentParts = parseVersionComponents(current) else {
            return false
        }
        let maxCount = max(latestParts.count, currentParts.count)
        for i in 0..<maxCount {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }

    func parseVersionComponents(_ version: String) -> [Int]? {
        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let pattern = "^[vV]?[0-9]+(\\.[0-9]+)*$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil else {
            return nil
        }

        let numericString: String
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            numericString = String(trimmed.dropFirst())
        } else {
            numericString = trimmed
        }

        let parts = numericString.split(separator: ".")
        guard !parts.isEmpty else { return nil }

        var components: [Int] = []
        for part in parts {
            guard let num = Int(part), num >= 0 else {
                return nil
            }
            components.append(num)
        }
        return components
    }

    private func showUpdateAlert(version: String, downloadUrl: String?) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.shared.updateAvailable
        let baseText = String(format: L10n.shared.updateFound, version)
        let currentText = L10n.shared.isRussian
            ? "Текущая версия: \(currentVersion)."
            : "Current version: \(currentVersion)."
        alert.informativeText = "\(baseText)\n\(currentText)"

        if downloadUrl == nil {
            alert.informativeText = "\(L10n.shared.updateNoDownloadInfo)\n\(currentText)"
            alert.addButton(withTitle: L10n.shared.ok)
            presentAlert(alert)
        } else {
            let primaryButton = alert.addButton(withTitle: L10n.shared.updateDownload)
            primaryButton.keyEquivalent = "\r"
            let secondaryButton = alert.addButton(withTitle: L10n.shared.updateLater)
            secondaryButton.keyEquivalent = "\u{1b}"

            presentAlert(alert) { [weak self] response in
                if response == .alertFirstButtonReturn,
                   let urlString = downloadUrl,
                   let url = URL(string: urlString) {
                    self?.startAutomatedUpdate(url: url, version: version, isBackgroundDownload: false)
                }
            }
        }
    }

    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.shared.updateLatest
        let currentText = L10n.shared.isRussian
            ? "Текущая версия: \(currentVersion)."
            : "Current version: \(currentVersion)."
        alert.informativeText = "\(L10n.shared.updateLatestInfo)\n\(currentText)"
        let okButton = alert.addButton(withTitle: L10n.shared.ok)
        okButton.keyEquivalent = "\r"
        presentAlert(alert)
    }

    private func showReadyToInstallAlert(dmgPath: String, version: String, isManual: Bool) {
        if !isManual && SettingsStore.shared.lastPromptedUpdateVersion == version {
            try? FileManager.default.removeItem(atPath: dmgPath)
            return
        }
        SettingsStore.shared.lastPromptedUpdateVersion = version

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.shared.updateAvailable
        let baseText = String(format: L10n.shared.updateFound, version)
        let currentText = L10n.shared.isRussian
            ? "Текущая версия: \(currentVersion)."
            : "Current version: \(currentVersion)."
        alert.informativeText = "\(baseText)\n\(currentText)"

        let primaryButton = alert.addButton(withTitle: L10n.shared.updateDownload)
        primaryButton.keyEquivalent = "\r"
        let secondaryButton = alert.addButton(withTitle: L10n.shared.updateLater)
        secondaryButton.keyEquivalent = "\u{1b}"

        presentAlert(alert) { [weak self] response in
            if response == .alertFirstButtonReturn {
                self?.performInstallation(dmgPath: dmgPath, expectedVersion: version)
            } else {
                try? FileManager.default.removeItem(atPath: dmgPath)
            }
        }
    }

    private func showUpdateFailureAlert(informativeText: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.shared.updateFailed
        let currentText = L10n.shared.isRussian
            ? "Текущая версия: \(currentVersion)."
            : "Current version: \(currentVersion)."
        alert.informativeText = "\(informativeText)\n\(currentText)"
        let okButton = alert.addButton(withTitle: L10n.shared.ok)
        okButton.keyEquivalent = "\r"
        presentAlert(alert)
    }

    private func presentAlert(
        _ alert: NSAlert,
        completion: ((NSApplication.ModalResponse) -> Void)? = nil
    ) {
        NSApp.activate(ignoringOtherApps: true)
        alert.icon = updaterAlertIcon()
        isPresentingModal = true

        let finish = { [weak self] (response: NSApplication.ModalResponse) in
            self?.isPresentingModal = false
            completion?(response)
        }

        if let window = alertParentWindow() {
            alert.beginSheetModal(for: window) { response in
                finish(response)
            }
        } else {
            let response = alert.runModal()
            finish(response)
        }
    }

    private func alertParentWindow() -> NSWindow? {
        let candidateWindows: [NSWindow?] = {
            let appDelegate = NSApp.delegate as? AppDelegate
            return [
                NSApp.keyWindow,
                appDelegate?.loadingWindow?.window,
                appDelegate?.settingsWindow?.window,
                appDelegate?.speedTestWindow?.window,
                appDelegate?.logWindow?.window,
                appDelegate?.helpWindow?.window
            ]
        }()

        for case let window? in candidateWindows {
            if window.isVisible && window.attachedSheet == nil {
                return window
            }
        }
        return nil
    }

    private func updaterAlertIcon() -> NSImage? {
        if let appIcon = DPISettingsAssets.appIcon() ?? NSApp.applicationIconImage, appIcon.isValid {
            guard let copy = appIcon.copy() as? NSImage else { return appIcon }
            copy.size = NSSize(width: 64, height: 64)
            return copy
        }
        return nil
    }

    private func startAutomatedUpdate(url: URL, version: String, isBackgroundDownload: Bool) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.startAutomatedUpdate(url: url, version: version, isBackgroundDownload: isBackgroundDownload)
            }
            return
        }

        guard !isDownloading, !isInstalling else { return }
        isDownloading = true

        let appDelegate = NSApp.delegate as? AppDelegate
        if !isBackgroundDownload {
            if appDelegate?.loadingWindow == nil {
                appDelegate?.loadingWindow = LoadingWindowController()
            }
            appDelegate?.loadingWindow?.updateStatus(L10n.shared.updateDownloading)
            appDelegate?.loadingWindow?.showWithFade()
        }

        downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            // URLSession owns localURL only for the lifetime of this callback.
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("DPIKillerUpdate-\(UUID().uuidString).dmg")
            let downloadResult: Result<URL, Error>
            do {
                if let error { throw error }
                guard let localURL,
                      let response = response as? HTTPURLResponse,
                      response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                try FileManager.default.copyItem(at: localURL, to: tempURL)
                downloadResult = .success(tempURL)
            } catch {
                downloadResult = .failure(error)
            }

            DispatchQueue.main.async {
                guard let self else {
                    try? FileManager.default.removeItem(at: tempURL)
                    return
                }
                self.isDownloading = false
                self.observation = nil
                self.downloadTask = nil
                switch downloadResult {
                case .success(let fileURL):
                    if isBackgroundDownload {
                        self.showReadyToInstallAlert(dmgPath: fileURL.path, version: version, isManual: false)
                    } else {
                        self.performInstallation(dmgPath: fileURL.path, expectedVersion: version)
                    }
                case .failure(let error):
                    AppLogger.log("Update download failed: \(error.localizedDescription)")
                    if !isBackgroundDownload {
                        appDelegate?.loadingWindow?.closeWithFade {
                            appDelegate?.loadingWindow = nil
                            self.showUpdateFailureAlert(informativeText: L10n.shared.updateDownloadFailedInfo)
                        }
                    }
                }
            }
        }

        if !isBackgroundDownload {
            observation = downloadTask?.progress.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    (NSApp.delegate as? AppDelegate)?.loadingWindow?.updateProgress(progress.fractionCompleted)
                }
            }
        }

        downloadTask?.resume()
    }

    private func performInstallation(dmgPath: String, expectedVersion: String) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.performInstallation(dmgPath: dmgPath, expectedVersion: expectedVersion)
            }
            return
        }

        guard !isInstalling else { return }
        isInstalling = true

        let appDelegate = NSApp.delegate as? AppDelegate
        if appDelegate?.loadingWindow == nil {
            appDelegate?.loadingWindow = LoadingWindowController()
            appDelegate?.loadingWindow?.showWithFade()
        }
        appDelegate?.loadingWindow?.updateStatus(L10n.shared.updateInstalling)
        appDelegate?.loadingWindow?.setProgressIndeterminate(true)

        let pid = ProcessInfo.processInfo.processIdentifier
        let appPath = targetAppPath
        let logPath = "/tmp/DPIKillerUpdate.log"
        let executableName = (Bundle.main.infoDictionary?["CFBundleExecutable"] as? String) ?? "DPIKiller"
        let bundleID = Bundle.main.bundleIdentifier ?? "com.antigravity.DPIKiller"
        let readyFlag = FileManager.default.temporaryDirectory.appendingPathComponent("dpikiller_ready_\(UUID().uuidString).flag").path
        try? FileManager.default.removeItem(atPath: readyFlag)

        let script = #"""
        set -eu
        appPath="$1"
        dmgPath="$2"
        expectedVersion="$3"
        expectedBundleID="$4"
        executableName="$5"
        callingPID="$6"
        logPath="$7"
        readyFlag="$8"

        mountPath=""
        workspaceDir=""
        stagedAppPath=""
        backupAppPath=""
        needsRollback=0
        preserveWorkspace=0

        exec >> "$logPath" 2>&1

        log() {
           printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
        }

        rollback() {
           log "Initiating rollback to previous app"
           if [ ! -d "$backupAppPath" ]; then
               log "Rollback impossible: backup missing; leaving target app untouched"
               return
           fi
           targetExecutable="$appPath/Contents/MacOS/$executableName"
            installedPIDs="$(ps -axo pid=,comm= | awk -v target="$targetExecutable" '{ pid = $1; $1 = ""; sub(/^[[:space:]]+/, ""); if ($0 == target) print pid }')"
           if [ -n "$installedPIDs" ]; then
               kill -TERM $installedPIDs 2>/dev/null || true
               sleep 0.5
               kill -9 $installedPIDs 2>/dev/null || true
           fi
           restoreTemp="$workspaceDir/restore_tmp.app"
           rm -rf "$restoreTemp"
            if ! ditto "$backupAppPath" "$restoreTemp"; then
                preserveWorkspace=1
                log "Rollback failed: ditto from backup failed; preserving backup in $backupAppPath"
                return
            fi
            rm -rf "$appPath"
            if ! mv "$restoreTemp" "$appPath"; then
                preserveWorkspace=1
                log "Rollback failed: moving restored app into place failed; preserving backup in $backupAppPath"
                return
            fi
            /usr/bin/open "$appPath"
            log "Rollback succeeded, restored previous app"
        }

        finish() {
           status=$?
           if [ "$status" -ne 0 ]; then
               if [ "$needsRollback" = "1" ]; then
                   rollback
               elif ! kill -0 "$callingPID" 2>/dev/null && [ -d "$appPath" ]; then
                   /usr/bin/open "$appPath" || true
               fi
           fi
           if [ -n "$mountPath" ] && [ -d "$mountPath" ]; then
               hdiutil detach "$mountPath" -force -quiet 2>/dev/null || true
           fi
            if [ "$preserveWorkspace" != "1" ] && [ -n "$workspaceDir" ] && [ -d "$workspaceDir" ]; then
               rm -rf "$workspaceDir"
            elif [ "$preserveWorkspace" = "1" ]; then
                log "Workspace preserved for recovery: $workspaceDir"
           fi
           rm -f "$dmgPath" "$readyFlag"
           exit "$status"
        }
        trap finish EXIT

        log "Staging update from $dmgPath for target $appPath"
        tmpBase="${TMPDIR:-/tmp}"
        workspaceDir="$(mktemp -d "$tmpBase/dpikiller_updater.XXXXXX")"
        mountPath="$workspaceDir/mount"
        stagedAppPath="$workspaceDir/$executableName.updated.app"
        backupAppPath="$workspaceDir/$executableName.previous.app"
        mkdir -p "$mountPath"

        hdiutil attach "$dmgPath" -mountpoint "$mountPath" -nobrowse -quiet

        sourceAppPath=""
        if [ -d "$mountPath/$executableName.app" ]; then
            sourceAppPath="$mountPath/$executableName.app"
        else
            for candidate in "$mountPath"/*.app; do
                if [ -d "$candidate" ]; then
                    sourceAppPath="$candidate"
                    break
                fi
            done
        fi

        if [ -z "$sourceAppPath" ] || [ ! -x "$sourceAppPath/Contents/MacOS/$executableName" ]; then
            log "Staged app is missing executable: $sourceAppPath"
            exit 1
        fi

        ditto "$sourceAppPath" "$stagedAppPath"
        xattr -rc "$stagedAppPath" || true
        codesign --verify --deep --strict "$stagedAppPath"

        stagedBundleID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$stagedAppPath/Contents/Info.plist" 2>/dev/null || true)"
        if [ -n "$expectedBundleID" ] && [ "$stagedBundleID" != "$expectedBundleID" ]; then
            log "Staged bundle ID $stagedBundleID does not match expected $expectedBundleID"
            exit 1
        fi

        stagedVersion="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$stagedAppPath/Contents/Info.plist" 2>/dev/null || true)"
        if [ -z "$stagedVersion" ] || [ "$stagedVersion" != "$expectedVersion" ]; then
            log "Staged version $stagedVersion does not match expected $expectedVersion"
            exit 1
        fi

        hdiutil detach "$mountPath" -force -quiet 2>/dev/null || true
        log "Staging and verification succeeded. Notifying caller."
        touch "$readyFlag"

        waitCount=0
        while kill -0 "$callingPID" 2>/dev/null; do
            sleep 0.1
            waitCount=$((waitCount + 1))
            if [ "$waitCount" -ge 150 ]; then
                log "Calling app did not terminate in 15s; aborting update without modifying installed app"
                exit 1
            fi
        done

        rm -rf "$backupAppPath"
        if [ -d "$appPath" ]; then
            ditto "$appPath" "$backupAppPath"
            needsRollback=1
        fi

        rm -rf "$appPath"
        ditto "$stagedAppPath" "$appPath"
        log "Installed version $stagedVersion to $appPath"

        /usr/bin/open "$appPath"
        smokePassed=0
        targetExecutable="$appPath/Contents/MacOS/$executableName"
        for _ in {1..30}; do
           sleep 0.5
            matchingPID="$(ps -axo pid=,comm= | awk -v target="$targetExecutable" '{ pid = $1; $1 = ""; sub(/^[[:space:]]+/, ""); if ($0 == target) { print pid; exit } }')"
           if [ -n "$matchingPID" ]; then
               sleep 2
                matchingPID2="$(ps -axo pid=,comm= | awk -v target="$targetExecutable" '{ pid = $1; $1 = ""; sub(/^[[:space:]]+/, ""); if ($0 == target) { print pid; exit } }')"
               if [ -n "$matchingPID2" ]; then
                   smokePassed=1
                   break
               fi
           fi
        done

        if [ "$smokePassed" != "1" ]; then
            log "Smoke check failed for $appPath"
            exit 1
        fi

        needsRollback=0
        log "Update install and smoke check succeeded."
        """#

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [
                "-c",
                script,
                "updater-installer",
                appPath,
                dmgPath,
                expectedVersion,
                bundleID,
                executableName,
                String(pid),
                logPath,
                readyFlag
            ]

            do {
                try process.run()

                // Wait up to 20 seconds for staging and verification to succeed before terminating app
                let startTime = Date()
                while !FileManager.default.fileExists(atPath: readyFlag) && process.isRunning && Date().timeIntervalSince(startTime) < 20.0 {
                    Thread.sleep(forTimeInterval: 0.1)
                }

                if FileManager.default.fileExists(atPath: readyFlag) {
                    try? FileManager.default.removeItem(atPath: readyFlag)
                    DispatchQueue.main.async {
                        NSApp.terminate(nil)
                    }
                } else {
                    if process.isRunning {
                        process.terminate()
                    }
                    try? FileManager.default.removeItem(atPath: readyFlag)
                    AppLogger.log("Update staging/verification failed or timed out; app remains open.")
                    DispatchQueue.main.async {
                        self.isInstalling = false
                        appDelegate?.loadingWindow?.closeWithFade {
                            appDelegate?.loadingWindow = nil
                            self.showUpdateFailureAlert(informativeText: L10n.shared.updateInstallFailedInfo)
                        }
                    }
                }
            } catch {
                AppLogger.log("Failed to launch detached install script: \(error)")
                DispatchQueue.main.async {
                    self.isInstalling = false
                    appDelegate?.loadingWindow?.closeWithFade {
                        appDelegate?.loadingWindow = nil
                        self.showUpdateFailureAlert(informativeText: L10n.shared.updateInstallFailedInfo)
                    }
                }
            }
        }
    }
}
