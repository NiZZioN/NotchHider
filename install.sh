#!/bin/zsh
# Builds the app, copies it to ~/Applications (or --dest <folder>) and starts it.
# --login also turns on "Launch at login".
set -e
cd "$(dirname "$0")"
DEST="$HOME/Applications"; LOGIN=0
while (( $# )); do case $1 in --login) LOGIN=1;; --dest) DEST=$2; shift;; esac; shift; done
./build.sh
pkill -x NotchHider 2>/dev/null && sleep 1 || true
mkdir -p "$DEST"
rm -rf "$DEST/NotchHider.app"
cp -R build/NotchHider.app "$DEST/"
(( LOGIN )) && "$DEST/NotchHider.app/Contents/MacOS/NotchHider" --register-login-item && echo "Launch at login: on"
open "$DEST/NotchHider.app"
echo "Installed to $DEST/NotchHider.app and started."
(( LOGIN )) || echo "Tip: turn on 'Launch at login' in its Settings window (or re-run with --login)."
