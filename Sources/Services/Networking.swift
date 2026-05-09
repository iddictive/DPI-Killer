import Cocoa
import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private var lastPathStatus: NWPath.Status?
    private var pendingRestorationWorkItem: DispatchWorkItem?
    private var hasStarted = false
    private let restorationStabilizationDelay: TimeInterval = 2.0
    var onConnectivityLost: (() -> Void)?
    var onConnectivityRestored: (() -> Void)?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let status = path.status
            let previousStatus = self.lastPathStatus

            guard status != previousStatus else { return }

            AppLogger.log("[NetworkMonitor] Connection status: \(status)")
            if previousStatus != .satisfied && status == .satisfied {
                AppLogger.log("[NetworkMonitor] Connectivity restored. Notifying...")
                self.pendingRestorationWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self, self.lastPathStatus == .satisfied else { return }
                    self.onConnectivityRestored?()
                }
                self.pendingRestorationWorkItem = workItem
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + self.restorationStabilizationDelay,
                    execute: workItem
                )
            } else {
                if previousStatus == .satisfied && status != .satisfied {
                    AppLogger.log("[NetworkMonitor] Connectivity lost. Notifying...")
                    self.onConnectivityLost?()
                }
                self.pendingRestorationWorkItem?.cancel()
                self.pendingRestorationWorkItem = nil
            }
            self.lastPathStatus = status
        }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        monitor.start(queue: queue)
    }

    func stop() {
        pendingRestorationWorkItem?.cancel()
        pendingRestorationWorkItem = nil
        monitor.cancel()
        hasStarted = false
    }
}

final class SpeedTestManager: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    static let shared = SpeedTestManager()

    private var session: URLSession?
    private var uploadSession: URLSession?
    private var downloadTask: URLSessionDownloadTask?
    private var uploadTask: URLSessionUploadTask?
    private let delegateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "SpeedTestQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private var startTime: Date?
    var onUpdate: ((Double, Double, Double) -> Void)?
    var onFinished: (() -> Void)?
    var onError: ((String) -> Void)?

    private var pingValue: Double = 0
    private var downloadValue: Double = 0
    private var uploadValue: Double = 0
    private var lastNotifyTime: Date = .distantPast
    private let notifyThrottle: TimeInterval = 0.3

    func startTest() {
        reset()
        measurePing()
    }

    func stopTest() {
        downloadTask?.cancel()
        uploadTask?.cancel()
        session?.invalidateAndCancel()
        uploadSession?.invalidateAndCancel()
        session = nil
        uploadSession = nil
        downloadTask = nil
        uploadTask = nil
        onFinished?()
    }

    func forceNotify() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onUpdate?(self.pingValue, self.downloadValue, self.uploadValue)
        }
    }

    private func reset() {
        pingValue = 0
        downloadValue = 0
        uploadValue = 0
        lastNotifyTime = .distantPast
    }

    private func measurePing() {
        let url = URL(string: "https://speed.cloudflare.com/cdn-cgi/trace")!
        let start = Date()
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { [weak self] _, _, error in
            if let error {
                self?.onError?(error.localizedDescription)
                return
            }
            self?.pingValue = Date().timeIntervalSince(start) * 1000
            self?.notify()
            self?.startDownload()
        }.resume()
    }

    private func startDownload() {
        let url = URL(string: "https://speed.cloudflare.com/__down?bytes=50000000")!
        let config = URLSessionConfiguration.ephemeral
        if DPIKillerManager.shared.isRunning {
            config.connectionProxyDictionary = SettingsStore.shared.resolvedEngine.sessionProxyDictionary(port: DPIKillerManager.shared.proxyPort)
        }
        session = URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
        startTime = Date()
        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }

    private func startUpload() {
        let url = URL(string: "https://speed.cloudflare.com/__up")!
        let data = Data(count: 10_000_000)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let config = URLSessionConfiguration.ephemeral
        if DPIKillerManager.shared.isRunning {
            config.connectionProxyDictionary = SettingsStore.shared.resolvedEngine.sessionProxyDictionary(port: DPIKillerManager.shared.proxyPort)
        }

        uploadSession?.invalidateAndCancel()
        uploadSession = URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
        startTime = Date()
        uploadTask = uploadSession?.uploadTask(with: request, from: data)
        uploadTask?.resume()
    }

    private func notify() {
        let now = Date()
        if now.timeIntervalSince(lastNotifyTime) >= notifyThrottle {
            lastNotifyTime = now
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.onUpdate?(self.pingValue, self.downloadValue, self.uploadValue)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let start = startTime else { return }
        let duration = Date().timeIntervalSince(start)
        if duration > 0 {
            downloadValue = (Double(totalBytesWritten) * 8) / (duration * 1_000_000)
            notify()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        forceNotify()
        startUpload()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let start = startTime else { return }
        let duration = Date().timeIntervalSince(start)
        if duration > 0 {
            uploadValue = (Double(totalBytesSent) * 8) / (duration * 1_000_000)
            notify()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }
            onError?(error.localizedDescription)
        } else if task == uploadTask {
            forceNotify()
            uploadSession?.finishTasksAndInvalidate()
            uploadSession = nil
            uploadTask = nil
            onFinished?()
        } else if task == downloadTask {
            self.session?.finishTasksAndInvalidate()
            self.session = nil
            self.downloadTask = nil
        }
    }
}

final class DiagnosticsManager: NSObject {
    static let shared = DiagnosticsManager()

    func checkBypass(completion: @escaping (Bool, String?) -> Void) {
        guard DPIKillerManager.shared.isRunning else {
            completion(false, L10n.shared.diagNoProxy)
            return
        }

        let url = URL(string: "https://www.google.com")!
        let config = URLSessionConfiguration.ephemeral

        config.connectionProxyDictionary = SettingsStore.shared.resolvedEngine.sessionProxyDictionary(port: DPIKillerManager.shared.proxyPort)
        config.timeoutIntervalForRequest = 5.0

        let session = URLSession(configuration: config)
        session.dataTask(with: url) { _, response, error in
            defer { session.finishTasksAndInvalidate() }
            if let error {
                completion(false, error.localizedDescription)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(true, nil)
                } else {
                    completion(false, "Status code: \(httpResponse.statusCode)")
                }
            } else {
                completion(false, "Unknown response")
            }
        }.resume()
    }
}
