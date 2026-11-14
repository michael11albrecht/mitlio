# Fuel prices API (`fuel-prices` Edge Function)

Contract for the app (P6c-T05, `FuelPriceService`) and the web calculator (PW-T04).
Plan: `docs/IMPLEMENTATION_PLAN.md` §7 P6c, ADR-20. Implementation: `supabase/functions/fuel-prices/`,
pure logic in `supabase/functions/_shared/{fuel,oil_bulletin}.ts`. Backend: `supabase/migrations/0005_fuel_prices.sql`.

## Request

```
GET /functions/v1/fuel-prices?type=e5|e10|diesel&lat=<float>&lng=<float>&radius=<km 1..10>
GET /functions/v1/fuel-prices?type=…&plz=<5 digits>
GET /functions/v1/fuel-prices?type=…                      (national average)
```

| Param | Rules |
|---|---|
| `type` | required: `e5`, `e10` or `diesel` |
| `lat`, `lng` | both or neither. `lat` in -90..90, `lng` in -180..180, decimal point, no exponent |
| `radius` | only with `lat`/`lng`; number 1..10 (km), rounded to whole km; default `5` |
| `plz` | exactly 5 digits. Not combinable with `lat`/`lng`/`radius` |

Unknown parameters are ignored. Only `GET` (and CORS `OPTIONS`) is accepted; anything else is `405`.
Auth: send the project anon key as `apikey` / `Authorization: Bearer <anon key>` like any Supabase function
(the hosted gateway requires it; the web calculator ships the anon key publicly, that is expected).

## Response

```
200 {"type":"e5","priceMilli":1799,"source":"tankerkoenig|eu-oil-bulletin","scope":"nearby|plz|national",
     "fetchedAt":"<ISO8601>","stations":<int>,"attribution":"<see below>","approximation":"e5"}
```

- `priceMilli`: thousandths of EUR per litre (`docs/domain-rules.md` units): 1.799 EUR/l is `1799`. Integer, never a float.
- `approximation`: present **only** as `"e5"`, when the value for the requested type is not measured but taken from E5
  (national `e10` from the bulletin, see below). Show it as an estimate ("ca.") in the UI. Absent otherwise.
- `attribution` (show it wherever the price is shown):
  - `source: "tankerkoenig"`: `Daten: MTS-K via Tankerkönig (CC BY 4.0)`
  - `source: "eu-oil-bulletin"`: `Quelle: EU Weekly Oil Bulletin`

### Scopes and sources

| Scope | Source | `priceMilli` | `fetchedAt` | `stations` |
|---|---|---|---|---|
| `nearby` | `tankerkoenig` | median of the open stations within `radius` of the ~1 km cell of the point | time of the provider fetch (cache time) | number of stations in the median |
| `plz` | `tankerkoenig` | same, around the main city of the PLZ's two-digit zone (regional, not street-exact), radius 10 km | as above | as above |
| `national` | `tankerkoenig` when the server has a provider key and a fresh value | median over the open stations around the 16 state capitals (10 km each) | as above | number of stations in the median |
| `national` | `eu-oil-bulletin` when there is no provider key (or the provider failed) | latest weekly bulletin price with taxes for Germany: Euro-super 95 maps to `e5`, Automotive gas oil to `diesel` | **date the bulletin prices are in force on** (up to about 7 days old), not the fetch time | `0` |

- The bulletin has no E10. National `type=e10` from the bulletin returns the E5 value with `"approximation":"e5"`.
  (Tankerkönig-derived national E10 is a real median and has no `approximation`.)
- The app must therefore treat `source` and `fetchedAt` as data and display age/source; `national` works with zero secrets.
- `nearby` and `plz` always need the Tankerkönig key on the server; without it they are `503 provider_unconfigured`.
- Server cache TTLs: nearby 10 min, plz 30 min, national (Tankerkönig) 1 h, bulletin 12 h. Responses carry
  `Cache-Control: public, max-age=60`. If the provider fails, a stale cached value is served instead of an error.

## Errors

| Status | Body | Meaning |
|---|---|---|
| 400 | `{"error":"invalid_params"}` | validation failed |
| 404 | `{"error":"no_data"}` | provider answered but there is no open station with a price in that area |
| 405 | `{"error":"method_not_allowed"}` | not GET |
| 429 | `{"error":"rate_limited"}` | per-client token bucket empty; `Retry-After` header (seconds) is set |
| 503 | `{"error":"provider_unconfigured"}` | `nearby`/`plz` requested but no provider API key on the server |
| 503 | `{"error":"provider_unavailable"}` | provider failed or returned garbage and no cached value exists |

Clients must treat any non-200 as "no live price": fall back to manual entry / last known value. Never retry
in a tight loop; honour `Retry-After`.

## Privacy and abuse protection (what the server does)

- Exact coordinates never leave the function: `lat`/`lng` are snapped to the centre of a geohash precision-6 cell
  (about 1.2 km x 0.6 km) *before* anything else. That snapped point is the only location sent to the provider
  and the only form stored in the cache key (`<geohash6>:<radius>`).
- A PLZ is never sent to the provider. It is mapped to a fixed city coordinate of its two-digit postcode zone
  (zones that do not exist, such as `05`, `11`, `43`, `62`, are `invalid_params`) and a radius-10 km query around
  that coordinate is made. The cache key is the PLZ.
- The provider request carries only: snapped lat/lng, radius, `sort=dist`, `type=all` and the API key. No client
  headers, no IP, no user id, no Origin.
- The client IP is never forwarded and never stored. The rate limiter stores `sha256(salt|ip)` only, in
  `rate_limits`, and rows older than a day are deleted by a cron job. The IP is read from `cf-connecting-ip`, else the
  first `x-forwarded-for` entry, as set by the Supabase proxy.
- CORS: `Access-Control-Allow-Origin` is echoed only for origins in the `FUEL_ALLOWED_ORIGINS` allowlist
  (own domain + app origins); other origins get no CORS headers.
- The cache table `fuel_price_cache` is publicly readable (anon + authenticated) and writable only by the
  service role. It contains no user data.

## Server configuration (secrets / env)

| Name | Meaning | Default |
|---|---|---|
| `TANKERKOENIG_API_KEY` | provider key; absent means `503 provider_unconfigured` for nearby/plz and bulletin for national | none |
| `TANKERKOENIG_BASE_URL` | provider base URL (tests point it to a stub) | `https://creativecommons.tankerkoenig.de/json` |
| `OIL_BULLETIN_URL` | URL of the weekly "prices with taxes" XLSX (tests point it to a stub) | the European Commission download |
| `FUEL_ALLOWED_ORIGINS` | comma separated CORS allowlist | none (no origin allowed) |
| `FUEL_RATE_LIMIT_SALT` | salt for the IP hash | the service role key |
| `FUEL_RATE_LIMIT_CAPACITY` / `FUEL_RATE_LIMIT_PER_MIN` | token bucket size / refill per minute | `30` / `30` |
| `FUEL_WARM_TOKEN` | value of the `x-fuel-warm` header that lets the hourly cron job force a refresh and skip the rate limit | none (warm-up disabled) |

The hourly `pg_cron` job (`fuel-prices-warm-national`) calls the function for the three fuel types with that header. It
does nothing until the Vault secrets `fuel_prices_url`, `fuel_prices_anon_key` and `fuel_prices_warm_token` exist.
