#!/bin/bash
set -e

APP_NAME="Teleprompter"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
VERSION="1.0"

# Build first if needed
if [ ! -d "$APP_BUNDLE" ]; then
    echo "App not found, building first..."
    ./build.sh
fi

echo "Packaging $APP_NAME..."

# --- PKG Installer ---
echo ""
echo "Creating .pkg installer..."

pkgbuild \
    --root "$APP_BUNDLE" \
    --identifier "com.teleprompter.app" \
    --version "$VERSION" \
    --install-location "/Applications/$APP_NAME.app" \
    "$BUILD_DIR/$APP_NAME.pkg"

echo "PKG created: $BUILD_DIR/$APP_NAME.pkg"

# --- DMG Disk Image ---
echo ""
echo "Creating .dmg disk image..."

DMG_DIR="$BUILD_DIR/dmg-staging"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Copy app into staging
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Add Applications symlink for drag-to-install
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$BUILD_DIR/$APP_NAME.dmg" \
    2>&1

rm -rf "$DMG_DIR"

echo "DMG created: $BUILD_DIR/$APP_NAME.dmg"

# --- ZIP (simplest) ---
echo ""
echo "Creating .zip archive..."

cd "$BUILD_DIR"
zip -r -q "$APP_NAME.zip" "$APP_NAME.app"
cd ..

echo "ZIP created: $BUILD_DIR/$APP_NAME.zip"

# Summary
echo ""
echo "========================================="
echo "  Packaging complete!"
echo "========================================="
echo ""
echo "  PKG installer:  $BUILD_DIR/$APP_NAME.pkg"
echo "  DMG disk image:  $BUILD_DIR/$APP_NAME.dmg"
echo "  ZIP archive:     $BUILD_DIR/$APP_NAME.zip"
echo ""
echo "  Share whichever format you prefer."
echo ""
echo "  NOTE: The app is ad-hoc signed (no Apple Developer ID)."
echo "  Recipients will need to:"
echo "    1. Right-click the app > Open (first launch only)"
echo "    2. Or: System Settings > Privacy & Security > Open Anyway"
echo ""
