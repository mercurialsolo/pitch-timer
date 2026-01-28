import AppKit

protocol TimerWindowDelegate: AnyObject {
    func timerWindowDidChangePosition()
}

class TimerWindowController: NSWindowController, NSWindowDelegate {
    private let timerManager: TimerManager
    private let preferences: Preferences
    private var timerLabel: NSTextField!
    private var containerView: NSView!
    private var isAlertMode: Bool = false
    private var isUserDragging = false
    weak var timerDelegate: TimerWindowDelegate?

    init(timerManager: TimerManager, preferences: Preferences) {
        self.timerManager = timerManager
        self.preferences = preferences

        let window = TimerWindow()
        super.init(window: window)

        setupWindow()
        updatePosition()
        updateDisplay(timeRemaining: preferences.timerDuration)

        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow() {
        guard let window = window as? TimerWindow else { return }

        window.styleMask = [.borderless, .titled]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        // Container view with rounded corners
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: 180, height: 80))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        containerView.layer?.cornerRadius = 20

        // Add shadow for better visibility
        containerView.layer?.shadowColor = NSColor.black.cgColor
        containerView.layer?.shadowOpacity = 0.5
        containerView.layer?.shadowOffset = NSSize(width: 0, height: -2)
        containerView.layer?.shadowRadius = 8

        // Timer label
        timerLabel = NSTextField(frame: NSRect(x: 15, y: 15, width: 150, height: 50))
        timerLabel.isEditable = false
        timerLabel.isSelectable = false
        timerLabel.isBordered = false
        timerLabel.backgroundColor = .clear
        timerLabel.textColor = .white
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 48, weight: .semibold)
        timerLabel.alignment = .center

        containerView.addSubview(timerLabel)

        window.contentView = containerView
        window.setContentSize(containerView.frame.size)

        window.makeKeyAndOrderFront(nil)
    }

    func updatePosition() {
        guard let window = window, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let sideMargin: CGFloat = 20

        let x: CGFloat
        let y: CGFloat

        switch preferences.overlayPosition {
        case .left:
            // Top left corner
            x = screenFrame.minX + sideMargin
            y = screenFrame.maxY - windowSize.height
        case .right:
            // Top right corner
            x = screenFrame.maxX - windowSize.width - sideMargin
            y = screenFrame.maxY - windowSize.height
        case .custom(let customX, let customY):
            // Use saved custom position
            x = customX
            y = customY
        }

        window.setFrameOrigin(NSPoint(x: x, y: y))
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

    func updateVisualAlert() {
        if isAlertMode && preferences.showRedAlert {
            containerView.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.8).cgColor
            timerLabel.textColor = .white
        } else {
            containerView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.7).cgColor
            timerLabel.textColor = .white
        }
    }

    func toggleVisibility() {
        guard let window = window else { return }

        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillMove(_ notification: Notification) {
        isUserDragging = true
    }

    func windowDidMove(_ notification: Notification) {
        guard isUserDragging, let window = window else { return }

        // Save custom position when user manually moves the window
        let origin = window.frame.origin
        preferences.overlayPosition = .custom(x: origin.x, y: origin.y)

        // Notify delegate that position changed
        timerDelegate?.timerWindowDidChangePosition()

        isUserDragging = false
    }
}

class TimerWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override func resignKey() {
        super.resignKey()
        // When we lose key status, keep floating but allow other apps to come forward
    }

    override func becomeKey() {
        super.becomeKey()
        // When we become key, ensure we're on top
        self.level = .floating
    }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.isMovableByWindowBackground = true
    }

    convenience init() {
        self.init(contentRect: NSRect(x: 0, y: 0, width: 180, height: 80),
                  styleMask: .borderless,
                  backing: .buffered,
                  defer: false)
    }
}
