#!/bin/zsh
# Compiles Sources/Core + Tests with Swift Testing and runs them. Works without SwiftPM, with either
# the Command Line Tools or Xcode (whichever `xcode-select -p` points at): it locates the Testing
# framework, its interop library and the test macros plugin inside the active developer directory.
set -e
cd "$(dirname "$0")"
DEV=$(xcode-select -p)
roots=("$DEV/Platforms/MacOSX.platform/Developer" "$DEV/Library/Developer" "$DEV/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift" "$DEV/usr/lib/swift")
locate() { for r in $roots; do [[ -d $r ]] && find "$r" -maxdepth 5 -name "$1" -print -quit 2>/dev/null; done | head -1; }

FW_PATH=$(locate Testing.framework)
PLUGIN=$(locate libTestingMacros.dylib)
INTEROP=$(locate lib_TestingInterop.dylib)          # only present in newer toolchains
[[ -n $FW_PATH && -n $PLUGIN ]] || { echo "Swift Testing not found under $DEV (need Xcode 16+ or matching Command Line Tools)"; exit 1; }
FW=$(dirname "$FW_PATH")
rpaths=(-Xlinker -rpath -Xlinker "$FW")
[[ -n $INTEROP ]] && rpaths+=(-Xlinker -rpath -Xlinker "$(dirname "$INTEROP")")

mkdir -p .build
swiftc -parse-as-library -F "$FW" -plugin-path "$(dirname "$PLUGIN")" "${rpaths[@]}" \
  -o .build/tests Sources/Core/*.swift Tests/*.swift
.build/tests
