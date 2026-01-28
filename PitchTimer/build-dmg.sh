#!/bin/bash
set -e

echo "🔨 Building PitchTimer..."

# Build release version
swift build -c release

# Create app bundle structure
APP_NAME="PitchTimer.app"
APP_DIR="build/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 Creating app bundle structure..."
rm -rf build
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
echo "📋 Copying executable..."
cp .build/release/PitchTimer "${MACOS_DIR}/PitchTimer"
chmod +x "${MACOS_DIR}/PitchTimer"

# Copy app icon if it exists
if [ -f "AppIcon.icns" ]; then
    echo "🎨 Copying app icon..."
    cp AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
else
    echo "⚠️  No app icon found, skipping..."
fi

# Copy menu bar icons if they exist
if [ -f "MenuBarIcon.png" ]; then
    echo "🎨 Copying menu bar icons..."
    cp MenuBarIcon.png "${RESOURCES_DIR}/MenuBarIcon.png"
    cp MenuBarIcon@2x.png "${RESOURCES_DIR}/MenuBarIcon@2x.png"
else
    echo "⚠️  No menu bar icons found, skipping..."
fi

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>PitchTimer</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.pitchtimer.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>PitchTimer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

echo "✅ App bundle created at: build/${APP_NAME}"

# Create DMG
echo "💿 Creating DMG..."
DMG_NAME="PitchTimer-1.0.0.dmg"
DMG_TEMP="build/dmg-temp"
DMG_PATH="build/${DMG_NAME}"

# Clean up previous DMG
rm -f "${DMG_PATH}"
rm -rf "${DMG_TEMP}"

# Create temporary DMG directory
mkdir -p "${DMG_TEMP}"

# Copy app to DMG temp directory
cp -R "${APP_DIR}" "${DMG_TEMP}/"

# Create Applications symlink
ln -s /Applications "${DMG_TEMP}/Applications"

# Copy install helper if it exists
if [ -f "install-helper.sh" ]; then
    cp install-helper.sh "${DMG_TEMP}/Fix Gatekeeper.command"
    chmod +x "${DMG_TEMP}/Fix Gatekeeper.command"
fi

# Create README in DMG
cat > "${DMG_TEMP}/README.txt" << 'EOF'
PitchTimer - Menu Bar Timer with Overtime Tracking
===================================================

INSTALLATION:
1. Drag PitchTimer.app to the Applications folder
2. Open Terminal and run: xattr -cr /Applications/PitchTimer.app
3. Open PitchTimer from Applications or Spotlight
4. The timer icon will appear in your menu bar

TROUBLESHOOTING:
If you see "PitchTimer is damaged" error:
• This is a macOS security warning (app is NOT actually damaged)
• Open Terminal and run: xattr -cr /Applications/PitchTimer.app
• Or right-click PitchTimer.app → Open → Open
• This removes the quarantine flag on unsigned apps

KEYBOARD SHORTCUTS:
• Cmd+Shift+T    Start/Stop timer
• Cmd+Shift+R    Reset timer
• Cmd+Shift+↑    Increase duration by 1 minute
• Cmd+Shift+↓    Decrease duration by 1 minute
• Cmd+Shift+D    Open duration dialog

FEATURES:
• Menu bar timer with overlay display
• Overtime tracking (continues counting with red background after zero)
• Draggable overlay window
• Large, easy-to-read display (48pt font)
• Customizable duration, position, and alerts
• CLI support: PitchTimer -d 600

For more information, visit the project repository.

Copyright © 2026. All rights reserved.
EOF

# Create DMG
echo "🔧 Creating disk image..."
hdiutil create -volname "PitchTimer" \
    -srcfolder "${DMG_TEMP}" \
    -ov -format UDZO \
    "${DMG_PATH}"

# Clean up temp directory
rm -rf "${DMG_TEMP}"

echo ""
echo "✅ DMG created successfully!"
echo "📍 Location: ${DMG_PATH}"
echo ""
echo "To install:"
echo "  1. Open ${DMG_NAME}"
echo "  2. Drag PitchTimer.app to Applications"
echo "  3. Launch from Applications or Spotlight"
echo ""
