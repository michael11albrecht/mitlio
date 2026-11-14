#!/usr/bin/env bash
# Fails if a release bundle contains the DebugDrive prefix `ext.mitlio` (plan §5.2: registration
# is behind kDebugMode and must be tree-shaken). Build first: (cd app && flutter build linux --release).
# usage: tool/check_release_strip.sh [bundle-dir]
# Runs on Linux (CI); skips elsewhere because only the Linux bundle is built in CI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "$(uname -s)" != "Linux" ] && [ -z "${1:-}" ]; then
  echo "check_release_strip: linux only (pass a bundle dir to check elsewhere), skipped"
  exit 0
fi

bundle="${1:-}"
if [ -z "$bundle" ]; then
  bundle=$(ls -d app/build/linux/*/release/bundle 2>/dev/null | head -n 1 || true)
fi
if [ -z "$bundle" ] || [ ! -d "$bundle" ]; then
  echo "check_release_strip: no release bundle found; run 'flutter build linux --release' in app/" >&2
  exit 2
fi
if ! find "$bundle" -name 'libapp.so' | grep -q .; then
  echo "check_release_strip: $bundle has no libapp.so (not an AOT release bundle?)" >&2
  exit 2
fi

if hits=$(grep -rl 'ext\.mitlio' "$bundle"); then
  echo "check_release_strip: FAIL, 'ext.mitlio' found in release bundle:" >&2
  echo "$hits" >&2
  exit 1
fi
echo "check_release_strip: OK, no 'ext.mitlio' in $bundle"
