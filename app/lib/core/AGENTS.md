<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# core

## Purpose
Shared app infrastructure. Only place allowed to create time, randomness and ids (`no-nondeterminism-outside-core` rule). Will host theme/design tokens (`core/theme`), routing and DI (P3-T01).

## Key Files
| File | Description |
|------|-------------|
| `app.dart` | `MitlioApp` root widget (`MaterialApp.router`; needs `ProviderScope`) |
| `clock.dart` / `id_generator.dart` | `Clock`, `IdGenerator` (UUIDv7) + test fakes |
| `logging.dart` | `Logger`, `ErrorSink` ring buffer |
| `providers.dart` / `router.dart` | Riverpod root providers (no codegen, ADR-23), `go_router` |

## For AI Agents

### Working In This Directory
- Provide `Clock`, `IdGenerator`, `Random` implementations here; consumers get them injected.
- Design tokens live in `core/theme` once added; Views must not use raw colors/styles.
- `app_test.dart` (pumped under `ProviderScope`) expects text `mitlio` on start — update test with any root UI change.

### Testing Requirements
- `make test-app`.

## Dependencies

### External
- `material_ui`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
