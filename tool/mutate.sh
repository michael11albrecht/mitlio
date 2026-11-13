#!/usr/bin/env bash
# Mutation testing for packages/domain (ADR-0010, ADR-0021).
#   tool/mutate.sh            mutate every non-generated file in packages/domain/lib
#   tool/mutate.sh --changed  only files changed vs origin/main (or main)
# Exit 0: score >= threshold or nothing to mutate. Exit 1: below threshold or error.
# Threshold lives in tool/mutation/domain.template.xml (<threshold failure="N"/>).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pkg="packages/domain"
out="$root/build/mutation"
mode="all"
[[ "${1:-}" == "--changed" ]] && mode="changed"

cd "$root"
if [ -d "$HOME/sdk/flutter/bin" ]; then
  export PATH="$HOME/sdk/flutter/bin:$PATH"
fi
if [[ "$mode" == "changed" ]]; then
  base=""
  for ref in origin/main main; do
    git rev-parse --verify -q "$ref" >/dev/null && base="$ref" && break
  done
  [[ -n "$base" ]] || { echo "mutate: no origin/main or main ref found" >&2; exit 1; }
  mb="$(git merge-base "$base" HEAD)"
  candidates="$({ git diff --name-only --diff-filter=d "$mb" -- "$pkg/lib"
                  git ls-files --others --exclude-standard -- "$pkg/lib"; } | sort -u)"
else
  candidates="$(find "$pkg/lib" -name '*.dart' | sort)"
fi

files=()
while IFS= read -r f; do
  [[ -z "$f" || "$f" != *.dart || ! -f "$f" ]] && continue
  case "$f" in
    *.g.dart | *.freezed.dart | *.drift.dart | */l10n/*) continue ;;
  esac
  files+=("${f#"$pkg"/}")
done <<<"$candidates"

if [[ ${#files[@]} -eq 0 ]]; then
  echo "mutate: no domain files to mutate ($mode); skipping."
  exit 0
fi

mkdir -p "$out"
{
  echo "  <files>"
  for f in "${files[@]}"; do echo "    <file>$f</file>"; done
  echo "  </files>"
} >"$out/files.xml"
awk -v f="$out/files.xml" '/@FILES@/ { while ((getline l < f) > 0) print l; next } { print }' \
  tool/mutation/domain.template.xml >"$out/domain.xml"

echo "mutate: ${#files[@]} file(s): ${files[*]}"
cd "$pkg"
set +e
dart run mutation_test --format html --output "$out/report" "$out/domain.xml"
rc=$?
set -e
echo "mutate: report in build/mutation/report"
# mutation_test exits non-zero when below the threshold or on config errors.
[[ $rc -eq 0 ]] && exit 0
exit 1
