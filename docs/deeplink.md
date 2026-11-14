# Deep link: web calculator to app ride form

Contract between the web calculator (PW-T06) and the app deep link import (P3r-T08).
Producer: `web/src/lib/deeplink.ts`. Shared fixtures: `tool/fixtures/deeplink.json`
(the app must parse every `expected` string back to its `input`).

```
mitlio://ride?km=<n>&l100=<n>&price=<n>&n=<int>&d=<0|1>&rt=<0|1>[&x=<n>][&t=<text>][&ev=1]
```

| Param | Meaning | Format |
|---|---|---|
| `km` | One-way distance in km | decimal, `.` separator, no grouping |
| `l100` | Consumption per 100 km (litres, or kWh when `ev=1`) | decimal |
| `price` | Price per litre (or per kWh when `ev=1`), in EUR | decimal |
| `n` | People including the driver | integer 1..100 |
| `d` | Driver pays a share | `1` yes, `0` no |
| `rt` | Round trip | `1` yes, `0` no |
| `x` | Tolls and extras in EUR | decimal, omitted when 0 or empty |
| `t` | Optional trip name | UTF-8, percent-encoded (`%20`, not `+`), max 60 characters, control characters removed, whitespace collapsed |
| `ev` | Electric vehicle | `1`, omitted otherwise |

Rules:

- Parameter order is fixed as listed; the receiver must not depend on it.
- Money amounts are decimals in EUR on the wire. The app converts to integer cents on import
  (rounding half up), it never uses `double` internally.
- The receiver ignores unknown params and treats invalid values as missing (prefilled defaults).
- No tracking or attribution params, ever.

The web page URL uses a sibling format for its own state (`?km=&l100=&p=&n=&d=&rt=&x=&ev=&t=`).
It is the same data with `p` instead of `price`, and the share links carry it.

When store links are configured (`APP_STORE_URL`, `PLAY_STORE_URL` in `web/site.config.mjs`,
env at build time) the calculator renders store buttons, an "open in app" button with this deep
link, and `<meta name="apple-itunes-app" content="app-id=…, app-argument=<deep link>">`.
