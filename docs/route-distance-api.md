# Route distance API (`route-distance` Edge Function)

Contract for the app (P9-T08, `RouteDistanceService`). Issue: #130. Implementation:
`supabase/functions/route-distance/index.ts`, all logic in `supabase/functions/_shared/route.ts`
(adapters, validation, rate limiting; I/O is injected so it is unit-tested with provider stubs).
Rate limits reuse `consume_rate_limit` from `supabase/migrations/0005_fuel_prices.sql` unchanged: no new migration.

Why a proxy: the app never holds a provider key and never talks to a third party directly. The provider only
sees the Edge Function's egress IP, not the user's IP or id.

## Request

`POST /functions/v1/route-distance` with `Content-Type: application/json`. POST (not GET) so typed text and
coordinates never appear in a URL or an access log. Auth: project anon key as `apikey` /
`Authorization: Bearer <anon key>` like any Supabase function.

```
{"action":"suggest","text":"<3..120 chars>","lang":"de|en"}
{"action":"distance","from":{"lat":49.0069,"lng":8.4037},"to":{"lat":48.7758,"lng":9.1829}}
```

| Field | Rules |
|---|---|
| `action` | `suggest` or `distance`; anything else is `400` |
| `text` | string; whitespace collapsed and trimmed, then 3..120 characters (code points), no control characters |
| `lang` | `en`, anything else means `de` |
| `lat`, `lng` | finite numbers, `lat` -90..90, `lng` -180..180 |

Only `POST` (and CORS `OPTIONS`) is accepted; anything else is `405`.

## Response

```
200 {"suggestions":[{"label":"Karlsruhe, Baden-Württemberg, Deutschland","lat":49.0069,"lng":8.4037}],
     "attribution":"Karten- und Routendaten © OpenStreetMap-Mitwirkende, via openrouteservice"}
200 {"meters":81234,"attribution":"…"}
```

- `suggestions`: at most 5, labels de-duplicated, coordinates rounded to 6 decimals. May be empty (no match).
- `meters`: driving distance of the **fastest** route, whole metres.
- `attribution`: credit line of the provider that answered. **Show it wherever provider data is shown**
  (OpenStreetMap ODbL / provider licence requirement). The app shows a fallback line if it is missing.
- Responses carry `Cache-Control: no-store`.

| Status | Body `error` | Meaning |
|---|---|---|
| 400 | `invalid_params` | validation failed |
| 404 | `no_route` | the provider found no drivable route (not retried on the fallback) |
| 405 | `method_not_allowed` | |
| 429 | `rate_limited` | per-user or global daily limit; `Retry-After` in seconds |
| 503 | `provider_unconfigured` | no provider key set |
| 503 | `provider_unavailable` | all configured providers failed, or the rate limiter is broken (fails closed) |

## Providers and selection

Adapter interface `RouteProvider { suggest, distance }` with two implementations:

| Provider | Autocomplete | Routing | Env |
|---|---|---|---|
| openrouteservice (HeiGIT, primary) | `GET /geocode/autocomplete` | `POST /v2/directions/driving-car`, `preference: fastest` | `ORS_API_KEY`, optional `ORS_BASE_URL` |
| Geoapify (fallback) | `GET /v1/geocode/autocomplete` | `GET /v1/routing?mode=drive&type=balanced` | `GEOAPIFY_API_KEY`, optional `GEOAPIFY_BASE_URL` |

`ROUTE_PROVIDER` is a comma separated order (`openrouteservice,geoapify` is the default; `geoapify` alone, or
`geoapify,openrouteservice`, work too; `ors` is a short name). A provider without its key is skipped. The next
provider is tried only when the previous one failed (timeout 6 s, 5xx, 401/429, unusable body), never on `no_route`.
Switching the provider is a secret change (`supabase secrets set`), not an app update.

Unverified (check once after the keys exist, no ADR was written yet): exact free-plan quotas of ORS and Geoapify,
whether the ORS endpoint `api.openrouteservice.org` is still current (set `ORS_BASE_URL` if it moved), the ORS
and Geoapify terms on caching and GDPR/DPA.

