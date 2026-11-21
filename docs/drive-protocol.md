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
| `ext.mitlio.seed` | `scenario` (required; known: `groups`, `empty`, `trip_4p`, `household_2p`, `rounding_edge`, `commute_3p`, `large_200_expenses`) | `{"ids": [...]}` from `DebugDataControl.seed(scenario)`; `groups` creates group "Wochenende" with Anna, Ben, Chiara, Dino (ids: group, then members). The file scenarios (`tool/fixtures/scenarios`, see `tool/fixtures/README.md`) are loaded through the repositories and also return `groupId` and `members` (name to id); `ids` = group, members, vehicles, templates, expenses, rides |
| `ext.mitlio.state` | `screen` (optional) | without `screen`: `{"route": "/", "screens": [...]}`; with: `{"route", "screen", "state": {...}}` from the registered `debugSnapshot()` |
| `ext.mitlio.navigate` | `route` (required, starts with `/`) | `{"route": "<resulting location>"}` |
| `ext.mitlio.errors` | none | `{"errors": [{"time", "source", "error", "stackTrace"}]}`; returns and clears the captured errors |
| `ext.mitlio.groups.create` | `name` (required), `currency` (ISO code, default `EUR`), `members` (JSON list of names, default none) | `{"id", "name", "currency"}`; calls `GroupsViewModel.create` |
| `ext.mitlio.groups.list` | none | `{"groups": [{"id", "name", "currency"}]}`; calls `GroupsViewModel.list` |
| `ext.mitlio.groups.archived` | none | `{"groups": [{"id", "name", "currency"}]}` (archived groups); calls `ArchivedGroupsViewModel.list` |
| `ext.mitlio.groups.restore` | `id` (required) | `{"id"}`; calls `ArchivedGroupsViewModel.restore` (`not_found` unknown, `conflict` if not archived) |
| `ext.mitlio.members.add` | `groupId`, `name` (both required) | `{"id", "name", "position"}`; calls `GroupDetailViewModel.addMember` |
| `ext.mitlio.auth.status` | none | `{"signedIn", "userIdPrefix"}` (first 8 characters of the anonymous user id, or null); read-only, never signs in |
| `ext.mitlio.auth.signIn` | none | `{"signedIn": true, "userIdPrefix"}`, or `{"error": "<RemoteError case>", "message"}` (`offline`, `rateLimited`, `serverDown`, ...); calls `AuthRepository.ensureSignedIn`, the step share and join do first |
| `ext.mitlio.group.share` | `groupId` (required) | `{"state", "uploaded", "total"}` (`state` `shared` or `uploading`), or `{"error": "<RemoteError case>" \| "not_found" \| "notMember", "message", "uploaded", "total"}`; calls `ShareGroupRepository.makeShared` (P6-T15): account, group row + bootstrap membership, then the full history; repeating it resumes, already shared is a no-op |
| `ext.mitlio.push.simulate` | `payload` (required, the FCM `data` map as a JSON object: `group_id`, `event`, `expense_id`, `hide_amounts`), `source` (`tap` default, `foreground`, `background`), `body` (the text the OS would have shown) | `{"route", "pulled", "opened": [...], "announced"}` (P6b-T07): feeds the message through `PushRouting.handle`, the same entry the platform streams use. A tap pulls the group (`SyncService.pull`), then opens the group and its expense (`route` is the top screen); `foreground` pulls and announces (`incoming`) without moving; `background` pulls only. A payload without a usable `group_id` is `invalid_params` (`announced` is `openFailed` for a tap) |
| `ext.mitlio.vehicles.catalogSearch` | `groupId`, `query` (required), `vehicleId` (optional, edit form) | `{"query", "suggestions": [{"name", "fuelType", "hybrid", "engineCc", "powerKw", "consumptionMilliPer100km"}], "noMatch", "catalogUnavailable"}`; calls `VehicleFormViewModel.searchCatalog` (bundled EEA car list, offline, max 5 hits) on the form instance the screen uses
| `ext.mitlio.vehicles.catalogPick` | `groupId`, `index` (into the last `catalogSearch`), `vehicleId` (optional) | `{"name", "fuelType", "consumptionMilliPer100km", "fromCatalog", "undoable"}`; calls `VehicleFormViewModel.applyCatalogEntry` (`invalid_params` for an index outside the suggestions)
| `ext.mitlio.setup.state` | `flowId` (required) | `{"flowId", "status", "step", "stepIndex", "total", "finished", "answers", "skipped", "canGoBack", "canSkip"}`; `status` is `loading`, `ready` or `failed`, `step` the current step id (null when finished). Reads the saved progress of the guided setup flow (`SetupFlowViewModel`, PU-T05); `not_found` for a flow id not registered in `setupFlowConfigsProvider` |
| `ext.mitlio.setup.next` | `flowId` (required), `answer` (optional; JSON-decoded when it parses, else a string) | the same snapshot after moving on; calls `SetupFlowViewModel.next`: checks the answer, saves, advances, finishes after the last step (`invalid_params` for a missing or rejected answer, `conflict` when there is no step, `internal` when saving fails; nothing moves on an error) |
| `ext.mitlio.setup.skip` | `flowId` (required) | the same snapshot; calls `SetupFlowViewModel.skip` (`invalid_params` for a step that cannot be skipped) |
| `ext.mitlio.setup.back` | `flowId` (required) | the same snapshot; calls `SetupFlowViewModel.back`, also from the finish screen to the last step (`conflict` on the first step) |
| (flow ids) | | `setupFlowConfigsProvider` is filled in `main.dart` with `car_setup` (PU-T08: `hasCar`, `name`, `fuel`, `consumption`, `extraCost`) and `car_cost` (PU-T09: `annualKm`, one step per cost, `depPurchase`/`depResale`/`depYears`, `basis`). Answers: `name` is `{"name", "type"}`, a cost step is `{"cents", "period": "month"\|"year"}`, consumption is thousandths per 100 km, `extraCost` is `flat` or `exact`. Saving the car is the finish screen's "Auto speichern" (`CarSetupViewModel.save`), not a drive command yet |

