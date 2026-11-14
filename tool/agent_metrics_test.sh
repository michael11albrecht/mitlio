#!/usr/bin/env bash
# Offline self test for tool/agent_metrics.sh using recorded gh output.
# Run: bash tool/agent_metrics_test.sh
# shellcheck disable=SC2016  # backticks in expected markdown are literal
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
fixture=tool/fixtures/agent_metrics_gh.json

# expect NAME EXPECTED_LINE OUTPUT
expect() {
  if printf '%s\n' "$3" | grep -qxF -- "$2"; then
    echo "ok   $1"
  else
    echo "FAIL $1: missing line: $2"
    printf '%s\n' "$3"
    fail=1
  fi
}

out="$(bash tool/agent_metrics.sh --input "$fixture")"
expect "fix rounds, first push red, pipe escaped" \
  '| #1 | feat: a / b | P9-T01 | `agent/p9-t01` | local-agent | 2 | 2 | 1 | no | 3 | 2 | |' "$out"
expect "app author, cancelled ignored, no body" \
  '| #2 | docs: readme | - | `agent/2-readme` | app | 1 | 1 | 0 | yes | 0 | 1 | |' "$out"
expect "manual, no CI history" \
  '| #3 | fix: old | PX-T02 | `fix/old` | manual | 1 | 0 | - | - | 1 | 6 | |' "$out"
expect "summary row" \
  '| **Summary** | **3 PRs** | | | | 4 | | median 0.5 | 50% | 4 | median 2 | |' "$out"

out="$(bash tool/agent_metrics.sh --input "$fixture" --since 2026-01-02 --until 2026-01-31)"
expect "date range" \
  '| **Summary** | **1 PRs** | | | | 1 | | median 0 | 100% | 0 | median 1 | |' "$out"

exit "$fail"
