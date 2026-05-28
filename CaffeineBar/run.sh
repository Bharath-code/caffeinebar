#!/bin/bash
# CaffeineBar — Build & Run as .app bundle
# Usage: ./run.sh [--release]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="CaffeineBar"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
BUILD_CONFIG="debug"

if [[ "$1" == "--release" ]]; then
    BUILD_CONFIG="release"
    echo "Building in release mode..."
    swift build -c release
else
    echo "Building in debug mode..."
    swift build
fi

BUILD_DIR="$SCRIPT_DIR/.build/$BUILD_CONFIG"

# Kill any existing instance
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5

echo "Packaging $APP_NAME.app..."

# Create .app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "$SCRIPT_DIR/Sources/Info.plist" "$APP_BUNDLE/Contents/"

# Copy resource bundle (sounds, assets)
RESOURCE_BUNDLE="$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
    echo "  ✓ Resources copied"
fi

# Copy Sparkle framework if present
SPARKLE_FW="$BUILD_DIR/Sparkle.framework"
if [ -d "$SPARKLE_FW" ]; then
    mkdir -p "$APP_BUNDLE/Contents/Frameworks"
    cp -R "$SPARKLE_FW" "$APP_BUNDLE/Contents/Frameworks/"
    echo "  ✓ Sparkle.framework copied"
fi

echo "  ✓ $APP_NAME.app ready"
echo ""
echo "Launching..."
open "$APP_BUNDLE"
echo "Done. Look for the cup icon in your menu bar."
echo "To quit: right-click the menu bar icon or use Activity Monitor."
