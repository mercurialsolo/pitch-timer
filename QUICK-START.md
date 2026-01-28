# PitchTimer Quick Start

## 🚀 Installation

### Step 1: Install
1. Open `PitchTimer-1.0.0.dmg`
2. Drag **PitchTimer.app** to **Applications**

### Step 2: Fix Gatekeeper (IMPORTANT!)
Open Terminal and run:
```bash
xattr -cr /Applications/PitchTimer.app
```

Or double-click **"Fix Gatekeeper.command"** in the DMG.

### Step 3: Launch
- Open from Applications
- Or use Spotlight: `Cmd+Space` → "PitchTimer"

---

## ⚡ Quick Reference

### Hotkeys
- `Cmd+Shift+T` - Start/Stop
- `Cmd+Shift+R` - Reset
- `Cmd+Shift+↑` - Add 1 minute
- `Cmd+Shift+↓` - Subtract 1 minute
- `Cmd+Shift+D` - Set duration

### Network Sync (Multi-Machine)
1. **Host**: Menu bar → Network Sync → Start Hosting
2. **Share code**: Give 6-digit code to others
3. **Join**: Enter code → Click Join
4. **Control**: Anyone can start/stop/reset

---

## ❓ Common Issues

### "PitchTimer is damaged"
```bash
# Run this in Terminal:
xattr -cr /Applications/PitchTimer.app
```

### "Unidentified developer"
1. Right-click PitchTimer.app
2. Click "Open"
3. Click "Open" again

### Timer icon not showing
- Restart PitchTimer
- Check menu bar isn't hidden

---

## 💡 Tips

- **Drag the overlay** to reposition it
- **Overtime mode**: Timer continues past 00:00 with red background
- **CLI launch**: `PitchTimer -d 300` (5 minutes)
- **Network sync**: Works on same WiFi/network only

---

## 📚 Full Documentation
- `README.md` - Complete feature guide
- `INSTALL.md` - Detailed installation
- `CLAUDE.md` - Development guide
