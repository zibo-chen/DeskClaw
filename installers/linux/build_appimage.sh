#!/bin/bash
# AppImage packaging script for CoralDesk
# Called from GitHub Actions CI
set -euo pipefail

APP_NAME="CoralDesk"
APP_BINARY="coraldesk"
ARCH="x86_64"
BUILD_DIR="build/linux/x64/release/bundle"
APPDIR="build/AppDir"

# Download appimagetool if not present
if [ ! -f /tmp/appimagetool ]; then
  wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" \
    -O /tmp/appimagetool
  chmod +x /tmp/appimagetool
fi

# Create AppDir structure
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy the Flutter bundle
cp -r "$BUILD_DIR"/* "$APPDIR/usr/bin/"

# Copy desktop file and icon
cp installers/linux/coraldesk.desktop "$APPDIR/usr/share/applications/${APP_BINARY}.desktop"
cp installers/linux/coraldesk.desktop "$APPDIR/${APP_BINARY}.desktop"

# Use app icon if available, otherwise create a placeholder
if [ -f "assets/icons/app_icon.png" ]; then
  cp assets/icons/app_icon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_BINARY}.png"
  cp assets/icons/app_icon.png "$APPDIR/${APP_BINARY}.png"
elif [ -f "assets/icons/icon.png" ]; then
  cp assets/icons/icon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_BINARY}.png"
  cp assets/icons/icon.png "$APPDIR/${APP_BINARY}.png"
fi

# Create AppRun
cat > "$APPDIR/AppRun" << 'APPRUN'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${HERE}/usr/lib:${LD_LIBRARY_PATH:-}"
exec "${HERE}/usr/bin/coraldesk" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# Build AppImage
ARCH=$ARCH /tmp/appimagetool --no-appstream "$APPDIR" \
  "build/${APP_NAME}-${ARCH}.AppImage"

echo "AppImage created: build/${APP_NAME}-${ARCH}.AppImage"
