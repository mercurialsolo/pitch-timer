import AppKit

class SettingsWindowController: NSWindowController {
    private let preferences: Preferences
    weak var delegate: SettingsWindowDelegate?

    private var durationField: NSTextField!
    private var playSoundCheckbox: NSButton!
    private var showRedAlertCheckbox: NSButton!
    private var positionSegmentedControl: NSSegmentedControl!
    private var displayModeSegmentedControl: NSSegmentedControl!
    private var screenPreferenceSegmentedControl: NSSegmentedControl!

    init(preferences: Preferences) {
        self.preferences = preferences

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()

        super.init(window: window)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Display mode setting
        let displayModeLabel = NSTextField(labelWithString: "Display Mode:")
        displayModeLabel.frame = NSRect(x: 20, y: 320, width: 150, height: 20)
        contentView.addSubview(displayModeLabel)

        displayModeSegmentedControl = NSSegmentedControl(labels: ["Overlay", "Full Screen"], trackingMode: .selectOne, target: self, action: #selector(displayModeChanged))
        displayModeSegmentedControl.frame = NSRect(x: 20, y: 290, width: 280, height: 28)
        displayModeSegmentedControl.selectedSegment = (preferences.displayMode == .overlay) ? 0 : 1
        contentView.addSubview(displayModeSegmentedControl)

        // Screen preference (for full screen)
        let screenLabel = NSTextField(labelWithString: "Full Screen Display:")
        screenLabel.frame = NSRect(x: 20, y: 250, width: 150, height: 20)
        contentView.addSubview(screenLabel)

        screenPreferenceSegmentedControl = NSSegmentedControl(labels: ["Main", "Secondary"], trackingMode: .selectOne, target: self, action: #selector(settingChanged))
        screenPreferenceSegmentedControl.frame = NSRect(x: 20, y: 220, width: 280, height: 28)
        screenPreferenceSegmentedControl.selectedSegment = (preferences.preferredFullScreenScreen == .main) ? 0 : 1
        screenPreferenceSegmentedControl.isEnabled = (preferences.displayMode == .fullScreen)
        contentView.addSubview(screenPreferenceSegmentedControl)

        // Duration setting
        let durationLabel = NSTextField(labelWithString: "Timer Duration (minutes):")
        durationLabel.frame = NSRect(x: 20, y: 180, width: 200, height: 20)
        contentView.addSubview(durationLabel)

        durationField = NSTextField(frame: NSRect(x: 20, y: 150, width: 100, height: 24))
        durationField.stringValue = "\(preferences.timerDuration / 60)"
        durationField.placeholderString = "5"
        contentView.addSubview(durationField)

        // Play sound checkbox
        playSoundCheckbox = NSButton(checkboxWithTitle: "Play sound when timer completes", target: self, action: #selector(settingChanged))
        playSoundCheckbox.frame = NSRect(x: 20, y: 110, width: 300, height: 20)
        playSoundCheckbox.state = preferences.playSoundOnComplete ? .on : .off
        contentView.addSubview(playSoundCheckbox)

        // Show red alert checkbox
        showRedAlertCheckbox = NSButton(checkboxWithTitle: "Show red background when timer completes", target: self, action: #selector(settingChanged))
        showRedAlertCheckbox.frame = NSRect(x: 20, y: 80, width: 350, height: 20)
        showRedAlertCheckbox.state = preferences.showRedAlert ? .on : .off
        contentView.addSubview(showRedAlertCheckbox)

        // Position setting (only for overlay mode)
        let positionLabel = NSTextField(labelWithString: "Overlay Position:")
        positionLabel.frame = NSRect(x: 20, y: 40, width: 150, height: 20)
        contentView.addSubview(positionLabel)

        positionSegmentedControl = NSSegmentedControl(labels: ["Left", "Right", "Custom"], trackingMode: .selectOne, target: self, action: #selector(settingChanged))
        positionSegmentedControl.frame = NSRect(x: 180, y: 38, width: 200, height: 28)

        // Determine selected segment based on position
        switch preferences.overlayPosition {
        case .left:
            positionSegmentedControl.selectedSegment = 0
        case .right:
            positionSegmentedControl.selectedSegment = 1
        case .custom:
            positionSegmentedControl.selectedSegment = 2
        }

        contentView.addSubview(positionSegmentedControl)

        // Save button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.frame = NSRect(x: 290, y: 20, width: 90, height: 32)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Enter key
        contentView.addSubview(saveButton)

        // Cancel button
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.frame = NSRect(x: 190, y: 20, width: 90, height: 32)
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
        contentView.addSubview(cancelButton)
    }

    @objc private func settingChanged() {
        // Live preview - could update here if desired
    }

    @objc private func displayModeChanged() {
        // Enable/disable screen preference based on display mode
        screenPreferenceSegmentedControl.isEnabled = (displayModeSegmentedControl.selectedSegment == 1)
    }

    @objc private func saveSettings() {
        // Parse duration
        if let minutes = Int(durationField.stringValue), minutes > 0 {
            preferences.timerDuration = minutes * 60
        }

        preferences.playSoundOnComplete = playSoundCheckbox.state == .on
        preferences.showRedAlert = showRedAlertCheckbox.state == .on

        // Update display mode
        preferences.displayMode = (displayModeSegmentedControl.selectedSegment == 0) ? .overlay : .fullScreen

        // Update screen preference
        preferences.preferredFullScreenScreen = (screenPreferenceSegmentedControl.selectedSegment == 0) ? .main : .secondary

        // Update position only if Left or Right is selected
        // If Custom is selected, keep the existing custom position
        switch positionSegmentedControl.selectedSegment {
        case 0:
            preferences.overlayPosition = .left
        case 1:
            preferences.overlayPosition = .right
        case 2:
            // Keep custom position as-is
            if case .custom = preferences.overlayPosition {
                // Already custom, do nothing
            } else {
                // If it wasn't custom before, this shouldn't happen, but set a default
                preferences.overlayPosition = .custom(x: 100, y: 100)
            }
        default:
            break
        }

        delegate?.settingsDidChange()
        window?.close()
    }

    @objc private func cancel() {
        window?.close()
    }

    override func showWindow(_ sender: Any?) {
        // Refresh values from preferences
        durationField.stringValue = "\(preferences.timerDuration / 60)"
        playSoundCheckbox.state = preferences.playSoundOnComplete ? .on : .off
        showRedAlertCheckbox.state = preferences.showRedAlert ? .on : .off

        // Update display mode
        displayModeSegmentedControl.selectedSegment = (preferences.displayMode == .overlay) ? 0 : 1

        // Update screen preference
        screenPreferenceSegmentedControl.selectedSegment = (preferences.preferredFullScreenScreen == .main) ? 0 : 1
        screenPreferenceSegmentedControl.isEnabled = (preferences.displayMode == .fullScreen)

        // Update position selection
        switch preferences.overlayPosition {
        case .left:
            positionSegmentedControl.selectedSegment = 0
        case .right:
            positionSegmentedControl.selectedSegment = 1
        case .custom:
            positionSegmentedControl.selectedSegment = 2
        }

        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

protocol SettingsWindowDelegate: AnyObject {
    func settingsDidChange()
}
