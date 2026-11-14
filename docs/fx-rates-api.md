# FX rates API (`fx-rates` Edge Function)

Contract for the app (P7-T02, `FxRateService`) and later the web calculator.
Plan: `docs/IMPLEMENTATION_PLAN.md` §7 P7 row T02, §2.5 (multi-currency, frozen ppm). Implementation:
`supabase/functions/fx-rates/`, pure logic in `supabase/functions/_shared/fx.ts`. Backend:
`supabase/migrations/0006_fx_rates.sql`. Same structure as `docs/fuel-prices-api.md`.

## Request

```
GET /functions/v1/fx-rates?base=USD&quote=EUR[&date=YYYY-MM-DD]
```

| Param | Rules |
|---|---|
| `base` | required, three upper-case letters (ISO 4217): the currency of 1 unit |
| `quote` | required, three upper-case letters, different from `base` |
| `date` | optional, a real day from `1999-01-04` to today (UTC). Absent or today: the latest rate |

Unknown parameters are ignored. Only `GET` (and CORS `OPTIONS`) is accepted; anything else is `405`.
Auth: send the project anon key as `apikey` / `Authorization: Bearer <anon key>`.

## Response

```
200 {"base":"USD","quote":"EUR","date":"2025-11-14","ratePpm":920000,"source":"frankfurter",
     "fetchedAt":"<ISO8601>","attribution":"Quelle: EZB-Referenzkurse via Frankfurter"}
```

- `ratePpm`: `quote` major units per 1 `base` major unit, times 1e6, an integer (`docs/domain-rules.md` "FX
  conversion"): 1 USD = 0.92 EUR is `920000`. This is the value the app freezes on the expense.
- Rounding: the provider's decimal is rounded half away from zero to a whole ppm (1.0869565 gives `1086957`).
  Rates below `0.0000005` (rounding to 0 ppm) or above `1000000` are rejected as garbage (`503`).
  Very small rates (for example a currency worth 0.00005 EUR) carry few significant digits; that is the ppm
  resolution of the domain, not a server limit.
- `date`: the ECB working day the rate is from. Weekends and holidays return the last working day, so it can be
  earlier than the requested day. The app shows it ("EZB, 13.11.").
- `attribution`: show it (or "EZB") wherever the suggestion is shown.

## Errors

| Status | Body | Meaning |
|---|---|---|
| 400 | `{"error":"invalid_params"}` | validation failed (also: future date, date before 1999-01-04) |
| 404 | `{"error":"no_data"}` | the provider does not publish that currency (ECB reference rates cover about 30) |
| 405 | `{"error":"method_not_allowed"}` | not GET |
| 429 | `{"error":"rate_limited"}` | per-client token bucket empty; `Retry-After` (seconds) is set |
| 503 | `{"error":"provider_unavailable"}` | provider failed or returned garbage and no cached value exists |

Clients treat any non-200 as "no suggestion": the user types the rate. Never retry in a tight loop.

## Source and caching

- Provider: Frankfurter (`https://api.frankfurter.app`, ECB reference rates, no key). Request
  `GET <FX_PROVIDER_URL>/latest?from=USD&to=EUR` or `/<date>?from=USD&to=EUR`.
- Cache table `fx_rates (base, quote, date) -> rate_ppm`, plus `source_date` (the ECB day) and `fetched_at`.
  `date` is the key day: the asked-for day, or today (UTC) for "latest". A weekend date is therefore cached under
  that weekend date and answers from the cache afterwards.
- "Latest" is refreshed when the cached value is older than 3 hours or from an earlier key day; a past day never
  changes and is served as long as it is cached. If the provider fails, the newest cached rate of the pair is served.
- A daily `pg_cron` job (`fx-rates-warm`, 15:20 UTC on working days, after the ECB publishes at about 16:00 CET)
  warms the common currencies quoted in EUR with the warm token. It does nothing until the Vault secrets
  `fx_rates_url`, `fx_rates_anon_key` and `fx_rates_warm_token` exist. Rows older than 60 days are deleted.

## Privacy and abuse protection

- The provider request is a plain GET carrying only the currency pair and the day. Nothing user-related: no client
  headers, no IP, no user id, no Origin, no amounts, no group or expense data.
- The client IP is never forwarded and never stored. The rate limiter stores `sha256(salt|"fx|"+ip)` only, in the
  shared `rate_limits` table (separate bucket from fuel-prices).
- CORS: `Access-Control-Allow-Origin` is echoed only for origins in `FX_ALLOWED_ORIGINS`; others get none.
- `fx_rates` is publicly readable (anon + authenticated) and writable only by the service role. No user data.

## Server configuration (secrets / env)

| Name | Meaning | Default |
|---|---|---|
| `FX_PROVIDER_URL` | provider base URL (tests point it to a stub) | `https://api.frankfurter.app` |
| `FX_ALLOWED_ORIGINS` | comma separated CORS allowlist | none (no origin allowed) |
| `FX_RATE_LIMIT_SALT` | salt for the IP hash | the service role key |
| `FX_RATE_LIMIT_CAPACITY` / `FX_RATE_LIMIT_PER_MIN` | token bucket size / refill per minute | `60` / `60` |
| `FX_WARM_TOKEN` | value of the `x-fx-warm` header that lets the cron job force a refresh and skip the rate limit | none (warm-up disabled) |
