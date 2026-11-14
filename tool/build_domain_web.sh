#!/usr/bin/env bash
# Compiles packages/domain_web to JS and enforces the size budget (ADR-19, PW-T01).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [ -d "$HOME/sdk/flutter/bin" ]; then
  export PATH="$HOME/sdk/flutter/bin:$PATH"
fi

MAX_GZ_BYTES=$((150 * 1000)) # 150 kB gzipped
OUT=build/domain_web/mitlio_domain.js

mkdir -p build/domain_web
dart compile js -O4 -o "$OUT" packages/domain_web/web/main.dart

raw=$(wc -c <"$OUT" | tr -d ' ')
gz=$(gzip -9 -c "$OUT" | wc -c | tr -d ' ')
echo "domain_web bundle: ${raw} B raw, ${gz} B gzip (budget ${MAX_GZ_BYTES} B gzip)"
if [ "$gz" -gt "$MAX_GZ_BYTES" ]; then
  echo "FAIL: gzip size ${gz} B exceeds budget ${MAX_GZ_BYTES} B" >&2
  exit 1
fi
