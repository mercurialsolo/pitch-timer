# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS timer application with the following key requirements:

- **Menu bar integration**: Timer accessible from macOS menu bar
- **Overlay display**: Transparent, draggable overlay positioned in corner (left/right)
- **Hotkey control**: Global hotkeys for start/stop functionality
- **Timer modes**: Support both countdown timer and stopwatch modes
- **Visual/audio alerts**: Optional sound playback and visual indicator (red display) when timer completes
- **Minimal UI**: Small, unobtrusive interface that can be positioned as needed

## Technology Stack

- **Language**: Swift 5.9+
- **Platform**: macOS 13.0+ (Ventura)
- **Build System**: Swift Package Manager
- **Frameworks**: AppKit, Carbon (for global hotkeys)

## Commands

### Build
```bash
cd PitchTimer
swift build -c release
```

### Run (Debug)
```bash
cd PitchTimer
swift run
```

### Run (Release)
```bash
cd PitchTimer
.build/release/PitchTimer
```

### Clean
```bash
cd PitchTimer
swift package clean
```

### Run with CLI Arguments
```bash
cd PitchTimer
# Set initial duration to 10 minutes (600 seconds)
swift run PitchTimer -- -d 600
# Or: swift run PitchTimer -- --duration 600

# Using built executable
.build/release/PitchTimer -d 300
```

### Run in CLI Mode
```bash
cd PitchTimer
# Run terminal-based timer (no GUI)
swift run PitchTimer -- --cli

# CLI mode with custom duration
.build/release/PitchTimer --cli -d 600

# Controls: [space]=start/stop, r=reset, +/-=adjust, q=quit
```

### Build DMG Installer
```bash
cd PitchTimer
./build-dmg.sh
# Creates build/PitchTimer-1.0.0.dmg
```

### Regenerate Icons
```bash
cd PitchTimer
swift create-icon.swift          # App icon (AppIcon.icns)
swift create-menubar-icon.swift  # Menu bar icons
```

## Architecture

### Core Components

**AppDelegate** (`AppDelegate.swift`)
- Main application coordinator
- Manages NSStatusItem (menu bar icon)
- Handles menu interactions and preference updates
- Delegates timer and hotkey events

**TimerManager** (`TimerManager.swift`)
- Core timer logic with Timer-based countdown
- Manages timer state (running/stopped)
- Notifies delegate on tick and completion
- Supports overtime tracking (continues into negative numbers after zero)
- Thread-safe timer operations
- **New**: `setTime()` method for perfect network synchronization

**TimerWindowController** (`TimerWindowController.swift`)
- Controls the overlay window (TimerWindow)
- Handles window positioning based on preferences (left/right corner)
- Updates display with countdown formatting (MM:SS)
- Manages visual alert state (red background when complete)
- Implements draggable, transparent, always-on-top window

**HotkeyManager** (`HotkeyManager.swift`)
- Registers global hotkeys using Carbon Event Manager
- Supports 5 hotkeys:
  - Cmd+Shift+T (start/stop)
  - Cmd+Shift+R (reset)
  - Cmd+Shift+↑ (increase duration)
  - Cmd+Shift+↓ (decrease duration)
  - Cmd+Shift+D (set duration dialog)
- Uses EventHotKey API for system-wide keyboard shortcuts
- Manages array of hotkey references for multiple registrations

**Preferences** (`Preferences.swift`)
- Simple data model for user settings
- No persistence (in-memory only currently)
- Properties: timerDuration, playSoundOnComplete, showRedAlert, overlayPosition
- `OverlayPosition` enum with three cases:
  - `.left` - Top-left corner
  - `.right` - Top-right corner
  - `.custom(x: CGFloat, y: CGFloat)` - User-dragged position with saved coordinates

**SettingsWindowController** (`SettingsWindowController.swift`)
- Dedicated settings window with standard macOS UI
- Accessible via menu or Cmd+, shortcut
- Provides unified interface for all preferences
- Live save/cancel functionality
- Three position options: Left, Right, Custom
- Custom position automatically selected when timer is dragged

