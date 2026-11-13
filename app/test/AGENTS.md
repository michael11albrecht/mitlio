<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# test

## Purpose
Flutter unit/widget tests for the app, plus repo-wide architecture rule tests.

## Key Files
| File | Description |
|------|-------------|
| `app_test.dart` | Smoke widget test: `MitlioApp` starts and shows "mitlio" |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `architecture/` | Static source-scan rules for layers and prohibitions (see `architecture/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- Tests first; bug fix = failing test first.
- Mirror `lib/` paths. ViewModel `lib/.../ui/x_view_model.dart` needs a test for it.
- No `skip:` without an issue link (`skip-needs-issue` rule). Never loosen tests to go green.
- DebugDrive handler tests go in `test/debug/` (invoke handlers directly, no VM service).

### Testing Requirements
- `make test-app`; with coverage via `tool/coverage.sh`.

## Dependencies

### External
- `flutter_test`, `integration_test`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
