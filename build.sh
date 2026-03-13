#!/bin/bash
set -e

APP_NAME="Teleprompter"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."

# Clean previous build
rm -rf "$BUILD_DIR"

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="arm64-apple-macos14.0"
else
    TARGET="x86_64-apple-macos14.0"
fi

SDK_PATH=$(xcrun --show-sdk-path)

echo "Target: $TARGET"
echo "SDK: $SDK_PATH"

# Generate app icon
echo "Generating app icon..."
swift generate_icon.swift
iconutil -c icns "$BUILD_DIR/$APP_NAME.iconset" -o "$BUILD_DIR/$APP_NAME.icns"
cp "$BUILD_DIR/$APP_NAME.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
echo "Icon generated."

# Compile
swiftc \
    -parse-as-library \
    -target "$TARGET" \
    -sdk "$SDK_PATH" \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework SwiftUI \
    -framework AppKit \
    -framework AVFoundation \
    -framework Combine \
    -framework Accelerate \
    -Osize \
    Sources/*.swift

echo "Compiled successfully."

# Copy Info.plist
cp Resources/Info.plist "$APP_BUNDLE/Contents/"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Code sign with entitlements
codesign --force --sign - \
    --entitlements Resources/Teleprompter.entitlements \
    "$APP_BUNDLE"

echo ""
echo "Build complete: $APP_BUNDLE"
echo ""
echo "Run with:  open $APP_BUNDLE"
echo ""
