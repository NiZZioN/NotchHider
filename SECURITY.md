# Security

## Reporting a vulnerability

Report it privately through GitHub: **Security → Report a vulnerability** on this repository. Please don't open a public issue for security problems.

## What Notch Hider touches

The app draws a window under the menu bar and stores a few preferences in UserDefaults. Apart from checking whether a Homebrew `Caskroom/notchhider` folder exists (to show the right update instructions), it reads no files. It asks for no permissions (no Screen Recording, Accessibility or similar) and has no entitlements. Its attack surface is mostly the way it is built and delivered.

**Network:** by default the app makes no network requests. It makes exactly one kind, an HTTPS `GET` of `https://api.github.com/repos/NiZZioN/NotchHider/releases/latest`, only when you turn on **Check for updates automatically** (at most once a day) or press **Check now** in Settings. The request uses an ephemeral session (no cookies, no disk cache) and sends no data beyond a `NotchHider/<version>` User-Agent; like any request, it lets GitHub see your IP address. The app reads only `tag_name` from the answer and never downloads or installs anything: it shows the new version, plus either the `brew upgrade` command or a link to the release page. That link is built by the app from the version number, never taken from the response.

## Trust chain

Every way of installing ends in code from this repository:

1. **Source:** changes reach `main` only through pull requests with the required checks green (tests and build, plus the security scan).
2. **Release:** pushing a `v*` tag runs `release.yml`. It refuses a tag whose commit isn't on `main` or doesn't match `Info.plist`, builds in a read-only job, and only a separate job that runs no repository code gets permission to publish.
3. **Homebrew:** the tap `NiZZioN/homebrew-tap` copies `notchhider.rb` from the latest release. The cask pins the zip's SHA-256. Because the app is ad-hoc signed and not notarized, the cask removes the quarantine attribute, so the integrity of the release is the only safeguard.
4. **`get.sh`:** the `curl | zsh` installer clones `main` over HTTPS and builds from source.

## Threat model

In scope:

- a network or mirror attacker during installation (`get.sh`, `install.sh`, `brew install`);
- a compromised GitHub Action or a malicious pull request in CI or the release pipeline;
- another unprivileged process on the same Mac abusing the running app or its preferences;
- secrets leaking through the repository or its history.
- a spoofed or tampered GitHub API response to the update check. The tag must be plain digits and dots, so at worst the app shows a wrong version number; it opens no URL from the response and runs nothing.

Out of scope: an attacker who already has root on the Mac, or control of the maintainer's GitHub account.

## Checks

`./scan.sh` runs on every pull request (CI job "Security scan") and locally: `zsh -n` on all scripts, actionlint, zizmor (auditor level) and gitleaks over the full history. Actions are pinned to commit SHAs and kept current by Dependabot.
