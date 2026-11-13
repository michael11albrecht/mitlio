<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# tool

## Purpose
Shell gates, agent hooks and gate config. Invoked from `Makefile`, CI workflows, lefthook and Claude Code hooks.

## Key Files
| File | Description |
|------|-------------|
| `coverage.sh` | Runs domain, drive_client and app tests with coverage, then `coverage_gate` (extra args forwarded) |
| `coverage_thresholds.yaml` | Per-glob min coverage: 80 % overall, 90 % domain/data/ViewModels/sync. **Do not lower** |
| `mutate.sh` | Mutation testing on `packages/domain/lib`; `--changed` = files changed vs `origin/main`. Report in `build/mutation/report` |
| `risk_label.sh` | Labels PR `critical`/`safe` (+ optional `ux-review`) from changed paths and line count (limit 400) |
| `risk_label_test.sh` | Self-test for `risk_label.sh` (`bash tool/risk_label_test.sh`) |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `hooks/` | Claude Code hooks: `format_file.sh` (PostToolUse, `dart format` edited file), `stop_check.sh` (Stop, blocks while `make check-fast` red) |
| `mutation/` | `domain.template.xml`: mutation_test config; `@FILES@` injected by `mutate.sh`; `<threshold failure="75"/>` |

## For AI Agents

### Working In This Directory
- Gate thresholds (`coverage_thresholds.yaml`, mutation `threshold`, `*_gate.dart`) are `critical`; only change when an issue explicitly asks.
- Scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, resolve repo root from script dir, add `$HOME/sdk/flutter/bin` to PATH when present.
- Must work on macOS (BSD) and Linux CI.
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.drift.dart`, `l10n/`) are excluded consistently across coverage, mutation, risk label — keep lists aligned.

### Testing Requirements
- `bash tool/risk_label_test.sh` after touching `risk_label.sh`.
- Run `tool/coverage.sh` / `tool/mutate.sh --changed` end-to-end after edits.

## Dependencies

### Internal
- `packages/tooling` (coverage gate), `packages/domain` (mutation target)

### External
- `jq` (hooks), `git`, `gitleaks` (optional), `mutation_test`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