## Rate limits

Two buckets per request, in this order, both through `consume_rate_limit(p_key, p_capacity, p_refill_per_sec)`:

1. Per user, per minute: key `route:<action>:u:<sha256(salt|route|id)>`. `id` is the JWT `sub` when the bearer
   token has one, else the client address. Defaults: 30 `suggest`/min, 10 `distance`/min
   (`ROUTE_SUGGEST_PER_MIN`, `ROUTE_DISTANCE_PER_MIN`). `Retry-After: 60`.
2. Global, per UTC day: key `route:<action>:global:<YYYY-MM-DD>`, a bucket that never refills and has a new key
   every day. Defaults: 1000 `suggest`, 1500 `distance` (`ROUTE_SUGGEST_DAILY`, `ROUTE_DISTANCE_DAILY`, capped at
   10000). Keep them **below the provider quota** so the free tier is never exceeded. `Retry-After` is the time
   to UTC midnight.

Raw ids, query text and coordinates never reach the database; only the salted hash and the day. Each day adds
two tiny `rate_limits` rows (the table is already small and rows can be pruned any time).

## Privacy

No logging of query text or coordinates: the function logs only `<provider> <action> failed: <class>`. No cache,
no persistence. Provider error messages are never forwarded or logged (they can contain the URL). See
`docs/data-flows.md`.

## Environment

| Secret | Purpose |
|---|---|
| `ORS_API_KEY` | openrouteservice key (free, <https://openrouteservice.org/dev/#/signup>) |
| `GEOAPIFY_API_KEY` | optional fallback key (<https://www.geoapify.com/>) |
| `ROUTE_PROVIDER` | optional order, see above |
| `ROUTE_ALLOWED_ORIGINS` | CORS allowlist (only needed for a web client; the app is not a browser) |
| `ROUTE_RATE_LIMIT_SALT` | salt for hashed rate-limit keys (falls back to the service role key) |
| `ROUTE_SUGGEST_PER_MIN`, `ROUTE_DISTANCE_PER_MIN`, `ROUTE_SUGGEST_DAILY`, `ROUTE_DISTANCE_DAILY` | optional limits |

Set with `supabase secrets set NAME=value --project-ref <ref>` (owner step, never in CI).

## App behaviour

Without a configured backend the forms show only the manual kilometre field (no dead buttons). With one, a
collapsed row "Start und Ziel eingeben, Strecke berechnen" opens two typeahead fields (300 ms debounce, from 3
characters). The one-way distance (rounded to 100 m) fills the kilometre field, which stays editable: after a hand
edit nothing overwrites it until the user taps "Neu berechnen". The existing round-trip switch of the form
doubles the distance. Failures (offline, rate limit with minutes, no route, service down) are shown inline;
manual entry never depends on the service. Only the distance is stored on a ride, never the labels. Saved places
(Zuhause, Arbeit) live in the local-only Drift table `local_places` and are wiped by "delete my data".
DebugDrive: `ext.mitlio.route.suggest`, `route.distance`, `route.manualEdit`, `route.recalculate`, `route.reset`.

## Web calculator (PW-T12, #207)

The website calculator has the same collapsed "Start und Ziel eingeben, Strecke berechnen" row (`web/src/calculator/route.ts`).
It is **off by default**: build with `ROUTE_WEB=1` (and `FUEL_API_URL`) to render it. The endpoint is
`route-distance` next to `fuel-prices`, so the CSP `connect-src` already covers it. The same flag renders the draft
Datenschutz section (`web/src/i18n/legal.ts`), which carries an `[[ENTWURF ...]]` placeholder: a production build fails
until the owner has signed off the wording and removed it. Owner steps: `ORS_API_KEY` secret and
`ROUTE_ALLOWED_ORIGINS` (the web origins, e.g. `https://mitlio.web.app,https://mitlio.de,https://www.mitlio.de`, set with
`supabase secrets set`; unlike `FUEL_ALLOWED_ORIGINS` no workflow sets it). Typing is debounced (300 ms, from 3
characters); `Retry-After` is exposed by CORS so the 429 message can name the wait.
