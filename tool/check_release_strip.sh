#!/usr/bin/env bash
# Fails if a release build contains the DebugDrive prefix `ext.mitlio` (plan §5.2: registration
# is behind kDebugMode and must be tree-shaken). Build first, e.g. (cd app && flutter build linux --release).
# usage: tool/check_release_strip.sh [bundle-dir | app.apk | app.aab | app.ipa]
# A directory is scanned as is (Linux bundle, iOS Runner.app). An archive is unzipped to a temp dir first.
# The AOT snapshot must be present (libapp.so, or App.framework/App on iOS), otherwise exit 2: a build
# without it would pass the check for the wrong reason.
# Without an argument it runs on Linux (CI) only and picks the Linux release bundle.
# Exit codes: 0 clean, 1 `ext.mitlio` found, 2 usage / nothing to check.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "$(uname -s)" != "Linux" ] && [ -z "${1:-}" ]; then
  echo "check_release_strip: linux only (pass a bundle dir or apk/aab/ipa to check elsewhere), skipped"
  exit 0
fi

target="${1:-}"
if [ -z "$target" ]; then
  target=$(ls -d app/build/linux/*/release/bundle 2>/dev/null | head -n 1 || true)
fi
if [ -z "$target" ] || { [ ! -d "$target" ] && [ ! -f "$target" ]; }; then
  echo "check_release_strip: no release build found; run 'flutter build linux --release' in app/" >&2
  exit 2
fi

scan="$target"
if [ -f "$target" ]; then
  case "$target" in
    *.apk | *.aab | *.ipa | *.zip) ;;
    *)
      echo "check_release_strip: $target is not a directory or an apk/aab/ipa/zip archive" >&2
      exit 2 ;;
  esac
  scan="$(mktemp -d)"
  trap 'rm -rf "$scan"' EXIT
  unzip -q "$target" -d "$scan"
fi

if ! find "$scan" \( -name 'libapp.so' -o -path '*App.framework/App' \) | grep -q .; then
  echo "check_release_strip: $target has no AOT snapshot (libapp.so or App.framework/App), not a release build?" >&2
  exit 2
fi

if hits=$(grep -rl 'ext\.mitlio' "$scan"); then
  echo "check_release_strip: FAIL, 'ext.mitlio' found in release build $target:" >&2
  echo "$hits" >&2
  exit 1
fi
echo "check_release_strip: OK, no 'ext.mitlio' in $target"
