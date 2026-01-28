# PitchTimer

A lightweight macOS menu bar timer app with overlay display and global hotkey support.

## Features

- **Menu Bar Integration**: Quick access from the macOS menu bar
- **Overlay Display**: Transparent, draggable overlay window positioned in screen corners
- **Application Menu**: Full menu bar when timer window is active
- **Settings Window**: Unified settings interface (Cmd+,)
- **Global Hotkeys**: Full keyboard control for timer operations
- **CLI Mode**: Terminal-based interface for headless operation 🆕
- **Countdown Timer**: Configurable duration with visual countdown
- **Overtime Tracking**: Timer continues into negative numbers showing how much you've overshot
- **Network Sync**: Connect multiple machines to run timers in perfect sync 🆕
- **Perfect Time Sync**: Millisecond-accurate synchronization across machines 🆕
- **Meeting Code System**: Easy connection using 6-digit codes 🆕
- **Alerts**: Optional sound playback and red visual indicator when timer completes
- **Customizable**: Choose overlay position (left/right corner) and alert preferences
- **Proper Focus Handling**: Click outside to defocus, timer stays on top when active

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later (for building)

## Building

### Using Swift Package Manager

```bash
cd PitchTimer
swift build -c release
```

The built executable will be at `.build/release/PitchTimer`

### Building DMG Installer

To create a distributable DMG with app icon:

```bash
cd PitchTimer
./build-dmg.sh
```

The DMG will be created at `build/PitchTimer-1.0.0.dmg`

### Regenerating Icons (Optional)

If you want to modify the app icon design:

```bash
cd PitchTimer
swift create-icon.swift          # Generate app icon
swift create-menubar-icon.swift  # Generate menu bar icon
./build-dmg.sh                   # Rebuild with new icons
```

### Running

```bash
swift run
```

Or run the built executable:

```bash
.build/release/PitchTimer
```

### Running with Custom Duration

You can specify an initial timer duration (in seconds) via command line:

```bash
# Run with 10 minute timer (600 seconds)
swift run PitchTimer -- -d 600

# Or using the built executable
.build/release/PitchTimer --duration 300
```

Available flags:
- `-d <seconds>` or `--duration <seconds>`: Set initial timer duration in seconds
- `-c` or `--cli`: Run in CLI mode (terminal-based interface)

### CLI Mode

Run the timer in your terminal without the GUI:

```bash
# Launch in CLI mode
.build/release/PitchTimer --cli

# With custom duration
.build/release/PitchTimer --cli -d 600
```

CLI Mode Controls:
- `[space]` - Start/Stop timer
- `r` - Reset timer
- `+`/`-` - Increase/Decrease duration by 1 minute
- `q` - Quit

## Usage

1. **Start the App**: Launch PitchTimer - it will appear in your menu bar
2. **Set Duration**:
   - Click menu bar icon → Preferences → Set Duration
   - Or press `Cmd+Shift+D` to open dialog
   - Or press `Cmd+Shift+↑` / `Cmd+Shift+↓` to adjust by 1 minute
   - Or launch with duration: `PitchTimer -d 600`
3. **Start Timer**: Click "Start Timer" from the menu or press `Cmd+Shift+T`
4. **Overlay**: The timer countdown appears in the screen corner (draggable)
5. **Adjust Timer**: Use arrow keys with `Cmd+Shift` to fine-tune duration while running
6. **Overtime**: Timer continues past zero with red background (e.g., 🔴 01:23)
7. **Stop Timer**: Click "Stop Timer" or press `Cmd+Shift+T` again
8. **Reset Timer**: Click "Reset Timer" or press `Cmd+Shift+R`

## Preferences

Access preferences via:
- **Menu Bar Icon**: Click the timer icon in the menu bar
- **Settings Window**: Press `Cmd+,` or click the timer overlay and choose PitchTimer → Settings
- **When Timer is Active**: Full application menu appears in the menu bar

Settings include:
- **Timer Duration**: Specify timer length in minutes
- **Play Sound on Complete**: Toggle sound alert
- **Show Red Alert**: Toggle red visual indicator when timer completes
- **Overlay Position**: Choose left or right corner

## Window Behavior

- **Menu Bar App**: PitchTimer lives in the menu bar (no Dock icon)
- **Application Name**: "PitchTimer" appears in menu bar when timer window is focused
- **Always On Top**: Timer overlay stays on top when app is active
- **Click to Focus**: Click the timer overlay to show application menu
- **Click Outside**: Click outside the timer to defocus and let other apps come forward
- **Draggable**: Drag the timer overlay by clicking and dragging anywhere on it
- **Smart Positioning**:
  - **Left**: Positions timer at top-left corner
  - **Right**: Positions timer at top-right corner
  - **Custom**: Automatically switches to custom when you drag the timer
  - Custom position is remembered until you select Left or Right again

## Hotkeys

### Timer Controls
- `Cmd+Shift+T`: Start/Stop timer
- `Cmd+Shift+R`: Reset timer
- `Cmd+Shift+↑`: Increase duration by 1 minute
- `Cmd+Shift+↓`: Decrease duration by 1 minute
- `Cmd+Shift+D`: Open duration settings dialog

### Network Sync
- `Cmd+Shift+H`: Host network session (shows code dialog)
- `Cmd+Shift+J`: Join network session (shows input dialog)

### Settings
- `Cmd+,`: Open Settings window (standard macOS shortcut)

**Note**: All keyboard shortcuts are also displayed in the menu bar dropdown for easy reference.

## Network Sync

Sync timers across multiple machines on the same network:

### Host a Session
1. Click menu bar icon → **Network Sync...**
2. Click **Start Hosting**
3. Share the 6-digit code with others
4. All connected timers will sync automatically

### Join a Session
1. Click menu bar icon → **Network Sync...**
2. Enter the 6-digit code
3. Click **Join**
4. Your timer syncs with the host

### Features
- ✅ Start/stop from any connected machine
- ✅ **Perfect sync** - All timers stay synchronized to the millisecond
- ✅ Host broadcasts time updates 10 times per second
- ✅ Duration changes sync automatically
- ✅ Works over local network (WiFi/Ethernet)
- ✅ Simple 6-digit meeting codes
- ✅ Automatic discovery via UDP broadcast

### Troubleshooting
If connection fails, check:
- Both machines on **same WiFi network**
- Firewall not blocking PitchTimer
- Code entered correctly (6 digits, no spaces)
- See `NETWORK-TROUBLESHOOTING.md` for detailed help

## Examples

### Quick 5-Minute Timer
```bash
swift run PitchTimer -- -d 300
```

### 25-Minute Pomodoro Timer
```bash
.build/release/PitchTimer -d 1500
```

### 1-Hour Presentation Timer
```bash
.build/release/PitchTimer --duration 3600
```

### Keyboard-Only Workflow
1. Launch app: `./run.sh`
2. Increase to desired time: Press `Cmd+Shift+↑` multiple times
3. Start: `Cmd+Shift+T`
4. Timer counts down to 00:00, then continues as 00:01, 00:02, etc.
5. Red background automatically shows overtime (no minus sign needed)
6. Reset when done: `Cmd+Shift+R`

### Presentation Timer with Overtime
Perfect for presentations where you want to see how much you're over/under time:
- Timer hits 00:00 → Beep sounds, turns red
- Continues counting: 00:01, 00:02, 00:15, etc. (with red background)
- Red background indicates overtime - no minus sign needed
- Shows exactly how much overtime you've used
- Never stops until you manually stop or reset it

## Development

See [CLAUDE.md](CLAUDE.md) for development guidelines and architecture details.

## License

Copyright © 2026. All rights reserved.
