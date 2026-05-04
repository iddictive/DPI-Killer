import AppKit
import SwiftUI

enum DPISettingsTokens {
    static let sidebarWidth: CGFloat = 176
    static let footerHeight: CGFloat = 58
    static let contentPadding: CGFloat = 18
    static let cardPadding: CGFloat = 14
    static let rowLabelWidth: CGFloat = 132
    static let controlHeight: CGFloat = 28
    static let cornerRadius: CGFloat = 8
    static let rowSpacing: CGFloat = 12
    static let cardSpacing: CGFloat = 14

    static let background = Color(nsColor: AppTheme.settingsBackground)
    static let sidebar = Color(nsColor: AppTheme.settingsSidebar)
    static let surface = Color(nsColor: AppTheme.settingsSurface)
    static let raisedSurface = Color(nsColor: AppTheme.settingsSurfaceRaised)
    static let separator = Color(nsColor: AppTheme.settingsSeparator)
    static let border = Color(nsColor: AppTheme.settingsBorder)
    static let primaryText = Color(nsColor: AppTheme.settingsTextPrimary)
    static let secondaryText = Color(nsColor: AppTheme.settingsTextSecondary)
    static let mutedText = Color(nsColor: AppTheme.settingsTextMuted)
    static let accent = Color(nsColor: .controlAccentColor)
    static let success = Color(nsColor: AppTheme.success)
    static let warning = Color(nsColor: AppTheme.warning)
    static let danger = Color(nsColor: AppTheme.danger)

    static let titleFont = Font.system(size: 13, weight: .semibold)
    static let bodyFont = Font.system(size: 13, weight: .regular)
    static let labelFont = Font.system(size: 12, weight: .medium)
    static let captionFont = Font.system(size: 12, weight: .regular)
    static let badgeFont = Font.system(size: 11, weight: .semibold)
}

enum SettingsBadgeStyle {
    case neutral
    case success
    case warning
    case danger

    var color: Color {
        switch self {
        case .neutral:
            return DPISettingsTokens.secondaryText
        case .success:
            return DPISettingsTokens.success
        case .warning:
            return DPISettingsTokens.warning
        case .danger:
            return DPISettingsTokens.danger
        }
    }
}

struct SettingsCompatibilityBadge: Identifiable {
    let id = UUID()
    let title: String
    let style: SettingsBadgeStyle
}

struct SettingsBadge: View {
    let title: String
    let style: SettingsBadgeStyle

    var body: some View {
        Text(title)
            .font(DPISettingsTokens.badgeFont)
            .foregroundStyle(style.color)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(style.color.opacity(0.12)))
            .overlay(Capsule().stroke(style.color.opacity(0.24), lineWidth: 1))
    }
}

struct SettingsSidebar: View {
    @Binding var selectedTab: SettingsTab

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 10) {
                if let icon = DPISettingsAssets.appIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                Text("DPI Killer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DPISettingsTokens.primaryText)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            .padding(.bottom, 8)

            ForEach(SettingsTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 15)

                        Text(tab.title)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(selectedTab == tab ? DPISettingsTokens.primaryText : DPISettingsTokens.secondaryText)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(selectedTab == tab ? DPISettingsTokens.accent.opacity(0.22) : .clear)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: DPISettingsTokens.sidebarWidth)
        .background(DPISettingsTokens.sidebar)
    }
}

enum DPISettingsAssets {
    static func appIcon() -> NSImage? {
        if let bundledURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: bundledURL),
           image.isValid {
            return image
        }

        let debugURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("assets/AppIcon.icns")
        if let image = NSImage(contentsOf: debugURL),
           image.isValid {
            return image
        }

        return NSApp.applicationIconImage
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DPISettingsTokens.rowSpacing) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DPISettingsTokens.titleFont)
                    .foregroundStyle(DPISettingsTokens.primaryText)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(DPISettingsTokens.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DPISettingsTokens.cornerRadius)
                .fill(DPISettingsTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DPISettingsTokens.cornerRadius)
                .stroke(DPISettingsTokens.border, lineWidth: 1)
        )
    }
}

struct SettingsRow<Content: View>: View {
    let label: String
    let help: String?
    @ViewBuilder let content: Content

