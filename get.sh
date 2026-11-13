#!/bin/zsh
# One-line installer for Notch Hider: downloads the source, builds it, installs it to ~/Applications
# and turns on Launch at login.
#
#   curl -fsSL https://raw.githubusercontent.com/NiZZioN/NotchHider/main/get.sh | zsh
#
# Options (after `zsh -s --`):  --no-login   don't turn on Launch at login
#                               --uninstall  remove Notch Hider instead
# Env: NOTCHHIDER_REPO (git URL or path), NOTCHHIDER_REF (branch/tag, default main)

# Everything runs inside main(), so a partially downloaded script never executes half-way.
main() {
  set -e
  local repo="${NOTCHHIDER_REPO:-https://github.com/NiZZioN/NotchHider.git}"
  local ref="${NOTCHHIDER_REF:-main}"
  local login=--login uninstall=0
  for arg in "$@"; do
    case $arg in
      --no-login) login="" ;;
      --uninstall) uninstall=1 ;;
      *) echo "Unknown option: $arg"; return 2 ;;
    esac
  done

  [[ $(uname -s) == Darwin ]] || { echo "Notch Hider only runs on macOS."; return 1; }
  [[ $(uname -m) == arm64 ]] || echo "Note: notched Macs are Apple silicon; this Mac is $(uname -m)."
  if ! xcrun --find swiftc >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
    echo "Notch Hider is built from source and needs Apple's Command Line Tools."
    echo "Starting their installer now. When it finishes, run this command again."
    xcode-select --install 2>/dev/null || true
    return 1
  fi

  local tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT
  echo "Downloading Notch Hider ($ref)..."
  git clone --quiet --depth 1 --branch "$ref" "$repo" "$tmp/NotchHider"

  if (( uninstall )); then
    zsh "$tmp/NotchHider/uninstall.sh"
  else
    echo "Building (runs the tests first)..."
    zsh "$tmp/NotchHider/install.sh" ${login:+$login}
  fi
}

main "$@"
