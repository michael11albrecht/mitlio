# Data flows (draft input for the privacy policy)

Plain-language list of what leaves the device and where it goes. The owner writes the privacy policy
(P7-T07); see also `docs/data-deletion.md`. Keep this file current when a flow is added.

How long each kind of data is kept: `docs/retention.md` (periods in `supabase/retention.json`).

## Providers (legal entity and transfer basis, as stated in the privacy text)

Checked against the providers' own pages on 2026-11-17; re-check when a provider changes its terms.

| Provider | Entity named in the text | Role | Transfer basis (per provider) |
|---|---|---|---|
| Supabase | Supabase Pte. Ltd., Singapore (DPA preamble) | processor, server in eu-central-1 | EU SCCs (DPA clause 12; no DPF) |
| Firebase Hosting | Google Ireland Limited (see "unverified" in PR #182) | processor | EU-US DPF (Google LLC certified), SCCs as fallback (Firebase DP terms). Google documents IP addresses for Hosting, kept "a few months" |
| Sentry | Functional Software, Inc. | processor, opt-in crash reports | DPF + SCCs fallback (DPA schedule 3). Event data at rest in Frankfurt when the EU region is chosen; accounts, tokens, support data in the US |
| Resend | Plus Five Five, Inc. (d/b/a Resend) | processor, contact form mail | DPF + EU SCCs (DPA). The "Ireland" region only selects where mail is sent from; Resend stores account data, mail metadata and logs in the US |
| Tankerkönig | Tankerkönig UG (haftungsbeschränkt), Nesselwang | independent source | none: only a rounded geohash point arrives, no personal data |
| EU Commission, Frankfurter | n/a | no personal data except the IP address on the direct Weekly Oil Bulletin download | n/a |
| Apple App Store, Google Play | Apple / Google | independent controllers for store accounts and downloads | their own policies; we receive no personal data |

## Shared groups (sync, not live yet)

Only once `app/config/prod.json` carries a Supabase URL and the user shares or joins a group. Without sync nothing
below happens. The privacy text for it is written (`futurePrivacySections*` in `web/src/i18n/legal.ts`) and rendered when
`SYNC_PRIVACY_RENDERED` is true; the production web build fails if the URL is set while it is not (`docs/release.md`).

| What the device contacts | What is sent | What the recipient can see |
|---|---|---|
| our Supabase project (Auth, PostgREST/RPC), region eu-central-1 | anonymous sign-in on the first share or join; then the group's rows as the outbox pushes them (`app/lib/features/sync/data/outbox_writer.dart`); pulls for the groups the account belongs to | Supabase (processor) and, through row-level security, the accounts linked to the group |

Stored on the server (tables of migrations 0001 to 0014):

- Account: random user id, no email or name, Supabase Auth sessions (`auth.users`, `auth.sessions`, refresh tokens).
- Group content, keyed by group: `groups` (name, currency, `created_by`), `members` (name, position, `paypal_me`,
  `iban_hint` = masked hint such as `DE89 …3000`, `user_id` link), `expenses` (title, category, amounts, currency, frozen
  fx rate, date, type, split mode, `trip_meta` JSON such as period, driver id, ride ids), `expense_payers`,
  `expense_shares`, `settlements` (from, to, amount, method), `rides` (date, distance, round trip, tolls, vehicle, driver,
  passengers, fuel price), `vehicles`, `ride_templates`. There is no notes column. Soft-deleted rows stay (`deleted_at`).
- `expense_revisions`: previous state of an expense before each change, author member, time; newest 50 per expense.
- `group_memberships` (account to group, member link, role owner/member), `group_invites` (SHA-256 token hash, creator,
  timestamps, `revoked_at`), `group_join_audit` (account, group, member, time; 90 days).
- `rate_limits`: `join:` plus hash of the user id, token bucket (see "Abuse protection" in the privacy text).
- Push notifications (migrations 0015, 0016; P6b): `device_tokens` (account, FCM token, platform, locale, app version,
  last seen; newest 20 per account), `notification_prefs` (account, group, level, quiet hours, hide amounts) and
  `notification_outbox` (group, actor account, event kind, entity id, display strings of the change: actor name, group
  name, title, amount, currency, member ids; no client access, no IBAN, no notes). Deleted with the account.

Never sent: full IBAN, BIC, account holder (`local_member_bank`, `local_profile_bank`), saved places (`local_places`),
route lookup text and place labels (only the distance goes into the ride), location, the crash-report choice.

Notes for the policy text:

- Legal bases: Art. 6(1)(b) for members using the feature; Art. 6(1)(f) for people who were entered by name and do not
  use mitlio (Art. 14 notice in the text: source = group members, categories = name plus amounts, shares, settlements,
  rides, optional PayPal.Me name / IBAN hint; removal by asking the group or privacy@mitlio.de) and for the join
  protocol and rate limit.
- Retention and deletion: `docs/retention.md`, `docs/data-deletion.md`.
- Unverified in code (check on the staging project before launch): which session metadata (IP, user agent) Supabase Auth
  keeps per session; the privacy text only says Supabase Auth creates session data.

## Fuel prices (chips in the ride and trip form)

| Case | What the device contacts | What is sent | What the recipient can see |
|---|---|---|---|
| No backend configured (current default) | `energy.ec.europa.eu` (European Commission), HTTPS GET of the public EU Weekly Oil Bulletin file | nothing but the request itself: no account, no key, no location, no ride or group data | the device's IP address and user agent, as for any download |
| Backend configured | our Supabase `fuel-prices` Edge Function | fuel type; postcode or position rounded to about 1 km only after the user's explicit tap | see `docs/fuel-prices-api.md` (server side) |

Notes for the policy text:

- Source credit shown in the app: "Quelle: EU Weekly Oil Bulletin (Europäische Kommission)".
- The device stores the last downloaded prices in a local file (no personal data) to work offline and to avoid
  downloading more than every 12 hours. Deleting the app deletes it.
- No cookies, no identifiers, no tracking SDKs involved.
- `web/src/i18n/legal.ts` (PR #124) is not on `main` yet; once merged, add one sentence there: "Für den
  Kraftstoffpreis (Bundesdurchschnitt) ruft die App ohne Server eine öffentliche Datei der Europäischen Kommission
  (energy.ec.europa.eu) ab; dabei ist deine IP-Adresse für die Kommission sichtbar, es werden keine personenbezogenen
  Daten übertragen."

## Route distance (start and destination in the ride and trip form)

Optional: the user opens "Start und Ziel eingeben, Strecke berechnen". Only with a configured backend; without it
the forms have only the manual kilometre field and nothing is sent.

| What the device contacts | What is sent | What the recipient can see |
|---|---|---|
| our Supabase `route-distance` Edge Function (POST, JSON body) | the text the user typed (from 3 characters, after a 300 ms pause), then the coordinates of the two places the user picked | the proxy forwards them to openrouteservice (HeiGIT, Germany) or, as fallback, Geoapify; those providers see the text/coordinates and the proxy's server address, never the user's IP address or id |

Notes for the policy text:

- Start and destination are personal data (they can reveal home and work). They are **not stored** anywhere on the
  server side: no logs of query text or coordinates, no cache. The proxy keeps only a salted hash of the user id (or
  address) and a counter for rate limiting. What the two providers keep is governed by their terms (DPA to check).
- On the ride only the **distance** is stored (as before). The place labels are never synced to the group.
- Saved places ("Zuhause", "Arbeit": label and coordinates) stay on the device in the local-only table
  `local_places`; they are never synced and are removed by "Alle meine Daten löschen" (`docs/data-deletion.md`).
- Suggestions need no location permission and no GPS.
- Provider data credit shown in the app: "Karten- und Routendaten © OpenStreetMap-Mitwirkende, via openrouteservice"
  (or "via Geoapify").
- No cookies, no identifiers, no tracking SDKs involved. API: `docs/route-distance-api.md`.

## Contact form (website, `/kontakt/` and `/en/contact/`)

Second contact channel next to `contact@mitlio.de` (Impressum). Web only; the app has no contact form. Without a
configured backend the page shows only the e-mail address and sends nothing.

| What the browser contacts | What is sent | What the recipient can see |
|---|---|---|
| our Supabase `contact` Edge Function (POST, JSON body) | the text the user typed: optional name, e-mail address, message, page language | the function forwards it as one e-mail through Resend (sent from Resend's Ireland region, sending domain mitlio.de; Resend stores account data, mail metadata and logs in the US, see "Providers" above) to our mailbox; Resend sees the mail and processes it as our processor (DPA to sign); the browser's IP address is seen by Supabase as for any request |

Notes for the policy text:

- **Nothing is stored by the function**: no database rows. Failure log lines hold only a status code and error type, never message, e-mail, name or IP. The only server-side
  trace is a salted hash of the IP and a counter in `rate_limits` (5 messages per hour) plus one global counter (50 per day), deleted after a day.
- The message ends up in our mailbox and with the e-mail providers involved; the owner decides retention there.
- Purpose and legal basis: answering the request (Art. 6(1)(b) or (f) GDPR). The honeypot field is not personal data.
- No cookies, no identifiers, no third-party scripts on the page. API: `docs/contact-api.md`.

## In-app feedback (Settings > Feedback; ADR-29, P7-T10; DRAFT until the owner signs off)

Only exists once the owner has stored the GitHub token (otherwise the function answers 503 and the app hides the row).

| What the app contacts | What is sent | What the recipient can see |
|---|---|---|
| our Supabase `submit-feedback` Edge Function (POST, JSON) | type (problem/idea/question), the text, optional reply e-mail, up to 3 screenshots, language; app version, OS and locale only if the user switched diagnostics on | the function creates one GitHub issue (GitHub, Inc.; labels `user-feedback` + `needs-triage`) with the text and, if allowed, version/OS/locale; screenshots and the e-mail go to the private Storage bucket `feedback-screenshots` (only the service role reads them) and are deleted after `feedback_days`; Supabase sees the request IP as for any request, a salted hash of it is kept one day for the rate limit |

Wording for the policy (DE/EN, DRAFT): `docs/feedback-api.md`. Contract: same file.
