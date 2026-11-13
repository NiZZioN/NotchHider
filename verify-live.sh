#!/bin/zsh
# Live regression test: captures each running strip window straight from the window server as
# 16-bit float pixels (no 8-bit conversion) and requires every visible pixel to be exactly
# RGB 0.0 (black style). Runs with square and rounded corners, then restores your settings.
# Restarts the app twice. Needs Screen Recording permission for the terminal.
# Usage: ./verify-live.sh [path/to/NotchHider.app]   (default: ~/Applications/NotchHider.app)
set -e
cd "$(dirname "$0")"
APP="${1:-$HOME/Applications/NotchHider.app}"
ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" Info.plist)
[[ -d $APP ]] || { echo "App not found at $APP"; exit 1; }
mkdir -p .build
swiftc -parse-as-library -O -o .build/floatcapture Tests/Live/floatcapture.swift 2>/dev/null
swiftc -O -o .build/windowids Tests/Live/windowids.swift 2>/dev/null

backup=.build/settings-backup.plist
defaults export "$ID" "$backup" 2>/dev/null || rm -f "$backup"
restart() { pkill -x NotchHider 2>/dev/null || true; sleep 1; open -g "$APP"; sleep 2; }
restore() {
  defaults delete "$ID" 2>/dev/null || true
  [[ -f $backup ]] && defaults import "$ID" "$backup"
  restart
}
trap restore EXIT

rc=0
check() {  # $1 = label, $2 = extra floatcapture flag
  restart
  local pid=$(pgrep -x NotchHider) || { echo "FAIL [$1]: NotchHider not running"; rc=1; return }
  local ids=("${(@f)$(.build/windowids $pid)}")
  [[ -z "${ids[1]}" ]] && { echo "FAIL [$1]: no strip window"; rc=1; return }
  for line in "${ids[@]}"; do
    echo -n "[$1] window $line -> "
    .build/floatcapture ${line%% *} $2 || { echo "  ^ FAIL"; rc=1 }
  done
}
defaults write "$ID" enabled -bool YES
defaults write "$ID" hasLaunchedBefore -bool YES
defaults write "$ID" look -string black
defaults write "$ID" roundCorners -bool NO;  check square
defaults write "$ID" roundCorners -bool YES; defaults write "$ID" cornerRadius -float 12; check rounded --expect-transparent
[[ $rc == 0 ]] && echo "PASS: every visible strip pixel is exactly RGB 0" || echo "FAIL"
exit $rc