    init(_ label: String, help: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.help = help
        self.content = content()
    }

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 3) {
            GridRow {
                Text(label)
                    .font(DPISettingsTokens.labelFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
                    .frame(width: DPISettingsTokens.rowLabelWidth, alignment: .trailing)

                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let help, !help.isEmpty {
                GridRow {
                    Color.clear
                        .frame(width: DPISettingsTokens.rowLabelWidth, height: 0)

                    Text(help)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsFooter: View {
    let statusText: String?
    let canSave: Bool
    let cancelTitle: String
    let saveTitle: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let statusText, !statusText.isEmpty {
                Text(statusText)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Button(cancelTitle, action: onCancel)
                .buttonStyle(.bordered)

            Button(saveTitle, action: onSave)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
        }
        .padding(.horizontal, 14)
        .frame(height: DPISettingsTokens.footerHeight)
        .background(DPISettingsTokens.background)
    }
}

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    private let onCancel: (() -> Void)?
    private let onSave: (() -> Void)?

    init(
        viewModel: SettingsViewModel = SettingsViewModel(),
        onCancel: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SettingsSidebar(selectedTab: $viewModel.selectedTab)

                Rectangle()
                    .fill(DPISettingsTokens.separator)
                    .frame(width: 1)

                ScrollView {
                    VStack(alignment: .leading, spacing: DPISettingsTokens.cardSpacing) {
                        tabContent
                    }
                    .padding(DPISettingsTokens.contentPadding)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .background(DPISettingsTokens.background)
            }

            Rectangle()
                .fill(DPISettingsTokens.separator)
                .frame(height: 1)

            SettingsFooter(
                statusText: viewModel.footerStatusText,
                canSave: viewModel.canSave,
                cancelTitle: L10n.shared.cancel,
                saveTitle: L10n.shared.saveAndRestart,
                onCancel: cancel,
                onSave: save
            )
        }
        .frame(minWidth: 780, idealWidth: 780, minHeight: 580, idealHeight: 580)
        .background(DPISettingsTokens.background)
        .foregroundStyle(DPISettingsTokens.primaryText)
        .onAppear {
            viewModel.refreshRuntimeStatus()
            viewModel.refreshCiadpiLocalStatus()
            viewModel.refreshSpoofdpiLocalStatus()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .backend:
            backendTab
        case .network:
            networkTab
        case .bypass:
            bypassTab
        case .dns:
            dnsTab
        case .app:
            appTab
        case .manual:
            manualTab
        }
    }

    private var backendTab: some View {
        VStack(alignment: .leading, spacing: DPISettingsTokens.cardSpacing) {
            SettingsCard(
                title: L10n.shared.sectionCore,
                subtitle: text(ru: "Выбор движка и базовая конфигурация запуска.", en: "Backend selection and launch configuration.")
            ) {
                SettingsRow(L10n.shared.backendModeTitle) {
                    Picker("", selection: $viewModel.backendSelection) {
                        ForEach(viewModel.backendSelections, id: \.self) { selection in
                            Text(viewModel.title(for: selection)).tag(selection)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 360)
                    .onChange(of: viewModel.backendSelection) { _ in
                        viewModel.backendSelectionChanged()
                    }
                }

                SettingsRow(L10n.shared.backendSummaryTitle) {
                    Text(viewModel.backendSummary)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.secondaryText)
                        .lineLimit(2)
                }

                SettingsRow(viewModel.backendPathLabel, help: viewModel.backendSelection == .custom ? L10n.shared.tipBinaryPath : L10n.shared.backendPathHint) {
                    if viewModel.backendSelection == .custom {
                        TextField(L10n.shared.binaryPlaceholder, text: $viewModel.customBinaryPath)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        pathText(viewModel.resolvedBinaryPath)
                    }
                }

                compatibilityBadges
            }

            ciadpiMaintenanceCard
            spoofdpiVersionCard
        }
    }

    private var networkTab: some View {
        SettingsCard(
            title: L10n.shared.sectionNetwork,
            subtitle: text(ru: "Порт, режим прокси и быстрые сетевые действия.", en: "Port, proxy mode, and quick network actions.")
        ) {
            SettingsRow(L10n.shared.portTitle, help: L10n.shared.tipLocalPort) {
                TextField(L10n.shared.portPlaceholder, text: $viewModel.localPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
            }

            SettingsRow(L10n.shared.runtimeModeTitle) {
                HStack(spacing: 8) {
                    SettingsBadge(title: viewModel.proxyModeTitle, style: .neutral)
                    SettingsBadge(title: viewModel.runtimeStatusTitle, style: viewModel.runtimeBadgeStyle)
                }
            }

            HStack(spacing: 10) {
                Button(L10n.shared.mobilePresetTitle) {
                    viewModel.applyMobilePreset()
                }
                .buttonStyle(.bordered)

                Button(text(ru: "Обновить статус", en: "Refresh Status")) {
                    viewModel.refreshRuntimeStatus()
                }
                .buttonStyle(.bordered)
            }
            .padding(.leading, DPISettingsTokens.rowLabelWidth + 12)
        }
    }

    private var bypassTab: some View {
        SettingsCard(
            title: L10n.shared.sectionDPI,
            subtitle: text(ru: "Флаги и параметры обхода DPI.", en: "DPI bypass flags and tuning.")
        ) {
            SettingsRow(text(ru: "Пресет", en: "Preset")) {
                Picker("", selection: $viewModel.selectedPreset) {
                    ForEach(SettingsPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 330)
                .onChange(of: viewModel.selectedPreset) { preset in
                    viewModel.applyPreset(preset)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(text(ru: "Managed flags", en: "Managed flags"))
                    .font(DPISettingsTokens.labelFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
                    .padding(.leading, 18)

                ForEach(viewModel.options) { option in
                    Toggle(isOn: Binding(
                        get: { viewModel.flagEnabled(option.flag) },
                        set: { viewModel.setFlag(option.flag, enabled: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(viewModel.optionTitle(option.flag))
                                    .font(DPISettingsTokens.bodyFont)

                                SettingsBadge(title: option.flag, style: .neutral)

                                if !viewModel.flagSupported(option.flag) {
                                    SettingsBadge(title: text(ru: "Недоступно", en: "Unavailable"), style: .warning)
                                }
                            }

                            Text(option.description)
                                .font(DPISettingsTokens.captionFont)
                                .foregroundStyle(DPISettingsTokens.secondaryText)

                            if !viewModel.flagSupported(option.flag) {
                                Text(viewModel.unsupportedReason(for: option.flag))
                                    .font(DPISettingsTokens.captionFont)
                                    .foregroundStyle(DPISettingsTokens.warning)
                            }
                        }
                    }
                    .toggleStyle(.checkbox)
                    .disabled(!viewModel.flagSupported(option.flag))
                    .opacity(viewModel.flagSupported(option.flag) ? 1 : 0.55)
                    .padding(.leading, 18)
                }
            }

            SettingsRow(L10n.shared.ttlTitle, help: L10n.shared.tipTTL) {
                TextField(L10n.shared.ttlPlaceholder, text: $viewModel.defaultTTL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }

            SettingsRow(L10n.shared.splitModeTitle, help: L10n.shared.tipSplitMode) {
                Picker("", selection: $viewModel.splitMode) {
                    ForEach(viewModel.splitModes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            SettingsRow(L10n.shared.httpsDisorder) {
                Toggle("", isOn: $viewModel.httpsDisorder)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
            }

            SettingsRow(L10n.shared.httpsFakeCount, help: L10n.shared.tipFakeCount) {
                if viewModel.resolvedEngine == .ciadpi {
                    HStack(spacing: 8) {
                        Toggle("", isOn: Binding(
                            get: { viewModel.ciadpiFakeEnabled },
                            set: { viewModel.ciadpiFakeEnabled = $0 }
                        ))
                        .toggleStyle(.checkbox)
                        .labelsHidden()

                        Text(text(ru: "boolean trigger: --fake -1 --ttl 8", en: "boolean trigger: --fake -1 --ttl 8"))
                            .font(DPISettingsTokens.captionFont)
                            .foregroundStyle(DPISettingsTokens.secondaryText)
                    }
                } else {
                    TextField("0", text: $viewModel.httpsFakeCount)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }
            }

            SettingsRow(
                L10n.shared.httpsChunkSize,
                help: viewModel.chunkSizeAvailable ? L10n.shared.tipChunkSize : text(ru: "Только spoofdpi.", en: "spoofdpi only.")
            ) {
                HStack(spacing: 8) {
                    TextField(L10n.shared.httpsChunkPlaceholder, text: $viewModel.httpsChunkSize)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .disabled(!viewModel.chunkSizeAvailable)

                    if !viewModel.chunkSizeAvailable {
                        SettingsBadge(title: text(ru: "spoofdpi", en: "spoofdpi"), style: .warning)
                    }
                }
            }
        }
    }

    private var dnsTab: some View {
        SettingsCard(
            title: L10n.shared.sectionDNS,
            subtitle: text(ru: "DNS resolver и DoH для SpoofDPI.", en: "DNS resolver and DoH for SpoofDPI.")
        ) {
            if !viewModel.dnsAvailable {
                Text(L10n.shared.dnsDisabledForCiadpi)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.warning)
                    .padding(.leading, DPISettingsTokens.rowLabelWidth + 12)
            }

            SettingsRow(L10n.shared.dnsAddrTitle, help: L10n.shared.tipDNSAddr) {
                TextField("8.8.8.8:53", text: $viewModel.dnsAddr)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!viewModel.dnsAvailable)
            }

            SettingsRow(L10n.shared.dnsModeTitle, help: L10n.shared.tipDNSSystem) {
                Picker("", selection: $viewModel.dnsMode) {
                    ForEach(viewModel.dnsModes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .labelsHidden()
                .disabled(!viewModel.dnsAvailable)
                .frame(width: 160)
            }

            SettingsRow(L10n.shared.dnsHttpsTitle) {
                TextField("https://dns.google/dns-query", text: $viewModel.dnsHttpsUrl)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!viewModel.dnsAvailable || viewModel.dnsMode != "https")
            }
        }
        .opacity(viewModel.dnsAvailable ? 1 : 0.72)
    }

    private var appTab: some View {
        SettingsCard(
            title: L10n.shared.sectionApp,
            subtitle: text(ru: "Поведение приложения и системная интеграция.", en: "App behavior and system integration.")
        ) {
            appToggle(title: L10n.shared.launchAtLogin, isOn: $viewModel.launchAtLogin)
            appToggle(title: L10n.shared.autoUpdateToggle, isOn: $viewModel.autoUpdate)
            appToggle(title: L10n.shared.autoDownloadToggle, isOn: $viewModel.autoDownload)
            appToggle(title: L10n.shared.disableIpv6, help: L10n.shared.ipv6Warning, isOn: $viewModel.disableIpv6)
            appToggle(title: L10n.shared.autoReconnect, help: L10n.shared.tipAutoReconnect, isOn: $viewModel.autoReconnect)

            Toggle(isOn: $viewModel.vpnModeEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.shared.vpnModeToggle)
                        .font(DPISettingsTokens.bodyFont)

                    Text(L10n.shared.tipVPNMode)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.secondaryText)
                }
            }
            .toggleStyle(.checkbox)
            .disabled(!viewModel.vpnAvailable)
            .opacity(viewModel.vpnAvailable ? 1 : 0.55)
            .padding(.leading, 18)

            HStack(spacing: 8) {
                SettingsBadge(title: viewModel.vpnStatusTitle, style: viewModel.vpnBadgeStyle)

                Button(text(ru: "Проверить доступ", en: "Check Access")) {
                    viewModel.ensureSystemExtensionActivated()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isActivatingSystemExtension)
            }
            .padding(.leading, DPISettingsTokens.rowLabelWidth + 12)
        }
    }

    private var ciadpiMaintenanceCard: some View {
        SettingsCard(
            title: "ciadpi",
            subtitle: text(ru: "Версия managed ciadpi и переустановка из upstream.", en: "Managed ciadpi version and upstream reinstall.")
        ) {
            SettingsRow(text(ru: "Выбран:", en: "Selected:")) {
                pathText(viewModel.ciadpiSelectedPath)
            }

            SettingsRow(text(ru: "Managed:", en: "Managed:")) {
                pathText(viewModel.ciadpiManagedPath)
            }

            SettingsRow(text(ru: "Версия:", en: "Version:")) {
                Text(viewModel.ciadpiManagedVersion)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
            }

            HStack(spacing: 10) {
                Text(viewModel.ciadpiStatusMessage)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(viewModel.ciadpiStatusStyle.color)
                    .lineLimit(2)

                Spacer(minLength: 12)

                Button(text(ru: "Обновить ciadpi", en: "Update ciadpi")) {
                    viewModel.updateCiadpi()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isUpdatingCiadpi)
            }
            .padding(.leading, DPISettingsTokens.rowLabelWidth + 12)
        }
    }

    private var manualTab: some View {
        VStack(alignment: .leading, spacing: DPISettingsTokens.cardSpacing) {
            SettingsCard(
                title: text(ru: "Manual ciadpi", en: "Manual ciadpi"),
                subtitle: L10n.shared.manualArgsPlaceholderCiadpi
            ) {
                TextField(L10n.shared.manualArgsPlaceholderCiadpi, text: $viewModel.ciadpiManualArgs)
                    .textFieldStyle(.roundedBorder)

                if let warning = viewModel.manualWarning(for: .ciadpi) {
                    Text(warning)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.warning)
                }
            }

            SettingsCard(
                title: text(ru: "Manual SpoofDPI", en: "Manual SpoofDPI"),
                subtitle: L10n.shared.manualArgsPlaceholderSpoofdpi
            ) {
                TextField(L10n.shared.manualArgsPlaceholderSpoofdpi, text: $viewModel.spoofdpiManualArgs)
                    .textFieldStyle(.roundedBorder)

                if let warning = viewModel.manualWarning(for: .spoofdpi) {
                    Text(warning)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.warning)
                }
            }

            SettingsCard(
                title: text(ru: "Command Preview", en: "Command Preview"),
                subtitle: text(ru: "Команда собирается из текущего draft-состояния.", en: "The command is built from the current draft state.")
            ) {
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(viewModel.commandPreview)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(DPISettingsTokens.primaryText)
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DPISettingsTokens.raisedSurface)
                )
            }
        }
    }

    private var spoofdpiVersionCard: some View {
        SettingsCard(
            title: L10n.shared.spoofdpiMaintenanceTitle,
            subtitle: text(ru: "Версия managed SpoofDPI и действия обновления.", en: "Managed SpoofDPI version and update actions.")
        ) {
            SettingsRow(L10n.shared.spoofdpiSelectedPath) {
                pathText(viewModel.spoofdpiSelectedPath)
            }

            SettingsRow(L10n.shared.spoofdpiManagedPath) {
                pathText(viewModel.spoofdpiManagedPath)
            }

            SettingsRow(L10n.shared.spoofdpiVersionTitle) {
                Text(viewModel.spoofdpiManagedVersion)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
            }

            SettingsRow(L10n.shared.spoofdpiLatestTitle) {
                Text(viewModel.spoofdpiLatestVersion)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
            }

            HStack(spacing: 10) {
                Text(viewModel.spoofdpiStatusMessage)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(viewModel.spoofdpiStatusStyle.color)
                    .lineLimit(2)

                Spacer(minLength: 12)

                Button(L10n.shared.spoofdpiCheck) {
                    viewModel.checkSpoofdpiVersion()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isCheckingSpoofdpi || viewModel.isUpdatingSpoofdpi)

                Button(L10n.shared.spoofdpiUpdate) {
                    viewModel.updateSpoofdpi()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canUpdateSpoofdpi || viewModel.isCheckingSpoofdpi || viewModel.isUpdatingSpoofdpi)
            }
            .padding(.leading, DPISettingsTokens.rowLabelWidth + 12)
        }
    }

    private var compatibilityBadges: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 132), spacing: 8, alignment: .leading)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(viewModel.compatibilityBadges) { badge in
                SettingsBadge(title: badge.title, style: badge.style)
            }
        }
        .padding(.leading, DPISettingsTokens.rowLabelWidth + 12)
    }

    private func appToggle(title: String, help: String? = nil, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DPISettingsTokens.bodyFont)

                if let help {
                    Text(help)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.secondaryText)
                }
            }
        }
        .toggleStyle(.checkbox)
        .padding(.leading, 18)
    }

    private func pathText(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundStyle(DPISettingsTokens.secondaryText)
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)
    }

    private func save() {
        viewModel.save()
        onSave?()
    }

    private func cancel() {
        if let onCancel {
            onCancel()
        } else {
            NSApp.keyWindow?.close()
        }
    }

    private func text(ru: String, en: String) -> String {
        L10n.shared.isRussian ? ru : en
    }
}

