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

final class SpeedTestViewModel: ObservableObject {
    @Published var ping = "--"
    @Published var download = "--"
    @Published var upload = "--"
    @Published var status = L10n.shared.speedTestReady
    @Published var isRunning = false
    @Published var errorMessage: String?

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        isRunning = true
        status = L10n.shared.testingPing

        SpeedTestManager.shared.onUpdate = { [weak self] ping, down, up in
            DispatchQueue.main.async {
                self?.ping = "\(Int(ping))"
                self?.download = String(format: "%.2f", down)
                self?.upload = String(format: "%.2f", up)
                if up > 0 {
                    self?.status = L10n.shared.testingUpload
                } else if down > 0 {
                    self?.status = L10n.shared.testingDownload
                }
            }
        }

        SpeedTestManager.shared.onFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.status = L10n.shared.speedTestComplete
            }
        }

        SpeedTestManager.shared.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.status = L10n.shared.speedTestFailed
                self?.errorMessage = error
            }
        }

        SpeedTestManager.shared.startTest()
    }

    func stop() {
        SpeedTestManager.shared.stopTest()
        isRunning = false
        status = L10n.shared.speedTestReady
    }

    func cleanup() {
        SpeedTestManager.shared.onUpdate = nil
        SpeedTestManager.shared.onFinished = nil
        SpeedTestManager.shared.onError = nil
        SpeedTestManager.shared.stopTest()
    }
}

struct SpeedTestView: View {
    @ObservedObject var model: SpeedTestViewModel

    private var showingError: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "speedometer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DPISettingsTokens.accent)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 8).fill(DPISettingsTokens.accent.opacity(0.14)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.shared.speedTest)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DPISettingsTokens.primaryText)
                    Text(model.status)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                SpeedMetricTile(title: L10n.shared.ping, value: model.ping, unit: L10n.shared.ms)
                SpeedMetricTile(title: L10n.shared.download, value: model.download, unit: L10n.shared.mbps)
                SpeedMetricTile(title: L10n.shared.upload, value: model.upload, unit: L10n.shared.mbps)
            }

            Group {
                if model.isRunning {
                    ProgressView()
                        .progressViewStyle(.linear)
                } else {
                    Capsule()
                        .fill(DPISettingsTokens.separator)
                }
            }
            .controlSize(.small)
            .opacity(model.isRunning ? 1 : 0)
            .frame(height: 8)

            HStack {
                Spacer(minLength: 0)
                Button(model.isRunning ? L10n.shared.stopTest : L10n.shared.startTest) {
                    model.toggle()
                }
                .keyboardShortcut(.defaultAction)
                .frame(width: 150)
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
        .frame(minWidth: 640, idealWidth: 640, maxWidth: .infinity, minHeight: 320, idealHeight: 320, maxHeight: .infinity)
        .background(DPISettingsTokens.background)
        .alert(L10n.shared.speedTestFailed, isPresented: showingError) {
            Button(L10n.shared.ok) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

struct SpeedMetricTile: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(DPISettingsTokens.badgeFont)
                .foregroundStyle(DPISettingsTokens.secondaryText)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(DPISettingsTokens.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(unit)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 8).fill(DPISettingsTokens.surface))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DPISettingsTokens.border, lineWidth: 1))
    }
}

final class SpeedTestWindowController: NSWindowController, NSWindowDelegate {
    private let model = SpeedTestViewModel()
    private var hostingController: NSHostingController<SpeedTestView>?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L10n.shared.speedTest
        AppTheme.styleUtilityWindow(window, minSize: NSSize(width: 640, height: 320))
        self.init(window: window)
        window.delegate = self
        setupUI()
    }

    private func setupUI() {
        let hostingController = NSHostingController(rootView: SpeedTestView(model: model))
        self.hostingController = hostingController
        window?.contentViewController = hostingController
    }

    func windowWillClose(_ notification: Notification) {
        model.cleanup()
        (NSApp.delegate as? AppDelegate)?.speedTestWindow = nil
    }
}

final class LogsViewModel: ObservableObject {
    @Published var text = ""

    func begin() {
        LogStore.shared.setProcessCaptureEnabled(true)
        LogStore.shared.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.refresh()
            }
        }
        refresh()
    }

    func end() {
        LogStore.shared.setProcessCaptureEnabled(false)
        LogStore.shared.onUpdate = nil
    }

    func refresh() {
        text = LogStore.shared.getAllLogs()
    }

    func clear() {
        LogStore.shared.clear()
        refresh()
    }

    func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(LogStore.shared.getAllLogs(), forType: .string)
    }
}

