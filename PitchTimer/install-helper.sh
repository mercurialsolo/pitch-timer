#!/bin/bash

# PitchTimer Installation Helper
# This script removes the quarantine attribute that causes the "damaged app" error

echo "🔧 PitchTimer Installation Helper"
echo "=================================="
echo ""

# Check if PitchTimer.app exists in Applications
if [ -d "/Applications/PitchTimer.app" ]; then
    echo "✓ Found PitchTimer.app in Applications"
    echo ""
    echo "Removing quarantine attribute..."
    xattr -cr "/Applications/PitchTimer.app"

    if [ $? -eq 0 ]; then
        echo "✅ Success! PitchTimer is ready to use."
        echo ""
        echo "You can now launch PitchTimer from:"
        echo "  • Applications folder"
        echo "  • Spotlight (Cmd+Space → 'PitchTimer')"
        echo "  • Launchpad"
        echo ""

        # Ask if they want to launch now
        read -p "Launch PitchTimer now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "/Applications/PitchTimer.app"
        fi
    else
        echo "❌ Failed to remove quarantine. Try running with sudo:"
        echo "   sudo $0"
    fi
else
    echo "❌ PitchTimer.app not found in /Applications"
    echo ""
    echo "Please install PitchTimer first:"
    echo "  1. Open PitchTimer-1.0.0.dmg"
    echo "  2. Drag PitchTimer.app to Applications"
    echo "  3. Run this script again"
fi

echo ""
