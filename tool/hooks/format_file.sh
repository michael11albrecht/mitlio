#!/usr/bin/env bash
# Claude Code PostToolUse hook: format the edited Dart file.
set -euo pipefail
file=$(jq -r '.tool_input.file_path // empty')
[[ "$file" == *.dart && -f "$file" ]] || exit 0
dart=$(command -v dart || echo "$HOME/sdk/flutter/bin/dart")
"$dart" format "$file" >/dev/null 2>&1 || true
