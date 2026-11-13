#!/bin/zsh
# Builds a release zip and the matching Homebrew cask.
#   ./release.sh               -> build.noindex/NotchHider-<version>.zip + build.noindex/notchhider.rb
#   ./release.sh --url <URL>   -> same, with a custom download URL in the cask (e.g. file:// for testing)
set -e
cd "$(dirname "$0")"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)
URL="https://github.com/NiZZioN/NotchHider/releases/download/v#{version}/NotchHider-#{version}.zip"
[[ $1 == --url ]] && URL=$2

./build.sh
ZIP="build.noindex/NotchHider-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent build.noindex/NotchHider.app "$ZIP"   # ditto keeps the code signature intact
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)
sed -e "s|@VERSION@|$VERSION|" -e "s|@SHA256@|$SHA|" -e "s|@URL@|$URL|" packaging/notchhider.rb.template > build.noindex/notchhider.rb
echo "Release zip: $ZIP"
echo "sha256:      $SHA"
echo "Cask:        build.noindex/notchhider.rb  (copy to the tap repo as Casks/notchhider.rb)"
