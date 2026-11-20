# ADR-28: Support the developer, opt-in and never in the payment

- **Status:** proposed (owner idea 2026-11-20; store-policy research below must be re-checked before P7-T09)
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
4. **Recommendation:** v1 = web footer link + Settings row that opens the **web page**
   `mitlio.de/unterstuetzen` (PayPal.Me, Ko-fi) in the system browser **only if** the owner accepts
   the review risk; otherwise IAP / Play Billing tip jar (`in_app_purchase` package, rationale in PR).
   Decide with a review submission to TestFlight/internal track first, not by guessing.
5. **PayPal.Me for tips to a private account:** friends-and-family style transfers are free in
   Germany, but PayPal treats tips/donations as commercial use of a private account; they can be
   limited or fee-bearing. Regular income also needs tax handling (Kleingewerbe/Steuerberater).
   Owner to clarify before launch; not an agent decision.

## Consequences

- No change to ADR-09; payments stay link-only.
- New settings flag `supportPromptState` (local only: last shown, count, dismissed), no analytics.
- Task P7-T09 (below in the plan) is blocked on the owner decisions in §12 #13.

## Revisit when

Epic v. Apple is decided (US link-out commission), the EU steering rules change, or tips exceed hosting
costs and a business setup becomes worthwhile.
