# Delete my data (P7-T07)

Plain-language description for the privacy policy the owner writes. In the app: Settings, Datenschutz,
"Alle meine Daten löschen". The screen explains what happens and asks the user to type the confirmation
word (LÖSCHEN / DELETE). There is no dialog and no undo, so this is the one place where we ask first.

## On the device

Deleted immediately and for good:

- all groups, members, expenses, settlements, rides, vehicles, ride templates and the edit history,
- payment details, including IBAN, BIC and account name, and the key that encrypts the IBAN (kept in the
  phone's Keychain/Keystore),
- the crash-report choice (back to "off").

Afterwards the app is in its first-run state. If something fails, nothing is half-deleted from the user's point
of view: the screen says so and the user can try again.

## On the server

mitlio has no accounts yet, so today nothing about a person is stored on the server and this step does nothing.
Once sign-in exists, the app first calls `delete_my_data()` (migration `0008_delete_my_data.sql`) and only then
wipes the device, so a failed call can simply be repeated. For the signed-in user it deletes:

- the links between the user and their groups (the user can no longer open them),
- the link between the user and their member entries (the entry keeps its name, but no longer points to an
  account),
- push tokens and notification settings, once those tables exist,
- the account itself, including invites the user created and login sessions.

Calling it twice is harmless.

## What stays

Group records that other people share stay for them: the group, its members' names, expenses, settlements and
rides. They belong to the group, not to one person, and removing them would change everybody else's balances.
A member entry that was linked to the deleted account remains as a plain name; the user can ask the group to
rename or remove it. Copies in other members' devices and in backups the user made themselves (exports, PDFs,
shared messages) are outside our reach.

## Technical notes

- `delete_my_data()` is `security definer`, empty `search_path`, acts for `auth.uid()` only; `anon` is denied.
- The account row is deleted from SQL. If a Supabase deployment ever refuses that, replace the `DELETE` in the
  migration with a returned flag and add an Edge Function using the service role as a follow-up.
- `groups.created_by` keeps the id of the deleted user. It no longer points to any account.
- pgTAP: `supabase/tests/database/rpc_delete_my_data.sql` (own data only, others untouched, anon denied,
  idempotent).
- App: `features/settings/` (`DeleteMyDataViewModel`, `DataDeletionRepository`). `ServerDataService` is inert
  until accounts exist; wire the RPC there.
