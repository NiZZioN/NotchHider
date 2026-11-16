# 1. The update check notifies, it never installs

Date: 2026-11-15

## Status

Accepted

## Context

Users asked for an automatic update check. Notch Hider is installed three ways: the Homebrew cask (which pins the zip's SHA-256 and strips the quarantine attribute), `get.sh` (builds `main` from source) and `install.sh` from a clone. The app is ad-hoc signed and not notarized. Before this feature it made no network requests at all, and SECURITY.md said so.

## Decision

- The app only **checks and tells**: it asks GitHub's "latest release" API, compares `tag_name` with its own `CFBundleShortVersionString`, and shows the newer version in Settings and the status menu. It never downloads, replaces or relaunches itself.
- Homebrew installs (a `Caskroom/notchhider` folder exists) are told to run `brew upgrade --cask notchhider`; every other install gets a link to the release page.
- The check is **off by default**. When on, it runs at launch and from an hourly timer, but only if the last attempt is 24 hours old. A failed attempt counts, so the API is never hammered. **Check now** works even when the automatic check is off.
- The release link is built from the validated version (ASCII digits and dots only), never from the response's `html_url`.

## Consequences

- No second update path that could drift from Homebrew's record or replace a source build with a binary, and no need to verify downloaded code without notarization.
- Users still update by hand, one step per install channel.
- Existing users keep a network-free app unless they opt in; SECURITY.md documents the single request.
