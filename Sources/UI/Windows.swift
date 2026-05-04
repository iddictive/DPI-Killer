import Cocoa
import Foundation
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

final class SettingsSectionView: NSView {
    let stack = NSStackView()

    init(title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.32).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.16).cgColor

        stack.orientation = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        addSubview(stack)
        stack.fill(parent: self, padding: 14)

        let headerStack = NSStackView()
        headerStack.orientation = .vertical
        headerStack.spacing = 3
        headerStack.alignment = .leading
        headerStack.addArrangedSubview(AppTheme.makeSectionTitle(title))
        if let subtitle, !subtitle.isEmpty {
            headerStack.addArrangedSubview(AppTheme.makeSecondaryText(subtitle))
        }

        stack.addArrangedSubview(headerStack)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SettingsWindowController: NSWindowController {
    private static let defaultContentSize = NSSize(width: 620, height: 580)

    private let formLabelWidth: CGFloat = 124
    private let fixedContentSize = SettingsWindowController.defaultContentSize

    var pathField: NSTextField!
    var backendModeButton: NSPopUpButton!
    var backendSummaryLabel: NSTextField!
    var backendPathHintLabel: NSTextField!
    var manualArgsField: NSTextField!
    var ttlField: NSTextField!
    var splitModeButton: NSPopUpButton!
    var httpsDisorderButton: NSButton!
    var httpsFakeCountField: NSTextField!
    var httpsChunkSizeField: NSTextField!
    var portField: NSTextField!
    var dnsAddrField: NSTextField!
    var dnsModeButton: NSPopUpButton!
    var dnsHttpsUrlField: NSTextField!
    var dnsHintLabel: NSTextField!
    var hotspotStatusLabel: NSTextField!
    var hotspotFixButton: NSButton!
    var checkboxes: [NSButton] = []
    var optionButtons: [String: NSButton] = [:]
    var optionRows: [String: NSView] = [:]
    var dnsControls: [NSControl] = []

    let options = [
        ArgumentOption(flag: "--system-proxy", description: L10n.shared.descSystemProxy),
        ArgumentOption(flag: "--silent", description: L10n.shared.descSilent),
        ArgumentOption(flag: "--dns-ipv4-only", description: L10n.shared.descIpv4Only),
        ArgumentOption(flag: "--debug", description: L10n.shared.descDebug),
        ArgumentOption(flag: "--policy-auto", description: L10n.shared.descPolicyAuto)
    ]

    convenience init() {
        let window = FixedSizeWindow(
            contentRect: NSRect(origin: .zero, size: SettingsWindowController.defaultContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = L10n.shared.settingsTitle
        AppTheme.styleWindow(window, minSize: SettingsWindowController.defaultContentSize)
        window.fixedFrameSize = window.frameRect(
            forContentRect: NSRect(origin: .zero, size: SettingsWindowController.defaultContentSize)
        ).size
        self.init(window: window)
        enforceFixedWindowSize(center: true)
        setupUI()
    }

    override func showWindow(_ sender: Any?) {
        let shouldCenter = window?.isVisible != true
        super.showWindow(sender)
        enforceFixedWindowSize(center: shouldCenter)
        DispatchQueue.main.async { [weak self] in
            self?.enforceFixedWindowSize(center: false)
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

        let targetFrame = NSRect(origin: .zero, size: frameSize)
        let currentOrigin = center ? NSPoint(x: window.frame.origin.x, y: window.frame.origin.y) : window.frame.origin
        let frame = NSRect(origin: currentOrigin, size: targetFrame.size)
        window.setFrame(frame, display: false)
        window.setContentSize(fixedContentSize)
        if center {
            window.center()
        }
    }

    func setupUI() {
        let background = AppTheme.makeWindowBackground()
        window?.contentView = background

        let rootStack = NSStackView()
        rootStack.orientation = .vertical
        rootStack.spacing = 12
        rootStack.alignment = .leading
        background.addSubview(rootStack)
        rootStack.fill(parent: background, padding: 16)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true

        let footerStack = NSStackView()
        footerStack.orientation = .horizontal
        footerStack.spacing = 10
        footerStack.alignment = .centerY

        let cancelBtn = NSButton(title: L10n.shared.cancel, target: self, action: #selector(cancelAction))
        AppTheme.styleSecondaryButton(cancelBtn)

        let saveButton = NSButton(title: L10n.shared.saveAndRestart, target: self, action: #selector(save))
        saveButton.keyEquivalent = "\r"
        AppTheme.stylePrimaryButton(saveButton)

        footerStack.addArrangedSubview(NSView())
        footerStack.addArrangedSubview(cancelBtn)
        footerStack.addArrangedSubview(saveButton)

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 16
        mainStack.alignment = .leading
        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(scrollView)
        let footerSeparator = AppTheme.makeSeparator()
        rootStack.addArrangedSubview(footerSeparator)
        rootStack.addArrangedSubview(footerStack)

        NSLayoutConstraint.activate([
            scrollView.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            footerSeparator.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            footerStack.widthAnchor.constraint(equalTo: rootStack.widthAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.contentView.heightAnchor),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        func addSection(_ section: NSView) {
            mainStack.addArrangedSubview(section)
            section.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        }

        let coreSection = createSection(
            title: L10n.shared.sectionCore,
            subtitle: L10n.shared.isRussian
                ? "Выбор backend-а и базовая конфигурация запуска."
                : "Backend selection and launch configuration."
        )
        backendModeButton = themedPopup(
            items: [
                L10n.shared.backendAuto,
                L10n.shared.backendCiadpi,
                L10n.shared.backendSpoofdpi,
                L10n.shared.backendCustom
            ],
            selected: localizedBackendTitle(for: SettingsStore.shared.backendSelection)
        )
        backendModeButton.target = self
        backendModeButton.action = #selector(backendSelectionChanged)
        addRow(label: L10n.shared.backendModeTitle, control: backendModeButton, to: coreSection.stack)

        backendSummaryLabel = AppTheme.makeSecondaryText("")
        addRow(label: L10n.shared.backendSummaryTitle, control: backendSummaryLabel, to: coreSection.stack)

        pathField = themedTextField(value: SettingsStore.shared.binaryPath, placeholder: L10n.shared.binaryPlaceholder)
        addRow(label: L10n.shared.binaryPathCustom, control: pathField, to: coreSection.stack, tooltip: L10n.shared.tipBinaryPath)

        backendPathHintLabel = AppTheme.makeSecondaryText(L10n.shared.backendPathHint)
        addIndentedRow(content: backendPathHintLabel, to: coreSection.stack)
        addSection(coreSection)

        let networkSection = createSection(
            title: L10n.shared.sectionNetwork,
            subtitle: L10n.shared.isRussian
                ? "Порт, статус хотспота и быстрые действия."
                : "Port, hotspot status, and quick actions."
        )
        hotspotStatusLabel = NSTextField(labelWithString: L10n.shared.diagChecking)
        hotspotStatusLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        addRow(label: L10n.shared.hotspotStatusTitle, control: hotspotStatusLabel, to: networkSection.stack)

        let hotspotActions = NSStackView()
        hotspotActions.orientation = .horizontal
        hotspotActions.spacing = 12
        hotspotActions.alignment = .centerY
        hotspotFixButton = NSButton(title: L10n.shared.fixHotspotButton, target: self, action: #selector(fixHotspotAction))
        AppTheme.styleSecondaryButton(hotspotFixButton)
        hotspotFixButton.isHidden = true

        let presetBtn = NSButton(title: L10n.shared.mobilePresetTitle, target: self, action: #selector(applyMobilePreset))
        AppTheme.stylePrimaryButton(presetBtn)
        hotspotActions.addArrangedSubview(hotspotFixButton)
        hotspotActions.addArrangedSubview(presetBtn)
        addIndentedRow(content: hotspotActions, to: networkSection.stack)

        portField = themedTextField(value: SettingsStore.shared.localPort, placeholder: L10n.shared.portPlaceholder, width: 120)
        addRow(label: L10n.shared.portTitle, control: portField, to: networkSection.stack, tooltip: L10n.shared.tipLocalPort)
        addSection(networkSection)
        updateHotspotStatus()

        let dpiSection = createSection(
            title: L10n.shared.sectionDPI,
            subtitle: L10n.shared.isRussian
                ? "Основные флаги и параметры обхода DPI."
                : "Primary DPI bypass flags and tuning."
        )
        let selected = SettingsStore.shared.selectedFlags
        for option in options {
            let cb = NSButton(checkboxWithTitle: option.flag, target: nil, action: nil)
            cb.state = selected.contains(option.flag) ? .on : .off
            cb.font = .systemFont(ofSize: 13, weight: .regular)
            checkboxes.append(cb)
            optionButtons[option.flag] = cb

            let optionStack = NSStackView()
            optionStack.orientation = .vertical
            optionStack.spacing = 3
            optionStack.alignment = .leading
            optionStack.addArrangedSubview(cb)

            let desc = NSTextField(wrappingLabelWithString: option.description)
            desc.font = .systemFont(ofSize: 12, weight: .regular)
            desc.textColor = AppTheme.textSecondary
            let descContainer = NSView()
            descContainer.translatesAutoresizingMaskIntoConstraints = false
            descContainer.addSubview(desc)
            desc.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                desc.topAnchor.constraint(equalTo: descContainer.topAnchor),
                desc.leadingAnchor.constraint(equalTo: descContainer.leadingAnchor, constant: 18),
                desc.trailingAnchor.constraint(equalTo: descContainer.trailingAnchor),
                desc.bottomAnchor.constraint(equalTo: descContainer.bottomAnchor)
            ])
            optionStack.addArrangedSubview(descContainer)
            addToggleRow(content: optionStack, to: dpiSection.stack)
            optionRows[option.flag] = optionStack
        }

        ttlField = themedTextField(value: SettingsStore.shared.defaultTTL, placeholder: L10n.shared.ttlPlaceholder, width: 90)
        addRow(label: L10n.shared.ttlTitle, control: ttlField, to: dpiSection.stack, tooltip: L10n.shared.tipTTL)

        splitModeButton = themedPopup(items: ["sni", "random", "chunk", "none"], selected: SettingsStore.shared.splitMode)
        addRow(label: L10n.shared.splitModeTitle, control: splitModeButton, to: dpiSection.stack, tooltip: L10n.shared.tipSplitMode)

        let disorderStack = NSStackView()
        disorderStack.orientation = .horizontal
        disorderStack.spacing = 12
        disorderStack.alignment = .centerY

        httpsDisorderButton = NSButton(checkboxWithTitle: L10n.shared.httpsDisorder, target: nil, action: nil)
        httpsDisorderButton.state = SettingsStore.shared.httpsDisorder ? .on : .off
        httpsDisorderButton.font = .systemFont(ofSize: 13, weight: .regular)
        disorderStack.addArrangedSubview(httpsDisorderButton)

        let fakeLabel = NSTextField(labelWithString: L10n.shared.httpsFakeCount)
        fakeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        fakeLabel.textColor = AppTheme.textSecondary
        httpsFakeCountField = themedTextField(value: SettingsStore.shared.httpsFakeCount, placeholder: "0", width: 68)

        let fakeStack = NSStackView()
        fakeStack.orientation = .horizontal
        fakeStack.spacing = 8
        fakeStack.alignment = .centerY
        fakeStack.addArrangedSubview(fakeLabel)
        fakeStack.addArrangedSubview(httpsFakeCountField)
        disorderStack.addArrangedSubview(fakeStack)
        addToggleRow(content: disorderStack, to: dpiSection.stack)

        httpsChunkSizeField = themedTextField(value: SettingsStore.shared.httpsChunkSize, placeholder: L10n.shared.httpsChunkPlaceholder, width: 90)
        addRow(label: L10n.shared.httpsChunkSize, control: httpsChunkSizeField, to: dpiSection.stack, tooltip: L10n.shared.tipChunkSize)
        addSection(dpiSection)

        let dnsSection = createSection(
            title: L10n.shared.sectionDNS,
            subtitle: L10n.shared.isRussian
                ? "Настройки DNS и DoH."
                : "DNS resolver and DoH settings."
        )
        dnsHintLabel = AppTheme.makeSecondaryText(L10n.shared.dnsDisabledForCiadpi)
        dnsSection.stack.addArrangedSubview(dnsHintLabel)

        dnsAddrField = themedTextField(value: SettingsStore.shared.dnsAddr, placeholder: "8.8.8.8:53")
        addRow(label: L10n.shared.dnsAddrTitle, control: dnsAddrField, to: dnsSection.stack, tooltip: L10n.shared.tipDNSAddr)
        dnsControls.append(dnsAddrField)

        dnsModeButton = themedPopup(items: ["udp", "https", "system"], selected: SettingsStore.shared.dnsMode)
        addRow(label: L10n.shared.dnsModeTitle, control: dnsModeButton, to: dnsSection.stack, tooltip: L10n.shared.tipDNSSystem)
        dnsControls.append(dnsModeButton)

        dnsHttpsUrlField = themedTextField(value: SettingsStore.shared.dnsHttpsUrl, placeholder: "https://dns.google/dns-query")
        addRow(label: "DoH URL", control: dnsHttpsUrlField, to: dnsSection.stack)
        dnsControls.append(dnsHttpsUrlField)
        addSection(dnsSection)

        let appSection = createSection(
            title: L10n.shared.sectionApp,
            subtitle: L10n.shared.isRussian
                ? "Поведение приложения и автодействия."
                : "App behavior and automation."
        )
        let loginCb = NSButton(checkboxWithTitle: L10n.shared.launchAtLogin, target: self, action: #selector(toggleLoginItem))
        loginCb.state = SettingsStore.shared.launchAtLogin ? .on : .off
        addCheckboxRow(button: loginCb, to: appSection.stack)

        let updateCb = NSButton(checkboxWithTitle: L10n.shared.autoUpdateToggle, target: self, action: #selector(toggleUpdateItem))
        updateCb.state = SettingsStore.shared.autoUpdate ? .on : .off
        addCheckboxRow(button: updateCb, to: appSection.stack)

        let autoDownloadCb = NSButton(checkboxWithTitle: L10n.shared.autoDownloadToggle, target: self, action: #selector(toggleDownloadItem))
        autoDownloadCb.state = SettingsStore.shared.autoDownload ? .on : .off
        addCheckboxRow(button: autoDownloadCb, to: appSection.stack)

        let ipv6Cb = NSButton(checkboxWithTitle: L10n.shared.disableIpv6, target: self, action: #selector(toggleIpv6))
        ipv6Cb.state = SettingsStore.shared.disableIpv6 ? .on : .off
        addCheckboxRow(button: ipv6Cb, to: appSection.stack)

        let reconnectCb = NSButton(checkboxWithTitle: L10n.shared.autoReconnect, target: self, action: #selector(toggleReconnect))
        reconnectCb.state = SettingsStore.shared.autoReconnect ? .on : .off
        reconnectCb.toolTip = L10n.shared.tipAutoReconnect
        addCheckboxRow(button: reconnectCb, to: appSection.stack)
        addSection(appSection)

        let manualSection = createSection(
            title: L10n.shared.sectionManual,
            subtitle: L10n.shared.isRussian
                ? "Ручные аргументы для редких случаев."
                : "Manual arguments for edge cases."
        )
        manualArgsField = themedTextField(value: manualArgsValue(), placeholder: L10n.shared.manualArgsPlaceholder)
        manualSection.stack.addArrangedSubview(manualArgsField)
        manualArgsField.widthAnchor.constraint(equalTo: manualSection.stack.widthAnchor).isActive = true
        addSection(manualSection)

        refreshBackendUI()
    }

    private func createSection(title: String, subtitle: String? = nil) -> SettingsSectionView {
        SettingsSectionView(title: title, subtitle: subtitle)
    }

    private func themedTextField(value: String, placeholder: String, width: CGFloat? = nil) -> NSTextField {
        let field = NSTextField()
        field.stringValue = value
        field.placeholderString = placeholder
        AppTheme.styleInput(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        if let width {
            field.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        return field
    }

    private func themedPopup(items: [String], selected: String) -> NSPopUpButton {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.addItems(withTitles: items)
        popup.selectItem(withTitle: selected)
        AppTheme.styleInput(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        return popup
    }

    private func localizedBackendTitle(for selection: BackendSelection) -> String {
        switch selection {
        case .automatic:
            return L10n.shared.backendAuto
        case .ciadpi:
            return L10n.shared.backendCiadpi
        case .spoofdpi:
            return L10n.shared.backendSpoofdpi
        case .custom:
            return L10n.shared.backendCustom
        }
    }

    private func selectedBackendSelection() -> BackendSelection {
        switch backendModeButton.titleOfSelectedItem {
        case L10n.shared.backendCiadpi:
            return .ciadpi
        case L10n.shared.backendSpoofdpi:
            return .spoofdpi
        case L10n.shared.backendCustom:
            return .custom
        default:
            return .automatic
        }
    }

    private func resolvedBackendPath() -> String {
        SettingsStore.shared.resolvedBinaryPath(
            for: selectedBackendSelection(),
            customPath: pathField?.stringValue
        )
    }

    private func refreshBackendUI() {
        guard backendModeButton != nil, pathField != nil else { return }

        let selection = selectedBackendSelection()
        let resolvedPath = resolvedBackendPath()
        let engine = SettingsStore.shared.currentEngine(for: resolvedPath)
        let isCustom = selection == .custom
        let isSpoofdpi = engine == .spoofdpi

        pathField.stringValue = resolvedPath
        pathField.isEditable = isCustom
        pathField.isEnabled = isCustom
        pathField.textColor = isCustom ? AppTheme.textPrimary : AppTheme.textSecondary
        pathField.backgroundColor = isCustom ? .controlBackgroundColor : .quaternaryLabelColor.withAlphaComponent(0.08)

        let pathState = FileManager.default.fileExists(atPath: resolvedPath)
            ? URL(fileURLWithPath: resolvedPath).lastPathComponent
            : L10n.shared.backendMissingSuffix
        backendSummaryLabel.stringValue = "\(engine.displayName) • \(engine.proxyDescription) • \(pathState)"

        backendPathHintLabel.isHidden = isCustom
        dnsHintLabel.isHidden = isSpoofdpi
        dnsControls.forEach {
            $0.isEnabled = isSpoofdpi
            $0.alphaValue = isSpoofdpi ? 1 : 0.55
        }

        let unsupportedFlags: Set<String>
        if isSpoofdpi {
            unsupportedFlags = ["--policy-auto"]
        } else {
            unsupportedFlags = ["--silent", "--dns-ipv4-only", "--debug"]
        }
        for option in options {
            let enabled = !unsupportedFlags.contains(option.flag)
            optionButtons[option.flag]?.isEnabled = enabled
            optionRows[option.flag]?.alphaValue = enabled ? 1 : 0.45
        }

        manualArgsField.placeholderString = isSpoofdpi
            ? L10n.shared.manualArgsPlaceholderSpoofdpi
            : L10n.shared.manualArgsPlaceholderCiadpi
    }

    private func addRow(label: String, control: NSView, to stack: NSStackView, tooltip: String? = nil) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let labelView = NSTextField(labelWithString: label)
        labelView.font = .systemFont(ofSize: 12, weight: .medium)
        labelView.textColor = AppTheme.textSecondary
        labelView.alignment = .right
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.widthAnchor.constraint(equalToConstant: formLabelWidth).isActive = true

        if let tooltip {
            control.toolTip = tooltip
        }

        control.setContentHuggingPriority(.defaultLow, for: .horizontal)
        control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(labelView)
        row.addArrangedSubview(control)
        stack.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    private func addIndentedRow(content: NSView, to stack: NSStackView) {
        addInsetRow(content: content, to: stack, leadingInset: formLabelWidth)
    }

    private func addToggleRow(content: NSView, to stack: NSStackView) {
        addInsetRow(content: content, to: stack, leadingInset: 18)
    }

    private func addInsetRow(content: NSView, to stack: NSStackView, leadingInset: CGFloat) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .top

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(equalToConstant: leadingInset).isActive = true

        content.setContentHuggingPriority(.defaultLow, for: .horizontal)
        content.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        row.addArrangedSubview(spacer)
        row.addArrangedSubview(content)
        stack.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    private func addCheckboxRow(button: NSButton, to stack: NSStackView) {
        button.font = .systemFont(ofSize: 13, weight: .regular)
        addToggleRow(content: button, to: stack)
    }

    private func manualArgsValue() -> String {
        SettingsStore.shared.manualArgsString(for: pathField?.stringValue)
    }

    @objc func backendSelectionChanged() {
        refreshBackendUI()
    }

    @objc func cancelAction() {
        window?.close()
    }

    @objc func applyMobilePreset() {
        ttlField.stringValue = "128"
        splitModeButton.selectItem(withTitle: "random")
        httpsChunkSizeField.stringValue = "20"
        httpsDisorderButton.state = .on
        httpsFakeCountField.stringValue = "0"
        if getSystemTTL() != 65 {
            fixHotspotAction()
        }
    }

    @objc func fixHotspotAction() {
        let script = "do shell script \"sysctl -w net.inet.ip.ttl=65 && sysctl -w net.inet6.ip6.hlim=65\" with administrator privileges"
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)

        if let error {
            AppLogger.log("AppleScript Error: \(error)")
            let alert = NSAlert()
            alert.messageText = L10n.shared.fixHotspotFailed
            alert.informativeText = "\(error["NSAppleScriptErrorMessage"] ?? "Unknown error")"
            alert.runModal()
        } else {
            updateHotspotStatus()
            (NSApp.delegate as? AppDelegate)?.refreshUI()
        }
    }

    func updateHotspotStatus() {
        let ttl = getSystemTTL()
        if ttl == 65 {
            hotspotStatusLabel.stringValue = L10n.shared.hotspotStatusOptimized
            hotspotStatusLabel.textColor = AppTheme.success
            hotspotFixButton.isHidden = true
        } else {
            hotspotStatusLabel.stringValue = L10n.shared.hotspotStatusThrottled
            hotspotStatusLabel.textColor = AppTheme.warning
            hotspotFixButton.isHidden = false
        }
    }

    func getSystemTTL() -> Int {
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["-n", "net.inet.ip.ttl"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               let value = Int(output) {
                return value
            }
        } catch {
            return 64
        }
        return 64
    }

    @objc func toggleLoginItem(_ sender: NSButton) {
        SettingsStore.shared.launchAtLogin = sender.state == .on
    }

    @objc func toggleDownloadItem(_ sender: NSButton) {
        SettingsStore.shared.autoDownload = sender.state == .on
    }

    @objc func toggleUpdateItem(_ sender: NSButton) {
        SettingsStore.shared.autoUpdate = sender.state == .on
    }

    @objc func toggleReconnect(_ sender: NSButton) {
        SettingsStore.shared.autoReconnect = sender.state == .on
    }

    @objc func toggleIpv6(_ sender: NSButton) {
        SettingsStore.shared.disableIpv6 = sender.state == .on
    }

    @objc func save() {
        var flags = Set<String>()
        for (index, checkbox) in checkboxes.enumerated() where checkbox.state == .on {
            flags.insert(options[index].flag)
        }

        let clampedPort = (Int(portField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 8080).clamped(to: 1...65535)
        let clampedTTL = (Int(ttlField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 128).clamped(to: 1...255)
        let clampedFakeCount = (Int(httpsFakeCountField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0).clamped(to: 0...100)
        let clampedChunkSize = (Int(httpsChunkSizeField.stringValue.trimmingCharacters(in: .whitespaces)) ?? 100).clamped(to: 1...1000)

        let backendSelection = selectedBackendSelection()
        SettingsStore.shared.applyBackendSelection(backendSelection, customPath: pathField.stringValue)
        SettingsStore.shared.defaultTTL = String(clampedTTL)
        SettingsStore.shared.splitMode = splitModeButton.titleOfSelectedItem ?? "sni"
        SettingsStore.shared.httpsDisorder = httpsDisorderButton.state == .on
        SettingsStore.shared.httpsFakeCount = String(clampedFakeCount)
        SettingsStore.shared.httpsChunkSize = String(clampedChunkSize)
        SettingsStore.shared.localPort = String(clampedPort)
        SettingsStore.shared.dnsAddr = dnsAddrField.stringValue.trimmingCharacters(in: .whitespaces)
        SettingsStore.shared.dnsMode = dnsModeButton.titleOfSelectedItem ?? "udp"
        SettingsStore.shared.dnsHttpsUrl = dnsHttpsUrlField.stringValue.trimmingCharacters(in: .whitespaces)

        SettingsStore.shared.updateArgs(
            with: flags,
            manual: manualArgsField.stringValue,
            ttl: SettingsStore.shared.defaultTTL,
            splitMode: SettingsStore.shared.splitMode,
            splitPos: "1",
            port: SettingsStore.shared.localPort,
            dnsAddr: SettingsStore.shared.dnsAddr,
            dnsMode: SettingsStore.shared.dnsMode,
            dnsHttpsUrl: SettingsStore.shared.dnsHttpsUrl
        )

        if DPIKillerManager.shared.isRunning {
            DPIKillerManager.shared.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DPIKillerManager.shared.start { _, _ in
                    (NSApp.delegate as? AppDelegate)?.refreshUI()
                }
            }
        }

        window?.close()
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
        if let icon = NSApp.applicationIconImage {
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