struct LogsView: View {
    @ObservedObject var model: LogsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DPISettingsTokens.accent)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 8).fill(DPISettingsTokens.accent.opacity(0.14)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.shared.logsTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DPISettingsTokens.primaryText)
                    Text(L10n.shared.logsDescription)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.secondaryText)
                }

                SettingsBadge(title: L10n.shared.logsLiveStatus, style: .neutral)
                Spacer(minLength: 0)

                Button(L10n.shared.clearLogs) {
                    model.clear()
                }
                Button(L10n.shared.copyLogs) {
                    model.copy()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            ScrollViewReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    Text(model.text.isEmpty ? L10n.shared.logsEmpty : model.text)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(model.text.isEmpty ? DPISettingsTokens.mutedText : DPISettingsTokens.primaryText)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(14)
                        .id("log-end")
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(DPISettingsTokens.surface))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DPISettingsTokens.border, lineWidth: 1))
                .onChange(of: model.text) { _ in
                    proxy.scrollTo("log-end", anchor: .bottom)
                }
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
        .frame(minWidth: 700, minHeight: 460)
        .background(DPISettingsTokens.background)
    }
}

final class LogWindowController: NSWindowController, NSWindowDelegate {
    private let model = LogsViewModel()
    private var hostingController: NSHostingController<LogsView>?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 460),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L10n.shared.logsTitle
        AppTheme.styleUtilityWindow(window, minSize: NSSize(width: 700, height: 460))
        self.init(window: window)
        window.delegate = self
        setupUI()
    }

    override func showWindow(_ sender: Any?) {
        model.begin()
        super.showWindow(sender)
    }

    private func setupUI() {
        let hostingController = NSHostingController(rootView: LogsView(model: model))
        self.hostingController = hostingController
        window?.contentViewController = hostingController
    }

    func windowWillClose(_ notification: Notification) {
        model.end()
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
        AppTheme.styleUtilityWindow(window, minSize: NSSize(width: 660, height: 500))
        self.init(window: window)
        setupUI()
        loadReadme()
    }

    func setupUI() {
        let background = AppTheme.makeSettingsBackground()
        window?.contentView = background

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.spacing = 14
        contentStack.alignment = .leading
        background.addSubview(contentStack)
        contentStack.fill(parent: background, padding: 18)

        let header = NSStackView()
        header.orientation = .vertical
        header.spacing = 3
        header.alignment = .leading

        let title = AppTheme.makeSettingsTitle(L10n.shared.helpTitle)
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        let subtitle = AppTheme.makeSettingsSecondaryText(L10n.shared.instructions)
        header.addArrangedSubview(title)
        header.addArrangedSubview(subtitle)
        contentStack.addArrangedSubview(header)

        let webContainer = NSView()
        webContainer.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.styleSettingsSurface(webContainer)
        contentStack.addArrangedSubview(webContainer)

        webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.translatesAutoresizingMaskIntoConstraints = false
        webContainer.addSubview(webView)
        webView.fill(parent: webContainer)

        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            webContainer.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            webContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 440)
        ])
    }

    func loadReadme() {
        guard let path = Bundle.main.path(forResource: "README", ofType: "md"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            webView.loadHTMLString(
                "<html><body style=\"margin:0;padding:28px;font:15px -apple-system;color:#f0f0f0;background:#17191e;\">\(L10n.shared.helpUnavailable)</body></html>",
                baseURL: nil
            )
            return
        }

        let html = markdownToHTML(cleanedHelpMarkdown(content))
        let styledHTML = """
        <html>
        <head>
        <style>
        :root { color-scheme: dark; }
        * { box-sizing: border-box; }
        html { background: #25272f; }
        body { max-width: 760px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, sans-serif; font-size: 14px; line-height: 1.58; padding: 22px 26px 34px; color: #f0f0f0; background: #25272f; }
        a { color: #6aa7ff; }
        h1, h2, h3 { color: #f0f0f0; }
        h1 { font-size: 21px; margin: 0 0 14px; padding-bottom: 10px; border-bottom: 1px solid rgba(255,255,255,0.08); }
        h2 { font-size: 16px; margin: 24px 0 8px; }
        h3 { font-size: 14px; margin: 18px 0 6px; }
        p { margin: 8px 0; }
        pre { background: #2c2f37; padding: 12px; border-radius: 8px; overflow-x: auto; border: 1px solid rgba(255,255,255,0.08); }
        code { background: #2c2f37; padding: 2px 5px; border-radius: 4px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 13px; }
        img { max-width: 100%; border-radius: 8px; border: 1px solid rgba(255,255,255,0.08); }
        li { margin: 5px 0 5px 18px; }
        hr { border: none; height: 1px; background: rgba(255,255,255,0.08); }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: Bundle.main.resourceURL)
    }

    private func cleanedHelpMarkdown(_ markdown: String) -> String {
        markdown.replacingOccurrences(
            of: "[✅❌⚠️🚀📊🔧🌐🔄🧪📋🎯💡🔥⭐️⭐]",
            with: "",
            options: .regularExpression
        )
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
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 220),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.appearance = NSAppearance(named: .darkAqua)
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
        contentStack.translatesAutoresizingMaskIntoConstraints = false

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
                imageView.widthAnchor.constraint(equalToConstant: 58),
                imageView.heightAnchor.constraint(equalToConstant: 58)
            ])
        }

        let title = NSTextField(labelWithString: "DPI Killer")
        title.font = .systemFont(ofSize: 21, weight: .bold)
        title.textColor = AppTheme.settingsTextPrimary
        title.alignment = .center

        let subtitle = NSTextField(wrappingLabelWithString: L10n.shared.preparingBypass)
        subtitle.font = .systemFont(ofSize: 13, weight: .regular)
        subtitle.textColor = AppTheme.settingsTextSecondary
        subtitle.alignment = .center
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.maximumNumberOfLines = 2
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
                progressView.heightAnchor.constraint(equalToConstant: 8)
            ])
        }
        if let cancelButton {
            contentStack.addArrangedSubview(cancelButton)
            cancelButton.setContentHuggingPriority(.required, for: .horizontal)
            cancelButton.widthAnchor.constraint(equalToConstant: 110).isActive = true
        }

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: background.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: background.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: background.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: background.trailingAnchor, constant: -24),
            subtitle.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
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
        layer?.backgroundColor = AppTheme.settingsSurfaceRaised.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = AppTheme.settingsBorder.cgColor
    }
}

final class LoaderProgressView: NSView {
    private let trackLayer = CALayer()
    private let fillLayer = CAGradientLayer()
    private var isIndeterminate = false
    private var progressValue: Double = 0

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

        trackLayer.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
        fillLayer.colors = [
            NSColor.controlAccentColor.withAlphaComponent(0.95).cgColor,
            AppTheme.accentSoft.withAlphaComponent(0.88).cgColor
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

        if isIndeterminate {
            startIndeterminateAnimationIfNeeded()
        } else {
            applyProgressFrame(progressValue)
        }
    }

    func setProgress(_ value: Double) {
        isIndeterminate = false
        fillLayer.removeAnimation(forKey: "loaderSlide")
        progressValue = max(0, min(1, value))
        applyProgressFrame(progressValue)
    }

    func setIndeterminate(_ isIndeterminate: Bool) {
        self.isIndeterminate = isIndeterminate
        if isIndeterminate {
            startIndeterminateAnimationIfNeeded()
        } else {
            fillLayer.removeAnimation(forKey: "loaderSlide")
            applyProgressFrame(progressValue)
        }
    }

    private func applyProgressFrame(_ value: Double) {
        guard bounds.width > 0, bounds.height > 0 else {
            needsLayout = true
            return
        }
        let width = max(bounds.width * CGFloat(value), bounds.height)
        fillLayer.frame = NSRect(x: 0, y: 0, width: width, height: bounds.height)
    }

    private func startIndeterminateAnimationIfNeeded() {
        guard bounds.width > 0, bounds.height > 0 else {
            needsLayout = true
            return
        }
        guard fillLayer.animation(forKey: "loaderSlide") == nil else { return }
        let segmentWidth = max(bounds.width * 0.34, bounds.height * 2.4)
        fillLayer.frame = NSRect(x: -segmentWidth, y: 0, width: segmentWidth, height: bounds.height)
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = -segmentWidth / 2
        animation.toValue = bounds.width + segmentWidth / 2
        animation.duration = 0.9
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fillLayer.add(animation, forKey: "loaderSlide")
    }
}
