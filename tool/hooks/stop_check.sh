#!/usr/bin/env bash
# Claude Code Stop hook: block finishing while `make check-fast` is red.
set -uo pipefail
input=$(cat)
# Avoid loops: if we already blocked once in this stop cycle, let it stop.
[[ "$(jq -r '.stop_hook_active // false' <<<"$input")" == "true" ]] && exit 0
# Only check when Dart sources changed.
git status --porcelain | grep -q '\.dart$\|pubspec\.yaml$' || exit 0
if ! out=$(make check-fast 2>&1); then
  echo "make check-fast failed — fix before finishing:" >&2
  tail -40 <<<"$out" >&2
  exit 2
fi
