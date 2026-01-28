# Installing PitchTimer

## Download

The installer DMG is located at:
```
PitchTimer/build/PitchTimer-1.0.0.dmg
```

## Installation Steps

### 1. Open the DMG
Double-click `PitchTimer-1.0.0.dmg` to mount it.

### 2. Install the App
Drag `PitchTimer.app` to the `Applications` folder shortcut in the DMG window.

### 3. Launch PitchTimer
You can launch PitchTimer in several ways:
- Open from Applications folder
- Use Spotlight (Cmd+Space, type "PitchTimer")
- Use Launchpad

### 4. First Launch
When you first launch PitchTimer:
1. The timer icon (⏱️) will appear in your menu bar
2. Click the icon to access timer controls
3. The overlay window will appear in the top-right corner (draggable)

## Keyboard Shortcuts

Once installed, you can control the timer globally:

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+T` | Start/Stop timer |
| `Cmd+Shift+R` | Reset timer |
| `Cmd+Shift+↑` | Increase duration by 1 minute |
| `Cmd+Shift+↓` | Decrease duration by 1 minute |
| `Cmd+Shift+D` | Open duration dialog |

## Uninstallation

To remove PitchTimer:
1. Quit the app from the menu bar (Click icon → Quit)
2. Delete `PitchTimer.app` from Applications
3. No other files or preferences are stored

## System Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel processor

## Troubleshooting

### "PitchTimer is damaged and can't be opened" or "from an unidentified developer"

This is a macOS Gatekeeper warning for unsigned apps. **The app is NOT actually damaged.**

**Quick Fix (Recommended):**
```bash
# Open Terminal and run:
xattr -cr /Applications/PitchTimer.app
```

**Alternative Fix:**
1. Right-click (or Control-click) on PitchTimer.app
2. Select "Open" from the menu
3. Click "Open" in the dialog
4. The app will open and this won't be needed again

**Why this happens:**
- PitchTimer is unsigned (no $99/year Apple Developer certificate)
- macOS quarantines apps from unknown sources
- This is normal for apps distributed outside the App Store

### Timer icon doesn't appear in menu bar

1. Make sure PitchTimer is running (check Activity Monitor)
2. Try quitting and relaunching
3. Check System Preferences → General → Menu Bar to ensure menu extras are visible

### Hotkeys don't work

1. Check System Preferences → Keyboard → Shortcuts for conflicts
2. Make sure PitchTimer is running
3. Try restarting the app

## Features

✅ **Menu Bar Timer** - Always accessible from your menu bar
✅ **Overlay Display** - Large, readable countdown (48pt font)
✅ **Overtime Tracking** - Continues counting with red background after zero
✅ **Global Hotkeys** - Control timer without switching apps
✅ **Draggable** - Position overlay wherever you want
✅ **CLI Support** - Launch with custom duration: `PitchTimer -d 600`

## Getting Started

### Quick Start (5-minute timer)
1. Launch PitchTimer
2. Click menu bar icon → Preferences → Set Duration
3. Enter `300` (seconds)
4. Press `Cmd+Shift+T` to start
5. Watch the countdown in the corner!

### For Presentations
1. Set your presentation time (e.g., 10 minutes = 600 seconds)
2. Press `Cmd+Shift+T` to start when you begin
3. Timer counts down: 10:00 → 09:59 → ... → 00:01 → 00:00
4. At zero: beep + red background
5. Continues: 00:01, 00:02, etc. (red = overtime)
6. See exactly how much over/under you went!

## Support

For issues, questions, or feature requests, please check the project documentation:
- `README.md` - Full usage guide
- `CLAUDE.md` - Development documentation
- `IMPLEMENTATION.md` - Technical details
