# DebugDrive protocol (`ext.mitlio.*`)

Contract for driving a running **debug** build of the app through the same ViewModel/Repository API the tests use
(plan §5.2). Implementation: `app/lib/debug/debug_drive.dart`; client: `packages/drive_client` (`tool/drive.sh`).

## Rules

- Registered via `dart:developer` `registerExtension` only inside `if (kDebugMode)` in `main.dart`, so release builds
  contain no `ext.mitlio` string (`tool/check_release_strip.sh`).
- Handlers are plain functions `Future<Map<String, Object?>> handle(Map<String, String> params)`, at most 15 lines,
  and never throw. Failures are returned as `{"error": "<code>", "message": "<text>"}`.
- Params arrive as strings (VM service limitation). The client JSON-encodes non-string values.
- Error codes: `invalid_params` (missing/invalid param, or a validation error such as a blank name), `not_found`, `conflict` (the command conflicts with current state), `internal` (unexpected exception or storage failure).

## Extensions

| Extension | Params | Returns |
|---|---|---|
| `ext.mitlio.ping` | none | `{"version": "0.1.0", "buildSha": "dev"}`; `buildSha` from `--dart-define=BUILD_SHA` |
| `ext.mitlio.reset` | none | `{"ok": true}`; deletes every row of the local database via `DebugDataControl.wipe()` |
| `ext.mitlio.seed` | `scenario` (required; known: `groups`) | `{"ids": [...]}` from `DebugDataControl.seed(scenario)`; `groups` creates group "Wochenende" with Anna, Ben, Chiara, Dino (ids: group, then members) |
| `ext.mitlio.state` | `screen` (optional) | without `screen`: `{"route": "/", "screens": [...]}`; with: `{"route", "screen", "state": {...}}` from the registered `debugSnapshot()` |
| `ext.mitlio.navigate` | `route` (required, starts with `/`) | `{"route": "<resulting location>"}` |
| `ext.mitlio.errors` | none | `{"errors": [{"time", "source", "error", "stackTrace"}]}`; returns and clears the captured errors |
| `ext.mitlio.groups.create` | `name` (required), `currency` (ISO code, default `EUR`), `members` (JSON list of names, default none) | `{"id", "name", "currency"}`; calls `GroupsViewModel.create` |
| `ext.mitlio.groups.list` | none | `{"groups": [{"id", "name", "currency"}]}`; calls `GroupsViewModel.list` |
| `ext.mitlio.members.add` | `groupId`, `name` (both required) | `{"id", "name", "position"}`; calls `GroupDetailViewModel.addMember` |

`reset` and `seed` go through the `DebugDataControl` interface; the default implementation (`DriftDebugDataControl`) works on the
real database and repositories.

`ext.mitlio.state` screens registered so far: `groups` (home list) and `group` (detail of the group last opened). Both report
`status` (`loading`, `error`, `empty`, `data`).

Feature handlers (`groups.create`, `expenses.add`, ...) are added with each slice and must be listed here.

## CLI

```
tool/drive.sh <extension|short-name> [json-params] [--uri-file .drive/uri] [--timeout 10]
make drive-up                 # flutter run -d linux (xvfb on Linux) in the background, writes .drive/uri
make drive CMD='ping'
make drive CMD='seed {"scenario":"trip"}'
make drive-down
```

Output: one JSON document on stdout, diagnostics on stderr.

| Exit | Meaning |
|---|---|
| 0 | extension returned JSON without `error` |
| 1 | extension returned `{"error", "message"}` (or the VM rejected the call, e.g. unknown extension: `rpc_error`) |
| 2 | connection error (URI file missing, VM unreachable, timeout, no isolate) |
| 64 | usage error |