struct SettingsArgumentOption: Identifiable {
    let flag: String
    let description: String

    var id: String { flag }
}

final class SettingsViewModel: ObservableObject {
    @Published var selectedTab: SettingsTab = .backend
    @Published var selectedPreset: SettingsPreset = .balanced
    @Published var backendSelection: BackendSelection
    @Published var customBinaryPath: String
    @Published var defaultTTL: String
    @Published var splitMode: String
    @Published var httpsDisorder: Bool
    @Published var httpsFakeCount: String
    @Published var httpsChunkSize: String
    @Published var localPort: String
    @Published var dnsAddr: String
    @Published var dnsMode: String
    @Published var dnsHttpsUrl: String
    @Published var launchAtLogin: Bool
    @Published var autoUpdate: Bool
    @Published var autoDownload: Bool
    @Published var disableIpv6: Bool
    @Published var autoReconnect: Bool
    @Published var vpnModeEnabled: Bool
    @Published var ciadpiManualArgs: String
    @Published var spoofdpiManualArgs: String
    @Published var footerStatus: String?
    @Published var spoofdpiStatusMessage: String
    @Published var spoofdpiStatusStyle: SettingsBadgeStyle = .neutral
    @Published var ciadpiStatusMessage: String
    @Published var ciadpiStatusStyle: SettingsBadgeStyle = .neutral
    @Published var isCheckingSpoofdpi = false
    @Published var isUpdatingSpoofdpi = false
    @Published var isUpdatingCiadpi = false
    @Published var isActivatingSystemExtension = false

