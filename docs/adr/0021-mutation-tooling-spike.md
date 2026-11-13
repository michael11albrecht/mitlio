# ADR-21: Mutation tooling spike (P1-T01 / P1-T03)

- **Status:** accepted (confirms ADR-10)
- **Date:** 2026-11-13

## Decision

Use `mutation_test` **1.8.1** (pub.dev, BSD-3, published ~Sep 2026, Dart + Flutter,
deps: args, path, xml) as a `dev_dependency` of `packages/domain`. No alternative needed.

## Spike

Scratch package with a largest-remainder `allocate(total, weights)` (6 good tests) plus a
deliberately weak `clamp100` (1 test). Dart 3.14.0, macOS arm64.

- Works on Dart 3.14 unchanged. 16 mutants, 7 s wall time (about 0.4 s per mutant, each
  one runs the full `dart test`). Weak file: 50 % detected; `allocate`: ~79 % detected.
- Mutations are text-level (literal and regex rules, 32 built-in; `-g` prints them).
  Not AST-aware, so some mutants are equivalent or noisy; this is why the threshold starts at 75 %.

## Config

- One XML file (`<mutations version="1.2">`): `<files>`/`<directories>`, `<commands>`
  (test command, expected return, timeout), `<exclude>` (tokens, regex, line ranges),
  `<rules>` (optional custom rules), `<threshold failure="N"/>` (default 80).
- Built-in threshold: the process exits non-zero (255) when the detected percentage is
  below `failure`; equal passes. Exit code 0 with 0 mutants ("Found 0 mutations").
- Reports: `html` (default), `junit`, `xunit`, `all`, `none` (`md`/`xml` deprecated).
  junit/xunit are machine-readable (one testcase per mutant, `<failure type="undetected">`
  with file and line), usable for the nightly "open issue per survivor" job (P8-T08).
- Repo layout: `tool/mutation/domain.template.xml` (commands, excludes, threshold),
  `tool/mutate.sh [--changed]` (builds the file list, injects it into the template,
  writes `build/mutation/domain.xml`, reports in `build/mutation/report`).

## Changed-files mode

The tool has no git awareness; its input is an explicit file list. `--changed` computes
`git diff --name-only --diff-filter=d $(git merge-base origin/main|main HEAD) -- packages/domain/lib`
plus untracked files, drops generated files (`*.g.dart`, `*.freezed.dart`,
`*.drift.dart`, `l10n/`), and writes them into `<files>`. No changed files: prints a
message and exits 0. The full run uses `find packages/domain/lib`.

## Limitations

- Test command is the whole package suite per mutant: runtime scales as mutants x suite
  time. Mitigation: changed-files on PRs, full run nightly. `--coverage lcov.info` can
  skip uncovered lines and is a later optimisation.
- Regex mutants are not semantically filtered; expect equivalent mutants and tune with
  `<exclude>` rules rather than chasing 100 %.
- Only one `<threshold>` per run, so per-package thresholds mean one XML per package
  (ViewModel/sync logic at 70 % later gets its own template).
- Needs the project to resolve (`flutter pub get`) before running; the script assumes that.
- Not for Flutter widget code (tests too slow); scope stays pure Dart per plan risk table.

## Revisit when

Mutant runtime on the real domain exceeds ~5 min for changed files, or the equivalent-mutant
rate makes 85 % unreachable; then evaluate coverage-guided skipping or a custom rule set.
