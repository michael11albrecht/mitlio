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
| Anonymous accounts (`auth.users.is_anonymous`) | Supabase | 13 months without activity (only once sync is live; no anonymous accounts exist before). Deleted exactly like "Alle meine Daten löschen" (`delete_account_data`, `docs/data-deletion.md`); non-anonymous users are never touched | `inactive_account_months` | cron `inactive-accounts-cleanup` (0014) |
| Groups with no linked account, with all their rows | Supabase | deleted at the next daily run once no `group_memberships` row is left (groups younger than 1 day are skipped so a group is not caught between its creation and its first membership) | none (follows the accounts) | cron `inactive-accounts-cleanup` (0014) |
| Expense edit history (`expense_revisions`) | Supabase | newest 50 revisions per expense (older ones pruned by the trigger); no time limit, kept while the group exists, also for soft-deleted expenses | `expense_revisions_per_expense` | trigger `record_expense_revision` (0007) |
| Shared group content (groups, members, expenses, settlements, rides, vehicles, ride templates; soft-deleted rows stay as tombstones) | Supabase | while the group exists (see the two rows above) | none | the cleanup above |
| Revoked / replaced invites (`expires_at = infinity`, token hash only) | Supabase | kept until the group is deleted (the 30-day rule only reaches invites with a finite expiry) | none | group cleanup (0014) |
| Supabase platform logs | Supabase | at most 7 days (plan-dependent, controlled by the provider) | `platform_logs_max_days` | provider |
| Crash reports (opt-in) | Sentry (EU) | 30 days | `sentry_days` | owner sets the project's data retention in Sentry |
| Website server logs | Firebase Hosting (Google) | controlled by Google; we have no access and do not evaluate them | none | provider |
| In-app feedback files (screenshots, reply address; private bucket `feedback-screenshots`) | Supabase Storage | 90 days (DRAFT, owner decides; the GitHub issue text is not auto-deleted, the owner closes it while triaging) | `feedback_days` | cron `feedback-cleanup` (0021) calling `submit-feedback`, inert until the Vault secrets exist (`docs/feedback-api.md`) |
| Emails and contact form messages | our mailbox | 12 months after the last message | `email_months` | mailbox auto-delete rule (owner) |
| Data protection requests and replies | our mailbox | 3 years (accountability, Art. 5(2) GDPR) | `privacy_request_years` | owner |

### Activity signal for anonymous accounts

"Activity" is the latest of `auth.users.last_sign_in_at`, `auth.users.created_at` and the newest
`auth.refresh_tokens.created_at` / `updated_at` of that user. Every token refresh of a running app rotates the refresh
token, so an app that is opened and talks to the server shows up there. Edits by other members do not keep a dormant
account alive (group rows carry no author column, so there is no per-user write timestamp). Anonymous accounts are
identified by `auth.users.is_anonymous`; users who linked an email or provider are not anonymous and are never deleted
by the job.

The contact form stores nothing on the server except the hashed rate-limit entry; the message itself only lives in the
mailbox (see `docs/data-flows.md`).

## Owner steps

- Mailboxes `contact@mitlio.de` and `privacy@mitlio.de` with a 12-month auto-delete rule (privacy requests are
  exempt from it for 3 years, e.g. by moving them to a separate folder).
- Sentry: set the project's data retention to 30 days.
