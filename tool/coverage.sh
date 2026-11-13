#!/usr/bin/env bash
# Runs all test suites with coverage and applies the coverage gate.
# Extra args are forwarded to the gate (e.g. --baseline f --write-summary f).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [ -d "$HOME/sdk/flutter/bin" ]; then
  export PATH="$HOME/sdk/flutter/bin:$PATH"
fi

# Pure Dart packages: test --coverage, then format to lcov (repo-relative to pkg).
dart_cov() {
  local pkg="$1"
  echo "==> coverage: $pkg"
  (
    cd "$ROOT/$pkg"
    rm -rf coverage
    dart test --coverage=coverage
    dart run coverage:format_coverage --lcov --check-ignore \
      --packages=../../.dart_tool/package_config.json \
      --report-on=lib --in=coverage --out=coverage/lcov.info
  )
}

dart_cov packages/domain
dart_cov packages/drive_client

echo "==> coverage: app"
(
  cd "$ROOT/app"
  flutter test --coverage
)

echo "==> coverage gate"
dart run packages/tooling/bin/coverage_gate.dart \
  --lcov "packages/domain/coverage/lcov.info=packages/domain" \
  --lcov "packages/drive_client/coverage/lcov.info=packages/drive_client" \
  --lcov "app/coverage/lcov.info=app" \
  "$@"
