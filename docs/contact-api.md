# Contact API (`contact` Edge Function)

Contact form on the website (`/kontakt/`, `/en/contact/`), second channel next to `contact@mitlio.de` in the Impressum.
Implementation: `supabase/functions/contact/`, pure logic in `supabase/functions/_shared/contact.ts` (Deno tests in
`contact_test.ts`). Web: `web/src/components/Contact.astro`, `web/src/contact/form.ts`, `web/src/lib/contact.ts`.
Data flow for the privacy policy: `docs/data-flows.md`.

## Request

```
POST /functions/v1/contact
Content-Type: application/json
{ "name": "optional, max 100", "email": "a@b.de", "message": "10..5000 chars", "locale": "de"|"en", "website": "" }
```

Auth: the project anon key as `apikey` / `Authorization: Bearer <anon key>` (the gateway requires it, the web ships it
publicly like for `fuel-prices`). `website` is a honeypot: a non-empty value returns `200 {"ok":true}` and sends nothing,
costs no rate limit token. Only `POST` (and CORS `OPTIONS`) is accepted.

## Response

`200 {"ok":true}` after the mail was accepted by the provider. Errors are `{"error":"<code>"}`:

| Status | Code | Meaning / what the web says |
|---|---|---|
| 400 | `invalid_json`, `invalid_locale` | malformed body (should not happen from the form) |
| 400 | `invalid_email`, `message_too_short`, `message_too_long`, `name_too_long` | validation, shown at the field |
| 405 | `method_not_allowed` | not POST |
| 429 | `rate_limited` (+ `retryAfter` seconds in the body, `Retry-After` header) | "Zu viele Nachrichten. Versuch es in N Minuten wieder." |
| 429 | `busy` (+ `retryAfter`, `Retry-After`) | the global daily cap is used up: "Formular stark ausgelastet, später versuchen oder an contact@mitlio.de schreiben" |
| 502 | `send_failed` | the provider refused or was unreachable: "nicht angekommen, versuch es später oder schreib an contact@mitlio.de" |
| 503 | `not_configured` | `RESEND_API_KEY`, `CONTACT_TO` or `CONTACT_FROM` missing: "Formular gerade nicht erreichbar. Schreib uns an contact@mitlio.de." |
| 503 | `rate_limit_unavailable` | the limiter (database) failed; the endpoint stays closed rather than unlimited. Shown as `send_failed` |

Validation order: honeypot, config, field validation, per-client limit, global cap, send. Validation errors cost no token.

## Mail

Sent with `POST https://api.resend.com/emails` (`Authorization: Bearer $RESEND_API_KEY`), plain text:
`from` = `CONTACT_FROM` (`kontakt@mitlio.de`), `to` = `CONTACT_TO`, `reply_to` = the user's address (so "Reply" answers
the user), `subject` = `mitlio Kontakt: <first 60 characters of the message>` (one line, control characters removed).
Body: name, e-mail, language, blank line, message.

**EU region:** Resend has no separate EU API host; the sending region is a property of the *domain* (create the domain
`mitlio.de` in the Resend dashboard with region **Ireland (eu-west-1)**). The function therefore calls the one endpoint
above. Verify this in the Resend docs before go-live; if Resend ever documents a regional host, change `RESEND_URL` in
`_shared/contact.ts`.

## Privacy and abuse protection

- Stores nothing: no database rows. The only log lines are `contact send failed: status=<code> type=<resend error name|error class|unknown>` (provider failures, so they show up in the Supabase function logs) and `contact rate limiter failed`. Never message, e-mail, name, IP or error text.
- Rate limit: token bucket in `public.rate_limits` via `consume_rate_limit` (same as `fuel-prices`), key
  `sha256(salt|contact|ip)` (IP from `cf-connecting-ip`, else first `x-forwarded-for`), default 5 per hour per client.
  One token returns after `3600 / limit` seconds, which is the `Retry-After` value (720 s by default).
- Global cap: one more bucket in `rate_limits` under the fixed key `contact:global` (no client data), default 50 mails per
  day over all clients, so rotating IPs cannot burn the Resend quota or flood the inbox. It is checked after the
  per-client limit; `Retry-After` is `86400 / limit` (1728 s by default).
- CORS: origins from `CONTACT_ALLOWED_ORIGINS`, falling back to `FUEL_ALLOWED_ORIGINS`; `Retry-After` is exposed.

## Server configuration (secrets / env)

| Name | Meaning | Default |
|---|---|---|
| `RESEND_API_KEY` | Resend API key (sending access) | none: `503 not_configured` |
| `CONTACT_TO` | recipient, `contact@mitlio.de` | none: `503 not_configured` |
| `CONTACT_FROM` | sender on the verified domain, `kontakt@mitlio.de` | none: `503 not_configured` |
| `CONTACT_ALLOWED_ORIGINS` | comma separated CORS allowlist | `FUEL_ALLOWED_ORIGINS` |
| `CONTACT_RATE_LIMIT_SALT` | salt for the IP hash | `FUEL_RATE_LIMIT_SALT`, then the service role key |
| `CONTACT_RATE_LIMIT_PER_HOUR` | messages per hour per client | `5` |
| `CONTACT_GLOBAL_PER_DAY` | messages per day over all clients | `50` |

Set with `supabase secrets set NAME=value --project-ref <ref>` (owner step, never in CI).
Deployment: `deploy-dev.yml` deploys every `supabase/functions/*/index.ts`, so `contact` needs no list entry.

## Web build

The form posts to `new URL('contact', FUEL_API_URL)`, i.e. the sibling function in the same project, with the same
anon key (`FUEL_API_ANON_KEY`); the CSP `connect-src` already allows that origin. Without `FUEL_API_URL` the page shows
the e-mail address instead of the form and makes no request.

Browsers give the same error for "offline" and "blocked" (CORS, wrong origin, server down). The form therefore checks
`navigator.onLine`: offline says so, otherwise it shows "Formular gerade nicht erreichbar, schreib an contact@mitlio.de".
