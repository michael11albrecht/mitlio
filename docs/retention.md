# Data retention

Single source of truth for the periods: [`supabase/retention.json`](../supabase/retention.json). The cleanup SQL, the
pgTAP test (`supabase/tests/database/retention.sql`) and the privacy text (`web/src/i18n/legal.ts`) must match it.
`web/tests/retention.spec.ts` and `web/tests/legal.spec.ts` fail when they drift. To change a period: edit the JSON, add
a new migration for the SQL (never edit a merged one), update the pgTAP test, then run the web tests.

| Data | Where | Period | Key in `retention.json` | Enforced by |
|---|---|---|---|---|
| Device data (groups, rides, expenses, settings, IBAN) | the user's device | until the user deletes it ("Alle meine Daten löschen") or uninstalls the app | none | user (`docs/data-deletion.md`) |
| Rate-limit IP hashes (`rate_limits`, also for the contact form) | Supabase | 1 day (at most ~2 days in practice: the job runs daily) | `rate_limits_days` | cron `fuel-prices-cleanup` (0005) |
| Fuel price cache, non-national (`fuel_price_cache`) | Supabase | 2 days | `fuel_cache_days` | cron `fuel-prices-cleanup` (0005) |
| Exchange rates (`fx_rates`) | Supabase | 60 days | `fx_rates_days` | cron `fx-rates-cleanup` (0006) |
| Join audit (`group_join_audit`) | Supabase | 90 days (only once sync is live) | `join_audit_days` | cron `join-data-cleanup` (0013) |
| Expired invites (`group_invites`) | Supabase | 30 days after expiry (only once sync is live) | `expired_invites_days_after_expiry` | cron `join-data-cleanup` (0013) |
| Anonymous accounts and groups left with no account | Supabase | accounts after 13 months of inactivity, groups once no account is left. **PLANNED, not active yet**: ships with sync (P6) | none yet | not implemented |
| Supabase platform logs | Supabase | at most 7 days (plan-dependent, controlled by the provider) | `platform_logs_max_days` | provider |
| Crash reports (opt-in) | Sentry (EU) | 30 days | `sentry_days` | owner sets the project's data retention in Sentry |
| Website server logs | Firebase Hosting (Google) | controlled by Google; we have no access and do not evaluate them | none | provider |
| Emails and contact form messages | our mailbox | 12 months after the last message | `email_months` | mailbox auto-delete rule (owner) |
| Data protection requests and replies | our mailbox | 3 years (accountability, Art. 5(2) GDPR) | `privacy_request_years` | owner |

The contact form stores nothing on the server except the hashed rate-limit entry; the message itself only lives in the
mailbox (see `docs/data-flows.md`).

## Owner steps

- Mailboxes `contact@mitlio.de` and `privacy@mitlio.de` with a 12-month auto-delete rule (privacy requests are
  exempt from it for 3 years, e.g. by moving them to a separate folder).
- Sentry: set the project's data retention to 30 days.
