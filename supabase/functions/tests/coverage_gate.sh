#!/usr/bin/env bash
# Unit tests + line coverage gate (>= 90 %) for the pure Edge Function logic (P6c-T03).
set -euo pipefail
cd "$(dirname "$0")/.."
min=90
dir="$(mktemp -d)"
deno test --allow-read=_shared/testdata --coverage="$dir/cov" _shared/
deno coverage "$dir/cov" --include='_shared/(fuel|oil_bulletin)\.ts' --lcov > "$dir/lcov.info"
awk -F: -v min="$min" '
  /^LF:/ { lf += $2 } /^LH:/ { lh += $2 }
  END {
    pct = lf ? 100 * lh / lf : 0
    printf "line coverage: %.1f%% (%d/%d), minimum %d%%\n", pct, lh, lf, min
    exit (pct < min)
  }' "$dir/lcov.info"
