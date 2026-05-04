import Cocoa

enum AppTheme {
    static let accent = NSColor.controlAccentColor
    static let accentSoft = NSColor.systemBlue
    static let warning = NSColor.systemOrange
    static let success = NSColor.systemGreen
    static let danger = NSColor.systemRed
    static let textPrimary = NSColor.labelColor
    static let textSecondary = NSColor.secondaryLabelColor
    static let textMuted = NSColor.tertiaryLabelColor
    static let settingsBackground = NSColor(calibratedRed: 0.090, green: 0.098, blue: 0.118, alpha: 1)
    static let settingsSidebar = NSColor(calibratedRed: 0.118, green: 0.126, blue: 0.150, alpha: 1)
    static let settingsSurface = NSColor(calibratedRed: 0.145, green: 0.153, blue: 0.180, alpha: 1)
    static let settingsSurfaceRaised = NSColor(calibratedRed: 0.172, green: 0.184, blue: 0.216, alpha: 1)
    static let settingsBorder = NSColor.white.withAlphaComponent(0.08)
    static let settingsSeparator = NSColor.white.withAlphaComponent(0.07)
    static let settingsTextPrimary = NSColor(calibratedWhite: 0.94, alpha: 1)
    static let settingsTextSecondary = NSColor(calibratedWhite: 0.70, alpha: 1)
    static let settingsTextMuted = NSColor(calibratedWhite: 0.50, alpha: 1)

    static func styleWindow(_ window: NSWindow?, minSize: NSSize? = nil) {
        guard let window else { return }
        window.appearance = nil
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.isMovableByWindowBackground = false
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.hasShadow = true
        if let minSize {
            window.minSize = minSize
        }
    }

    static func styleSettingsWindow(_ window: NSWindow?, minSize: NSSize? = nil) {
        guard let window else { return }
        window.appearance = NSAppearance(named: .darkAqua)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.isMovableByWindowBackground = true
        window.backgroundColor = settingsBackground
        window.isOpaque = true
        window.hasShadow = true
        if let minSize {
            window.minSize = minSize
        }
    }

    static func makeWindowBackground(material: NSVisualEffectView.Material = .windowBackground) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .withinWindow
        view.state = .active
        return view
    }

    static func makeSettingsBackground() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = settingsBackground.cgColor
        return view
    }

    static func stylePrimaryButton(_ button: NSButton) {
        button.isBordered = true
        button.bezelStyle = .rounded
        button.contentTintColor = nil
        button.font = .systemFont(ofSize: 13, weight: .semibold)
    }

    static func styleSecondaryButton(_ button: NSButton) {
        button.isBordered = true
        button.bezelStyle = .rounded
        button.contentTintColor = nil
        button.font = .systemFont(ofSize: 13, weight: .regular)
    }

    static func styleInput(_ control: NSControl) {
        control.font = .systemFont(ofSize: 13, weight: .regular)

        if let textField = control as? NSTextField {
            textField.isBordered = true
            textField.isBezeled = true
            textField.drawsBackground = true
            textField.backgroundColor = .controlBackgroundColor
            textField.textColor = textPrimary
            textField.focusRingType = .default
            if let placeholder = textField.placeholderString {
                textField.placeholderAttributedString = NSAttributedString(
                    string: placeholder,
                    attributes: [.foregroundColor: NSColor.placeholderTextColor]
                )
            }
        }

        if let popup = control as? NSPopUpButton {
            popup.contentTintColor = nil
        }
    }

    static func styleSettingsInput(_ control: NSControl) {
        styleInput(control)

        if let textField = control as? NSTextField {
            textField.backgroundColor = settingsSurfaceRaised
            textField.textColor = settingsTextPrimary
            textField.placeholderAttributedString = NSAttributedString(
                string: textField.placeholderString ?? "",
                attributes: [.foregroundColor: settingsTextMuted]
            )
        }

        if let popup = control as? NSPopUpButton {
            popup.contentTintColor = settingsTextPrimary
        }
    }

    static func makeSectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = textPrimary
        return label
    }

    static func makeSecondaryText(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = textSecondary
        return label
    }

    static func makeSettingsTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = settingsTextPrimary
        return label
    }

    static func makeSettingsSecondaryText(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = settingsTextSecondary
        return label
    }

    static func makeStatusBadge(text: String, color: NSColor) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 999
        container.layer?.backgroundColor = color.withAlphaComponent(0.12).cgColor
        container.layer?.borderWidth = 1
        container.layer?.borderColor = color.withAlphaComponent(0.22).cgColor

        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 5),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -5)
        ])
        return container
    }

    static func makeSeparator() -> NSView {
        let separator = NSView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
        return separator
    }
}

final class MetricCardView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "—")
    private let unitLabel = NSTextField(labelWithString: "")

    init(title: String, unit: String) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        addSubview(stack)
        stack.fill(parent: self, padding: 16)

        titleLabel.stringValue = title.uppercased()
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = AppTheme.textSecondary

        valueLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        valueLabel.textColor = AppTheme.textPrimary

        unitLabel.stringValue = unit
        unitLabel.font = .systemFont(ofSize: 12, weight: .regular)
        unitLabel.textColor = AppTheme.textSecondary

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(unitLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(value: String) {
        valueLabel.stringValue = value
    }
}

extension NSView {
    func fill(parent: NSView, padding: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor, constant: padding),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: padding),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -padding),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -padding)
        ])
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