    @Published private var flagsByEngine: [BypassEngine: Set<String>]
    @Published private var spoofdpiStatus: SpoofdpiUpdateStatus?
    @Published private var vpnAvailabilityIssue: String?
    @Published private var tunnelActive: Bool

    let backendSelections: [BackendSelection] = [.automatic, .ciadpi, .spoofdpi, .custom]
    let splitModes = ["sni", "random", "chunk", "none"]
    let dnsModes = ["udp", "https", "system"]
    let options: [SettingsArgumentOption] = [
        SettingsArgumentOption(flag: "--system-proxy", description: L10n.shared.descSystemProxy),
        SettingsArgumentOption(flag: "--silent", description: L10n.shared.descSilent),
        SettingsArgumentOption(flag: "--dns-ipv4-only", description: L10n.shared.descIpv4Only),
        SettingsArgumentOption(flag: "--debug", description: L10n.shared.descDebug),
        SettingsArgumentOption(flag: "--policy-auto", description: L10n.shared.descPolicyAuto)
    ]

    private let store: SettingsStore
    private let updater: SpoofdpiUpdater

    init(
        store: SettingsStore = .shared,
        updater: SpoofdpiUpdater = .shared,
        tunnelManager: TunnelManager = .shared,
        systemExtensionManager: SystemExtensionManager = .shared
    ) {
        self.store = store
        self.updater = updater

        let draft = store.loadDraft()
        backendSelection = draft.backendSelection
        customBinaryPath = draft.customPath
        defaultTTL = draft.common.defaultTTL
        splitMode = draft.common.splitMode
        httpsDisorder = draft.common.httpsDisorder
        httpsFakeCount = draft.common.httpsFakeCount
        httpsChunkSize = draft.common.httpsChunkSize
        localPort = draft.common.localPort
        dnsAddr = draft.common.dnsAddr
        dnsMode = draft.common.dnsMode
        dnsHttpsUrl = draft.common.dnsHttpsUrl
        launchAtLogin = draft.common.launchAtLogin
        autoUpdate = draft.common.autoUpdate
        autoDownload = draft.common.autoDownload
        disableIpv6 = draft.common.disableIpv6
        autoReconnect = draft.common.autoReconnect
        vpnModeEnabled = draft.common.vpnModeEnabled
        ciadpiManualArgs = draft.ciadpi.manualArgs
        spoofdpiManualArgs = draft.spoofdpi.manualArgs
        flagsByEngine = [
            .ciadpi: draft.ciadpi.selectedFlags,
            .spoofdpi: draft.spoofdpi.selectedFlags
        ]
        spoofdpiStatusMessage = store.managedSpoofdpiPath.isEmpty ? L10n.shared.spoofdpiManagedMissing : L10n.shared.spoofdpiReady
        ciadpiStatusMessage = FileManager.default.isExecutableFile(atPath: store.managedCiadpiPath)
            ? (L10n.shared.isRussian ? "ciadpi установлен." : "ciadpi is installed.")
            : (L10n.shared.isRussian ? "Managed ciadpi не установлен." : "Managed ciadpi is not installed.")
        vpnAvailabilityIssue = systemExtensionManager.availabilityIssue()
        tunnelActive = tunnelManager.isActive

        refreshCiadpiLocalStatus()
        refreshSpoofdpiLocalStatus()
    }

