#!/bin/zsh
# Runs the unit tests, then builds build/NotchHider.app (ad-hoc signed, Apple silicon).
set -e
cd "$(dirname "$0")"
APP="build/NotchHider.app"

echo "Running tests..."
mkdir -p .build
./test.sh > .build/test.log 2>&1 || { cat .build/test.log; echo "Tests failed - not building."; exit 1; }
tail -1 .build/test.log

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"
swiftc -O -target arm64-apple-macos13.0 -o "$APP/Contents/MacOS/NotchHider" Sources/Core/*.swift Sources/App/main.swift
codesign --force -s - "$APP"
echo "Built $APP"
