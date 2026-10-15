import Foundation

/// One stream per backend process; repeated transport failures share a ten-second window.
final class BackendLogStream {
    private let engine: BypassEngine
    private let queue = DispatchQueue(label: "com.iddictive.backend-log", qos: .utility)
    private var buffer = Data()
    private var timeoutCount = 0
    private var latestTimeout = ""
    private var window = 0

    init(engine: BypassEngine) {
        self.engine = engine
    }

    func append(_ data: Data, captureVerbose: Bool) {
        queue.async {
            self.buffer.append(data)
            while let newline = self.buffer.firstIndex(of: 10) {
                let line = String(decoding: self.buffer.prefix(upTo: newline), as: UTF8.self)
                self.buffer.removeSubrange(...newline)
                self.record(line, captureVerbose: captureVerbose)
            }
            if self.buffer.count > 8 * 1024 {
                self.record(String(decoding: self.buffer, as: UTF8.self), captureVerbose: captureVerbose)
                self.buffer.removeAll(keepingCapacity: true)
            }
        }
    }

    func finish() {
        queue.async {
            if !self.buffer.isEmpty {
                self.record(String(decoding: self.buffer, as: UTF8.self), captureVerbose: true)
                self.buffer.removeAll()
            }
            self.flushTimeouts()
        }
    }

    private func record(_ line: String, captureVerbose: Bool) {
        guard !line.isEmpty else { return }
        guard captureVerbose || line.range(of: "\\b(ERR|ERROR|FATAL|PANIC)\\b|\\berr=", options: [.regularExpression, .caseInsensitive]) != nil else { return }
        guard engine == .spoofdpi,
              line.hasPrefix("WRN "),
              line.contains("[srv] conn_init; error handling request;"),
              line.contains("dial tcp "), line.hasSuffix("i/o timeout\"") else {
            LogStore.shared.append(line)
            return
        }
        timeoutCount += 1
        latestTimeout = line
        guard timeoutCount == 1 else { return }
        LogStore.shared.append(line)
        window += 1
        let currentWindow = window
        queue.asyncAfter(deadline: .now() + 10) {
            guard self.window == currentWindow else { return }
            self.flushTimeouts()
        }
    }

    private func flushTimeouts() {
        if timeoutCount > 1 {
            LogStore.shared.append("[\(engine.rawValue)] \(timeoutCount - 1) further requests failed with the same outbound TCP timeout. Latest: \(latestTimeout)")
        }
        timeoutCount = 0
        latestTimeout = ""
        window += 1
    }
}
