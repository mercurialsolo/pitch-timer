import AppKit

protocol FullScreenWindowDelegate: AnyObject {
    func fullScreenWindowDidRequestExit()
}

class FullScreenWindowController: NSWindowController, NSWindowDelegate {
    private let preferences: Preferences
    private var timerLabel: NSTextField!
    private var backgroundView: NSView!
    private var isAlertMode: Bool = false
    weak var delegate: FullScreenWindowDelegate?

    init(preferences: Preferences) {
        self.preferences = preferences

        let window = FullScreenWindow()
        super.init(window: window)

        setupWindow()
        setupExitHandlers()

        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow() {
        guard let window = window as? FullScreenWindow else { return }

        window.styleMask = [.borderless, .titled]
        window.backgroundColor = .black
        window.isOpaque = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        // Black background view
        backgroundView = NSView()
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.black.cgColor

        // Large centered timer label
        timerLabel = NSTextField()
        timerLabel.isEditable = false
        timerLabel.isSelectable = false
        timerLabel.isBordered = false
        timerLabel.backgroundColor = .clear
        timerLabel.textColor = .white
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 150, weight: .semibold)
        timerLabel.alignment = .center

        backgroundView.addSubview(timerLabel)
        window.contentView = backgroundView
    }

    private func setupExitHandlers() {
        guard let window = window else { return }

        // ESC key handler
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.exitFullScreen()
                return nil
            }
            return event
        }

        // Click anywhere to exit
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        window.contentView?.addGestureRecognizer(clickGesture)
    }

    @objc private func handleClick() {
        exitFullScreen()
    }

    func showOnScreen(_ screenPreference: ScreenPreference) {
        guard let window = window else { return }
        guard let screen = selectScreen(screenPreference) else { return }

        let screenFrame = screen.frame
        window.setFrame(screenFrame, display: true)

        // Update timer label frame to be centered
        layoutTimerLabel()

        window.makeKeyAndOrderFront(nil)
    }

    private func selectScreen(_ preference: ScreenPreference) -> NSScreen? {
        switch preference {
        case .main:
            return NSScreen.main
        case .secondary:
            return NSScreen.screens.count > 1
                ? NSScreen.screens.first { $0 != NSScreen.main }
                : NSScreen.main
        }
    }

    private func layoutTimerLabel() {
        guard let window = window else { return }

        let windowFrame = window.frame
        let labelWidth: CGFloat = 500
        let labelHeight: CGFloat = 200

        let labelX = (windowFrame.width - labelWidth) / 2
        let labelY = (windowFrame.height - labelHeight) / 2

        timerLabel.frame = NSRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
    }

    func updateDisplay(timeRemaining: Int) {
        let absTime = abs(timeRemaining)
        let minutes = absTime / 60
        let seconds = absTime % 60

        // Always show time in same format - red background indicates overtime
        timerLabel.stringValue = String(format: "%02d:%02d", minutes, seconds)

        // Reset to normal color if timer is reset to positive
        if timeRemaining > 0 && isAlertMode {
            isAlertMode = false
            updateVisualAlert()
        }

        // Show red alert when timer hits zero or goes negative
        if timeRemaining <= 0 && preferences.showRedAlert && !isAlertMode {
            isAlertMode = true
            updateVisualAlert()
        }
    }

    private func updateVisualAlert() {
        if isAlertMode && preferences.showRedAlert {
            backgroundView.layer?.backgroundColor = NSColor.red.cgColor
            timerLabel.textColor = .white
        } else {
            backgroundView.layer?.backgroundColor = NSColor.black.cgColor
            timerLabel.textColor = .white
        }
    }

    func exitFullScreen() {
        delegate?.fullScreenWindowDidRequestExit()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Cleanup if needed
    }
}

class FullScreenWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }

    convenience init() {
        self.init(contentRect: .zero,
                  styleMask: .borderless,
                  backing: .buffered,
                  defer: false)
    }
}
