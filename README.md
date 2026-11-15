# mitlio

[![ci](https://github.com/michael11albrecht/mitlio/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/michael11albrecht/mitlio/actions/workflows/ci.yml?query=branch%3Amain)
[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

**The private taxometer.** Share car-ride costs and group expenses fairly — commutes, holidays, shared trips — with live fuel prices, simple settle-up via PayPal.Me or SEPA QR code, and no ads.

Status: early development. See [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md) for the full plan and [`docs/adr/`](docs/adr/) for decisions.

## Development

```sh
make bootstrap   # install dependencies and git hooks
make check       # full quality gate (definition of done)
make help        # all commands
```

Contributor and agent rules: [`CLAUDE.md`](CLAUDE.md).

## Roadmap

Task IDs refer to [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md). Last updated 2026-11-15.

**Done:** offline app (groups, people, expenses, rides and trip cost, balances, settle-up via
PayPal.Me / SEPA QR, multi-currency, edit history, CSV/PDF export, statistics, onboarding,
delete-my-data), live fuel prices (EU average without key, nearby via Tankerkönig), SEO web
calculator with DE/EN landing pages, backend schema/RLS/RPCs/invites/rate limits (tested in CI,
not deployed), CI with coverage, mutation and golden gates, agent pipeline.

**In progress**

- [ ] Invite link per group that a new link replaces, owner can remove accounts ([ADR-24](docs/adr/0024-people-accounts-invite-link.md), server side)
- [ ] Backend choice for launch: Supabase Free vs Pro vs Firebase (research running; [ADR-18](docs/adr/0018-cost-policy.md) cost policy)

**Needs the owner (accounts, money, legal, decisions)**

- [ ] Accounts: Supabase EU project + secrets, Firebase project (FCM, Hosting), own domain (`SITE_URL`), Sentry DSN, Tankerkönig API key (nearby prices only)
- [ ] Signing: App Store Connect name reservation, iOS signing, Android keystore, Play service account (P1-T12, P8-T02)
- [ ] Legal texts: Impressum and Datenschutzerklärung (P7-T07, technical basis in [`docs/data-deletion.md`](docs/data-deletion.md))
- [ ] Release 0.2.0 (release-please PR #98)
- [ ] Repo settings: required checks and approvals; agent-fix-ci cost limit; auto-merge for `safe` PRs (P8-T07)
- [ ] Undecided: several accounts per person (e.g. couples)

**Next, in order**

1. [ ] **Field test** (P5): signed builds on own devices, real trip, every doubted number becomes a fixture + test
2. [ ] **Go/no-go for sync** (P5-T04, ADR)
3. [ ] **Sync in the app** (P6-T07–T16): anonymous sign-in, outbox, push/pull, realtime, two-device E2E, share/join UI with "Wer bist du?", convert local group to shared, minimum-version gate
4. [ ] **Push notifications** (P6b): FCM setup, notification outbox + `notify` function, per-group settings, quiet hours, hide amounts
5. [ ] **Delivery** (P8-T03/T04): staging deploy on merge, TestFlight + Play internal nightly, release workflow with approval
6. [ ] **Website live** (PW-T10/T11): Firebase Hosting on own domain, security headers, app links, Google Search Console via DNS TXT (no analytics script, PW-T09 decided)

**Later (backlog, P9):** receipt photos, on-device receipt OCR, recurring expenses, opt-in payment
reminders, weekly digest, read-only web share link, per-field merge if field data shows lost edits.

## License

Copyright (C) 2026 Michael Albrecht

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3 or (at your option) any later version. See [`LICENSE`](LICENSE).
