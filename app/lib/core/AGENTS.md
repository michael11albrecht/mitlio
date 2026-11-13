<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# core

## Purpose
Shared app infrastructure. Only place allowed to create time, randomness and ids (`no-nondeterminism-outside-core` rule). Will host theme/design tokens (`core/theme`), routing and DI (P3-T01).

## Key Files
| File | Description |
|------|-------------|
| `app.dart` | `MitlioApp` root widget; placeholder `MaterialApp` until P3-T01 |

## For AI Agents

### Working In This Directory
- Provide `Clock`, `IdGenerator`, `Random` implementations here; consumers get them injected.
- Design tokens live in `core/theme` once added; Views must not use raw colors/styles.
- `app_test.dart` expects text `mitlio` on start — update test with any root UI change.

### Testing Requirements
- `make test-app`.

## Dependencies

### External
- `material_ui`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
