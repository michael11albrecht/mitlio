# Fuel prices API (`fuel-prices` Edge Function)

Contract for the app (P6c-T05, `FuelPriceService`) and the web calculator (PW-T04).
Plan: `docs/IMPLEMENTATION_PLAN.md` §7 P6c, ADR-20. Implementation: `supabase/functions/fuel-prices/`,
pure logic in `supabase/functions/_shared/fuel.ts`. Backend: `supabase/migrations/0005_fuel_prices.sql`.

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
| `radius` | only with `lat`/`lng`; number 1..10 (km); default `5` |
| `plz` | exactly 5 digits. Not combinable with `lat`/`lng` |

Unknown parameters are ignored. Only `GET` (and CORS `OPTIONS`) is accepted; anything else is `405`.
Auth: send the project anon key as `apikey` / `Authorization: Bearer <anon key>` like any Supabase function
(the hosted gateway requires it; the web calculator ships the anon key publicly, that is expected).

## Response

```
200 {"type":"e5","priceMilli":1799,"source":"tankerkoenig","scope":"nearby|plz|national",
     "fetchedAt":"<ISO8601>","stations":<int>,"attribution":"Daten: MTS-K via Tankerkönig (CC BY 4.0)"}
```

- `priceMilli`: thousandths of EUR per litre (`docs/domain-rules.md` units): 1.799 EUR/l is `1799`. Integer, never a float.
  `nearby`/`plz`: median of the open stations that report the fuel type (`plz` around the zone's main city). `national`: median over a fixed sample of
  large cities across all German states.
- `fetchedAt`: when the provider data was fetched (cache time), not the request time. Show its age in the UI.
- `stations`: how many stations the median is based on.
- The attribution string must be shown wherever the price is shown (CC BY 4.0).
- Responses carry `Cache-Control: public, max-age=60`. TTL on the server: nearby 10 min, plz 30 min, national 1 h.

## Errors

| Status | Body | Meaning |
|---|---|---|
| 400 | `{"error":"invalid_params"}` | validation failed |
| 404 | `{"error":"no_data"}` | provider answered but there is no open station with a price in that area |
| 405 | `{"error":"method_not_allowed"}` | not GET |
| 429 | `{"error":"rate_limited"}` | per-client token bucket empty; `Retry-After` header (seconds) is set |
| 503 | `{"error":"provider_unconfigured"}` | no provider API key configured on the server |
| 503 | `{"error":"provider_unavailable"}` | provider failed or returned garbage and no cached value exists |

Clients must treat any non-200 as "no live price": fall back to manual entry / last known value. Never retry
in a tight loop; honour `Retry-After`.

## Privacy and abuse protection (what the server does)

- Exact coordinates never leave the function: `lat`/`lng` are snapped to the centre of a geohash precision-6 cell
  (about 1.2 km x 0.6 km) *before* anything else. That snapped point is the only location sent to the provider
  and the only form stored in the cache key (`<geohash6>:<radius>`).
- A PLZ is never sent to the provider. It is mapped to a fixed city coordinate of its two-digit postcode zone
  (zones that do not exist, such as `05`, `11`, `43`, `62`, are `invalid_params`) and a radius-10 km query around
  that coordinate is made. `plz` results are therefore a regional price (about the zone's main city), not
  street-exact. The cache key is the PLZ.
- The client IP is never forwarded and never stored. The rate limiter stores `sha256(ip + salt)` only, in
  `rate_limits`, and rows older than a day are deleted.
- CORS: `Access-Control-Allow-Origin` is echoed only for origins in the `FUEL_ALLOWED_ORIGINS` allowlist
  (own domain + app origins); other origins get no CORS headers.
- The cache table `fuel_price_cache` is publicly readable (anon + authenticated) and writable only by the
  service role. It contains no user data.

## Server configuration (secrets / env)

| Name | Meaning | Default |
|---|---|---|
| `TANKERKOENIG_API_KEY` | provider key; absent means `503 provider_unconfigured` | none |
| `TANKERKOENIG_BASE_URL` | provider base URL (tests point it to a stub) | `https://creativecommons.tankerkoenig.de/json` |
| `FUEL_ALLOWED_ORIGINS` | comma separated CORS allowlist | none (no origin allowed) |
| `FUEL_RATE_LIMIT_SALT` | salt for the IP hash | falls back to the service role key |
| `FUEL_RATE_LIMIT_CAPACITY` / `FUEL_RATE_LIMIT_PER_MIN` | token bucket size / refill per minute | `30` / `30` |
