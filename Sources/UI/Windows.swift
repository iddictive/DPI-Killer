import Cocoa
import Foundation
import SwiftUI
import WebKit

struct ArgumentOption {
    let flag: String
    let description: String
}

final class FixedSizeWindow: NSWindow {
    var fixedFrameSize: NSSize?

    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        super.setFrame(clampedFrame(frameRect), display: flag)
    }

    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        super.setFrame(clampedFrame(frameRect), display: displayFlag, animate: animateFlag)
    }

    private func clampedFrame(_ frameRect: NSRect) -> NSRect {
        guard let fixedFrameSize else { return frameRect }
        return NSRect(origin: frameRect.origin, size: fixedFrameSize)
    }
}

final class SettingsWindowController: NSWindowController {
    private static let defaultContentSize = NSSize(width: 780, height: 580)

    private let fixedContentSize = SettingsWindowController.defaultContentSize
    private var hostingController: NSHostingController<SettingsView>?
    private let model = SettingsViewModel()

    convenience init() {
        let window = FixedSizeWindow(
            contentRect: NSRect(origin: .zero, size: SettingsWindowController.defaultContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L10n.shared.settingsTitle
        AppTheme.styleSettingsWindow(window, minSize: SettingsWindowController.defaultContentSize)
        window.fixedFrameSize = window.frameRect(
            forContentRect: NSRect(origin: .zero, size: SettingsWindowController.defaultContentSize)
        ).size
        self.init(window: window)
        enforceFixedWindowSize(center: true)
        setupSwiftUI()
    }

    override func showWindow(_ sender: Any?) {
        let shouldCenter = window?.isVisible != true
        model.refreshRuntimeStatus()
        super.showWindow(sender)
        enforceFixedWindowSize(center: shouldCenter)
        DispatchQueue.main.async { [weak self] in
            self?.enforceFixedWindowSize(center: false)
            self?.model.refreshRuntimeStatus()
        }
        window?.level = .normal
    }

    private func enforceFixedWindowSize(center: Bool) {
        guard let window else { return }
        let frameSize = (window as? FixedSizeWindow)?.fixedFrameSize
            ?? window.frameRect(forContentRect: NSRect(origin: .zero, size: fixedContentSize)).size
        window.styleMask.remove(.resizable)
        window.minSize = fixedContentSize
        window.maxSize = fixedContentSize
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let currentOrigin = center ? NSPoint(x: window.frame.origin.x, y: window.frame.origin.y) : window.frame.origin
        window.setFrame(NSRect(origin: currentOrigin, size: frameSize), display: false)
        window.setContentSize(fixedContentSize)
        if center {
            window.center()
        }
    }

    private func setupSwiftUI() {
        let rootView = SettingsView(viewModel: model, onCancel: { [weak self] in
            self?.window?.close()
        }, onSave: { [weak self] in
            guard let self else { return }
            if DPIKillerManager.shared.isRunning {
                (NSApp.delegate as? AppDelegate)?.restartRuntime()
            }
            self.window?.close()
        })
        let hostingController = NSHostingController(rootView: rootView)
        self.hostingController = hostingController
        window?.contentViewController = hostingController
    }
}

final class SpeedTestWindowController: NSWindowController, NSWindowDelegate {
    private var pingCard: MetricCardView!
    private var downloadCard: MetricCardView!
    private var uploadCard: MetricCardView!
    private var progressIndicator: NSProgressIndicator!
    private var startButton: NSButton!
    private var stageLabel: NSTextField!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L10n.shared.speedTest
        AppTheme.styleWindow(window, minSize: NSSize(width: 620, height: 360))
        self.init(window: window)
        window.delegate = self
        setupUI()
    }

    private func setupUI() {
        let background = AppTheme.makeWindowBackground()
        window?.contentView = background

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .leading
        background.addSubview(contentStack)
        contentStack.fill(parent: background, padding: 20)

        stageLabel = AppTheme.makeSecondaryText(
            L10n.shared.isRussian
                ? "Cloudflare probe через текущую сетевую цепочку приложения."
                : "Cloudflare probe routed through the app's current network chain."
        )
        contentStack.addArrangedSubview(stageLabel)

        pingCard = metricContainer(title: L10n.shared.ping, unit: L10n.shared.ms)
        downloadCard = metricContainer(title: L10n.shared.download, unit: L10n.shared.mbps)
        uploadCard = metricContainer(title: L10n.shared.upload, unit: L10n.shared.mbps)

        let metrics = NSGridView(views: [[pingCard!, downloadCard!, uploadCard!]])
        metrics.rowSpacing = 0
        metrics.columnSpacing = 16
        metrics.translatesAutoresizingMaskIntoConstraints = false

        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = true
        progressIndicator.startAnimation(nil)
        progressIndicator.isHidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        startButton = NSButton(title: L10n.shared.startTest, target: self, action: #selector(startClicked))
        AppTheme.stylePrimaryButton(startButton)

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.spacing = 0
        actions.alignment = .centerY
        actions.addArrangedSubview(NSView())
        actions.addArrangedSubview(startButton)

        contentStack.addArrangedSubview(metrics)
        contentStack.addArrangedSubview(progressIndicator)
        contentStack.addArrangedSubview(actions)

        NSLayoutConstraint.activate([
            metrics.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            progressIndicator.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            actions.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 220),
            startButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func metricContainer(title: String, unit: String) -> MetricCardView {
        let card = MetricCardView(title: title, unit: unit)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 150).isActive = true
        return card
    }

    @objc private func startClicked() {
        if startButton.title == L10n.shared.startTest {
            startButton.title = L10n.shared.stopTest
            progressIndicator.isHidden = false
            progressIndicator.startAnimation(nil)
            stageLabel.stringValue = L10n.shared.testingPing

            SpeedTestManager.shared.onUpdate = { [weak self] ping, down, up in
                DispatchQueue.main.async {
                    self?.pingCard.update(value: "\(Int(ping))")
                    self?.downloadCard.update(value: String(format: "%.2f", down))
                    self?.uploadCard.update(value: String(format: "%.2f", up))
                    if up > 0 {
                        self?.stageLabel.stringValue = L10n.shared.testingUpload
                    } else if down > 0 {
                        self?.stageLabel.stringValue = L10n.shared.testingDownload
                    }
                }
            }

            SpeedTestManager.shared.onFinished = { [weak self] in
                DispatchQueue.main.async {
                    self?.startButton.title = L10n.shared.startTest
                    self?.progressIndicator.stopAnimation(nil)
                    self?.progressIndicator.isHidden = true
                    self?.stageLabel.stringValue = L10n.shared.isRussian ? "Тест завершён." : "Test complete."
                }
            }

            SpeedTestManager.shared.onError = { [weak self] error in
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Error"
                    alert.informativeText = error
                    alert.runModal()
                    self?.startButton.title = L10n.shared.startTest
                    self?.progressIndicator.stopAnimation(nil)
                    self?.progressIndicator.isHidden = true
                    self?.stageLabel.stringValue = error
                }
            }

            SpeedTestManager.shared.startTest()
        } else {
            SpeedTestManager.shared.stopTest()
        }
    }

    func windowWillClose(_ notification: Notification) {
        SpeedTestManager.shared.onUpdate = nil
        SpeedTestManager.shared.onFinished = nil
        SpeedTestManager.shared.onError = nil
        SpeedTestManager.shared.stopTest()
        (NSApp.delegate as? AppDelegate)?.speedTestWindow = nil
    }
}

final class LogWindowController: NSWindowController, NSWindowDelegate {
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var liveBadge: NSView!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 460),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L10n.shared.logsTitle
        AppTheme.styleWindow(window, minSize: NSSize(width: 620, height: 380))
        self.init(window: window)
        window.delegate = self
        setupUI()
    }

