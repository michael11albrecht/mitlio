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
| `ext.mitlio.groups.create` | `name` (required), `currency` (ISO code, default `EUR`), `members` (JSON list of names, default none), `withProfile` (`true`: add the profile as first member and mark it as own, like the group form) | `{"id", "name", "currency"}`; calls `GroupsViewModel.create` |
| `ext.mitlio.groups.list` | none | `{"groups": [{"id", "name", "currency"}]}`; calls `GroupsViewModel.list` |
| `ext.mitlio.groups.archived` | none | `{"groups": [{"id", "name", "currency"}]}` (archived groups); calls `ArchivedGroupsViewModel.list` |
| `ext.mitlio.groups.restore` | `id` (required) | `{"id"}`; calls `ArchivedGroupsViewModel.restore` (`not_found` unknown, `conflict` if not archived) |
| `ext.mitlio.members.add` | `groupId`, `name` (both required) | `{"id", "name", "position"}`; calls `GroupDetailViewModel.addMember` |
| `ext.mitlio.auth.status` | none | `{"signedIn", "userIdPrefix"}` (first 8 characters of the anonymous user id, or null); read-only, never signs in |
| `ext.mitlio.auth.signIn` | none | `{"signedIn": true, "userIdPrefix"}`, or `{"error": "<RemoteError case>", "message"}` (`offline`, `rateLimited`, `serverDown`, ...); calls `AuthRepository.ensureSignedIn`, the step share and join do first |
| `ext.mitlio.group.share` | `groupId` (required) | `{"state", "uploaded", "total"}` (`state` `shared` or `uploading`), or `{"error": "<RemoteError case>" \| "not_found" \| "notMember", "message", "uploaded", "total"}`; calls `ShareGroupRepository.makeShared` (P6-T15): account, group row + bootstrap membership, then the full history; repeating it resumes, already shared is a no-op |
| `ext.mitlio.push.simulate` | `payload` (required, the FCM `data` map as a JSON object: `group_id`, `event`, `expense_id`, `hide_amounts`), `source` (`tap` default, `foreground`, `background`), `body` (the text the OS would have shown) | `{"route", "pulled", "opened": [...], "announced"}` (P6b-T07): feeds the message through `PushRouting.handle`, the same entry the platform streams use. A tap pulls the group (`SyncService.pull`), then opens the group and its expense (`route` is the top screen); `foreground` pulls and announces (`incoming`) without moving; `background` pulls only. A payload without a usable `group_id` is `invalid_params` (`announced` is `openFailed` for a tap) |
| `ext.mitlio.support.state` | none | `{"enabled", "settledSinceShown", "lastShown", "dismissed"}` (P7-T09, ADR-28): the remote flag `support_tips_enabled` (off until the owner sets it) and the local state of the success-screen line; calls `SupportRepository` |
| `ext.mitlio.support.setFlag` | `enabled` (`true` or `false`, required) | `{"enabled"}`: stands in for the owner flipping `app_config.support_tips_enabled`; writes the flag cache the repository trusts for 12 hours (debug builds only) |
| `ext.mitlio.support.setPrompt` | `settled` (counter), `lastShownDaysAgo`, `dismissed` (`true` or `false`), all optional | the `support.state` result after scripting the local line state; a malformed number is `invalid_params` |
| `ext.mitlio.support.reached` | none | `{"visible"}`: one visit of the "all settled" screen through `SupportPromptViewModel.settledScreenReached` (counts, applies the 5-settlements and 30-days limits; nothing is counted while the flag is off) |
| `ext.mitlio.support.dismiss` | none | `{"dismissed": true}`; calls `SupportPromptViewModel.dismissForever` ("Nicht mehr zeigen", permanent) |
| `ext.mitlio.support.tips` | none | `{"state": "ready", "products": [{"size", "price"}]}` or `{"state": "unavailable", "error": "storeUnavailable" \| "productsUnavailable"}`; calls `TipJarViewModel.load` (the store lists the three sizes; without StoreKit/Play Billing it is `storeUnavailable`) |
| `ext.mitlio.support.tip` | `size` (`small`, `medium` or `large`, required) | the tip jar state after the purchase: `{"state": "thanks"}`, or `{"state": "ready", "error": "purchaseFailed" \| null}` (a cancel is `error` null); calls `TipJarViewModel.tip` and opens the store's purchase sheet |
| `ext.mitlio.vehicles.catalogSearch` | `groupId`, `query` (required), `vehicleId` (optional, edit form) | `{"query", "suggestions": [{"name", "fuelType", "hybrid", "engineCc", "powerKw", "consumptionMilliPer100km"}], "noMatch", "catalogUnavailable"}`; calls `VehicleFormViewModel.searchCatalog` (bundled EEA car list, offline, max 5 hits) on the form instance the screen uses
| `ext.mitlio.vehicles.catalogPick` | `groupId`, `index` (into the last `catalogSearch`), `vehicleId` (optional) | `{"name", "fuelType", "consumptionMilliPer100km", "fromCatalog", "undoable"}`; calls `VehicleFormViewModel.applyCatalogEntry` (`invalid_params` for an index outside the suggestions)
| `ext.mitlio.setup.state` | `flowId` (required) | `{"flowId", "status", "step", "stepIndex", "total", "finished", "answers", "skipped", "canGoBack", "canSkip"}`; `status` is `loading`, `ready` or `failed`, `step` the current step id (null when finished). Reads the saved progress of the guided setup flow (`SetupFlowViewModel`, PU-T05); `not_found` for a flow id not registered in `setupFlowConfigsProvider` |
| `ext.mitlio.setup.next` | `flowId` (required), `answer` (optional; JSON-decoded when it parses, else a string) | the same snapshot after moving on; calls `SetupFlowViewModel.next`: checks the answer, saves, advances, finishes after the last step (`invalid_params` for a missing or rejected answer, `conflict` when there is no step, `internal` when saving fails; nothing moves on an error) |
| `ext.mitlio.setup.skip` | `flowId` (required) | the same snapshot; calls `SetupFlowViewModel.skip` (`invalid_params` for a step that cannot be skipped) |
| `ext.mitlio.setup.back` | `flowId` (required) | the same snapshot; calls `SetupFlowViewModel.back`, also from the finish screen to the last step (`conflict` on the first step) |
| `ext.mitlio.cars.list` | none | `{"cars": [{"id", "name", "fuelType", "consumptionMilliPer100km", "wearMilliPerKm"}]}`; the personal cars ("Meine Autos", PU-T10) |
| `ext.mitlio.cars.add` | none | the saved car `{"id", "name", ...}`; the finish action of the car flow (`CarSetupViewModel.save`): stores the car answered through `setup.*` (`car_setup`, plus `car_cost` for own costs) in "Meine Autos" and resets both flows (`conflict` while the answers are incomplete) |
| `ext.mitlio.cars.edit` | `id` (required), `name`, `fuelType`, `consumptionMilli`, `wearMilli` (all optional) | `{"car", "groups"}`; calls `CarEditViewModel.save`: saves the personal car and carries it to every linked group copy, `groups` = groups updated (`not_found` unknown car, `invalid_params` blank name or no consumption). The undo is kept for `cars.undoEdit` |
| `ext.mitlio.cars.undoEdit` | none | `{"ok": true}`; runs the undo of the last `cars.edit` (the snackbar's "Rückgängig"); `conflict` if there is none |
| `ext.mitlio.cars.use` | `groupId`, `carId` (both required) | the group copy `{"id", "name", ...}`; calls `GroupCarPickerViewModel.use`: creates the linked copy, or returns the one the group already has (`not_found` unknown car or group) |
| `ext.mitlio.cars.linked` | `vehicleId` (required) | `{"vehicleId", "linked"}`; reads `VehicleLinkViewModel`: is the group vehicle a copy of a personal car |
| `ext.mitlio.cars.unlink` | `vehicleId` (required) | `{"vehicleId", "linked": false}`; calls `VehicleLinkViewModel.unlink`, the copy keeps its values |
| `ext.mitlio.cards.state` | `card` (`settlePayment`, `groupCar` or `newGroupProfile`) | `{"card", "visible"}`; re-reads `EntryCardViewModel` (inline just-in-time card, PU-T11) |
| `ext.mitlio.cards.dismiss` | `card` | `{"card", "visible": false}`; calls `EntryCardViewModel.dismiss`, permanent (stored in local setup state, cleared by `reset`) |
| `ext.mitlio.profile.summary` | none | `{"summary"}`: `none`, `noPayment`, `paypal`, `iban` or `both`, what the settings row "Mein Profil" says; never an IBAN |
| `ext.mitlio.profile.qr` | none | `{"state": "loaded", "name", "payload"}`, `{"state": "noIban"}` or an error; re-reads `MyQrViewModel` ("Mein QR-Code teilen", PU-T16). `payload` is the EPC text without amount (line 8 empty) and contains the IBAN: debug builds only |
| `ext.mitlio.profile.shareQr` | none | `{"shared": true}`; calls `MyQrViewModel.share`: renders the code as PNG and opens the share sheet (`not_found` without IBAN, `internal` if the picture or the sheet fails). The call returns only after the sheet is dismissed, so the drive client times out while it is open: screenshot, then close the sheet |
| `ext.mitlio.feedback.available` | none | `{"availability"}`: `available`, `unavailable` (no backend, or the server says `provider_unconfigured`: the Settings row is hidden) or `unknown` (probe failed: the row stays). In a debug build without `SUPABASE_URL` the fake backend answers `available` (ADR-29, P7-T10) |
| `ext.mitlio.feedback.state` | none | the draft: `{"type", "messageLength", "hasEmail", "screenshots", "includeDiagnostics", "canSubmit", "status": "editing"\|"sending"\|"sent", "error"}`; never the text or the address |
| `ext.mitlio.feedback.draft` | any of `type` (`problem`, `idea`, `question`), `message`, `email`, `diagnostics` (`true`/`false`) | the draft state after the changes (`FeedbackViewModel.setType/setMessage/setEmail/setIncludeDiagnostics`); `invalid_params` for an unknown type |
| `ext.mitlio.feedback.diagnostics` | none | `{"appVersion", "os", "locale", "preview"}`: exactly what "App-Infos mitsenden" would send |
| `ext.mitlio.feedback.addScreenshot` / `feedback.removeScreenshot` | `data` (base64 image, default a 1x1 PNG) / `index` | the draft state; `invalid_params` over 3 pictures or over 5 MB. Stands in for the system photo picker, which a drive client cannot operate |
| `ext.mitlio.feedback.submit` | `locale` (`de`\|`en`, default `de`) | `{"sent": true, ...state}`; calls `FeedbackViewModel.submit`. Failures keep the draft: `invalid_params` (invalid draft or content refused), `rate_limited`, `unavailable` (not set up), `internal` (offline, server down) |
| `ext.mitlio.feedback.reset` | none | the empty draft state |
| `ext.mitlio.profile.photo.state` | none | `{"hasPhoto", "bytes", "canPick"}`; reads `ProfilePhotoViewModel` (PU-T13). Never the picture; `canPick` is false while no camera/gallery is registered |
| `ext.mitlio.profile.photo.set` | `data` (required, base64 of any picture) | `{"outcome": "saved" or "unusable"}`; `ProfilePhotoViewModel.setFromBytes`: crops square, compresses to at most 100 kB, saves in the private app folder (`unusable` for bytes that are no picture; `invalid_params` for missing or non-base64 `data`). Debug builds only, the way to give a photo without the system picker |
| `ext.mitlio.profile.photo.pick` | `source` (`camera` or `gallery`) | `{"outcome": "saved", "cancelled", "denied" or "unusable"}`; `ProfilePhotoViewModel.pick` (`not_found` while no picker is registered, `invalid_params` for another source) |
| `ext.mitlio.profile.photo.remove` | none | `{"removed": true}`; `ProfilePhotoViewModel.remove`: the avatar goes back to colour and initials/emoji. `reset` removes the photo too |
| `ext.mitlio.members.isOwn` | `memberId` (required) | `{"memberId", "own"}`; is the member "Ich" of this device (local marker, PU-T10) |
| (flow ids) | | `setupFlowConfigsProvider` is filled in `main.dart` with `car_setup` (PU-T08: `hasCar`, `name`, `fuel`, `consumption`, `extraCost`) and `car_cost` (PU-T09: `annualKm`, one step per cost, `depPurchase`/`depResale`/`depYears`, `basis`). Answers: `name` is `{"name", "type"}`, a cost step is `{"cents", "period": "month"\|"year"}`, consumption is thousandths per 100 km, `extraCost` is `flat` or `exact`. Saving the car is the finish screen's "Auto speichern" (`CarSetupViewModel.save`), not a drive command yet |
| (flow ids, PU-T12) | | Rare flows on the step flow, driven with `setup.*`: `first_group` (steps `name`, `people` = JSON list of names, `currency` = code; people and currency skippable), `commute_template:<groupId>` (`name`, `route` = `{"meters", "roundTrip"}`, `vehicle` = vehicle id, `people` = `{"driver", "passengers": [ids]}`, `tolls` = cents; people and tolls skippable) and `month_settle:<groupId>:<YYYY-MM>` (`rides`, `amounts`, each answered with `true`). A flow id with a scope (after the first colon) is its own copy of the base flow with its own progress. Each flow ends on its finish screen, whose button is one of the commands below |
| `ext.mitlio.onboarding.createGroup` | none | `{"id", "name", "currency"}`; the finish action of `first_group` (`FirstGroupViewModel.create`): creates the group with the people (the profile "Ich" first) and clears the flow; `conflict` while the name is missing |
| `ext.mitlio.rides.commute.save` | `groupId` (required) | the stored template `{"id", "name", "distanceMeters", "roundTrip", "vehicleId", "defaultDriverId", "defaultPassengerIds", "tollsCents"}`; the finish action of `commute_template:<groupId>` (`CommuteTemplateViewModel.save`); `conflict` while name, route or car are missing |
| `ext.mitlio.rides.settleFlow.confirm` | `groupId`, `month` (`YYYY-MM`) (both required) | `{"month", "rideCount", "expenseIds"}`; the finish action of `month_settle:<groupId>:<month>` (`MonthSettleFlowViewModel.confirm`): settles the month like `rides.settle` once both looks were answered (`conflict` before that) and clears the review |
| `ext.mitlio.recurring.create` | `groupId`, `title`, `amountCents` (group currency), `frequency` (`daily`, `weekly`, `monthly`, `yearly`) (all required); `interval` (default 1), `start` (`YYYY-MM-DD`, default today), `end`, `payers` (JSON `{memberId: cents}`, default the first member), `split` (JSON like `expenses.add`, default equal among everyone), `category`, `lastGenerated` (`YYYY-MM-DD`, an expense for that day exists already) | the rule `{"id", "groupId", "title", "amountCents", "payers", "category", "frequency", "interval", "start", "end", "lastGenerated", "next", "paused"}`; calls `RecurringViewModel.create` (P9-T03): stores a rule, creates no expense by itself (`recurring.catchUp` does). The rule is checked like an expense (`invalid_params`) |
| `ext.mitlio.recurring.update` | `id` (required) plus the params of `recurring.create` except `groupId` | the updated rule; calls `RecurringViewModel.update`: replaces what it creates and when, keeps `lastGenerated` and `paused` (`not_found` unknown id) |
| `ext.mitlio.recurring.list` | `groupId` (required) | `{"rules": [...]}`, shape as in `create`; `next` is the first date after today (null when the rule ended) |
| `ext.mitlio.recurring.pause` | `id` (required), `paused` (`true` default, `false` resumes) | the rule; calls `RecurringViewModel.setPaused`. Resuming skips the dates that passed meanwhile (`lastGenerated` moves up to the newest one on or before today) |
| `ext.mitlio.recurring.delete` | `id` (required) | `{"id"}`; calls `RecurringViewModel.delete`: expenses already made stay |
| `ext.mitlio.recurring.catchUp` | none | `{"created", "skipped", "failures": [{"title", "error"}]}`; runs `RecurringCatchUpViewModel.run`, what the app does on start and on resume: one expense per due date, oldest first, at most 12 per rule (`skipped` = older due dates left out), the clock is the injected one. A failing rule stops itself only and is listed in `failures`; nothing is marked as made for it |

`navigate` also reaches the first-run routes `/welcome` (onboarding, shown on `/` while no group exists) and `/trip` (the trip form without a group). Onboarding has no commands of its own: the commute path creates its group through `GroupsViewModel.create`, i.e. what `groups.create` calls.

`reset` and `seed` go through the `DebugDataControl` interface; the default implementation (`DriftDebugDataControl`) works on the
real database and repositories.

`ext.mitlio.state` screens registered so far (wired in `app/lib/debug/debug_snapshots.dart`, ViewModels never import `debug/`): `groups` (home list), `recurring` (`/groups/:id/recurring`: `{status, groupId, rules}`) and `group` (detail of the group in the current route, `{"status":"not_open"}` otherwise). Both report
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
