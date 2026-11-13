#!/bin/zsh
# Compiles Sources/Core + Tests with Swift Testing and runs them. Works without SwiftPM.
# Supports Command Line Tools and Xcode toolchains (whichever `xcode-select -p` points at).
set -e
cd "$(dirname "$0")"
DEV=$(xcode-select -p)
if [[ -d "$DEV/Platforms/MacOSX.platform" ]]; then          # full Xcode
  FW="$DEV/Platforms/MacOSX.platform/Developer/Library/Frameworks"
  LIB="$DEV/Platforms/MacOSX.platform/Developer/usr/lib"
  PLUGINS="$DEV/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing"
else                                                        # Command Line Tools
  FW="$DEV/Library/Developer/Frameworks"
  LIB="$DEV/Library/Developer/usr/lib"
  PLUGINS="$DEV/usr/lib/swift/host/plugins/testing"
fi
mkdir -p .build
swiftc -parse-as-library -F "$FW" -plugin-path "$PLUGINS" \
  -Xlinker -rpath -Xlinker "$FW" -Xlinker -rpath -Xlinker "$LIB" \
  -o .build/tests Sources/Core/*.swift Tests/*.swift
.build/tests
