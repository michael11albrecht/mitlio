# Fixtures

## `scenarios/*.json` (seed scenarios)

Single source of the data `ext.mitlio.seed {"scenario": "<name>"}` loads into a debug build and the tests load
into the repositories (never raw SQL). The app bundles them as assets through the symlink
`app/assets/scenarios` -> `tool/fixtures/scenarios`. Loader: `app/lib/debug/seed/scenario_seeder.dart`.

| Scenario | Content |
|---|---|
| `empty` | one group, no members |
| `trip_4p` | 4 friends, 3 trip expenses (consumption and km-rate mode, tolls, ferry) and 5 regular expenses |
| `household_2p` | 2 people, 30 days of equal, shares and percent expenses |
| `rounding_edge` | 1 ct and 10 ct across 3, percent 3333/3333/3334, exact 333/333/334 |
| `commute_3p` | 3 colleagues, one vehicle, one template, 20 rides in October 2026 |
| `large_200_expenses` | 8 members, 200 expenses generated from `generate.seed` (own LCG, platform independent) |

Format (names reference members, vehicles and templates; money is `int` cents, split weights as in the app):

```json
{
  "group": "Name", "currency": "EUR", "members": ["Anna", "Ben"],
  "vehicles": [{"name", "fuelType", "consumptionMilliPer100km", "wearMilliPerKm?", "kmRateMilliPerKm?"}],
  "templates": [{"name", "distanceMeters", "vehicle", "roundTrip?", "driver?", "passengers?", "tollsCents?"}],
  "rides": [{"date", "template", "driver?", "passengers?", "pricePerUnitMilli"}],
  "trips": [{"title", "date", "distanceMeters", "driver", "passengers", "consumptionMilliPer100km+pricePerUnitMilli | kmRateMilliPerKm", "..."}],
  "expenses": [{"title", "amountCents", "date", "payers": {"Anna": 1000}, "split": {"mode": "equal|shares|percent|exact", "participants|weights": "..."}}],
  "generate": {"seed", "count", "from", "days"},
  "expected": {"balances": {"Anna": -100}, "transfers": [{"from", "to", "amountCents"}]}
}
```

`expected` was computed once with the domain (`computeBalances` + `simplifyDebts`; for `commute_3p` after settling the
rides of October 2026 per driver with `aggregateRides`) and is committed. `app/test/debug/seed_scenarios_test.dart`
asserts that loading plus computing equals it. Changing a scenario or a domain rule means recomputing and reviewing
the `expected` diff.

## Other files

`trip_web.json`, `deeplink.json`: shared cross-platform fixtures; `agent_metrics_gh.json`: input for `tool/agent_metrics_test.sh`.