**CLITimer** (`CLITimer.swift`)
- Terminal-based timer interface (--cli mode)
- Uses raw terminal mode for immediate keyboard input
- Displays timer countdown in terminal with real-time updates
- Supports keyboard controls: space (start/stop), r (reset), +/- (adjust), q (quit)
- Implements TimerManagerDelegate for timer updates

**NetworkSyncManager** (`NetworkManager2.swift`)
- Handles peer-to-peer timer synchronization with **millisecond-perfect accuracy**
- Uses NWListener/NWConnection for TCP communication
- Supports hosting (server) and joining (client) modes
- Broadcasts timer commands to all connected peers
- **Host broadcasts time sync updates 10 times per second** for perfect synchronization
- Clients receive and apply time updates to stay perfectly in sync with host

**NetworkDiscovery** (`NetworkDiscovery.swift`)
- Bonjour/mDNS service discovery for local network
- Publishes/browses _pitchtimer._tcp. services
- Resolves service addresses for connection
- Enables meeting code based connections

**NetworkViewController** (`NetworkViewController.swift`)
- UI for network sync controls
- Displays 6-digit session codes
- Handles host/join/disconnect actions
- Shows connection status and peer count

### Key Design Patterns

- **Delegation**: TimerManager and HotkeyManager use delegate pattern to notify AppDelegate
- **MVC-like**: TimerWindowController manages view (window), TimerManager manages model (state)
- **Menu Bar App**: Uses NSStatusItem with LSUIElement=true to hide from Dock

### Window Behavior

The overlay window (TimerWindow):
- Borderless with transparent background
- Floating level (always on top when active)
- Draggable by background (isMovableByWindowBackground)
- Smart positioning:
  - **Left**: Top-left corner with 20pt side margin
  - **Right**: Top-right corner with 20pt side margin
  - **Custom**: User-dragged position, automatically saved
- Size: 180×80 pixels with 20pt corner radius
- Large, bold text (48pt semibold monospaced digits)
- Semi-transparent black background (75% opacity)
- Subtle drop shadow for better visibility
- Switches to red when timer completes (if enabled)
- Shows application menu when focused
- Proper focus handling - clicking outside defocuses

### Hotkey Registration

Uses Carbon Event Manager for global hotkeys:
- Registers EventHotKey with GetApplicationEventTarget
- Multiple hotkeys supported via hotKeyRefs array
- Current hotkeys (all with Cmd+Shift modifier):
  - T (kVK_ANSI_T, ID: 1) - Start/Stop
  - R (kVK_ANSI_R, ID: 2) - Reset
  - ↑ (kVK_UpArrow, ID: 3) - Increase duration by 60s
  - ↓ (kVK_DownArrow, ID: 4) - Decrease duration by 60s
  - D (kVK_ANSI_D, ID: 5) - Open duration dialog
  - H (kVK_ANSI_H, ID: 6) - Host network session
  - J (kVK_ANSI_J, ID: 7) - Join network session
- Event handler converts hotkey events to delegate calls via ID matching
- All shortcuts also displayed in menu bar dropdown with keyEquivalent

### CLI Argument Parsing

Main.swift parses command line arguments before app initialization:
- Supports `-d` or `--duration` flags
- Passes initial duration to AppDelegate constructor
- AppDelegate applies CLI duration to Preferences if provided
- Example: `./PitchTimer -d 600` starts with 10-minute timer

## Development Notes

### Adding New Hotkeys
1. Add new case to `HotkeyType` enum
2. Register new hotkey in `HotkeyManager.registerHotkeys()`
3. Handle new type in `AppDelegate.hotkeyPressed(type:)`

### Adding Preferences
1. Add property to `Preferences` class
2. Add menu item in `AppDelegate.setupMenuBar()`
3. Add action handler in `AppDelegate`
4. Update relevant controller (e.g., `TimerWindowController`)

