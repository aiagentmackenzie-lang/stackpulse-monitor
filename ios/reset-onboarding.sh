#!/bin/bash
# Reset StackPulse onboarding state
# Run this to force fresh onboarding

echo "Resetting StackPulse UserDefaults..."

# Kill app if running
xcrun devicectl device terminate --device 9951F577-F60D-559E-B392-3109D2BD4D92 app.rork.stackpulse-monitor 2>/dev/null || true

# Clear UserDefaults for the app
# Note: This requires the device to be unlocked
xcrun devicectl device clear-app-data --device 9951F577-F60D-559E-B392-3109D2BD4D92 app.rork.stackpulse-monitor 2>/dev/null || echo "Could not clear app data - app will be fresh on reinstall anyway"

echo "✅ Done. Reinstall the app for fresh onboarding."
echo ""
echo "Safe presets to test:"
echo "  1. Express (.npm) - will definitely work"
echo "  2. Django (.platform → PyPI) - should work now"
echo "  3. Node.js (.platform → NPM) - should work now"