`navigate` also reaches the first-run routes `/welcome` (onboarding, shown on `/` while no group exists) and `/trip` (the trip form without a group). Onboarding has no commands of its own: the commute path creates its group through `GroupsViewModel.create`, i.e. what `groups.create` calls.

`reset` and `seed` go through the `DebugDataControl` interface; the default implementation (`DriftDebugDataControl`) works on the
real database and repositories.

`ext.mitlio.state` screens registered so far (wired in `app/lib/debug/debug_snapshots.dart`, ViewModels never import `debug/`): `groups` (home list) and `group` (detail of the group in the current route, `{"status":"not_open"}` otherwise). Both report
`status` (`loading`, `error`, `empty`, `data`).

Progress of a setup flow survives an app restart (it is stored in `local_settings`, key `setup_flow.<flowId>`) and `ext.mitlio.reset` clears it. Flows are registered by their feature in `setupFlowConfigsProvider` (`app/lib/core/ui/setup_flow/`); the framework ships none. `main.dart` registers the profile flow (`flowId` `profile`, PU-T07; steps `name`, `avatar`, `paypal_wanted`, `paypal_me`, `bank_wanted`, `iban`); the car flow (PU-T08) adds its own. Profile answers: the name and the PayPal.Me link are strings, `avatar` is `{"color": <ARGB int or null>, "emoji": <string or null>}`, the two yes/no steps are `true`/`false`, `iban` is `{"iban": "...", "holder": "..."}`. The IBAN goes to the local bank table only: the snapshot and the saved progress show `true` for the `iban` step, never the IBAN. `paypal_me` is only a step after `paypal_wanted` is `true`, `iban` only after `bank_wanted` is `true` (`total` counts the visible steps).

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
