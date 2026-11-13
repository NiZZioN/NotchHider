#!/bin/zsh
# Removes the login item, quits Notch Hider, deletes the app and its settings.
APP="${1:-$HOME/Applications/NotchHider.app}"
ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$(dirname "$0")/Info.plist")
[[ -x "$APP/Contents/MacOS/NotchHider" ]] && "$APP/Contents/MacOS/NotchHider" --unregister-login-item
pkill -x NotchHider 2>/dev/null
rm -rf "$APP"
defaults delete "$ID" 2>/dev/null
echo "Notch Hider uninstalled."
