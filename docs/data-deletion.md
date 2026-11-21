# Delete my data (P7-T07)

Plain-language description for the privacy policy the owner writes. In the app: Settings, Datenschutz,
"Alle meine Daten löschen". The screen explains what happens and asks the user to type the confirmation
word (LÖSCHEN / DELETE). There is no dialog and no undo, so this is the one place where we ask first.

## On the device

Deleted immediately and for good:

- all groups, members, expenses, settlements, rides, vehicles, ride templates and the edit history,
- saved places ("Zuhause", "Arbeit") of the ride distance lookup,
- payment details, including IBAN, BIC and account name, and the key that encrypts the IBAN (kept in the
  phone's Keychain/Keystore),
- the crash-report choice (back to "off").

Afterwards the app is in its first-run state. If something fails, nothing is half-deleted from the user's point
of view: the screen says so and the user can try again.

## On the server

Without sync (today: no Supabase URL in `app/config/prod.json`) nothing about a person is stored on the server and this
step does nothing. Once sync is live, the app first calls `delete_my_data()` (migration `0008`, rewritten in `0010` and
`0014`) and only then wipes the device, so a failed call can simply be repeated. `delete_my_data()` acts for
`auth.uid()` and delegates to `delete_account_data(uid)` (migration `0014`), the one deletion path that the daily
cleanup of inactive anonymous accounts (`docs/retention.md`) uses as well. For the account it deletes:

- the links between the user and their groups (the user can no longer open them),
- the link between the user and their member entries (the entry keeps its name, but no longer points to an
  account),
- push tokens and notification settings, once those tables exist,
- the account itself, including invites the user created, their entries in the join audit and login sessions,
- the user's rows in Supabase Auth's audit log (`auth.audit_log_entries`, migration `0017`): Auth writes one per token
  refresh and logout, with no link to the account, so they are removed by user id. The owner also switches the
  database audit log off (`supabase/README.md`); a daily job purges leftovers older than 7 days,
- ownership: a group the user owned passes to its oldest remaining membership.

Calling it twice is harmless.

## What stays

Group records that other people share stay for them: the group, its members' names, expenses, settlements and
rides. They belong to the group, not to one person, and removing them would change everybody else's balances.
A member entry that was linked to the deleted account remains as a plain name; the user can ask the group to
rename or remove it (or write to privacy@mitlio.de). The expense edit history (`expense_revisions`) stays with the group.
When the deleted account was the last one linked to a group, the daily job `cleanup_inactive_accounts()` (0014) deletes
the group and all its rows at its next run (groups younger than one day are skipped). Copies in other members' devices and in backups the user made themselves (exports, PDFs,
shared messages) are outside our reach.

## Technical notes

- `delete_my_data()` is `security definer`, empty `search_path`, acts for `auth.uid()` only; `anon` is denied.
- The account row is deleted from SQL. If a Supabase deployment ever refuses that, replace the `DELETE` in the
  migration with a returned flag and add an Edge Function using the service role as a follow-up.
- `groups.created_by` keeps the id of the deleted user. It no longer points to any account.
- `delete_account_data(uid)` is internal: execute is revoked from `public`, `anon` and `authenticated`; only
  `delete_my_data()` and the cleanup job (both `security definer`) call it.
- Audit rows: skipped when `auth.audit_log_entries` does not exist; when it is not accessible the function raises a
  warning and the rest of the deletion still runs. The purge `cleanup_auth_audit_log()` (cron `auth-audit-cleanup`)
  follows `auth_audit_days` in `supabase/retention.json`.
- pgTAP: `supabase/tests/database/rpc_delete_my_data.sql` (own data only, others untouched, anon denied,
  idempotent), `retention.sql` (automatic path: threshold, shared groups, orphan groups, dependent rows, audit purge threshold),
  `auth_audit_log.sql` (audit rows removed with the account, others kept, empty table no-op).
- App: `features/settings/` (`DeleteMyDataViewModel`, `DataDeletionRepository`). `ServerDataService` is inert
  until accounts exist; wire the RPC there.