### Timer Customization
- Timer ticks at 1-second intervals via `Timer.scheduledTimer`
- Time remaining tracked in `TimerManager.timeRemaining` (supports negative values)
- Delegate called on each tick for display updates
- Timer continues counting after reaching zero (overtime mode)
- Completion alert fires at zero, but timer keeps running
- Overtime shown with same time format (no minus sign) - red background indicates overtime
- Red visual alert persists throughout overtime period

### Network Synchronization

**Architecture:**
- Peer-to-peer using Network framework (NWListener/NWConnection)
- Host creates TCP listener on dynamic port (59000-60000 range)
- Clients connect directly to host's IP:port
- Dual discovery: Bonjour/mDNS + UDP broadcast

**Discovery Methods:**
1. **UDP Broadcast** (Primary, more reliable)
   - Host broadcasts "{code}:{port}" via UDP on port 59100
   - Broadcasts every 2 seconds
   - Clients listen on UDP 59100 for matching code
   - Extracts IP from UDP packet source

2. **Bonjour/mDNS** (Secondary, fallback)
   - Service type: `_pitchtimer._tcp.`
   - Service name: "PitchTimer-{code}"
   - Published on local domain
   - Automatic name resolution to IP:port

**Session Codes:**
- 6-digit random codes for easy sharing
- Used in both UDP broadcasts and Bonjour service names
- Clients filter broadcasts/services by matching code
- Automatic local network discovery

**Command Protocol:**
- JSON-encoded TimerCommand enum over TCP
- Commands: start, stop, reset, setDuration, updateTime
- Broadcast from initiating machine to all peers
- Received commands trigger same actions on all machines

**State Synchronization:**
- **Perfect Millisecond Sync**: Host broadcasts time updates 10x per second
- AppDelegate intercepts local timer actions (start/stop/reset)
- Broadcasts commands via NetworkSyncManager
- **Host Mode**: When timer starts, begins broadcasting `.updateTime(time, isRunning)` every 100ms
- **Client Mode**: Receives `.updateTime` commands and directly sets timer via `TimerManager.setTime()`
- NetworkManagerDelegate receives remote commands
- Remote commands trigger same TimerManager methods
- Result: All timers display exactly the same time with <100ms latency

**Connection Flow:**
```
Host:
1. NetworkSyncManager.startHosting()
2. Generate 6-digit code
3. Start NWListener on available port
4. Publish Bonjour service "PitchTimer-{code}"
5. Wait for incoming connections

Join:
1. NetworkSyncManager.joinSession(code:)
2. NetworkDiscovery.resolveService(forCode:)
3. Browse for "PitchTimer-{code}" via Bonjour
4. Resolve service to get IP:port
5. Create NWConnection to host
6. Start receiving commands
```

## Icon Assets

### App Icon (AppIcon.icns)
- Generated programmatically via `create-icon.swift`
- Circular timer design with tick marks (60 ticks, every 5th is longer)
- Shows "05 MIN" as default display
- Size: 225KB .icns file with all required resolutions
- Located in `Resources/AppIcon.icns` in app bundle

### Menu Bar Icon
- Generated via `create-menubar-icon.swift`
- Simplified design (12 ticks like a clock face)
- Shows single digit "5" in center
- Template image for automatic dark mode support
- Two sizes: MenuBarIcon.png (18x18) and MenuBarIcon@2x.png (36x36)
- Fallback to system "timer" symbol if custom icons not found

### Icon Generation
Both icons are generated programmatically using Swift/AppKit:
- Pure code, no external image files needed
- Renders circles, tick marks, and text using CoreGraphics
- Can be regenerated anytime by running the Swift scripts
- Automatically converted to required macOS formats

## Limitations

- No persistence: Preferences reset on app restart
- Single hotkey: Only start/stop currently supported
- No stopwatch mode: Only countdown timer implemented
- Basic sound: Uses system beep only