    var resolvedBinaryPath: String {
        store.resolvedBinaryPath(for: backendSelection, customPath: customBinaryPath)
    }

    var resolvedEngine: BypassEngine {
        store.currentEngine(for: resolvedBinaryPath)
    }

    var dnsAvailable: Bool {
        BackendCapability.forEngine(resolvedEngine).supportsDNS
    }

    var chunkSizeAvailable: Bool {
        BackendCapability.forEngine(resolvedEngine).supportsChunkSize
    }

    var vpnAvailable: Bool {
        vpnAvailabilityIssue == nil
    }

    var backendSummary: String {
        let path = resolvedBinaryPath
        let pathState = FileManager.default.fileExists(atPath: path)
            ? URL(fileURLWithPath: path).lastPathComponent
            : L10n.shared.backendMissingSuffix
        return "\(resolvedEngine.displayName) • \(resolvedEngine.proxyDescription) • \(pathState)"
    }

    var backendPathLabel: String {
        backendSelection == .custom
            ? text(ru: "Custom path:", en: "Custom path:")
            : text(ru: "Resolved path:", en: "Resolved path:")
    }

    var proxyModeTitle: String {
        "\(resolvedEngine.displayName) • \(resolvedEngine.proxyDescription)"
    }

    var runtimeStatusTitle: String {
        if vpnModeEnabled {
            return tunnelActive ? L10n.shared.runtimeModeVpn : L10n.shared.vpnStatusReady
        }
        return L10n.shared.runtimeModeProxy
    }

    var runtimeBadgeStyle: SettingsBadgeStyle {
        vpnModeEnabled && !vpnAvailable ? .warning : .neutral
    }

    var vpnStatusTitle: String {
        if let vpnAvailabilityIssue {
            return vpnAvailabilityIssue
        }
        if vpnModeEnabled {
            return tunnelActive ? L10n.shared.runtimeModeVpn : L10n.shared.vpnStatusReady
        }
        return L10n.shared.vpnStatusDisabled
    }

    var vpnBadgeStyle: SettingsBadgeStyle {
        if vpnAvailabilityIssue != nil {
            return .warning
        }
        return vpnModeEnabled ? .success : .neutral
    }

    var spoofdpiSelectedPath: String {
        compactPath(spoofdpiStatus?.selectedPath ?? resolvedBinaryPath)
    }

    var spoofdpiManagedPath: String {
        compactPath(spoofdpiStatus?.managedPath ?? store.managedSpoofdpiPath)
    }

    var spoofdpiManagedVersion: String {
        spoofdpiStatus?.managedVersion ?? L10n.shared.versionUnknown
    }

    var spoofdpiLatestVersion: String {
        spoofdpiStatus?.latestVersion ?? L10n.shared.versionUnknown
    }

    var canUpdateSpoofdpi: Bool {
        spoofdpiStatus?.updateAvailable == true && spoofdpiStatus?.downloadURL != nil
    }

    var ciadpiSelectedPath: String {
        let path = resolvedEngine == .ciadpi ? resolvedBinaryPath : store.resolvedBinaryPath(for: .ciadpi)
        return compactPath(path)
    }

    var ciadpiManagedPath: String {
        compactPath(store.managedCiadpiPath)
    }

    var ciadpiManagedVersion: String {
        ciadpiVersion(at: store.managedCiadpiPath) ?? L10n.shared.versionUnknown
    }

