import AppKit
import Combine
import SwiftUI

enum DPISettingsTokens {
    static let sidebarWidth: CGFloat = 176
    static let footerHeight: CGFloat = 58
    static let contentPadding: CGFloat = 18
    static let shellPadding: CGFloat = 10
    static let cardPadding: CGFloat = 14
    static let rowLabelWidth: CGFloat = 132
    static let controlHeight: CGFloat = 28
    static let cornerRadius: CGFloat = 8
    static let sidebarCornerRadius: CGFloat = 12
    static let rowSpacing: CGFloat = 12
    static let cardSpacing: CGFloat = 20

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
    static let labelFont = Font.system(size: 13, weight: .regular)
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
            .foregroundStyle(.primary)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(style.color.opacity(0.12)))
    }
}

struct SettingsSidebar: View {
    @Binding var selectedTab: SettingsTab

    var body: some View {
        List(selection: $selectedTab) {
            ForEach(SettingsTab.allCases) { tab in
                Label(tab.title, systemImage: tab.systemImage)
                    .tag(tab)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .padding(.top, 8)
        .frame(width: DPISettingsTokens.sidebarWidth)
    }
}

struct SettingsMaterialBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
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
    let showsSurface: Bool
    @ViewBuilder let content: Content

    init(title: String, subtitle: String? = nil, showsSurface: Bool = true, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.showsSurface = showsSurface
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

            VStack(alignment: .leading, spacing: DPISettingsTokens.rowSpacing) {
                content
            }
            .padding(showsSurface ? DPISettingsTokens.cardPadding : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if showsSurface {
                    RoundedRectangle(cornerRadius: DPISettingsTokens.cornerRadius)
                        .fill(DPISettingsTokens.surface)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(DPISettingsTokens.labelFont)
                .foregroundStyle(.primary)
                .frame(width: DPISettingsTokens.rowLabelWidth, alignment: .leading)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 3) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .help(help ?? "")
    }
}

struct SettingsFooter: View {
    let statusText: String?

    var body: some View {
        HStack(spacing: 10) {
            if let statusText, !statusText.isEmpty {
                Text(statusText)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
                    .lineLimit(1)
                    .help(statusText)
            }

            Spacer(minLength: 12)

        }
        .padding(.horizontal, 14)
        .frame(height: DPISettingsTokens.footerHeight)
        .background(DPISettingsTokens.background)
    }
}

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    private let onCancel: (() -> Void)?

    init(
        viewModel: SettingsViewModel = SettingsViewModel(),
        onCancel: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.selectedTab.title)
                .font(DPISettingsTokens.titleFont)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 0) {
                SettingsSidebar(selectedTab: $viewModel.selectedTab)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: DPISettingsTokens.cardSpacing) {
                        tabContent
                            .disabled(viewModel.isApplyingSettings)
                    }
                    .id(viewModel.selectedTab)
                    .padding(DPISettingsTokens.contentPadding)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .background(DPISettingsTokens.background)
            }

            Divider()

            SettingsFooter(
                statusText: viewModel.footerStatusText
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SettingsMaterialBackground().ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .top)
        .onExitCommand {
            viewModel.save()
            cancel()
        }
        .onAppear {
            viewModel.refreshRuntimeStatus()
            viewModel.refreshEngineVersionsIfNeeded()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .backend:
            backendTab
        case .network:
            networkTab
            bypassTab
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
                title: L10n.shared.sectionCore
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker(L10n.shared.backendModeTitle, selection: $viewModel.backendSelection) {
                        ForEach(viewModel.backendSelections, id: \.self) { selection in
                            Text(viewModel.title(for: selection)).tag(selection)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: viewModel.backendSelection) { _ in
                        viewModel.backendSelectionChanged()
                    }
                }

                if !FileManager.default.isExecutableFile(atPath: viewModel.resolvedBinaryPath) {
                    Text(L10n.shared.backendMissingSuffix)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(DPISettingsTokens.warning)
                }
                pathText(viewModel.resolvedBinaryPath)

            }

            SettingsCard(title: text(ru: "Обновления движков", en: "Engine Updates")) {
                ciadpiMaintenanceCard
                Divider()
                spoofdpiVersionCard
            }
        }
    }

    private var networkTab: some View {
        SettingsCard(
            title: text(ru: "Подключение", en: "Connection")
        ) {
            SettingsRow(L10n.shared.portTitle, help: L10n.shared.tipLocalPort) {
                TextField(L10n.shared.portPlaceholder, text: $viewModel.localPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
            }

            SettingsRow(L10n.shared.runtimeModeTitle) {
                Text("\(viewModel.proxyModeTitle) · \(viewModel.runtimeStatusTitle)")
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Toggle(L10n.shared.descSystemProxy, isOn: $viewModel.systemProxyEnabled)
                .toggleStyle(.checkbox)

            if NetworkSettingsClient.shared.isSupported, NetworkSettingsClient.shared.needsApproval {
                Button(text(ru: "Разрешить сетевой помощник в macOS", en: "Approve network helper in macOS")) {
                    NetworkSettingsClient.shared.openApprovalSettings()
                }
                .buttonStyle(.bordered)
            }

            Text(L10n.shared.systemProxyModeHelp)
                .font(DPISettingsTokens.captionFont)
                .foregroundStyle(DPISettingsTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if !viewModel.systemProxyEnabled {
                Text(text(ru: "Локальный режим: подключи приложение к прокси вручную или через Shadowrocket. Настройки macOS не меняются.", en: "Local mode: connect an app to the proxy manually or through Shadowrocket. macOS settings stay unchanged."))
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SettingsRow(L10n.shared.hotspotStatusTitle) {
                HStack(spacing: 8) {
                    Text(viewModel.networkOptimizationStatusTitle)
                        .font(DPISettingsTokens.captionFont)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                    if viewModel.isApplyingNetworkOptimization {
                        ProgressView().controlSize(.small)
                    } else {
                        Button(text(ru: "Оптимизация сети", en: "Optimize Network")) {
                            viewModel.applyNetworkOptimization()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.needsNetworkOptimization)
                        .help(text(ru: "Установить TTL 65 для раздачи интернета. macOS запросит пароль администратора.", en: "Set TTL to 65 for hotspot use. macOS will request administrator access."))
                    }
                }
            }
        }
    }

    private var bypassTab: some View {
        SettingsCard(
            title: L10n.shared.sectionDPI
        ) {
            SettingsRow(text(ru: "Пресет", en: "Preset")) {
                Picker("", selection: $viewModel.selectedPreset) {
                    Text(text(ru: "Свои настройки", en: "Custom settings")).tag(Optional<SettingsPreset>.none)
                    ForEach(SettingsPreset.allCases) { preset in
                        Text(preset.title).tag(Optional(preset))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(viewModel.presetSummary)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
            ForEach(viewModel.options.filter { viewModel.flagSupported($0.flag) }) { option in
                SettingsRow(viewModel.optionTitle(option.flag), help: option.description) {
                    Toggle(viewModel.optionTitle(option.flag), isOn: Binding(
                        get: { viewModel.flagEnabled(option.flag) },
                        set: { viewModel.setFlag(option.flag, enabled: $0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                    .help(option.description)
                }
            }
            Divider()

            if viewModel.resolvedEngine == .ciadpi {
                SettingsRow(L10n.shared.ttlTitle, help: L10n.shared.tipTTL) {
                    TextField(L10n.shared.ttlPlaceholder, text: $viewModel.defaultTTL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }
            }

            SettingsRow(L10n.shared.splitModeTitle, help: L10n.shared.tipSplitMode) {
                Picker("", selection: $viewModel.splitMode) {
                    ForEach(viewModel.splitModes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .frame(minWidth: 160, alignment: .leading)
            }

            SettingsRow(L10n.shared.httpsDisorder, help: text(ru: "Отправлять фрагменты HTTPS в изменённом порядке для обхода DPI.", en: "Send HTTPS fragments out of order to bypass DPI.")) {
                Toggle("", isOn: $viewModel.httpsDisorder)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
            }

            if viewModel.resolvedEngine == .spoofdpi {
                SettingsRow(L10n.shared.httpsFakeCount, help: L10n.shared.tipFakeCount) {
                    TextField("0", text: $viewModel.httpsFakeCount)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }
            }

            if viewModel.chunkSizeAvailable {
                SettingsRow(L10n.shared.httpsChunkSize, help: L10n.shared.tipChunkSize) {
                    TextField(L10n.shared.httpsChunkPlaceholder, text: $viewModel.httpsChunkSize)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }
            }
        }
    }

    private var dnsTab: some View {
        SettingsCard(
            title: L10n.shared.sectionDNS
        ) {
            if !viewModel.dnsAvailable {
                Text(L10n.shared.dnsDisabledForCiadpi)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(DPISettingsTokens.secondaryText)
            } else {
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
                    .fixedSize()
                    .frame(minWidth: 160, alignment: .leading)
                }

                SettingsRow(L10n.shared.dnsHttpsTitle) {
                    TextField("https://dns.google/dns-query", text: $viewModel.dnsHttpsUrl)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!viewModel.dnsAvailable || viewModel.dnsMode != "https")
                }
            }
        }
    }

    private var appTab: some View {
        VStack(alignment: .leading, spacing: DPISettingsTokens.cardSpacing) {
            SettingsCard(title: L10n.shared.sectionApp) {
                appToggle(title: L10n.shared.launchAtLogin, isOn: $viewModel.launchAtLogin)
                appToggle(title: L10n.shared.autoUpdateToggle, isOn: $viewModel.autoUpdate)
                appToggle(title: L10n.shared.autoDownloadToggle, isOn: $viewModel.autoDownload)
            }

            SettingsCard(title: text(ru: "Подключение", en: "Connection")) {
                appToggle(title: L10n.shared.autoReconnect, help: L10n.shared.tipAutoReconnect, isOn: $viewModel.autoReconnect)

                Button(viewModel.isConfiguringShadowrocket ? L10n.shared.configuringShadowrocket : L10n.shared.configureShadowrocket) {
                    viewModel.configureShadowrocket()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isConfiguringShadowrocket || viewModel.isApplyingNetworkOptimization)

            }
        }
    }

    private var ciadpiMaintenanceCard: some View {
        engineMaintenanceRow(
            name: "ciadpi", version: viewModel.ciadpiManagedVersion,
            latest: viewModel.ciadpiLatestVersion, path: viewModel.ciadpiManagedPath,
            message: viewModel.ciadpiStatusMessage, style: viewModel.ciadpiStatusStyle,
            busy: viewModel.isCheckingCiadpi || viewModel.isUpdatingCiadpi,
            canUpdate: viewModel.canUpdateCiadpi,
            check: viewModel.checkCiadpiVersion, update: viewModel.updateCiadpi
        )
    }

    private var manualTab: some View {
        VStack(alignment: .leading, spacing: DPISettingsTokens.cardSpacing) {
            SettingsCard(
                title: "ciadpi", showsSurface: false
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
                title: "SpoofDPI", showsSurface: false
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
                title: text(ru: "Команда запуска", en: "Launch Command"), showsSurface: false
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
        engineMaintenanceRow(
            name: "SpoofDPI", version: viewModel.spoofdpiManagedVersion,
            latest: viewModel.spoofdpiLatestVersion, path: viewModel.spoofdpiManagedPath,
            message: viewModel.spoofdpiStatusMessage, style: viewModel.spoofdpiStatusStyle,
            busy: viewModel.isCheckingSpoofdpi || viewModel.isUpdatingSpoofdpi,
            canUpdate: viewModel.canUpdateSpoofdpi,
            check: viewModel.checkSpoofdpiVersion, update: viewModel.updateSpoofdpi
        )
    }

    private func engineMaintenanceRow(
        name: String, version: String, latest: String, path: String,
        message: String, style: SettingsBadgeStyle, busy: Bool, canUpdate: Bool,
        check: @escaping () -> Void, update: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(name).font(DPISettingsTokens.bodyFont)
                Text(version).font(DPISettingsTokens.captionFont).foregroundStyle(.secondary)
                Spacer()
                if busy { ProgressView().controlSize(.small) }
                Text(canUpdate
                     ? text(ru: "Доступна \(latest)", en: "\(latest) available")
                     : message)
                    .font(DPISettingsTokens.captionFont)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if !busy && !canUpdate && style != .success {
                    Button(action: check) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help(text(ru: "Повторить проверку обновлений", en: "Retry checking for updates"))
                    .accessibilityLabel(text(ru: "Проверить обновления \(name)", en: "Check for \(name) updates"))
                }
                if canUpdate {
                    Button(text(ru: "Обновить", en: "Update"), action: update)
                        .disabled(busy)
                }
            }
            .buttonStyle(.bordered)
            pathText(path)
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
        .help(help ?? "")
    }

    private func pathText(_ value: String) -> some View {
        let path = (value as NSString).expandingTildeInPath
        return HStack(spacing: 8) {
            Text(value)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(DPISettingsTokens.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .help(path)
            Spacer(minLength: 0)
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .help(text(ru: "Показать движок в Finder", en: "Show engine in Finder"))
            .accessibilityLabel(text(ru: "Показать движок в Finder", en: "Show engine in Finder"))
            .disabled(!FileManager.default.fileExists(atPath: path))
        }
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
    var selectedPreset: SettingsPreset? {
        get {
            SettingsPreset.allCases.first {
                let values = $0.parameters
                return defaultTTL == values.ttl && splitMode == values.split
                    && httpsDisorder == values.disorder && httpsFakeCount == values.fakes && httpsChunkSize == values.chunk
            }
        }
        set { if let newValue { applyPreset(newValue) } }
    }

    var presetSummary: String {
        selectedPreset?.summary(for: resolvedEngine)
            ?? text(ru: "Параметры изменены вручную и не совпадают с пресетом.", en: "These parameters were changed manually and do not match a preset.")
    }
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
    @Published var systemProxyEnabled: Bool
    @Published var vpnClientCompatibilityEnabled: Bool
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
    @Published var isCheckingCiadpi = false
    @Published var isUpdatingCiadpi = false
    @Published var isActivatingSystemExtension = false
    @Published var isApplyingNetworkOptimization = false
    @Published var isConfiguringShadowrocket = false

    @Published private var flagsByEngine: [BypassEngine: Set<String>]
    @Published private var spoofdpiStatus: SpoofdpiUpdateStatus?
    @Published private var ciadpiStatus: CiadpiUpdateStatus?
    @Published private var vpnAvailabilityIssue: String?
    @Published private var tunnelActive: Bool
    @Published private var networkOptimizationApplied = false
    @Published private(set) var backendRunning = false
    @Published private var runtimePort: Int?
    @Published private var runtimeCiadpiPort: Int?

    let backendSelections: [BackendSelection] = [.ciadpi, .spoofdpi]
    let splitModes = ["sni", "random", "chunk", "none"]
    let dnsModes = ["udp", "https", "system"]
    let options: [SettingsArgumentOption] = [
        SettingsArgumentOption(flag: "--dns-ipv4-only", description: L10n.shared.descIpv4Only),
        SettingsArgumentOption(flag: "--debug", description: L10n.shared.descDebug),
        SettingsArgumentOption(flag: "--policy-auto", description: L10n.shared.descPolicyAuto)
    ]

    private let store: SettingsStore
    private let updater: SpoofdpiUpdater
    private let ciadpiUpdater: CiadpiUpdater
    private var settingsObservation: AnyCancellable?
    private var pendingApply: DispatchWorkItem?
    private var lastAppliedDraft: SettingsDraft
    @Published private(set) var isApplyingSettings = false

    init(
        store: SettingsStore = .shared,
        updater: SpoofdpiUpdater = .shared,
        ciadpiUpdater: CiadpiUpdater = .shared,
        tunnelManager: TunnelManager = .shared,
        systemExtensionManager: SystemExtensionManager = .shared
    ) {
        self.store = store
        self.updater = updater
        self.ciadpiUpdater = ciadpiUpdater

        let draft = store.loadDraft()
        lastAppliedDraft = draft
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
        systemProxyEnabled = draft.common.systemProxyEnabled
        vpnClientCompatibilityEnabled = draft.common.vpnClientCompatibilityEnabled
        vpnModeEnabled = draft.common.vpnModeEnabled
        ciadpiManualArgs = draft.ciadpi.manualArgs
        spoofdpiManualArgs = draft.spoofdpi.manualArgs
        flagsByEngine = [
            .ciadpi: draft.ciadpi.selectedFlags,
            .spoofdpi: draft.spoofdpi.selectedFlags
        ]
        spoofdpiStatusMessage = L10n.shared.isRussian ? "SpoofDPI установлен." : "SpoofDPI is installed."
        ciadpiStatusMessage = FileManager.default.isExecutableFile(atPath: store.managedCiadpiPath)
            ? (L10n.shared.isRussian ? "ciadpi установлен." : "ciadpi is installed.")
            : (L10n.shared.isRussian ? "Managed ciadpi не установлен." : "Managed ciadpi is not installed.")
        vpnAvailabilityIssue = systemExtensionManager.availabilityIssue()
        tunnelActive = tunnelManager.isActive
        networkOptimizationApplied = store.isNetworkOptimizationApplied()
        backendRunning = DPIKillerManager.shared.isRunning
        runtimePort = DPIKillerManager.shared.activePort
        runtimeCiadpiPort = DPIKillerManager.shared.activeCiadpiPort

        refreshCiadpiLocalStatus()
        refreshSpoofdpiLocalStatus()
        settingsObservation = objectWillChange.sink { [weak self] _ in
            self?.scheduleApply()
        }
    }

    var resolvedBinaryPath: String {
        store.resolvedBinaryPath(for: backendSelection, customPath: customBinaryPath)
    }

    var isDualSelection: Bool {
        backendSelection == .dual
    }

    var dualPaths: [(engine: BypassEngine, path: String)] {
        store.dualBinaryPaths()
    }

    var resolvedEngine: BypassEngine {
        store.currentEngine(for: resolvedBinaryPath)
    }

    private var ciadpiResolvedPath: String {
        resolvedEngine == .ciadpi ? resolvedBinaryPath : store.resolvedBinaryPath(for: .ciadpi)
    }

    var dnsAvailable: Bool {
        if isDualSelection {
            return true
        }
        return BackendCapability.forEngine(resolvedEngine).supportsDNS
    }

    var chunkSizeAvailable: Bool {
        if isDualSelection {
            return true
        }
        return BackendCapability.forEngine(resolvedEngine).supportsChunkSize
    }

    var vpnAvailable: Bool {
        vpnAvailabilityIssue == nil
    }

    var backendSummary: String {
        if isDualSelection {
            return "spoofdpi + ciadpi • HTTP+SOCKS"
        }
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
        if isDualSelection {
            return "spoofdpi + ciadpi • HTTP+SOCKS"
        }
        return resolvedEngine.displayName + " • " + resolvedEngine.proxyDescription
    }

    var runtimeStatusTitle: String {
        if DPIKillerManager.shared.runtimeStatus == .needsAttention { return L10n.shared.statusPartial }
        guard backendRunning else { return L10n.shared.statusStopped }
        let portSuffix = backendRunning ? " • Port \(runtimePort ?? DPIKillerManager.shared.proxyPort)" : ""
        return (SystemProxyController.shared.hasLease ? L10n.shared.runtimeModeProxy : L10n.shared.runtimeModeLocalProxy) + portSuffix
    }

    var runtimeBadgeStyle: SettingsBadgeStyle {
        vpnModeEnabled && !vpnAvailable ? .warning : .neutral
    }

    var needsNetworkOptimization: Bool { !networkOptimizationApplied }

    var networkOptimizationStatusTitle: String {
        networkOptimizationApplied ? L10n.shared.networkOptimizationActive : L10n.shared.networkOptimizationInactive
    }

    var networkOptimizationBadgeStyle: SettingsBadgeStyle {
        networkOptimizationApplied ? .success : .warning
    }

    var vpnStatusTitle: String {
        if vpnClientCompatibilityEnabled {
            return L10n.shared.runtimeModeLocalProxy
        }
        if let vpnAvailabilityIssue {
            return vpnAvailabilityIssue
        }
        if vpnModeEnabled {
            return tunnelActive ? L10n.shared.runtimeModeVpn : L10n.shared.vpnStatusReady
        }
        return L10n.shared.vpnStatusDisabled
    }

    var vpnBadgeStyle: SettingsBadgeStyle {
        if vpnClientCompatibilityEnabled {
            return .neutral
        }
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
        compactPath(ciadpiResolvedPath)
    }

    var ciadpiManagedPath: String {
        compactPath(store.managedCiadpiPath)
    }

    var ciadpiManagedVersion: String {
        ciadpiStatus?.managedVersion ?? L10n.shared.versionUnknown
    }

    var ciadpiLatestVersion: String {
        ciadpiStatus?.latestVersion ?? L10n.shared.versionUnknown
    }

    var canUpdateCiadpi: Bool {
        ciadpiStatus?.updateAvailable == true && ciadpiStatus?.sourceTarballURL != nil
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
        if isDualSelection {
            return dualPaths.map { item in
                ([item.path] + buildLaunchArguments(for: item.engine, binaryPath: item.path)).map(shellQuoted).joined(separator: " ")
            }.joined(separator: "\n")
        }
        return ([resolvedBinaryPath] + buildLaunchArguments()).map(shellQuoted).joined(separator: " ")
    }

    var vpnClientCompatibilityStatus: String {
        String(format: L10n.shared.vpnClientCompatibilityStatus, clamp(localPort, defaultValue: 8080, range: 1...65535))
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
        case .dual:
            return L10n.shared.backendDual
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
        if flag == "--system-proxy", vpnClientCompatibilityEnabled {
            return false
        }
        if isDualSelection {
            return [.ciadpi, .spoofdpi].contains(where: { engine in
                BackendCapability.forEngine(engine).supports(flag: flag)
                    && selectedFlags(for: engine).contains(flag)
            })
        }
        return selectedFlags(for: resolvedEngine).contains(flag)
    }

    func setFlag(_ flag: String, enabled: Bool) {
        guard flagSupported(flag) else { return }
        guard !(flag == "--system-proxy" && vpnClientCompatibilityEnabled && enabled) else { return }
        if isDualSelection {
            for engine in [BypassEngine.ciadpi, BypassEngine.spoofdpi] {
                guard BackendCapability.forEngine(engine).supports(flag: flag) else { continue }
                var flags = selectedFlags(for: engine)
                if enabled {
                    flags.insert(flag)
                } else {
                    flags.remove(flag)
                }
                flagsByEngine[engine] = flags
            }
            return
        }
        var flags = selectedFlags(for: resolvedEngine)
        if enabled {
            flags.insert(flag)
        } else {
            flags.remove(flag)
        }
        flagsByEngine[resolvedEngine] = flags
    }

    func flagSupported(_ flag: String) -> Bool {
        if flag == "--system-proxy", vpnClientCompatibilityEnabled {
            return false
        }
        if isDualSelection {
            return BackendCapability.forEngine(.ciadpi).supports(flag: flag)
                || BackendCapability.forEngine(.spoofdpi).supports(flag: flag)
        }
        return BackendCapability.forEngine(resolvedEngine).supports(flag: flag)
    }

    func unsupportedReason(for flag: String) -> String {
        switch flag {
        case "--system-proxy":
            return text(ru: "Отключено в режиме совместимости с VPN-клиентами.", en: "Disabled in VPN client compatibility mode.")
        case "--policy-auto":
            return text(ru: "Только ciadpi.", en: "ciadpi only.")
        case "--silent", "--dns-ipv4-only", "--debug":
            return text(ru: "Только spoofdpi.", en: "spoofdpi only.")
        default:
            return text(ru: "Недоступно для выбранного backend.", en: "Unavailable for the selected backend.")
        }
    }

    func applyMobilePreset() {
        applyPreset(.hotspot)
        save()
        applyNetworkOptimization()
    }

    func applyPreset(_ preset: SettingsPreset) {
        let values = preset.parameters
        defaultTTL = values.ttl
        splitMode = values.split
        httpsDisorder = values.disorder
        httpsFakeCount = values.fakes
        httpsChunkSize = values.chunk
    }

    func refreshRuntimeStatus() {
        vpnAvailabilityIssue = SystemExtensionManager.shared.availabilityIssue()
        tunnelActive = TunnelManager.shared.isActive
        networkOptimizationApplied = store.isNetworkOptimizationApplied()
        backendRunning = DPIKillerManager.shared.isRunning
        runtimePort = DPIKillerManager.shared.activePort
        if vpnClientCompatibilityEnabled, vpnModeEnabled {
            vpnModeEnabled = false
        }
        if !vpnAvailable, vpnModeEnabled {
            vpnModeEnabled = false
        }
    }

    func applyNetworkOptimization() {
        guard !isApplyingNetworkOptimization else { return }
        isApplyingNetworkOptimization = true
        footerStatus = L10n.shared.networkOptimizationApplying
        store.applyNetworkOptimization { [weak self] success, error in
            guard let self else { return }
            self.isApplyingNetworkOptimization = false
            self.networkOptimizationApplied = self.store.isNetworkOptimizationApplied()
            if success {
                self.footerStatus = L10n.shared.fixHotspotSuccess
                (NSApp.delegate as? AppDelegate)?.refreshUI()
            } else {
                self.footerStatus = error?.isEmpty == false ? error : L10n.shared.fixHotspotFailed
                (NSApp.delegate as? AppDelegate)?.refreshUI()
            }
        }
    }

    func configureShadowrocket() {
        guard !isConfiguringShadowrocket else { return }
        let ciadpiPath = store.resolvedBinaryPath(for: .ciadpi)
        guard FileManager.default.isExecutableFile(atPath: ciadpiPath) else {
            footerStatus = L10n.shared.shadowrocketNeedsCiadpi
            return
        }

        isConfiguringShadowrocket = true
        footerStatus = L10n.shared.configuringShadowrocket
        backendSelection = .ciadpi
        customBinaryPath = ciadpiPath
        systemProxyEnabled = false
        vpnClientCompatibilityEnabled = false
        vpnModeEnabled = false
        flagsByEngine[.ciadpi]?.remove("--system-proxy")
        flagsByEngine[.spoofdpi]?.remove("--system-proxy")

        let openImport: (Bool, String?) -> Void = { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshRuntimeStatus()
                guard success else {
                    self.isConfiguringShadowrocket = false
                    self.footerStatus = error?.isEmpty == false ? error : L10n.shared.backendStartTimeout
                    return
                }

                let port = self.runtimePort ?? DPIKillerManager.shared.proxyPort
                self.footerStatus = self.openShadowrocketImport(port: port)
                    ? L10n.shared.shadowrocketOpened
                    : L10n.shared.shadowrocketOpenFailed
                self.isConfiguringShadowrocket = false
            }
        }

        save { success, error in
            guard success else { openImport(false, error); return }
            if DPIKillerManager.shared.isRunning {
                openImport(true, nil)
            } else {
                DPIKillerManager.shared.start(completion: openImport)
            }
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
            spoofdpiStatusMessage = text(ru: "SpoofDPI установлен.", en: "SpoofDPI is installed.")
            spoofdpiStatusStyle = .neutral
        }
    }

    func refreshCiadpiLocalStatus() {
        let status = ciadpiUpdater.localStatus(selectedPath: ciadpiResolvedPath)
        ciadpiStatus = status
        if status.managedVersion != nil {
            ciadpiStatusMessage = text(ru: "ciadpi установлен.", en: "ciadpi is installed.")
            ciadpiStatusStyle = .neutral
        } else {
            ciadpiStatusMessage = text(ru: "Managed ciadpi не установлен.", en: "Managed ciadpi is not installed.")
            ciadpiStatusStyle = .warning
        }
    }

    private var lastAutomaticEngineCheck: Date?

    func refreshEngineVersionsIfNeeded() {
        guard lastAutomaticEngineCheck.map({ Date().timeIntervalSince($0) >= 300 }) ?? true else { return }
        lastAutomaticEngineCheck = Date()
        checkCiadpiVersion()
        checkSpoofdpiVersion()
    }

    func checkCiadpiVersion() {
        guard !isCheckingCiadpi, !isUpdatingCiadpi else { return }
        isCheckingCiadpi = true
        ciadpiStatusMessage = text(ru: "Проверка ciadpi...", en: "Checking ciadpi...")
        ciadpiStatusStyle = .neutral
        ciadpiUpdater.checkStatus(selectedPath: ciadpiResolvedPath) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isCheckingCiadpi = false
                switch result {
                case .success(let status):
                    self.ciadpiStatus = status
                    self.ciadpiStatusMessage = status.updateAvailable
                        ? self.text(ru: "Доступно обновление ciadpi.", en: "ciadpi update is available.")
                        : self.text(ru: "ciadpi актуален.", en: "ciadpi is up to date.")
                    self.ciadpiStatusStyle = status.updateAvailable ? .warning : .success
                case .failure(let error):
                    self.ciadpiStatusMessage = self.text(ru: "Не удалось проверить ciadpi.", en: "Could not check ciadpi.")
                    self.ciadpiStatusStyle = .warning
                    AppLogger.log("ciadpi SwiftUI update check failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func checkSpoofdpiVersion() {
        guard !isCheckingSpoofdpi, !isUpdatingSpoofdpi else { return }
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
        ciadpiUpdater.installLatest { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isUpdatingCiadpi = false
                switch result {
                case .success(let status):
                    self.ciadpiStatus = status
                    self.ciadpiStatusMessage = self.text(ru: "ciadpi обновлён.", en: "ciadpi was updated.")
                    self.ciadpiStatusStyle = .success
                    SettingsStore.shared.saveDetectedBinaryPath(SettingsStore.shared.detectBestBinaryPath())
                case .failure(let error):
                    self.ciadpiStatusMessage = self.text(ru: "Не удалось обновить ciadpi.", en: "Could not update ciadpi.")
                    self.ciadpiStatusStyle = .warning
                    AppLogger.log("ciadpi SwiftUI update failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func settingsDraft() -> SettingsDraft {
        let sanitizedVPNClientCompatibility = vpnClientCompatibilityEnabled
        let sanitizedCommon = CommonSettings(
            localPort: String(clamp(localPort, defaultValue: 8080, range: 1...65535)),
            defaultTTL: String(clamp(defaultTTL, defaultValue: 64, range: 1...255)),
            splitMode: splitMode.isEmpty ? "sni" : splitMode,
            httpsDisorder: httpsDisorder,
            httpsFakeCount: String(clamp(httpsFakeCount, defaultValue: 0, range: 0...100)),
            httpsChunkSize: String(clamp(httpsChunkSize, defaultValue: 20, range: 1...255)),
            dnsAddr: dnsAddr.trimmingCharacters(in: .whitespacesAndNewlines),
            dnsMode: dnsMode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "udp" : dnsMode.trimmingCharacters(in: .whitespacesAndNewlines),
            dnsHttpsUrl: dnsHttpsUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            launchAtLogin: launchAtLogin,
            autoUpdate: autoUpdate,
            autoDownload: autoDownload,
            disableIpv6: disableIpv6,
            autoReconnect: autoReconnect,
            systemProxyEnabled: systemProxyEnabled,
            vpnClientCompatibilityEnabled: sanitizedVPNClientCompatibility,
            vpnModeEnabled: vpnModeEnabled && vpnAvailable && !sanitizedVPNClientCompatibility
        )
        return SettingsDraft(
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
    }

    private func scheduleApply() {
        pendingApply?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.applySettings() }
        pendingApply = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func save(completion: ((Bool, String?) -> Void)? = nil) {
        pendingApply?.cancel()
        applySettings(completion: completion)
    }

    private func applySettings(completion: ((Bool, String?) -> Void)? = nil) {
        guard !isApplyingSettings, canSave else { completion?(false, validationIssue); return }
        let requested = settingsDraft()
        guard requested != lastAppliedDraft else { completion?(true, nil); return }
        let previous = store.loadDraft()
        let oldCommand = store.commandPreview()
        let wasRunning = DPIKillerManager.shared.isRunning || DPIKillerManager.shared.process?.isRunning == true
        store.saveDraft(requested)
        let saved = store.loadDraft()
        let restart = oldCommand != store.commandPreview()
        isApplyingSettings = true
        footerStatus = text(ru: "Применяю настройки…", en: "Applying settings…")
        AppLogger.log("[Settings] Applying: engine=\(store.currentEngine().rawValue), systemProxy=\(store.usesSystemProxy), backendActive=\(wasRunning), restart=\(restart).")

        let finish: (Bool, String?) -> Void = { [weak self] success, error in
            guard let self else { return }
            if success {
                self.lastAppliedDraft = saved
                if self.settingsDraft() == requested { self.restoreDraft(saved) }
                self.footerStatus = error ?? (DPIKillerManager.shared.isRunning
                    ? self.text(ru: "Настройки применены.", en: "Settings applied.")
                    : self.text(ru: "Настройки сохранены. Движок выключен.", en: "Settings saved. Backend is stopped."))
                AppLogger.log("[Settings] Applied successfully. backendActive=\(DPIKillerManager.shared.isRunning).")
            } else {
                self.lastAppliedDraft = previous
                self.store.saveDraft(previous)
                if self.settingsDraft() == requested { self.restoreDraft(previous) }
                self.footerStatus = error ?? self.text(ru: "Не удалось применить настройки.", en: "Could not apply settings.")
                AppLogger.log("[Settings] Apply failed: \(error ?? "unknown"). Previous settings restored.")
            }
            self.isApplyingSettings = false
            self.refreshRuntimeStatus()
            self.scheduleApply()
            completion?(success && error != DPIKillerManager.settingsChangeCancelled, error)
        }
        guard wasRunning else { finish(true, nil); return }
        DPIKillerManager.shared.reconfigure(restartBackend: restart) { success, error in
            if NetworkSettingsClient.shared.isSupported, NetworkSettingsClient.shared.needsApproval {
                finish(true, NetworkSettingsClient.shared.approvalMessage)
                return
            }
            if error == DPIKillerManager.settingsChangeCancelled {
                finish(true, error)
                return
            }
            self.store.saveDraft(success ? saved : previous)
            if success || DPIKillerManager.shared.matchesConfiguredBackend {
                finish(success, error)
                return
            }
            self.store.saveDraft(previous)
            AppLogger.log("[Settings] Recovering previous working backend after failed change.")
            DPIKillerManager.shared.start { recovered, recoveryError in
                if !recovered { AppLogger.log("[Settings] Previous backend recovery failed: \(recoveryError ?? "unknown").") }
                finish(false, error ?? recoveryError)
            }
        }
    }

    private func restoreDraft(_ draft: SettingsDraft) {
        backendSelection = draft.backendSelection
        customBinaryPath = draft.customPath
        localPort = draft.common.localPort
        defaultTTL = draft.common.defaultTTL
        splitMode = draft.common.splitMode
        httpsDisorder = draft.common.httpsDisorder
        httpsFakeCount = draft.common.httpsFakeCount
        httpsChunkSize = draft.common.httpsChunkSize
        dnsAddr = draft.common.dnsAddr
        dnsMode = draft.common.dnsMode
        dnsHttpsUrl = draft.common.dnsHttpsUrl
        launchAtLogin = draft.common.launchAtLogin
        autoUpdate = draft.common.autoUpdate
        autoDownload = draft.common.autoDownload
        disableIpv6 = draft.common.disableIpv6
        autoReconnect = draft.common.autoReconnect
        systemProxyEnabled = draft.common.systemProxyEnabled
        vpnClientCompatibilityEnabled = draft.common.vpnClientCompatibilityEnabled
        vpnModeEnabled = draft.common.vpnModeEnabled
        ciadpiManualArgs = draft.ciadpi.manualArgs
        spoofdpiManualArgs = draft.spoofdpi.manualArgs
        flagsByEngine = [.ciadpi: draft.ciadpi.selectedFlags, .spoofdpi: draft.spoofdpi.selectedFlags]
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
        if manualWarning(for: resolvedEngine) != nil {
            return text(ru: "В Manual есть конфликтующие аргументы.", en: "Manual args contain incompatible flags.")
        }
        return nil
    }

    private func selectedFlags(for engine: BypassEngine) -> Set<String> {
        flagsByEngine[engine] ?? []
    }

    private var dualUsesSystemProxy: Bool {
        selectedFlags(for: .spoofdpi).contains("--system-proxy")
            || selectedFlags(for: .ciadpi).contains("--system-proxy")
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
        buildLaunchArguments(for: resolvedEngine, binaryPath: resolvedBinaryPath)
    }

    private func buildLaunchArguments(for engine: BypassEngine, binaryPath: String) -> [String] {
        store.launchArguments(draft: settingsDraft(), binaryPath: binaryPath)
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

    private func openShadowrocketImport(port: Int) -> Bool {
        guard var components = URLComponents(string: "socks5://127.0.0.1:\(port)") else {
            return false
        }
        components.fragment = "DPI Killer"
        guard let url = components.url,
              NSWorkspace.shared.urlForApplication(toOpen: url) != nil else {
            return false
        }
        return NSWorkspace.shared.open(url)
    }

    private func clamp(_ value: String, defaultValue: Int, range: ClosedRange<Int>) -> Int {
        let parsed = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? defaultValue
        return min(max(parsed, range.lowerBound), range.upperBound)
    }

    private func text(ru: String, en: String) -> String {
        L10n.shared.isRussian ? ru : en
    }
}
