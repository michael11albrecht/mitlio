# ADR-28: Support the developer, opt-in and never in the payment

- **Status:** accepted (owner 2026-11-20); store-policy research below must be re-checked before P7-T09 ships; tax handling open
- **Date:** 2026-11-20

## Context

Hosting and development cost money (ADR-18). The owner asked for a way for users to tip, ideally when
they settle a group. Product rule #0 (no ads, no dark patterns, no popups) and ADR-09 (mitlio never
touches money, no PSP) limit the options.

## Decision

1. **Never inside the payment.** No tip row, preselected amount or extra transfer in the settle flow.
   mitlio only builds payment links for the friend (ADR-09); adding the developer to a transfer would
   make the app a payment intermediary (PSD2 licensing, tax) and is a nudge at a payment step.
2. **Quiet opt-in surfaces only**, all one tap and dismissible, none blocking:
   - Settings row "mitlio unterstützen".
   - One line on the "all settled" success screen, shown after the result, at most once per 5
     settlements and never twice in 30 days; "Nicht mehr zeigen" is permanent. No popup, no amount.
   - Web calculator footer (with issue #186 footer credit).
3. **Where the link goes, per surface** (research 2026-11-20, secondary sources, verify first):
   - **Web:** `paypal.me/<handle>` or Ko-fi/GitHub Sponsors. No store rules apply.
   - **iOS app:** Apple allows tips to the developer **via in-app purchase** (guideline 3.1.1, IAP
     tip, 15 % commission under the Small Business Program). External links are allowed on the US
     storefront since May 2025 (no entitlement, show only when the storefront is US); EU needs the
     StoreKit External Purchase entitlement and a commission; elsewhere an external payment link
     risks rejection under 3.1.1 (one developer report: a "buy me a coffee" link was rejected, tips
     excluded from the entitlement). Default for iOS: **IAP consumable tip jar** (3 sizes) or no
     in-app tip and only the web link on mitlio.de reachable from the store page.
   - **Android app:** Google Play Payments policy allows external donation links only for
     verified tax-exempt nonprofits; a private PayPal.Me link in the app is a removal risk. Default
     for Android: **Play Billing consumable** or no in-app link.
4. **Owner decision 2026-11-20:** a tip must be one tap (Face ID / Apple Pay) or people do not tip, and
   the "Offers In-App Purchases" label is judged a small risk (measure install rate before/after).
   So: **iOS = IAP consumable tip jar (3 sizes, e.g. 1/3/5 €), Android = Play Billing consumable
   (same sizes), web = PayPal.Me link.** The app itself never links out to PayPal, which avoids the
   rejection/removal risk above. Dependency `in_app_purchase` (rationale in the PR). No ad, tracking
   or attribution SDK; purchase state is not synced and not analysed.
5. **PayPal.Me for the web page:** owner is fine with it. Before launch the owner checks how PayPal
   treats tips/donations on a private account.
6. **Tax is open (owner action):** tip income is probably taxable; whether it is a trade (Gewerbe),
   whether Kleinunternehmerregelung applies and how Apple/Google payouts are booked needs one session
   with a Steuerberater. Same answer for IAP and PayPal. Until then the feature ships **behind a
   remote flag, off**; it is switched on only after the owner confirms.

## Consequences

- No change to ADR-09; payments stay link-only.
- New settings flag `supportPromptState` (local only: last shown, count, dismissed), no analytics.
- Task P7-T09 builds everything behind a remote flag (off); switching it on waits for the tax answer (§12 #13c).

## Revisit when

Epic v. Apple is decided (US link-out commission), the EU steering rules change, or tips exceed hosting
costs and a business setup becomes worthwhile.