    override func showWindow(_ sender: Any?) {
        beginObservingLogs()
        super.showWindow(sender)
        updateLogs()
    }

    private func setupUI() {
        let background = AppTheme.makeWindowBackground()
        window?.contentView = background

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.spacing = 14
        contentStack.alignment = .leading
        background.addSubview(contentStack)
        contentStack.fill(parent: background, padding: 20)

        let subtitle = AppTheme.makeSecondaryText(
            L10n.shared.isRussian
                ? "Живой circular buffer без спама в память."
                : "Live circular buffer without runaway memory growth."
        )
        liveBadge = AppTheme.makeStatusBadge(text: "STREAMING", color: AppTheme.accentSoft)
        contentStack.addArrangedSubview(subtitle)
        contentStack.addArrangedSubview(liveBadge)

        scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        textView = NSTextView()
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.drawsBackground = false
        textView.textColor = AppTheme.textPrimary
        textView.textContainerInset = NSSize(width: 8, height: 10)
        scrollView.documentView = textView
        contentStack.addArrangedSubview(scrollView)
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.spacing = 12
        actions.alignment = .centerY

        let clearBtn = NSButton(title: L10n.shared.clearLogs, target: self, action: #selector(clearLogs))
        AppTheme.styleSecondaryButton(clearBtn)
        let copyBtn = NSButton(title: L10n.shared.copyLogs, target: self, action: #selector(copyLogs))
        AppTheme.stylePrimaryButton(copyBtn)
        actions.addArrangedSubview(NSView())
        actions.addArrangedSubview(clearBtn)
        actions.addArrangedSubview(copyBtn)
        contentStack.addArrangedSubview(actions)

        NSLayoutConstraint.activate([
            scrollView.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            actions.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
    }

    private func beginObservingLogs() {
        LogStore.shared.setProcessCaptureEnabled(true)
        LogStore.shared.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.updateLogs()
            }
        }
    }

    private func endObservingLogs() {
        LogStore.shared.setProcessCaptureEnabled(false)
        LogStore.shared.onUpdate = nil
    }

    private func updateLogs() {
        guard window?.isVisible == true else { return }
        let text = LogStore.shared.getAllLogs()
        let wasAtBottom = scrollView.verticalScroller?.floatValue ?? 1.0 > 0.95
        textView.string = text
        if wasAtBottom {
            textView.scrollToEndOfDocument(nil)
        }
    }

    @objc private func clearLogs() {
        LogStore.shared.clear()
    }

    @objc private func copyLogs() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(LogStore.shared.getAllLogs(), forType: .string)
    }

    func windowWillClose(_ notification: Notification) {
        endObservingLogs()
        textView.string = ""
        (NSApp.delegate as? AppDelegate)?.logWindow = nil
    }
}

final class HelpWindowController: NSWindowController {
    var webView: WKWebView!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 620),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L10n.shared.helpTitle
        AppTheme.styleWindow(window, minSize: NSSize(width: 660, height: 500))
        self.init(window: window)
        setupUI()
        loadReadme()
    }

    func setupUI() {
        let background = AppTheme.makeWindowBackground()
        window?.contentView = background

        webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(webView)
        webView.fill(parent: background, padding: 16)
    }

    func loadReadme() {
        guard let path = Bundle.main.path(forResource: "README", ofType: "md"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            webView.loadHTMLString(
                "<html><body>\(L10n.shared.isRussian ? "Инструкция недоступна." : "Manual not available.")</body></html>",
                baseURL: nil
            )
            return
        }

        let html = markdownToHTML(content)
        let styledHTML = """
        <html>
        <head>
        <style>
        :root { color-scheme: light dark; }
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; font-size: 15px; line-height: 1.65; padding: 24px 28px; color: #1d1d1f; background: #ffffff; }
        a { color: #0a84ff; }
        h1, h2, h3 { color: #1d1d1f; }
        h1 { font-size: 28px; border-bottom: 1px solid #d2d2d7; padding-bottom: 10px; }
        h2 { margin-top: 30px; }
        pre { background: #f5f5f7; padding: 14px; border-radius: 10px; overflow-x: auto; border: 1px solid #d2d2d7; }
        code { background: #f5f5f7; padding: 2px 5px; border-radius: 4px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
        img { max-width: 100%; border-radius: 8px; border: 1px solid #d2d2d7; }
        li { margin: 6px 0; }
        hr { border: none; height: 1px; background: #d2d2d7; }
        @media (prefers-color-scheme: dark) {
        body { color: #f5f5f7; background: #1c1c1e; }
        a { color: #4ea1ff; }
        h1, h2, h3 { color: #ffffff; }
        h1 { border-bottom-color: #3a3a3c; }
        pre, code { background: #2c2c2e; border-color: #3a3a3c; }
        img { border-color: #3a3a3c; }
        hr { background: #3a3a3c; }
        }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: Bundle.main.resourceURL)
    }

    private func markdownToHTML(_ markdown: String) -> String {
        var result = ""
        let lines = markdown.components(separatedBy: .newlines)
        var inCodeBlock = false
        var codeContent = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    result += "<pre><code>\(codeContent.trimmingCharacters(in: .whitespacesAndNewlines))</code></pre>\n"
                    codeContent = ""
                    inCodeBlock = false
                } else {
                    inCodeBlock = true
                }
                continue
            }
            if inCodeBlock {
                codeContent += line
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;") + "\n"
                continue
            }
            if trimmed.isEmpty {
                result += "<br>\n"
                continue
            }
            if trimmed.hasPrefix("<") {
                result += line + "\n"
                continue
            }
            if line.hasPrefix("# ") {
                result += "<h1>\(processInline(String(line.dropFirst(2))))</h1>\n"
            } else if line.hasPrefix("## ") {
                result += "<h2>\(processInline(String(line.dropFirst(3))))</h2>\n"
            } else if line.hasPrefix("### ") {
                result += "<h3>\(processInline(String(line.dropFirst(4))))</h3>\n"
            } else if trimmed == "---" {
                result += "<hr>\n"
            } else if trimmed.hasPrefix("- ") {
                result += "<li>\(processInline(String(trimmed.dropFirst(2))))</li>\n"
            } else {
                result += "<p>\(processInline(line))</p>\n"
            }
        }
        return result
    }

    private func processInline(_ text: String) -> String {
        var processed = text
        processed = processed.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "<b>$1</b>", options: .regularExpression)
        processed = processed.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)
        processed = processed.replacingOccurrences(of: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        return processed
    }
}

final class LoadingWindowController: NSWindowController {
    private var sublabel: NSTextField?
    private var progressView: LoaderProgressView?
    private var cancelButton: NSButton?
    var cancelHandler: (() -> Void)?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 196),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        self.init(window: window)
        setupUI()
    }

    func setupUI() {
        let background = LoaderBackgroundView()
        window?.contentView = background

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .centerX
        background.addSubview(contentStack)
        contentStack.fill(parent: background, padding: 24)

        let iconContainer = NSView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.widthAnchor.constraint(equalToConstant: 72).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: 72).isActive = true
        if let icon = DPISettingsAssets.appIcon() {
            let imageView = NSImageView(image: icon)
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 56),
                imageView.heightAnchor.constraint(equalToConstant: 56)
            ])
        }

        let title = NSTextField(labelWithString: "DPI Killer")
        title.font = .systemFont(ofSize: 21, weight: .bold)
        title.textColor = AppTheme.textPrimary
        title.alignment = .center

        let subtitle = NSTextField(labelWithString: L10n.shared.preparingBypass)
        subtitle.font = .systemFont(ofSize: 13, weight: .regular)
        subtitle.textColor = AppTheme.textSecondary
        subtitle.alignment = .center
        sublabel = subtitle

        progressView = LoaderProgressView()
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        progressView?.setIndeterminate(true)

        cancelButton = NSButton(title: L10n.shared.cancel, target: self, action: #selector(cancelClicked))
        if let cancelButton {
            AppTheme.styleSecondaryButton(cancelButton)
            cancelButton.isHidden = true
        }

        contentStack.addArrangedSubview(iconContainer)
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(subtitle)
        if let progressView {
            contentStack.addArrangedSubview(progressView)
            NSLayoutConstraint.activate([
                progressView.widthAnchor.constraint(equalToConstant: 220),
                progressView.heightAnchor.constraint(equalToConstant: 10)
            ])
        }
        if let cancelButton {
            contentStack.addArrangedSubview(cancelButton)
            cancelButton.widthAnchor.constraint(equalToConstant: 110).isActive = true
        }
    }

    func updateStatus(_ text: String, showCancel: Bool = false) {
        DispatchQueue.main.async {
            self.sublabel?.stringValue = text
            self.cancelButton?.isHidden = !showCancel
        }
    }

    func updateProgress(_ value: Double) {
        DispatchQueue.main.async {
            self.progressView?.setIndeterminate(false)
            self.progressView?.setProgress(value)
        }
    }

    func setProgressIndeterminate(_ value: Bool) {
        DispatchQueue.main.async {
            self.progressView?.setIndeterminate(value)
        }
    }

    @objc func cancelClicked() {
        cancelHandler?()
    }

    func showWithFade() {
        window?.alphaValue = 0
        window?.center()
        showWindow(nil)
        NSAnimationContext.runAnimationGroup {
            $0.duration = 0.22
            window?.animator().alphaValue = 1
        }
    }

    func closeWithFade(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({
            $0.duration = 0.18
            window?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
            self?.window?.alphaValue = 1
            completion()
        })
    }
}

final class LoaderBackgroundView: NSView {
    private let gradientLayer = CAGradientLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.cornerRadius = 18
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        gradientLayer.colors = [
            NSColor.windowBackgroundColor.blended(withFraction: 0.32, of: NSColor.systemOrange)?.cgColor ?? NSColor.windowBackgroundColor.cgColor,
            NSColor.windowBackgroundColor.blended(withFraction: 0.18, of: NSColor.systemYellow)?.cgColor ?? NSColor.windowBackgroundColor.cgColor,
            NSColor.windowBackgroundColor.blended(withFraction: 0.06, of: NSColor.systemBrown)?.cgColor ?? NSColor.windowBackgroundColor.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)

        layer?.addSublayer(gradientLayer)
    }

    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
    }
}

final class LoaderProgressView: NSView {
    private let trackLayer = CALayer()
    private let fillLayer = CAGradientLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.addSublayer(trackLayer)
        layer?.addSublayer(fillLayer)

        trackLayer.backgroundColor = NSColor.white.withAlphaComponent(0.14).cgColor
        fillLayer.colors = [
            NSColor.white.withAlphaComponent(0.95).cgColor,
            NSColor.systemYellow.withAlphaComponent(0.95).cgColor
        ]
        fillLayer.startPoint = CGPoint(x: 0, y: 0.5)
        fillLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }

    override func layout() {
        super.layout()
        let radius = bounds.height / 2
        layer?.cornerRadius = radius
        trackLayer.frame = bounds
        trackLayer.cornerRadius = radius
        fillLayer.cornerRadius = radius
        if fillLayer.animation(forKey: "loaderSlide") == nil {
            fillLayer.frame = bounds.insetBy(dx: bounds.width * 0.34, dy: 0)
        }
    }

    func setProgress(_ value: Double) {
        fillLayer.removeAnimation(forKey: "loaderSlide")
        let clamped = max(0, min(1, value))
        let width = max(bounds.width * CGFloat(clamped), bounds.height)
        fillLayer.frame = NSRect(x: 0, y: 0, width: width, height: bounds.height)
    }

    func setIndeterminate(_ isIndeterminate: Bool) {
        if isIndeterminate {
            let segmentWidth = max(bounds.width * 0.34, bounds.height * 2.4)
            fillLayer.frame = NSRect(x: -segmentWidth, y: 0, width: segmentWidth, height: bounds.height)
            let animation = CABasicAnimation(keyPath: "position.x")
            animation.fromValue = -segmentWidth / 2
            animation.toValue = bounds.width + segmentWidth / 2
            animation.duration = 0.9
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            fillLayer.add(animation, forKey: "loaderSlide")
        } else {
            fillLayer.removeAnimation(forKey: "loaderSlide")
        }
    }
}
