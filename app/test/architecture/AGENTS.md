<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# architecture

## Purpose
Architecture gate (P1-T04). Scans every Dart file in the repo as text and enforces the layer table and prohibitions from `CLAUDE.md`. Runs inside `flutter test`.

## Key Files
| File | Description |
|------|-------------|
| `architecture_test.dart` | Applies all rules to the real repo; also self-tests rules on fixtures. Holds `showDialogAllowlist` (keep empty) |
| `rules.dart` | `Rule`/`Violation` types and `buildRules()`: domain-purity, services-no-ui, repositories-no-ui, viewmodel-no-services-or-views, viewmodel-no-buildcontext, views-no-data, debug-no-views, no-nondeterminism-outside-core, no-print, no-double-money, viewmodel-has-test, no-raw-style, dialog-allowlist, skip-needs-issue |
| `source_scanner.dart` | `SourceTree`/`SourceFile`: loads repo, strips comments/strings, parses import/export directives to repo-relative targets |

## For AI Agents

### Working In This Directory
- Treat as a gate: fix the code, not the rule. Changing or relaxing a rule is an architecture decision (Opus/owner), not an implementation fix.
- Adding a rule: add to `buildRules()` and add positive + negative fixture tests in `architecture_test.dart`.
- Do not add entries to `showDialogAllowlist` unless an issue explicitly asks.

### Testing Requirements
- `cd app && flutter test test/architecture`.

## Dependencies

### External
- `dart:io`, `flutter_test`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
