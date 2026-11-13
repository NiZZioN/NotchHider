#!/bin/zsh
# Security and lint checks for the scripts, workflows and git history. Runs in CI ("Security scan")
# and locally. Needs: actionlint, zizmor, gitleaks (brew install actionlint zizmor gitleaks).
# zizmor's online audits use GH_TOKEN; locally it falls back to `gh auth token`, else runs offline.
cd "$(dirname "$0")"
rc=0
run() { echo "== $1"; shift; "$@" || { echo "FAIL"; rc=1; }; }
for tool in actionlint zizmor gitleaks; do
  command -v $tool >/dev/null || { echo "Missing $tool (brew install actionlint zizmor gitleaks)"; exit 2; }
done

# shellcheck can't parse zsh, so the scripts get zsh's own syntax check.
run "zsh -n" zsh -c 'for f in *.sh; do zsh -n "$f" || { echo "syntax error: $f"; exit 1; }; done'
run actionlint actionlint

: ${GH_TOKEN:=$(gh auth token 2>/dev/null)}
if [[ -n $GH_TOKEN ]]; then
  run zizmor env GH_TOKEN="$GH_TOKEN" zizmor --persona=auditor --no-progress .github
else
  run "zizmor (offline)" zizmor --persona=auditor --no-progress --offline .github
fi

run "gitleaks (history)" gitleaks git . --no-banner --redact
run "gitleaks (working tree)" gitleaks dir . --no-banner --redact

(( rc == 0 )) && echo "PASS: security scan clean" || echo "FAIL: see above"
exit $rc