    var compatibilityBadges: [SettingsCompatibilityBadge] {
        [
            SettingsCompatibilityBadge(title: text(ru: "Backend: \(resolvedEngine.displayName)", en: "Backend: \(resolvedEngine.displayName)"), style: .neutral),
            SettingsCompatibilityBadge(title: text(ru: "Proxy: \(resolvedEngine.proxyDescription)", en: "Proxy: \(resolvedEngine.proxyDescription)"), style: .neutral),
            SettingsCompatibilityBadge(
                title: FileManager.default.fileExists(atPath: resolvedBinaryPath) ? text(ru: "Binary: найден", en: "Binary: found") : text(ru: "Binary: не найден", en: "Binary: missing"),
                style: FileManager.default.fileExists(atPath: resolvedBinaryPath) ? .success : .warning
            ),
            SettingsCompatibilityBadge(
                title: dnsAvailable ? text(ru: "DNS: SpoofDPI", en: "DNS: SpoofDPI") : text(ru: "DNS: системный", en: "DNS: system"),
                style: dnsAvailable ? .success : .neutral
            ),
            SettingsCompatibilityBadge(
                title: chunkSizeAvailable ? text(ru: "Chunk size: доступен", en: "Chunk size: available") : text(ru: "Chunk size: только spoofdpi", en: "Chunk size: spoofdpi only"),
                style: chunkSizeAvailable ? .success : .neutral
            )
        ]
    }

    var commandPreview: String {
        ([resolvedBinaryPath] + buildLaunchArguments()).map(shellQuoted).joined(separator: " ")
    }

    var ciadpiFakeEnabled: Bool {
        get { clamp(httpsFakeCount, defaultValue: 0, range: 0...100) > 0 }
        set { httpsFakeCount = newValue ? "1" : "0" }
    }

    var canSave: Bool {
        validationIssue == nil
    }

    var footerStatusText: String? {
        validationIssue ?? footerStatus
    }

    func title(for selection: BackendSelection) -> String {
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

    func backendSelectionChanged() {
        guard backendSelection != .custom else { return }
        customBinaryPath = store.resolvedBinaryPath(for: backendSelection, customPath: customBinaryPath)
        refreshCiadpiLocalStatus()
        refreshSpoofdpiLocalStatus()
    }

    func optionTitle(_ flag: String) -> String {
        switch flag {
        case "--system-proxy":
            return text(ru: "Системный proxy", en: "System proxy")
        case "--silent":
            return text(ru: "Тихий запуск", en: "Silent startup")
        case "--dns-ipv4-only":
            return text(ru: "DNS только IPv4", en: "DNS IPv4 only")
        case "--debug":
            return text(ru: "Debug logs", en: "Debug logs")
        case "--policy-auto":
            return text(ru: "Adaptive policy", en: "Adaptive policy")
        default:
            return flag
        }
    }

    func flagEnabled(_ flag: String) -> Bool {
        selectedFlags(for: resolvedEngine).contains(flag)
    }

    func setFlag(_ flag: String, enabled: Bool) {
        guard flagSupported(flag) else { return }
        var flags = selectedFlags(for: resolvedEngine)
        if enabled {
            flags.insert(flag)
        } else {
            flags.remove(flag)
        }
        flagsByEngine[resolvedEngine] = flags
    }

    func flagSupported(_ flag: String) -> Bool {
        BackendCapability.forEngine(resolvedEngine).supports(flag: flag)
    }

    func unsupportedReason(for flag: String) -> String {
        switch flag {
        case "--policy-auto":
            return text(ru: "Только ciadpi.", en: "ciadpi only.")
        case "--silent", "--dns-ipv4-only", "--debug":
            return text(ru: "Только spoofdpi.", en: "spoofdpi only.")
        default:
            return text(ru: "Недоступно для выбранного backend.", en: "Unavailable for the selected backend.")
        }
    }

    func applyMobilePreset() {
        selectedPreset = .hotspot
        applyPreset(.hotspot)
    }

    func applyPreset(_ preset: SettingsPreset) {
        switch preset {
        case .balanced:
            defaultTTL = "128"
            splitMode = "random"
            httpsDisorder = true
            httpsFakeCount = "0"
            httpsChunkSize = "20"
        case .hotspot:
            defaultTTL = "65"
            splitMode = "random"
            httpsDisorder = true
            httpsFakeCount = resolvedEngine == .ciadpi ? "1" : "0"
            httpsChunkSize = "20"
        case .conservative:
            defaultTTL = "128"
            splitMode = "sni"
            httpsDisorder = false
            httpsFakeCount = "0"
            httpsChunkSize = "20"
        }
        footerStatus = text(ru: "\(preset.title) применён.", en: "\(preset.title) applied.")
    }

    func refreshRuntimeStatus() {
        vpnAvailabilityIssue = SystemExtensionManager.shared.availabilityIssue()
        tunnelActive = TunnelManager.shared.isActive
        if !vpnAvailable, vpnModeEnabled {
            vpnModeEnabled = false
        }
    }

    func ensureSystemExtensionActivated() {
        isActivatingSystemExtension = true
        footerStatus = L10n.shared.diagChecking
        SystemExtensionManager.shared.ensureActivated { [weak self] success, message, disableToggle in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isActivatingSystemExtension = false
                if disableToggle {
                    self.vpnModeEnabled = false
                }
                self.vpnAvailabilityIssue = SystemExtensionManager.shared.availabilityIssue()
                self.footerStatus = message ?? (success ? L10n.shared.vpnStatusReady : L10n.shared.vpnStatusUnavailable)
            }
        }
    }

    func refreshSpoofdpiLocalStatus() {
        let status = updater.localStatus(selectedPath: resolvedBinaryPath)
        spoofdpiStatus = status
        if status.managedVersion == nil {
            spoofdpiStatusMessage = L10n.shared.spoofdpiManagedMissing
            spoofdpiStatusStyle = .warning
        } else {
            spoofdpiStatusMessage = L10n.shared.spoofdpiReady
            spoofdpiStatusStyle = .neutral
        }
    }

