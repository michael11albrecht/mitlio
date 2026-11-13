<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# lib

## Purpose
App source for `package:mitlio`. Entry point plus shared core. Feature folders (`features/<feature>/{data,ui}/`) and `debug/` (DebugDrive `ext.mitlio.*` handlers) land in P3+.

## Key Files
| File | Description |
|------|-------------|
| `main.dart` | `runApp(MitlioApp())` — keep trivial |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `core/` | App root widget, shared infrastructure (see `core/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- Layer import rules enforced by `app/test/architecture/` (domain-purity, services-no-ui, repositories-no-ui, viewmodel-no-services-or-views, viewmodel-no-buildcontext, views-no-data, debug-no-views).
- No `print`, no `double` money, no raw styles, no `showDialog` (undo instead of confirm; allowlist empty).
- `DateTime.now()`, `Random()`, UUID creation only inside `core/`; inject `Clock`, `IdGenerator`, `Random` elsewhere.
- DebugDrive handlers: ≤ 15 lines, call one VM/repository method, return JSON, errors as `{error, message}`; document in `docs/drive-protocol.md`.

### Testing Requirements
- Mirror files under `app/test/`. Run `make test-app`.

## Dependencies

### Internal
- `mitlio_domain`

### External
- `material_ui`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
