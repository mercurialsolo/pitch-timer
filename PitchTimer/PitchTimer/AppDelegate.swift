import AppKit
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timerWindowController: TimerWindowController?
    var fullScreenWindowController: FullScreenWindowController?
    var timerManager: TimerManager!
    var hotkeyManager: HotkeyManager!
    var preferences: Preferences!
    var networkManager: NetworkSyncManager!
    private var networkWindow: NSWindow?
    private var networkViewController: NetworkViewController?
    private var settingsWindowController: SettingsWindowController?
    private var initialDuration: Int?

    init(initialDuration: Int? = nil) {
        self.initialDuration = initialDuration
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set application name
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            UserDefaults.standard.set(bundleName, forKey: "AppleTitle")
        }

        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)

        // Initialize preferences
        preferences = Preferences()

        // Override with CLI duration if provided
        if let duration = initialDuration {
            preferences.timerDuration = duration
        }

        // Initialize timer manager
        timerManager = TimerManager(preferences: preferences)
        timerManager.delegate = self

        // Initialize hotkey manager
        hotkeyManager = HotkeyManager()
        hotkeyManager.delegate = self
        hotkeyManager.registerHotkeys()

        // Initialize network manager
        networkManager = NetworkSyncManager()
        networkManager.delegate = self

        // Setup application menu (shown when timer window is active)
        setupApplicationMenu()

        // Setup menu bar
        setupMenuBar()

        // Create overlay window
        timerWindowController = TimerWindowController(timerManager: timerManager, preferences: preferences)
        timerWindowController?.timerDelegate = self
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregisterHotkeys()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Try to load custom menu bar icon first, fallback to system symbol
            if let customIcon = NSImage(named: "MenuBarIcon") {
                customIcon.isTemplate = true
                button.image = customIcon
            } else {
                button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer")
            }
        }

        let menu = NSMenu()

        // Start/Stop
        let startStopItem = NSMenuItem(title: "Start Timer", action: #selector(toggleTimer), keyEquivalent: "")
        startStopItem.tag = 1
        startStopItem.keyEquivalentModifierMask = [.command, .shift]
        startStopItem.keyEquivalent = "t"
        menu.addItem(startStopItem)

        // Reset
        let resetItem = NSMenuItem(title: "Reset Timer", action: #selector(resetTimer), keyEquivalent: "r")
        resetItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(resetItem)

        menu.addItem(NSMenuItem.separator())

        // Show/Hide Overlay
        menu.addItem(NSMenuItem(title: "Toggle Overlay", action: #selector(toggleOverlay), keyEquivalent: ""))

        // Full Screen
        let fullScreenItem = NSMenuItem(title: "Enter Full Screen", action: #selector(toggleFullScreen), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.command, .shift]
        fullScreenItem.tag = 4
        menu.addItem(fullScreenItem)

        menu.addItem(NSMenuItem.separator())

        // Host Network
        let hostItem = NSMenuItem(title: "Host Network Session", action: #selector(hostNetwork), keyEquivalent: "h")
        hostItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(hostItem)

        // Join Network
        let joinItem = NSMenuItem(title: "Join Network Session...", action: #selector(joinNetwork), keyEquivalent: "j")
        joinItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(joinItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences submenu
        let preferencesMenu = NSMenu()

        // Timer duration
        let durationItem = NSMenuItem(title: "Set Duration...", action: #selector(showDurationDialog), keyEquivalent: "d")
        durationItem.keyEquivalentModifierMask = [.command, .shift]
        preferencesMenu.addItem(durationItem)

        // Increase/Decrease duration
        let increaseItem = NSMenuItem(title: "Increase Duration", action: #selector(increaseDuration), keyEquivalent: String(Unicode.Scalar(NSUpArrowFunctionKey)!))
        increaseItem.keyEquivalentModifierMask = [.command, .shift]
        preferencesMenu.addItem(increaseItem)

        let decreaseItem = NSMenuItem(title: "Decrease Duration", action: #selector(decreaseDuration), keyEquivalent: String(Unicode.Scalar(NSDownArrowFunctionKey)!))
        decreaseItem.keyEquivalentModifierMask = [.command, .shift]
        preferencesMenu.addItem(decreaseItem)

        preferencesMenu.addItem(NSMenuItem.separator())

        // Sound toggle
        let soundItem = NSMenuItem(title: "Play Sound on Complete", action: #selector(toggleSound), keyEquivalent: "")
        soundItem.state = preferences.playSoundOnComplete ? .on : .off
        soundItem.tag = 2
        preferencesMenu.addItem(soundItem)

        // Visual alert toggle
        let visualItem = NSMenuItem(title: "Show Red Alert", action: #selector(toggleVisualAlert), keyEquivalent: "")
        visualItem.state = preferences.showRedAlert ? .on : .off
        visualItem.tag = 3
        preferencesMenu.addItem(visualItem)

        // Corner position
        preferencesMenu.addItem(NSMenuItem.separator())
        let positionItem = NSMenuItem(title: "Overlay Position", action: nil, keyEquivalent: "")
        let positionMenu = NSMenu()

        let leftItem = NSMenuItem(title: "Left", action: #selector(setPositionLeft), keyEquivalent: "")
        if case .left = preferences.overlayPosition {
            leftItem.state = .on
        }
        positionMenu.addItem(leftItem)

        let rightItem = NSMenuItem(title: "Right", action: #selector(setPositionRight), keyEquivalent: "")
        if case .right = preferences.overlayPosition {
            rightItem.state = .on
        }
        positionMenu.addItem(rightItem)

        let customItem = NSMenuItem(title: "Custom", action: nil, keyEquivalent: "")
        customItem.isEnabled = false  // Read-only indicator
        if case .custom = preferences.overlayPosition {
            customItem.state = .on
        }
        positionMenu.addItem(customItem)

        positionItem.submenu = positionMenu
        preferencesMenu.addItem(positionItem)

        let preferencesItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
        preferencesItem.submenu = preferencesMenu
        menu.addItem(preferencesItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func setupApplicationMenu() {
        let mainMenu = NSMenu()

        // App menu (first menu - shows as app name in menu bar)
        let appMenuItem = NSMenuItem()
        appMenuItem.title = "PitchTimer"
        let appMenu = NSMenu(title: "PitchTimer")

        appMenu.addItem(NSMenuItem(title: "About PitchTimer", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Hide PitchTimer", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "Quit PitchTimer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Timer menu
        let timerMenuItem = NSMenuItem()
        let timerMenu = NSMenu(title: "Timer")

        timerMenu.addItem(NSMenuItem(title: "Start/Stop", action: #selector(toggleTimer), keyEquivalent: ""))
        timerMenu.addItem(NSMenuItem(title: "Reset", action: #selector(resetTimer), keyEquivalent: "r"))
        timerMenu.addItem(NSMenuItem.separator())
        timerMenu.addItem(NSMenuItem(title: "Increase Duration", action: #selector(increaseDuration), keyEquivalent: "+"))
        timerMenu.addItem(NSMenuItem(title: "Decrease Duration", action: #selector(decreaseDuration), keyEquivalent: "-"))
        timerMenu.addItem(NSMenuItem.separator())
        timerMenu.addItem(NSMenuItem(title: "Toggle Overlay", action: #selector(toggleOverlay), keyEquivalent: "t"))

        timerMenuItem.submenu = timerMenu
        mainMenu.addItem(timerMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")

        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: ""))

        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "PitchTimer",
            .applicationVersion: "1.0.0",
            .credits: NSAttributedString(string: "A simple, elegant timer for macOS")
        ])
    }

    @objc private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(preferences: preferences)
            settingsWindowController?.delegate = self
        }
        settingsWindowController?.showWindow(nil)
    }

    @objc private func toggleTimer() {
        if timerManager.isRunning {
            timerManager.stop()
            updateMenuItemTitle(tag: 1, title: "Start Timer")
            networkManager.broadcast(.stop)
            networkManager.stopTimeSyncBroadcast()
        } else {
            timerManager.start()
            updateMenuItemTitle(tag: 1, title: "Stop Timer")
            networkManager.broadcast(.start)

            // Start time sync broadcasting if we're the host
            networkManager.startTimeSyncBroadcast { [weak self] in
                guard let self = self else { return (0, false) }
                return (self.timerManager.currentTime, self.timerManager.isRunning)
            }
        }
    }

    @objc private func toggleOverlay() {
        timerWindowController?.toggleVisibility()
    }

    @objc private func toggleFullScreen() {
        let newMode: DisplayMode = (preferences.displayMode == .fullScreen) ? .overlay : .fullScreen
        switchDisplayMode(to: newMode)
    }

    private func switchDisplayMode(to mode: DisplayMode) {
        preferences.displayMode = mode

        switch mode {
        case .overlay:
            // Close full-screen
            fullScreenWindowController?.close()
            fullScreenWindowController = nil

            // Show overlay
            timerWindowController?.window?.makeKeyAndOrderFront(nil)

        case .fullScreen:
            // Hide overlay
            timerWindowController?.window?.orderOut(nil)

            // Create and show full-screen
            fullScreenWindowController = FullScreenWindowController(preferences: preferences)
            fullScreenWindowController?.delegate = self
            fullScreenWindowController?.showOnScreen(preferences.preferredFullScreenScreen)

            // Update with current time
            fullScreenWindowController?.updateDisplay(timeRemaining: timerManager.currentTime)
        }

        // Broadcast to network peers
        networkManager.broadcast(.setDisplayMode(mode))

        // Update menu item title
        updateFullScreenMenuItem()
    }

    private func updateFullScreenMenuItem() {
        guard let menu = statusItem?.menu else { return }
        let title = (preferences.displayMode == .fullScreen) ? "Exit Full Screen" : "Enter Full Screen"
        for item in menu.items where item.tag == 4 {
            item.title = title
            break
        }
    }

    @objc private func resetTimer() {
        timerManager.reset()
        updateMenuItemTitle(tag: 1, title: "Start Timer")
        networkManager.broadcast(.reset)
        networkManager.stopTimeSyncBroadcast()
    }

    @objc private func increaseDuration() {
        preferences.timerDuration += 60 // Increase by 1 minute
        timerManager.reset()
        showDurationNotification()
        networkManager.broadcast(.setDuration(preferences.timerDuration))
    }

    @objc private func decreaseDuration() {
        if preferences.timerDuration > 60 { // Minimum 1 minute
            preferences.timerDuration -= 60 // Decrease by 1 minute
            timerManager.reset()
            showDurationNotification()
            networkManager.broadcast(.setDuration(preferences.timerDuration))
        }
    }

    private func showDurationNotification() {
        // Update window to show current duration
        timerWindowController?.updateDisplay(timeRemaining: preferences.timerDuration)
    }

    @objc private func showDurationDialog() {
        let alert = NSAlert()
        alert.messageText = "Set Timer Duration"
        alert.informativeText = "Enter duration in seconds:"

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = "\(preferences.timerDuration)"
        input.placeholderString = "Seconds"
        alert.accessoryView = input

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let duration = Int(input.stringValue), duration > 0 {
                preferences.timerDuration = duration
                timerManager.reset()
                networkManager.broadcast(.setDuration(duration))
            }
        }
    }

    @objc private func toggleSound() {
        preferences.playSoundOnComplete.toggle()
        updateMenuItemState(tag: 2, state: preferences.playSoundOnComplete ? .on : .off)
    }

    @objc private func toggleVisualAlert() {
        preferences.showRedAlert.toggle()
        updateMenuItemState(tag: 3, state: preferences.showRedAlert ? .on : .off)
        timerWindowController?.updateVisualAlert()
    }

    @objc private func setPositionLeft() {
        preferences.overlayPosition = .left
        timerWindowController?.updatePosition()
        updatePositionMenuItems()
    }

    @objc private func setPositionRight() {
        preferences.overlayPosition = .right
        timerWindowController?.updatePosition()
        updatePositionMenuItems()
    }

    @objc private func showNetworkSync() {
        if networkWindow == nil {
            let viewController = NetworkViewController()
            networkViewController = viewController

            viewController.onHost = { [weak self] in
                guard let self = self else { return "" }
                return self.networkManager.startHosting()
            }

            viewController.onJoin = { [weak self] code, completion in
                guard let self = self else {
                    completion(false)
                    return
                }
                self.networkManager.joinSession(code: code, completion: completion)
            }

            viewController.onDisconnect = { [weak self] in
                self?.networkManager.disconnect()
            }

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Network Sync"
            window.contentViewController = viewController
            window.center()
            window.isReleasedWhenClosed = false

            networkWindow = window
        }

        networkWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func hostNetwork() {
        let code = networkManager.startHosting()

        let alert = NSAlert()
        alert.messageText = "Hosting Network Session"
        alert.informativeText = "Share this code with others to join:\n\n\(code)\n\nOthers can press Cmd+Shift+J to join."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func joinNetwork() {
        let alert = NSAlert()
        alert.messageText = "Join Network Session"
        alert.informativeText = "Enter the 6-digit session code:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Join")
        alert.addButton(withTitle: "Cancel")

        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputTextField.placeholderString = "123456"
        alert.accessoryView = inputTextField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let code = inputTextField.stringValue.trimmingCharacters(in: .whitespaces)
            if !code.isEmpty {
                networkManager.joinSession(code: code) { success in
                    DispatchQueue.main.async {
                        if !success {
                            let errorAlert = NSAlert()
                            errorAlert.messageText = "Connection Failed"
                            errorAlert.informativeText = "Could not connect to session '\(code)'. Make sure the code is correct and both devices are on the same network."
                            errorAlert.alertStyle = .warning
                            errorAlert.addButton(withTitle: "OK")
                            errorAlert.runModal()
                        }
                    }
                }
            }
        }
    }

    private func updateMenuItemTitle(tag: Int, title: String) {
        if let menu = statusItem?.menu,
           let item = menu.item(withTag: tag) {
            item.title = title
        }
    }

    private func updateMenuItemState(tag: Int, state: NSControl.StateValue) {
        if let menu = statusItem?.menu,
           let prefsItem = menu.item(withTitle: "Preferences"),
           let prefsMenu = prefsItem.submenu,
           let item = prefsMenu.item(withTag: tag) {
            item.state = state
        }
    }

    private func updatePositionMenuItems() {
        if let menu = statusItem?.menu,
           let prefsItem = menu.item(withTitle: "Preferences"),
           let prefsMenu = prefsItem.submenu,
           let positionItem = prefsMenu.item(withTitle: "Overlay Position"),
           let positionMenu = positionItem.submenu {

            // Update menu item states based on current position
            positionMenu.item(withTitle: "Left")?.state = {
                if case .left = preferences.overlayPosition { return .on }
                return .off
            }()

            positionMenu.item(withTitle: "Right")?.state = {
                if case .right = preferences.overlayPosition { return .on }
                return .off
            }()

            positionMenu.item(withTitle: "Custom")?.state = {
                if case .custom = preferences.overlayPosition { return .on }
                return .off
            }()
        }
    }
}

extension AppDelegate: TimerManagerDelegate {
    func timerDidComplete() {
        if preferences.playSoundOnComplete {
            NSSound.beep()
        }
        updateMenuItemTitle(tag: 1, title: "Start Timer")
    }

    func timerDidUpdate(timeRemaining: Int) {
        switch preferences.displayMode {
        case .overlay:
            timerWindowController?.updateDisplay(timeRemaining: timeRemaining)
        case .fullScreen:
            fullScreenWindowController?.updateDisplay(timeRemaining: timeRemaining)
        }
    }
}

extension AppDelegate: HotkeyManagerDelegate {
    func hotkeyPressed(type: HotkeyType) {
        switch type {
        case .startStop:
            toggleTimer()
        case .reset:
            resetTimer()
        case .increaseDuration:
            increaseDuration()
        case .decreaseDuration:
            decreaseDuration()
        case .setDuration:
            showDurationDialog()
        case .hostNetwork:
            hostNetwork()
        case .joinNetwork:
            joinNetwork()
        case .toggleFullScreen:
            toggleFullScreen()
        }
    }
}

extension AppDelegate: NetworkManagerDelegate {
    func didReceiveTimerCommand(_ command: TimerCommand) {
        switch command {
        case .start:
            if !timerManager.isRunning {
                timerManager.start()
                updateMenuItemTitle(tag: 1, title: "Stop Timer")
            }
        case .stop:
            if timerManager.isRunning {
                timerManager.stop()
                updateMenuItemTitle(tag: 1, title: "Start Timer")
            }
        case .reset:
            timerManager.reset()
            updateMenuItemTitle(tag: 1, title: "Start Timer")
        case .setDuration(let duration):
            preferences.timerDuration = duration
            timerManager.reset()
        case .updateTime(let time, let running):
            // Sync timer state from host (perfect sync)
            timerManager.setTime(time, isRunning: running)
            updateMenuItemTitle(tag: 1, title: running ? "Stop Timer" : "Start Timer")
        case .setDisplayMode(let mode):
            if preferences.displayMode != mode {
                switchDisplayMode(to: mode)
            }
        }
    }

    func didUpdateConnectionStatus(_ status: ConnectionStatus) {
        networkViewController?.updateStatus(status)
    }
}

// MARK: - SettingsWindowDelegate

extension AppDelegate: SettingsWindowDelegate {
    func settingsDidChange() {
        // Reset timer with new duration
        timerManager.reset()

        // Switch display mode if changed
        switchDisplayMode(to: preferences.displayMode)

        // Update overlay position
        timerWindowController?.updatePosition()

        // Update menu item states
        updateMenuItemState(tag: 2, state: preferences.playSoundOnComplete ? .on : .off)
        updateMenuItemState(tag: 3, state: preferences.showRedAlert ? .on : .off)
        updatePositionMenuItems()

        // Broadcast duration change if connected
        networkManager.broadcast(.setDuration(preferences.timerDuration))
    }
}

// MARK: - TimerWindowDelegate

extension AppDelegate: TimerWindowDelegate {
    func timerWindowDidChangePosition() {
        // Update menu items to reflect custom position
        updatePositionMenuItems()
    }
}

// MARK: - FullScreenWindowDelegate

extension AppDelegate: FullScreenWindowDelegate {
    func fullScreenWindowDidRequestExit() {
        switchDisplayMode(to: .overlay)
    }
}