    func refreshCiadpiLocalStatus() {
        if FileManager.default.isExecutableFile(atPath: store.managedCiadpiPath) {
            ciadpiStatusMessage = text(ru: "ciadpi установлен.", en: "ciadpi is installed.")
            ciadpiStatusStyle = .neutral
        } else {
            ciadpiStatusMessage = text(ru: "Managed ciadpi не установлен.", en: "Managed ciadpi is not installed.")
            ciadpiStatusStyle = .warning
        }
    }

    func checkSpoofdpiVersion() {
        isCheckingSpoofdpi = true
        spoofdpiStatusMessage = L10n.shared.spoofdpiChecking
        spoofdpiStatusStyle = .neutral
        updater.checkStatus(selectedPath: resolvedBinaryPath) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isCheckingSpoofdpi = false
                switch result {
                case .success(let status):
                    self.spoofdpiStatus = status
                    self.spoofdpiStatusMessage = status.updateAvailable ? L10n.shared.spoofdpiUpdateReady : L10n.shared.spoofdpiReady
                    self.spoofdpiStatusStyle = status.updateAvailable ? .warning : .success
                case .failure(let error):
                    self.spoofdpiStatusMessage = L10n.shared.spoofdpiCheckFailed
                    self.spoofdpiStatusStyle = .warning
                    AppLogger.log("SpoofDPI SwiftUI update check failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func updateSpoofdpi() {
        isUpdatingSpoofdpi = true
        spoofdpiStatusMessage = L10n.shared.spoofdpiUpdating
        spoofdpiStatusStyle = .neutral
        updater.installLatest { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isUpdatingSpoofdpi = false
                switch result {
                case .success(let status):
                    self.spoofdpiStatus = status
                    self.spoofdpiStatusMessage = L10n.shared.spoofdpiUpdated
                    self.spoofdpiStatusStyle = .success
                case .failure(let error):
                    self.spoofdpiStatusMessage = L10n.shared.spoofdpiUpdateFailed
                    self.spoofdpiStatusStyle = .warning
                    AppLogger.log("SpoofDPI SwiftUI update failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func updateCiadpi() {
        isUpdatingCiadpi = true
        ciadpiStatusMessage = text(ru: "Обновление ciadpi...", en: "Updating ciadpi...")
        ciadpiStatusStyle = .neutral
        DPIKillerManager.shared.install { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isUpdatingCiadpi = false
                if success {
                    self.refreshCiadpiLocalStatus()
                    self.refreshSpoofdpiLocalStatus()
                    self.ciadpiStatusMessage = self.text(ru: "ciadpi обновлён.", en: "ciadpi was updated.")
                    self.ciadpiStatusStyle = .success
                } else {
                    self.ciadpiStatusMessage = error ?? self.text(ru: "Не удалось обновить ciadpi.", en: "Could not update ciadpi.")
                    self.ciadpiStatusStyle = .warning
                }
            }
        }
    }

    func save() {
        guard canSave else { return }
        let sanitizedCommon = CommonSettings(
            localPort: String(clamp(localPort, defaultValue: 8080, range: 1...65535)),
            defaultTTL: String(clamp(defaultTTL, defaultValue: 128, range: 1...255)),
            splitMode: splitMode.isEmpty ? "sni" : splitMode,
            httpsDisorder: httpsDisorder,
            httpsFakeCount: String(clamp(httpsFakeCount, defaultValue: 0, range: 0...100)),
            httpsChunkSize: String(clamp(httpsChunkSize, defaultValue: 20, range: 1...1000)),
            dnsAddr: dnsAddr.trimmingCharacters(in: .whitespacesAndNewlines),
            dnsMode: dnsMode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "udp" : dnsMode.trimmingCharacters(in: .whitespacesAndNewlines),
            dnsHttpsUrl: dnsHttpsUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            launchAtLogin: launchAtLogin,
            autoUpdate: autoUpdate,
            autoDownload: autoDownload,
            disableIpv6: disableIpv6,
            autoReconnect: autoReconnect,
            vpnModeEnabled: vpnModeEnabled && vpnAvailable
        )
        let draft = SettingsDraft(
            backendSelection: backendSelection,
            customPath: customBinaryPath,
            common: sanitizedCommon,
            ciadpi: EngineSettings(
                selectedFlags: selectedFlags(for: .ciadpi).intersection(BackendCapability.forEngine(.ciadpi).supportedFlags),
                manualArgs: ciadpiManualArgs
            ),
            spoofdpi: EngineSettings(
                selectedFlags: selectedFlags(for: .spoofdpi).intersection(BackendCapability.forEngine(.spoofdpi).supportedFlags),
                manualArgs: spoofdpiManualArgs
            )
        )
        store.saveDraft(draft)

        localPort = sanitizedCommon.localPort
        defaultTTL = sanitizedCommon.defaultTTL
        httpsFakeCount = sanitizedCommon.httpsFakeCount
        httpsChunkSize = sanitizedCommon.httpsChunkSize
        dnsAddr = sanitizedCommon.dnsAddr
        dnsMode = sanitizedCommon.dnsMode
        dnsHttpsUrl = sanitizedCommon.dnsHttpsUrl
        vpnModeEnabled = sanitizedCommon.vpnModeEnabled
        refreshSpoofdpiLocalStatus()
        refreshRuntimeStatus()
        footerStatus = text(ru: "Настройки сохранены.", en: "Settings saved.")
    }

    func manualWarning(for engine: BypassEngine) -> String? {
        let manual = manualArgs(for: engine)
        let duplicates = store.duplicateManagedFlags(in: manual)
        if !duplicates.isEmpty {
            return text(ru: "Дубли managed flags: \(duplicates.joined(separator: ", "))", en: "Duplicate managed flags: \(duplicates.joined(separator: ", "))")
        }
        let unsupported = store.unsupportedManualArgs(manual, for: engine)
        if !unsupported.isEmpty {
            return text(ru: "Недоступно для \(engine.displayName): \(unsupported.joined(separator: ", "))", en: "Unavailable for \(engine.displayName): \(unsupported.joined(separator: ", "))")
        }
        return nil
    }

    private var validationIssue: String? {
        if Int(localPort.trimmingCharacters(in: .whitespacesAndNewlines)) == nil {
            return text(ru: "Порт должен быть числом.", en: "Port must be numeric.")
        }
        if Int(defaultTTL.trimmingCharacters(in: .whitespacesAndNewlines)) == nil {
            return text(ru: "TTL должен быть числом.", en: "TTL must be numeric.")
        }
        if backendSelection == .custom, customBinaryPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text(ru: "Укажи путь к backend.", en: "Select a backend path.")
        }
        if manualWarning(for: .ciadpi) != nil || manualWarning(for: .spoofdpi) != nil {
            return text(ru: "В Manual есть конфликтующие аргументы.", en: "Manual args contain incompatible flags.")
        }
        return nil
    }

    private func selectedFlags(for engine: BypassEngine) -> Set<String> {
        flagsByEngine[engine] ?? []
    }

    private func manualArgs(for engine: BypassEngine) -> String {
        switch engine {
        case .ciadpi:
            return ciadpiManualArgs
        case .spoofdpi:
            return spoofdpiManualArgs
        }
    }

    private func buildLaunchArguments() -> [String] {
        let engine = resolvedEngine
        let manualParts = argumentParts(from: manualArgs(for: engine))
        let flags = selectedFlags(for: engine).intersection(BackendCapability.forEngine(engine).supportedFlags)
        let port = clamp(localPort, defaultValue: 8080, range: 1...65535)
        let ttlValue = clamp(defaultTTL, defaultValue: 128, range: 1...255)
        let fakeCount = clamp(httpsFakeCount, defaultValue: 0, range: 0...100)
        let chunkSize = clamp(httpsChunkSize, defaultValue: 20, range: 1...1000)

        switch engine {
        case .spoofdpi:
            var args: [String] = []
            if spoofdpiSupportsHeadlessMode(binaryPath: resolvedBinaryPath) {
                args.append("--no-tui")
            }
            if flags.contains("--silent") { args.append("--silent") }
            if flags.contains("--dns-ipv4-only") { args += ["--dns-qtype", "ipv4"] }
            if flags.contains("--debug") { args += ["--log-level", "debug"] }
            args += ["--default-fake-ttl", "\(ttlValue)"]
            if !splitMode.isEmpty && splitMode != "sni" {
                args += ["--https-split-mode", splitMode]
            }
            if httpsDisorder {
                args.append("--https-disorder")
            }
            if fakeCount > 0 {
                args += ["--https-fake-count", "\(fakeCount)"]
            }
            if chunkSize > 0 {
                args += ["--https-chunk-size", "\(chunkSize)"]
            }
            args += ["--listen-addr", "127.0.0.1:\(port)"]

            let spoofDNSMode = normalizedSpoofdpiDNSMode(dnsMode)
            let trimmedDNS = dnsAddr.trimmingCharacters(in: .whitespacesAndNewlines)
            if spoofDNSMode != "system", !trimmedDNS.isEmpty {
                args += ["--dns-addr", trimmedDNS]
            }
            args += ["--dns-mode", spoofDNSMode]

            let trimmedDoH = dnsHttpsUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            if spoofDNSMode == "https", !trimmedDoH.isEmpty {
                args += ["--dns-https-url", trimmedDoH]
            }
            return args + manualParts
        case .ciadpi:
            var args: [String] = ["-p", "\(port)", "--def-ttl", "\(ttlValue)"]
            if flags.contains("--policy-auto") {
                args += ["--auto", "torst"]
            }
            switch splitMode {
            case "sni":
                args += ["--split", "1+s"]
            case "chunk":
                args += ["--tlsrec", "1+s"]
            case "random":
                if !args.contains("--auto") {
                    args += ["--auto", "torst"]
                }
                args += ["--tlsrec", "1+s"]
            default:
                break
            }
            if httpsDisorder {
                args += ["--disorder", "1"]
            }
            if fakeCount > 0 {
                args += ["--fake", "-1", "--ttl", "8"]
            }
            return args + manualParts
        }
    }

    private func normalizedSpoofdpiDNSMode(_ value: String) -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "", "udp":
            return "udp"
        case "https", "doh":
            return "https"
        case "system", "sys":
            return "system"
        default:
            return "udp"
        }
    }

    private func spoofdpiSupportsHeadlessMode(binaryPath: String) -> Bool {
        guard FileManager.default.isExecutableFile(atPath: binaryPath) else { return false }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["--version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return false }
            let pattern = #"spoofdpi\s+(\d+)\.(\d+)\.(\d+)"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                  let majorRange = Range(match.range(at: 1), in: output),
                  let minorRange = Range(match.range(at: 2), in: output),
                  let major = Int(output[majorRange]),
                  let minor = Int(output[minorRange]) else {
                return false
            }
            return major > 1 || (major == 1 && minor >= 4)
        } catch {
            return false
        }
    }

    private func ciadpiVersion(at path: String) -> String? {
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

    private func argumentParts(from string: String) -> [String] {
        string.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }

    private func compactPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func shellQuoted(_ value: String) -> String {
        guard !value.isEmpty else { return "''" }
        let safe = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_+-=./:@")
        if value.rangeOfCharacter(from: safe.inverted) == nil {
            return value
        }
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func clamp(_ value: String, defaultValue: Int, range: ClosedRange<Int>) -> Int {
        let parsed = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? defaultValue
        return min(max(parsed, range.lowerBound), range.upperBound)
    }

    private func text(ru: String, en: String) -> String {
        L10n.shared.isRussian ? ru : en
    }
}
