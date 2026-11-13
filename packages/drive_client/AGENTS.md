<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# drive_client (`mitlio_drive`)

## Purpose
CLI that calls `ext.mitlio.*` VM service extensions on a running debug app (DebugDrive). Lets agents and CI drive the app through the same ViewModel/Repository API tests use. P0 skeleton; real client in P3-T04.

## Key Files
| File | Description |
|------|-------------|
| `lib/mitlio_drive.dart` | `extensionPrefix` (`ext.mitlio.`) and `extensionName()` qualifier |
| `lib/drive_client.dart` | Leftover `dart create` sample (`calculate()`); candidate for removal |
| `bin/drive.dart` | `drive <extension> [json-params]` entry; currently exits 69 (not implemented) |
| `test/mitlio_drive_test.dart` | Tests for `extensionName` |

## For AI Agents

### Working In This Directory
- Protocol contract lives in `docs/drive-protocol.md`; keep client and doc in sync.
- Exit codes: 64 usage error, 69 unavailable. Keep sysexits-style codes.
- `.drive/` state dir is gitignored.

### Testing Requirements
- `make test-drive`. Coverage ≥ 80 %.

## Dependencies

### External
- `args`, `vm_service`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
