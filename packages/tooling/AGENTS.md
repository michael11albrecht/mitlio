<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# tooling (`mitlio_tooling`)

## Purpose
Repository gates written in Dart. Currently the coverage gate (P1-T02): merges lcov files, applies per-glob thresholds from `tool/coverage_thresholds.yaml`, optionally compares to a baseline summary.

## Key Files
| File | Description |
|------|-------------|
| `bin/coverage_gate.dart` | Executable; delegates to `runCoverageGate` |
| `lib/mitlio_tooling.dart` | Barrel export of `src/` |
| `lib/src/cli.dart` | Arg parsing (`--lcov path[=prefix]`, `--config`, `--baseline`, `--write-summary`, `--root`), `runCoverageGate` |
| `lib/src/config.dart` | `GateConfig`/`Threshold` YAML parsing with `FormatException` on bad input |
| `lib/src/gate.dart` | `GlobResult`, `GateStatus` (pass/fail/skip — skip when no lines match) |
| `lib/src/lcov.dart` | `parseLcov`, `FileCoverage`; path normalization to repo-relative |
| `test/` | `cli_test`, `gate_test`, `lcov_test` |

## For AI Agents

### Working In This Directory
- Gate logic is `critical`: never change behavior to make a failing gate pass. Thresholds live in `tool/coverage_thresholds.yaml` — do not lower.
- CLI writes to injected `out`/`err` sinks and returns exit code; keep it testable without `exit()`.

### Testing Requirements
- `cd packages/tooling && dart test`. Tests use temp dirs for file IO.

## Dependencies

### External
- `args`, `glob`, `path`, `yaml`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
