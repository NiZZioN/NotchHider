#!/bin/zsh
# Runs the unit tests, then builds build.noindex/NotchHider.app (ad-hoc signed, Apple silicon).
# The ".noindex" suffix keeps Spotlight from listing this copy next to the installed app.
set -e
cd "$(dirname "$0")"
APP="build.noindex/NotchHider.app"
# The logo body on an opaque 824px squircle in a 1024 canvas. macOS 26+ puts icons with
# translucent or glowing edges (like assets/hide_notch_logo.png) on a grey tile.
ICON_SRC="assets/AppIcon.png"

echo "Running tests..."
mkdir -p .build
./test.sh > .build/test.log 2>&1 || { cat .build/test.log; echo "Tests failed - not building."; exit 1; }
tail -1 .build/test.log

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"

# App icon: every iconset size from the 1024px source.
ICONSET=".build/AppIcon.iconset"
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z $size $size "$ICON_SRC" --out "$ICONSET/icon_${size}x${size}.png" > /dev/null
  sips -z $((size * 2)) $((size * 2)) "$ICON_SRC" --out "$ICONSET/icon_${size}x${size}@2x.png" > /dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

swiftc -O -target arm64-apple-macos13.0 -o "$APP/Contents/MacOS/NotchHider" Sources/Core/*.swift Sources/App/main.swift
codesign --force -s - "$APP"
echo "Built $APP"
