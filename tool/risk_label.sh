#!/usr/bin/env bash
# Mechanical PR risk labeling (docs/IMPLEMENTATION_PLAN.md §6.4, §2.6).
#
# Input : changed files, one per line, either `path` or `STATUS<TAB>path`
#         (STATUS as in `git diff --name-status`; only `A` matters, for ux-review).
#         Read from stdin when stdin is not a terminal, otherwise from
#         `git diff --name-status origin/main...HEAD`.
# Option: --git     force diff mode even when stdin is not a terminal (CI).
#         --lines N  number of changed lines ALREADY excluding generated, test and
#         golden files. Without it, computed from `git diff --numstat` (diff mode only).
# Output: line 1 = `critical` | `safe`; then optional line `ux-review`;
#         then one `# reason` line per finding.
set -euo pipefail

BASE="${RISK_BASE:-origin/main}"
HEAD_REF="${RISK_HEAD:-HEAD}" # CI (pull_request_target) sets RISK_HEAD to the fetched PR head
LINE_LIMIT=400
lines=""
force_git=0
while [ $# -gt 0 ]; do
  case "$1" in
    --lines) lines="${2:?--lines needs a number}"; shift 2 ;;
    --git) force_git=1; shift ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Generated / test / golden files do not count towards the line budget.
is_excluded() {
  case "$1" in
    *.g.dart|*.freezed.dart|*.gen.dart|*.mocks.dart|*/l10n/app_localizations*.dart|*/generated/*) return 0 ;;
    *_test.dart|*/test/*|*/integration_test/*|*/test_driver/*) return 0 ;;
    *.png|*/goldens/*|*/golden/*|*/failures/*) return 0 ;;
    pubspec.lock|*/pubspec.lock|*/package-lock.json) return 0 ;;
  esac
  return 1
}
is_golden() {
  case "$1" in *.png|*/goldens/*|*/golden/*) return 0 ;; esac
  return 1
}

use_git=0
if [ "$force_git" = 1 ] || [ -t 0 ]; then
  use_git=1
  input="$(git diff --name-status "$BASE"..."$HEAD_REF")"
else
  input="$(cat)"
fi

critical=()
ux=0
goldens=0
paths=()

add_reason() { critical+=("$1"); }

while IFS= read -r row; do
  [ -z "$row" ] && continue
  status="M"
  path="$row"
  case "$row" in
    *$'\t'*)
      status="${row%%$'\t'*}"
      path="${row##*$'\t'}" # for renames (R100 old new) take the new path
      ;;
  esac
  path="${path#./}"
  paths+=("$path")

  case "$path" in
    supabase/*) add_reason "supabase: $path" ;;
    app/lib/features/sync/*|app/lib/core/auth/*) add_reason "sync/auth: $path" ;;
    .github/*|CODEOWNERS) add_reason "CI/ownership: $path" ;;
    Makefile|*/Makefile) add_reason "Makefile: $path" ;;
    tool/*_gate.dart) add_reason "gate: $path" ;;
    analysis_options.yaml|*/analysis_options.yaml|lefthook.yml) add_reason "tooling config: $path" ;;
    .claude/*|CLAUDE.md) add_reason "agent contract: $path" ;;
    pubspec.yaml|*/pubspec.yaml|pubspec.lock|*/pubspec.lock) add_reason "dependencies: $path" ;;
    package.json|*/package.json|*/package-lock.json) add_reason "dependencies: $path" ;;
    ios/*|*/ios/*|android/*|*/android/*) add_reason "native platform: $path" ;;
    app/linux/*) add_reason "linux harness: $path" ;;
    app/lib/debug/*) add_reason "debug (release-strip risk): $path" ;;
    app/app_identity.yaml) add_reason "app identity: $path" ;;
  esac

  if is_golden "$path"; then goldens=1; fi


  case "$status:$path" in
    A:app/lib/*/ui/*_view.dart) ux=1 ;;
  esac
  case "$path" in
    app/lib/core/router/*|app/lib/*router*.dart|app/lib/*/*router*.dart|app/lib/*/*/*router*.dart) ux=1 ;;
  esac
done <<< "$input"

if [ "$goldens" = 1 ]; then
  matched=0
  for p in "${paths[@]}"; do
    case "$p" in *_test.dart|app/lib/*/ui/*|app/lib/*/*/ui/*|app/lib/*/*/*/ui/*) matched=1 ;; esac
  done
  [ "$matched" = 0 ] && add_reason "golden changed without matching widget/test change"
fi

if [ -z "$lines" ]; then
  lines=0
  if [ "$use_git" = 1 ]; then
    while IFS=$'\t' read -r add del file; do
      [ -z "$file" ] && continue
      [ "$add" = "-" ] && continue # binary
      is_excluded "$file" && continue
      lines=$((lines + add + del))
    done < <(git diff --numstat "$BASE"..."$HEAD_REF")
  fi
fi
case "$lines" in ''|*[!0-9]*) echo "--lines must be a number" >&2; exit 2 ;; esac
if [ "$lines" -gt "$LINE_LIMIT" ]; then
  add_reason "diff too large: $lines changed lines (> $LINE_LIMIT, excl. generated/test/golden)"
fi

# §2.6: a new screen or navigation change is a human UX gate -> also critical.
[ "$ux" = 1 ] && add_reason "ux-review: new *_view.dart screen or router change"

if [ ${#critical[@]} -gt 0 ]; then echo critical; else echo safe; fi
[ "$ux" = 1 ] && echo ux-review
if [ ${#critical[@]} -gt 0 ]; then
  for r in "${critical[@]}"; do echo "# $r"; done
fi
exit 0
