#!/usr/bin/env bash
# Calls a DebugDrive extension on the running debug app (docs/drive-protocol.md).
# usage: tool/drive.sh <extension> [json-params] [--uri-file F] [--timeout S]
# JSON on stdout only. Exit: 0 ok, 1 extension error, 2 connection error, 64 usage.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [ -d "$HOME/sdk/flutter/bin" ]; then
  export PATH="$HOME/sdk/flutter/bin:$PATH"
fi

exec dart run packages/drive_client/bin/drive.dart --uri-file="${DRIVE_URI_FILE:-$ROOT/.drive/uri}" "$@"
