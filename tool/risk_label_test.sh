#!/usr/bin/env bash
# Self test for tool/risk_label.sh (no bats). Run: bash tool/risk_label_test.sh
set -u
cd "$(dirname "$0")/.."
fail=0

# check NAME EXPECTED_FIRST_LINE EXPECT_UX(0|1) EXTRA_ARGS... <<< input
check() {
  local name="$1" want="$2" ux="$3"; shift 3
  local out; out="$(bash tool/risk_label.sh "$@" </dev/stdin)"
  local got; got="$(printf '%s\n' "$out" | head -1)"
  local hasux=0; printf '%s\n' "$out" | grep -qx ux-review && hasux=1
  if [ "$got" = "$want" ] && [ "$hasux" = "$ux" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name: want $want ux=$ux, got:"; printf '%s\n' "$out"; fail=1
  fi
}

check "docs only is safe" safe 0 <<< "docs/README.md"
check "plain feature code is safe" safe 0 --lines 50 <<< $'app/lib/features/trips/data/trip_repo.dart\napp/test/trip_repo_test.dart'
check "migration" critical 0 <<< "supabase/migrations/001_init.sql"
check "supabase config" critical 0 <<< "supabase/config.toml"
check "sync" critical 0 <<< "app/lib/features/sync/engine.dart"
check "auth" critical 0 <<< "app/lib/core/auth/session.dart"
check "workflow" critical 0 <<< ".github/workflows/ci.yml"
check "CODEOWNERS" critical 0 <<< ".github/CODEOWNERS"
check "Makefile" critical 0 <<< "Makefile"
check "gate" critical 0 <<< "tool/coverage_gate.dart"
check "non-gate tool is safe" safe 0 <<< "tool/other.dart"
check "analysis_options" critical 0 <<< "analysis_options.yaml"
check "lefthook" critical 0 <<< "lefthook.yml"
check ".claude" critical 0 <<< ".claude/settings.json"
check "CLAUDE.md" critical 0 <<< "CLAUDE.md"
check "pubspec" critical 0 <<< "packages/domain/pubspec.yaml"
check "pubspec.lock" critical 0 <<< "pubspec.lock"
check "package.json" critical 0 <<< "web/package.json"
check "ios" critical 0 <<< "app/ios/Runner/Info.plist"
check "android" critical 0 <<< "app/android/app/src/main/AndroidManifest.xml"
check "linux" critical 0 <<< "app/linux/CMakeLists.txt"
check "debug" critical 0 <<< "app/lib/debug/handlers.dart"
check "app_identity" critical 0 <<< "app/app_identity.yaml"
check "401 lines" critical 0 --lines 401 <<< "app/lib/core/money.dart"
check "400 lines is safe" safe 0 --lines 400 <<< "app/lib/core/money.dart"
check "golden without widget change" critical 0 <<< "app/test/goldens/home.png"
check "golden with widget test change" safe 0 --lines 5 <<< $'app/test/goldens/home.png\napp/test/home_view_test.dart'
check "new view -> ux-review + critical" critical 1 <<< $'A\tapp/lib/features/trips/ui/trip_view.dart'
check "modified view is safe" safe 0 <<< $'M\tapp/lib/features/trips/ui/trip_view.dart'
check "router change" critical 1 <<< "app/lib/core/router/app_router.dart"

# Reasons are printed
if bash tool/risk_label.sh <<< "Makefile" | grep -q '^# '; then echo "ok   reasons printed"; else echo "FAIL reasons"; fail=1; fi

# git diff mode: 1000-line generated file is excluded, small change => safe; big real change => critical
tmp="$(mktemp -d)"; script="$PWD/tool/risk_label.sh"
(
  cd "$tmp" && git init -q -b main && git config user.email t@t && git config user.name t
  mkdir -p app/lib && echo a > app/lib/a.dart && git add . && git commit -qm base
  git update-ref refs/remotes/origin/main HEAD
  seq 1 1000 > app/lib/big.g.dart; echo b >> app/lib/a.dart
  git add . && git commit -qm gen
  [ "$(bash "$script" --git </dev/null | head -1)" = safe ] && echo "ok   git mode excludes generated" || { echo "FAIL git mode generated"; exit 1; }
  seq 1 500 > app/lib/real.dart; git add . && git commit -qm real
  [ "$(bash "$script" --git </dev/null | head -1)" = critical ] && echo "ok   git mode counts real lines" || { echo "FAIL git mode real"; exit 1; }
) || fail=1
rm -rf "$tmp"

[ "$fail" = 0 ] && echo "all passed" || { echo "FAILURES"; exit 1; }
