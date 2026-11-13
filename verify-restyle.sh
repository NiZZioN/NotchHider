#!/bin/zsh
# Live regression test for changing settings at runtime: restyles ONE window through a sequence of
# radius and black/glass changes, float-capturing it after every step. Every black step must be
# exactly RGB 0 with the right transparency, and the corner cut-out must grow with the radius.
# (Glass steps are only switched through; their look is checked against the real desktop separately.)
cd "$(dirname "$0")"
mkdir -p .build
swiftc -parse-as-library -O -o .build/floatcapture Tests/Live/floatcapture.swift 2>/dev/null
swiftc -parse-as-library -O -o .build/restyle Sources/Core/*.swift Tests/Live/restyle.swift 2>/dev/null || { echo "build failed"; exit 1; }
steps=(black:0 black:12 black:20 black:4 black:0 glass:0 black:0 glass:12 black:12 glass:20 black:0)
rc=0; prev_r=""; prev_t=0
coproc .build/restyle $steps
while read -p look r id; do
  if [[ $look == glass ]]; then echo "glass $r -> (switched)"; prev_r=""; print -p ""; continue; fi
  flag=""; (( r > 0 )) && flag=--expect-transparent
  out=$(.build/floatcapture $id $flag); ok=$?
  t=$(echo "$out" | sed -n 's/.*transparent=\([0-9]*\).*/\1/p')
  msg="black $r -> $out"
  [[ $ok != 0 ]] && { msg="$msg   <- FAIL (non-black pixels or wrong transparency)"; rc=1 }
  if [[ -n $prev_r ]] && (( r > prev_r && t <= prev_t )); then msg="$msg   <- FAIL (cut-out did not grow)"; rc=1; fi
  echo "$msg"; prev_r=$r; prev_t=$t
  print -p ""
done
[[ $rc == 0 ]] && echo "PASS: in-place restyling keeps black pure" || echo "FAIL"
exit $rc
