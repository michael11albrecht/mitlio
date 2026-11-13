<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# app

## Purpose
Flutter app `mitlio` (workspace member, `resolution: workspace`). Shipped targets: iOS + Android. `linux/` is a headless CI/DebugDrive harness only, never released. Currently a P0 skeleton: root widget only; routing, theme, DI arrive in P3-T01.

## Key Files
| File | Description |
|------|-------------|
| `pubspec.yaml` | App deps: `material_ui`, `mitlio_domain`; dev: `flutter_test`, `integration_test` |
| `app_identity.yaml` | Single source of truth for name, flavors (dev/prod bundle ids), URL scheme, link domain, DebugDrive namespace (ADR-16/17) |
| `.metadata` | Flutter tool metadata (generated) |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `lib/` | App source (see `lib/AGENTS.md`) |
| `test/` | Widget + architecture tests (see `test/AGENTS.md`) |
| `android/` | Android host project (see `android/AGENTS.md`) |
| `ios/` | iOS host project (see `ios/AGENTS.md`) |
| `linux/` | Headless test/DebugDrive harness (see `linux/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- Feature-first layout: `lib/features/<feature>/{data,ui}/`, shared in `lib/core/`, DebugDrive in `lib/debug/`.
- MVVM: View → ViewModel → Repository → Service. Views hold no logic; every user action is a ViewModel command reachable from DebugDrive.
- Business math belongs in `packages/domain`, not here.
- All UI strings via ARB (l10n). Design tokens only from `core/theme`.
- Change identity values only in `app_identity.yaml`.

### Testing Requirements
- `make test-app` (= `flutter test` here). Architecture rules run as part of it.
- Every ViewModel command: success, validation error, repository failure tests. ViewModels need a matching test file (`viewmodel-has-test` rule).
- Coverage ≥ 90 % for `lib/**/data/**`, `lib/**/ui/*_view_model.dart`, `lib/features/sync/**`.

### Common Patterns
- `build/`, `coverage/`, `.dart_tool/` are generated — ignore.

## Dependencies

### Internal
- `packages/domain` (`mitlio_domain`)

### External
- Flutter SDK (pinned in root `pubspec.yaml`), `material_ui`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
