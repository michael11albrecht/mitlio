# ADR-27: Sync go, v1 scope

- **Status:** accepted (go: owner decision 2026-11-15, closes P5-T04). The v1 scope cuts in §2 are
  proposed by the planner and confirmed by the owner in review of the plan PR.
- **Date:** 2026-11-15

## Context

P5-T04 is the go/no-go for app-side sync. The field test has not surfaced anything that argues
against sharing groups across devices, and the server side (P6-T01..T06, ADR-24) is merged. A
staging project exists (Frankfurt) with anonymous sign-ins enabled; its first deploy waits on a
token permission fix. Rule #0 (simplicity) still applies: v1 sync should be the smallest thing that
makes a shared group trustworthy.

## Decision

### 1. Go

App-side sync (P6-T07..T16) starts now. The field test continues in parallel; its findings are fixed
as normal issues and do not block sync work. ADR-07 (outbox + pull cursor, aggregate LWW with HLC)
and ADR-24 (people vs. accounts, one rotating link, owner removal) stand unchanged.

### 2. v1 scope cuts

1. **No realtime in v1 (P6-T12 deferred).** The app pulls when it starts or comes back to the
   foreground, when a group is opened, on pull-to-refresh and right after a successful push. Local
   writes push after a short debounce. Friend groups edit rarely at the same moment, and realtime
   costs connections (ADR-18) and a second code path. Revisit when users report stale data, or fold
   it into P6b: a push notification already triggers a pull (P6b-T07).
2. **Anonymous accounts only, no sign-out in v1** (amends the P6-T07 row). Signing in happens
   silently on the first share or join. There is no "Abmelden" button: an anonymous account cannot be
   recovered after signing out, so the button would only destroy data. Leaving everything is the
   existing "Meine Daten löschen" (`delete_my_data`). Account linking (email/Apple/Google, ADR-08)
   stays later. A lost phone means rejoining with the link; the owner removes the old account, then
   the person is connected again (ADR-24).
3. **The version gate blocks sync only, never local use** (P6-T16). An old app keeps working offline
   and says it can no longer share until it is updated. Offline-first stays true.
4. **No conflict UI.** A concurrent edit of the same aggregate resolves by LWW (ADR-07) without a
   dialog. This is the documented behaviour, not a silent error: the expense history shows the
   overwritten version.
5. **Server-side `expense_revisions` are not pulled in v1.** The app keeps its local history; a
   pulled change is recorded there like a local edit.

### 3. Error contract (no silent errors, plan §2.6 #9)

Every server failure maps to one app-side `RemoteError` case with a du-form message and a next step.
Copy below is the intended German text; final wording goes through `docs/copy-guide.md`.

| Server signal | Case | Message (de) |
|---|---|---|
| no connection / timeout | `offline` | "Keine Verbindung. Deine Änderungen sind gespeichert und gehen raus, sobald du online bist." |
| SQLSTATE `P0429` `rate_limited`, auth HTTP 429 | `rateLimited(wait)` | "Zu viele Versuche. Versuch es in {n} Min. nochmal." |
| `invite_invalid` | `inviteInvalid` | "Dieser Link gilt nicht mehr. Bitte um einen neuen Link." |
| `member_already_claimed` | `memberAlreadyClaimed` | "{Name} ist schon mit einem anderen Handy verbunden. Wähl eine andere Person." |
| `membership_already_linked` | `alreadyConnected` | "Du bist in dieser Gruppe schon als {Name} verbunden." |
| `member_not_found` | `memberGone` | "Diese Person gibt es in der Gruppe nicht mehr. Wähl eine andere." |
| `42501` "not the owner of this group" | `notOwner` | "Das kann nur, wer die Gruppe erstellt hat." |
| `42501` "not a member of this group" | `notMember` | "Du bist nicht mehr in dieser Gruppe. Deine Daten bleiben auf diesem Handy." |
| `cannot remove own membership` | `cannotRemoveSelf` | "Dich selbst kannst du hier nicht entfernen." |
| version below `min_supported_version` | `versionTooOld` | "Diese Version kann nicht mehr teilen. Aktualisiere mitlio." + store button |
| HTTP 5xx | `serverDown` | "Der Server antwortet gerade nicht. Wir versuchen es gleich nochmal." |
| other 4xx on push (e.g. `payers_sum_mismatch`) | `rejected(code)` | "„{Titel}“ konnte nicht geteilt werden. Sie ist nur auf diesem Handy." |
| pull page cannot be applied (unreadable `updated_at`, local DB refusal; P6-T11) | `pullFailed(reason)` | "Neue Änderungen aus der Gruppe konnten nicht übernommen werden. Deine eigenen Daten sind sicher. Versuch es später nochmal oder aktualisiere mitlio." |

- **One message for invalid, expired and revoked links.** `join_group` returns `invite_invalid` for
  all three on purpose: telling them apart would confirm that a guessed token once existed. The
  next step is the same in every case: ask for a new link.
- **Rate-limit wait:** migration 0012 adds `hint = 'retry_after_seconds=<n>'` to the `P0429` raise.
  Without a hint the app says "in ein paar Minuten".
- **Stale writes are not errors.** `upsert_expense` returning `applied=false`, or the LWW trigger
  rejecting an older `updated_at`, means the server already has a newer version. The op is dropped
  and the next pull brings the newer version. This is the one documented exception to "never
  swallow".
- **Removed account (`notMember` on push or pull):** the group becomes local-only on this device,
  all data is kept, and the group shows the message above with "Neuen Link erbitten" as next step.

### 4. Testing without a live server

- The app talks to the backend only through narrow interfaces (`AuthService`, `SyncRemote`,
  `InviteRemote`, `AppConfigRemote`). Each has an in-memory fake that implements the server rules the
  app relies on (membership, LWW on HLC, `upsert_expense` invariants, `server_seq` order, every error
  code above).
- One shared contract suite per interface runs against the fake in `make test`, and against a local
  Supabase (`supabase start`) in a dedicated CI job added by P6-T13. Tests never hit staging or prod.
- The two-device E2E harness (P6-T13) runs in that same job.

## Consequences

- New migration 0012 (`app_config` with `min_supported_version`, rate-limit hint). No merged migration
  changes.
- Drift schema v5: local-only sync state (shared flag per group, pull cursor, persisted HLC node id).
- New app dependency `supabase_flutter` (ADR-06), rationale in its PR.
- The issues for P6-T07..T16 are listed in the plan rows.

## Revisit when

Users report stale data (add realtime), lost edits (ADR-07 per-field merge), or ask to sign in on a
second phone (account linking).
