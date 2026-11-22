# Feedback API (`submit-feedback` Edge Function)

In-app feedback (ADR-29, plan P7-T10, issue #230). The app posts a report; the function turns it into a GitHub
issue labelled `user-feedback` + `needs-triage` (never `agent-implement`: user text is untrusted, a human rewrites it
into a spec first). Implementation: `supabase/functions/submit-feedback/`, pure logic in
`supabase/functions/_shared/feedback.ts` (Deno tests in `feedback_test.ts`, integration test with a GitHub stub in
`tests/feedback_integration_test.ts`). Bucket and retention job: migration `0020_feedback_bucket.sql`.

## Availability probe

`GET /functions/v1/submit-feedback` (anon key as bearer, like the other functions)

- `200 {"available":true}`: the GitHub token secret exists.
- `503 {"error":"provider_unconfigured"}`: it does not. The app hides the Feedback row (merging is safe before the owner
  has done the owner steps below). A failed or timed-out probe (offline) does not hide the row: the form opens and
  the submit shows the real error.

## Submit

```
POST /functions/v1/submit-feedback
Content-Type: application/json
{
  "type": "problem" | "idea" | "question",
  "message": "10..5000 chars",
  "email": "optional, only when the user wants a reply",
  "locale": "de" | "en",
  "diagnostics": { "appVersion": "0.4.0+1", "os": "iOS 18.1", "locale": "de_DE" },   // optional, opt-in
  "screenshots": [ { "data": "<base64 png|jpeg|webp>" } ]                           // 0..3, 5 MB each decoded
}
```

`200 {"ok":true}` once the issue exists. The response never contains the token, the issue URL or the feedback id.
Errors are `{"error":"<code>"}`:

| Status | Code | Meaning / what the app says |
|---|---|---|
| 400 | `invalid_json`, `invalid_type`, `invalid_locale`, `invalid_diagnostics` | malformed body (should not happen from the form) |
| 400 | `message_too_short`, `message_too_long`, `invalid_email` | validation, shown at the field |
| 400 | `too_many_screenshots`, `invalid_screenshot` | more than 3, or not a PNG/JPEG/WebP (decided by the bytes) |
| 413 | `screenshot_too_large`, `payload_too_large` | over 5 MB per image / body too big |
| 405 | `method_not_allowed` | not GET/POST |
| 429 | `rate_limited` (+ `retryAfter` seconds, `Retry-After`) | 5 reports per hour and client: "Versuch es in N Minuten wieder." |
| 429 | `busy` (+ `retryAfter`, `Retry-After`) | global cap of 100 per day used up |
| 502 | `upload_failed`, `send_failed` | storage or GitHub refused/unreachable; nothing is kept server-side (uploaded files are removed again), the app keeps the draft |
| 503 | `provider_unconfigured` | no GitHub token yet |
| 503 | `rate_limit_unavailable` | the limiter (database) failed; the endpoint stays closed rather than unlimited |

Order: config, size, validation, per-client limit, global cap, uploads, issue. Validation errors cost no token.
Rate-limit keys are salted sha256 of the client IP (`feedback|<ip>`), stored in `rate_limits` like the other
functions (deleted after a day). The app has no stable device id before sign-in, so per-device limiting is the IP
bucket; App Attest / Play Integrity only if spam appears (ADR-29 §5).

## What goes where

| Data | Where | Who can read it |
|---|---|---|
| type, text, language, version/OS/locale (only with the opt-in) | GitHub issue (public repo!) inside a code block, labels `user-feedback`, `needs-triage` | everyone who can read the issue |
| screenshots | private Storage bucket `feedback-screenshots`, folder `<feedback id>/` | service role / owner in the dashboard |
| reply e-mail | same bucket, `<feedback id>/contact.json` | service role / owner in the dashboard |

The issue names the feedback id and how many screenshots exist, never a link. The e-mail never appears in the issue.
User text is wrapped in a code fence longer than any backtick run in it (no mentions, links or HTML fire) and the
issue says it is untrusted. Titles are one line with `@` neutralised.

## Retention

`feedback_days` = 90 in `supabase/retention.json` (DRAFT, owner decides). Daily cron `feedback-cleanup` (0020) calls
this function with the header `x-feedback-cleanup: <token>`; the function deletes files older than the period through
the Storage API (a SQL delete would leave the bytes in the object store). Inert until the Vault secrets exist.
GitHub issues are not deleted automatically; the owner closes/deletes them while triaging.

## Secrets and owner steps

Edge Function secrets (`supabase secrets set NAME=value --project-ref <ref>`):

| Secret | Purpose |
|---|---|
| `FEEDBACK_GITHUB_TOKEN` | fine-grained PAT (or GitHub App installation token) for `michael11albrecht/mitlio` with **Issues: read and write** only. Until it exists the function answers 503 and the app hides the form |
| `FEEDBACK_CLEANUP_TOKEN` | random string; the same value goes into the Vault secret `feedback_cleanup_token` |
| `FEEDBACK_RATE_LIMIT_SALT` | optional; falls back to the contact/fuel salt, then the service key |
| `FEEDBACK_GITHUB_REPO`, `FEEDBACK_GITHUB_API_URL`, `FEEDBACK_RATE_LIMIT_PER_HOUR`, `FEEDBACK_GLOBAL_PER_DAY`, `FEEDBACK_RETENTION_DAYS` | optional overrides (defaults: this repo, api.github.com, 5, 100, 90) |

Vault secrets for the retention job (SQL editor, per project): `select vault.create_secret('<value>', '<name>');` for
`feedback_url` (`https://<ref>.supabase.co/functions/v1/submit-feedback`), `feedback_anon_key`, `feedback_cleanup_token`.

The bucket is created by migration 0020 (Storage must be enabled in the project, it is by default). Also needed from
the owner: sign-off of the privacy text below, a retention decision, and the labels `user-feedback` / `needs-triage`
(GitHub creates missing labels on first use).

## Privacy text (DRAFT, needs owner sign-off, not yet published in `web/src/i18n/legal.ts`)

Add to the data-protection page once the feature is switched on (the periods come from `retention.json`
`feedback_days`):

**DE (Entwurf).** *Feedback aus der App.* Wenn du uns über „Einstellungen > Feedback“ schreibst, senden wir deinen
Text (und, wenn du es auswählst, bis zu drei Screenshots, deine E-Mail-Adresse und Versionsangaben: App-Version,
Betriebssystem, Sprache) an unseren Supabase-Dienst (Edge Function, EU) und von dort als Ticket an GitHub (GitHub, Inc.,
USA, Standardvertragsklauseln / DPF). Das Ticket enthält deinen Text und, nur wenn du es erlaubst, App-Version,
Betriebssystem und Sprache; es ist öffentlich lesbar, **schreibe deshalb keine privaten Daten in den Text**. Screenshots
und deine E-Mail-Adresse stehen nicht im Ticket, sondern in einem nicht öffentlichen Speicher bei Supabase und sind nur
für uns lesbar; wir löschen sie nach 90 Tagen. Rechtsgrundlage: Art. 6 Abs. 1 lit. f DSGVO (Bearbeitung deiner
Rückmeldung) bzw. lit. a für freiwillige Angaben. Zum Schutz vor Missbrauch speichern wir einen gesalzenen Hash deiner
IP-Adresse für einen Tag (Rate-Limit). Du kannst jederzeit Löschung verlangen: privacy@mitlio.de.

**EN (draft).** *Feedback from the app.* If you write to us via "Settings > Feedback", we send your text (and, if you
choose, up to three screenshots, your e-mail address and version details: app version, operating system, language) to
our Supabase service (Edge Function, EU) and from there as an issue to GitHub (GitHub, Inc., USA, SCCs / DPF). The issue
contains your text and, only if you allow it, app version, operating system and language; it is publicly readable, so
**do not put private data in the text**. Screenshots and your e-mail address are not in the issue but in a non-public
storage bucket at Supabase that only we can read; we delete them after 90 days. Legal basis: Art. 6(1)(f) GDPR
(handling your feedback), or (a) for optional details. To prevent abuse we store a salted hash of your IP address for
one day (rate limit). You can ask for deletion at any time: privacy@mitlio.de.

Also to settle before go-live: whether the issue tracker stays public (a private tracker would remove the "public" sentence),
and the GitHub data-processing terms.
