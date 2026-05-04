import Foundation

final class LogStore {
    static let shared = LogStore()

    private let maxLines = 300
    private let maxTotalBytes = 256 * 1024
    private let maxEntryBytes = 4 * 1024
    private(set) var lines: [String] = []
    var onUpdate: (() -> Void)?
    private var totalBytes = 0
    private var captureProcessLogs = false
    private let queue = DispatchQueue(label: "com.iddictive.logstore", qos: .utility)
    private var lastUpdate: Date = .distantPast
    private let throttleInterval: TimeInterval = 0.2
    private var updatePending = false

    func append(_ text: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let newLines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard !newLines.isEmpty else { return }

            let timestamp = ISO8601DateFormatter.string(
                from: Date(),
                timeZone: .current,
                formatOptions: [.withTime, .withColonSeparatorInTime]
            )

            for line in newLines {
                let entry = "[\(timestamp)] \(self.truncate(line, limit: self.maxEntryBytes))"
                self.lines.append(entry)
                self.totalBytes += entry.lengthOfBytes(using: .utf8)
            }

            self.trimIfNeeded()
            self.scheduleUpdate()
        }
    }

    func clear() {
        queue.async {
            self.lines.removeAll()
            self.totalBytes = 0
            DispatchQueue.main.async {
                self.onUpdate?()
            }
        }
    }

    func getAllLogs() -> String {
        queue.sync {
            lines.joined(separator: "\n")
        }
    }

    func setProcessCaptureEnabled(_ enabled: Bool) {
        queue.async {
            self.captureProcessLogs = enabled
        }
    }

    func shouldCaptureProcessLogs() -> Bool {
        queue.sync {
            captureProcessLogs
        }
    }

    private func truncate(_ text: String, limit: Int) -> String {
        guard text.lengthOfBytes(using: .utf8) > limit else { return text }
        let suffix = " …[truncated]"
        let budget = max(0, limit - suffix.lengthOfBytes(using: .utf8))
        var result = ""
        var used = 0
        for scalar in text.unicodeScalars {
            let scalarBytes = String(scalar).lengthOfBytes(using: .utf8)
            if used + scalarBytes > budget {
                break
            }
            result.unicodeScalars.append(scalar)
            used += scalarBytes
        }
        return result + suffix
    }

    private func trimIfNeeded() {
        while lines.count > maxLines {
            removeFirstLine()
        }
        while totalBytes > maxTotalBytes, !lines.isEmpty {
            removeFirstLine()
        }
    }

    private func removeFirstLine() {
        guard !lines.isEmpty else { return }
        let removed = lines.removeFirst()
        totalBytes -= removed.lengthOfBytes(using: .utf8)
    }

    private func scheduleUpdate() {
        dispatchPrecondition(condition: .onQueue(queue))
        guard !updatePending else { return }

        let now = Date()
        let timeSinceLast = now.timeIntervalSince(lastUpdate)

        if timeSinceLast >= throttleInterval {
            lastUpdate = now
            DispatchQueue.main.async { [weak self] in
                self?.onUpdate?()
                self?.queue.async {
                    self?.updatePending = false
                }
            }
            updatePending = true
        } else {
            updatePending = true
            let delay = throttleInterval - timeSinceLast
            queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.lastUpdate = Date()
                DispatchQueue.main.async { [weak self] in
                    self?.onUpdate?()
                    self?.queue.async {
                        self?.updatePending = false
                    }
                }
            }
        }
    }
}

enum AppLogger {
    static func log(_ message: String) {
        LogStore.shared.append(message)
        NSLog("%@", message)
    }
}
