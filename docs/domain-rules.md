# Domain rules

Normative spec for `packages/domain` (`mitlio_domain`). Agents implement exactly this; if something here is
ambiguous, comment on the issue instead of guessing. Plan context: `IMPLEMENTATION_PLAN.md` §2.5, P2.

The fenced `json` blocks marked `<!-- examples:NAME -->` are golden test data. Table-driven tests load this file
(`packages/domain/test/support/domain_rules_examples.dart`), so the doc and the tests can never disagree.

## Conventions

- **Money is `int` in minor units** ("cents"). Never `double`, never `num` arithmetic on amounts.
- **No `DateTime.now()`, `Random()`, UUIDs** in domain code. Callers pass ids and dates in.
- **Web safety:** the domain is compiled with dart2js for the web calculator. Ints are only exact up to 2^53.
  Any intermediate product that can exceed that (`a × b` of amounts/rates/distances) uses `BigInt`.
  `Money.maxAbsCents = 999999999999999` (just under 10^15); results beyond that throw `MoneyOverflow`.
- **Validation returns, programmer errors throw.** User-reachable invalid input → `Result.err(<sealed error>)`.
  Violated preconditions that callers must guarantee (negative weights passed internally, mismatched
  currencies in `Money` arithmetic) → `ArgumentError`.
- **Error class names are unique across the package** (one barrel export). When a variant name is already taken by
  another error family, prefix it with the family name, e.g. `SettlementUnknownMember`, `TripNoParticipants`.
- **Layout:** one concept per file under `lib/src/<area>/`, exported from `lib/mitlio_domain.dart`
  (keep the export list sorted). Tests mirror it under `test/<area>/`.
- **Every public function:** example tests (from this doc), ≥ 1 `glados` property test, edge cases.

## Shared types (P2-T01)

```dart
sealed class Result<T, E> { … }        // Ok<T, E>(value) / Err<T, E>(error); exhaustive switch
final class Ok<T, E> extends Result<T, E> { final T value; }
final class Err<T, E> extends Result<T, E> { final E error; }

final class Currency {                 // value equality on code
  final String code;                   // ISO 4217, upper-case
  final int minorUnits;                // EUR 2, JPY 0, KWD 3
  static Currency? tryParse(String code);
  static const eur, usd, gbp, chf, jpy, …;  // at least: EUR USD GBP CHF JPY SEK NOK DKK PLN CZK HUF
}                                            // RON BGN TRY ISK(0) KWD(3) CAD AUD NZD

final class Money implements Comparable<Money> {   // value equality on (cents, currency)
  final int cents; final Currency currency;
  Money(int cents, Currency currency);             // throws MoneyOverflow if |cents| > maxAbsCents
  Money operator +(Money o); Money operator -(Money o); Money operator -();
  bool get isZero, isNegative, isPositive;
  // different currencies in + - compareTo → ArgumentError
}

final class Member {                   // the minimal member view the domain needs
  final String id; final int position;
}
List<Member> tieOrder(Iterable<Member> members);  // sorted by position, then id (String.compareTo)
```

`Money` has no formatting (locale formatting is the app's job). There is a `toString()` for debugging only.

## Allocation — largest remainder (P2-T02)

```dart
List<int> allocate(int total, List<int> weights);
```

- `total >= 0`; every weight `>= 0`; `sum(weights) > 0` — otherwise `ArgumentError`.
- Weight 0 always receives 0.
- Index order **is** the tie order. Callers order participants with `tieOrder` first.
- Algorithm: `W = Σ weights`. For each i: `q_i = floor(total × w_i / W)`, `r_i = (total × w_i) mod W`
  (BigInt). `left = total − Σ q_i`. Give +1 to the `left` indices with the largest `r_i`; on equal `r_i`,
  the lower index wins.
- Guarantees: `Σ result = total`; same input → same output; equal weights differ by at most 1.

<!-- examples:allocate -->
```json
[
  {"total": 100,  "weights": [1, 1, 1],    "result": [34, 33, 33]},
  {"total": 1000, "weights": [1, 2],       "result": [333, 667]},
  {"total": 10,   "weights": [1, 1, 1, 0], "result": [4, 3, 3, 0]},
  {"total": 5,    "weights": [3, 3, 1],    "result": [2, 2, 1]},
  {"total": 1,    "weights": [1, 1, 1],    "result": [1, 0, 0]},
  {"total": 0,    "weights": [1, 1],       "result": [0, 0]}
]
```

`[3, 3, 1]` with 5: floors `[2, 2, 0]`, remainders `[1, 1, 5]` → the one left-over cent goes to index 2.

## Split modes (P2-T03)

```dart
sealed class SplitSpec {}
final class EqualSplit extends SplitSpec   { final Set<String> participants; }
final class SharesSplit extends SplitSpec  { final Map<String, int> weights; }      // 0 = excluded
final class PercentSplit extends SplitSpec { final Map<String, int> basisPoints; }  // must sum to 10000
final class ExactSplit extends SplitSpec   { final Map<String, int> cents; }        // must sum to amount

Result<Map<String, int>, SplitError> computeShares({
  required int amountCents, required SplitSpec spec, required List<Member> members,
});

sealed class SplitError {}
// AmountNotPositive, NoParticipants, UnknownMember(id), NegativeValue(id),
// PercentNotFull(sum), ExactMismatch(sum, expected)
```

- The result maps **every** member in `members` to a share (0 for not participating), so callers can rely on
  the key set.
- Members not mentioned in the spec's map/set participate with 0.
- `EqualSplit` = `allocate` with weight 1 per participant. `SharesSplit` = `allocate` with the weights.
  `PercentSplit` = `allocate` with the basis points as weights after checking `Σ == 10000`.
  `ExactSplit` = taken as-is after checking `Σ == amount`, each `>= 0`.
- Always use `tieOrder(members)` for the weight order.
- Check order (the first failure wins): amount > 0 → unknown ids → negative values → mode sum checks → at
  least one participant with share/weight > 0.

Members for the examples: `A(pos 0)`, `B(pos 1)`, `C(pos 2)`.

<!-- examples:split -->
```json
[
  {"amount": 1000, "spec": {"equal": ["A", "B", "C"]},                   "shares": {"A": 334, "B": 333, "C": 333}},
  {"amount": 1000, "spec": {"equal": ["A", "C"]},                        "shares": {"A": 500, "B": 0, "C": 500}},
  {"amount": 1000, "spec": {"shares": {"A": 2, "B": 1, "C": 1}},         "shares": {"A": 500, "B": 250, "C": 250}},
  {"amount": 1000, "spec": {"shares": {"A": 1, "B": 0, "C": 1}},         "shares": {"A": 500, "B": 0, "C": 500}},
  {"amount": 1000, "spec": {"percent": {"A": 5000, "B": 2500, "C": 2500}}, "shares": {"A": 500, "B": 250, "C": 250}},
  {"amount": 1001, "spec": {"percent": {"A": 3333, "B": 3333, "C": 3334}}, "shares": {"A": 334, "B": 333, "C": 334}},
  {"amount": 1000, "spec": {"exact": {"A": 600, "B": 400}},              "shares": {"A": 600, "B": 400, "C": 0}},
  {"amount": 1000, "spec": {"exact": {"A": 600, "B": 300}},              "error": "ExactMismatch"},
  {"amount": 1000, "spec": {"percent": {"A": 5000, "B": 4000}},          "error": "PercentNotFull"},
  {"amount": 1000, "spec": {"equal": []},                                "error": "NoParticipants"},
  {"amount": 1000, "spec": {"equal": ["A", "X"]},                        "error": "UnknownMember"},
  {"amount": 0,    "spec": {"equal": ["A", "B"]},                        "error": "AmountNotPositive"}
]
```

Percent 1001 walk-through: floors `[333, 333, 333]`, remainders `[6333, 6333, 7334]`, two cents left → C
(7334), then A (6333, wins the tie against B by order).

**Tie order example:** members `X(pos 1, id "b")`, `Y(pos 0, id "z")`, `Z(pos 0, id "a")` → order `Z, Y, X`;
equal split of 100 → `Z 34, Y 33, X 33`.

## Expense and settlement (P2-T04)

```dart
final class Expense {
  final String id; final String title; final int amountCents; final Currency currency; final DateTime date;
  final Map<String, int> payers;   // memberId → paid cents, every value > 0, Σ == amountCents
  final Map<String, int> shares;   // memberId → share cents (computed), Σ == amountCents
  static Result<Expense, ExpenseError> create({
    required String id, required String title, required int amountCents, required Currency currency,
    required DateTime date, required Map<String, int> payers, required SplitSpec split,
    required List<Member> members,
  });
}
// ExpenseError: EmptyTitle, InvalidSplit(SplitError), NoPayer, PayerNotMember(id),
//               NonPositivePayment(id), PayersMismatch(sum, expected)

final class Settlement {
  final String id; final String fromId; final String toId; final int amountCents; final Currency currency;
  final DateTime date;
  static Result<Settlement, SettlementError> create({…, required List<Member> members});
}
// SettlementError: SettlementNonPositiveAmount, SelfTransfer, SettlementUnknownMember(id)
```

- The constructor is private: an invalid `Expense`/`Settlement` cannot exist.
- `title` is trimmed; empty after trimming → `EmptyTitle`.
- Expense check order: title → amount and split (via `computeShares`) → payers.

## Balances (P2-T05)

```dart
Map<String, int> computeBalances({
  required List<Member> members, required Iterable<Expense> expenses, required Iterable<Settlement> settlements,
});
```

`net(m) = Σ paid(m) − Σ share(m) + Σ sent(m) − Σ received(m)`. Positive = gets money back. Every member is a
key (0 if untouched). Ids not in `members`, or more than one currency → `ArgumentError`. Guarantee: `Σ net == 0`.

<!-- examples:balances -->
```json
[
  {
    "members": ["A", "B", "C"],
    "expenses": [
      {"payers": {"A": 3000}, "shares": {"A": 1000, "B": 1000, "C": 1000}},
      {"payers": {"B": 600},  "shares": {"A": 300, "B": 300}}
    ],
    "settlements": [],
    "balances": {"A": 1700, "B": -700, "C": -1000}
  },
  {
    "members": ["A", "B", "C"],
    "expenses": [
      {"payers": {"A": 3000}, "shares": {"A": 1000, "B": 1000, "C": 1000}},
      {"payers": {"B": 600},  "shares": {"A": 300, "B": 300}}
    ],
    "settlements": [{"from": "C", "to": "A", "amount": 1000}],
    "balances": {"A": 700, "B": -700, "C": 0}
  }
]
```

## Simplify debts (P2-T06)

```dart
final class Transfer { final String fromId; final String toId; final int amountCents; }
List<Transfer> simplifyDebts(Map<String, int> balances, List<Member> members);
```

- `Σ balances != 0`, or a key not in `members` → `ArgumentError`.
- Greedy loop: pick the debtor with the most negative balance and the creditor with the most positive
  balance. Ties go to the earlier member in `tieOrder(members)`. Transfer `min(|debt|, credit)`, update both,
  and repeat until all are 0.
- Guarantees: ≤ n−1 transfers; applying them zeroes every balance; no self-transfers; no zero transfers;
  deterministic.

<!-- examples:simplify -->
```json
[
  {"balances": {"A": 1700, "B": -700, "C": -1000},
   "transfers": [{"from": "C", "to": "A", "amount": 1000}, {"from": "B", "to": "A", "amount": 700}]},
  {"balances": {"A": 500, "B": 500, "C": -600, "D": -400},
   "transfers": [{"from": "C", "to": "A", "amount": 500}, {"from": "D", "to": "B", "amount": 400},
                 {"from": "C", "to": "B", "amount": 100}]},
  {"balances": {"A": 0, "B": 0}, "transfers": []}
]
```

## Trip cost (P2-T07)

Units avoid floating point:

| Input | Unit | Example |
|---|---|---|
| `distanceMeters` | int metres (one way) | 250 km → `250000` |
| `consumptionMilliPer100km` | thousandths of a litre (or kWh) per 100 km | 6.5 l → `6500` |
| `pricePerUnitMilli` | thousandths of the major currency unit per litre/kWh | 1.799 €/l → `1799` |
| `wearMilliPerKm` | thousandths of the major unit per km | 0.05 €/km → `50` |
| `kmRateMilliPerKm` | thousandths of the major unit per km (replaces fuel + wear) | 0.30 €/km → `300` |
| `tollsCents`, `ferryCents` | minor units, totals for the whole trip (not doubled) | |

```dart
final class TripInput {
  final int distanceMeters; final bool roundTrip; final Currency currency;
  final TripCostMode mode;             // sealed: Consumption(consumptionMilliPer100km, pricePerUnitMilli,
                                       //                     wearMilliPerKm = 0) | KmRate(kmRateMilliPerKm)
  final int tollsCents, ferryCents;    // default 0
  final String driverId; final Set<String> passengerIds; final bool driverCounts;
}
final class TripCost { final int fuelCents, wearCents, kmRateCents, tollsCents, ferryCents, totalCents;
                       final Map<String, int> shares; }
Result<TripCost, TripError> computeTripCost(TripInput input, List<Member> members);
Result<Expense, ExpenseError> tripToExpense(…);   // payer = driver (pays totalCents), split = the shares above
// TripError: NonPositiveDistance, TripNegativeValue(field), TripNoParticipants, DriverIsPassenger, TripUnknownMember(id),
//            UnsupportedCurrency (minorUnits > 3)
```

- `d = distanceMeters × (roundTrip ? 2 : 1)`. Let `k = 10^(3 − minorUnits)` (EUR: 10).
- `fuel = roundHalfUp(d × consumption × price / (10^8 × k))` (EUR: divisor `1e9`).
- `wear = roundHalfUp(d × wear / (1000 × k))`; `kmRate = roundHalfUp(d × rate / (1000 × k))`.
- `total = fuel + wear + kmRate + tolls + ferry` (each component is rounded separately).
- Participants = passengers + driver if `driverCounts`. Shares = equal `allocate` over the participants in
  `tieOrder`.
- All intermediate products use `BigInt`.

<!-- examples:trip -->
```json
[
  {"name": "consumption, driver counts",
   "input": {"distanceMeters": 250000, "roundTrip": false, "consumption": 6500, "price": 1799,
             "driver": "A", "passengers": ["B", "C"], "driverCounts": true},
   "fuel": 2923, "total": 2923, "shares": {"A": 975, "B": 974, "C": 974}},
  {"name": "consumption, driver free",
   "input": {"distanceMeters": 250000, "roundTrip": false, "consumption": 6500, "price": 1799,
             "driver": "A", "passengers": ["B", "C"], "driverCounts": false},
   "fuel": 2923, "total": 2923, "shares": {"A": 0, "B": 1462, "C": 1461}},
  {"name": "round trip rounds once on doubled distance",
   "input": {"distanceMeters": 250000, "roundTrip": true, "consumption": 6500, "price": 1799,
             "driver": "A", "passengers": ["B"], "driverCounts": true},
   "fuel": 5847, "total": 5847, "shares": {"A": 2924, "B": 2923}},
  {"name": "wear and tolls",
   "input": {"distanceMeters": 250000, "roundTrip": false, "consumption": 6500, "price": 1799, "wear": 50,
             "tollsCents": 1150, "driver": "A", "passengers": ["B"], "driverCounts": true},
   "fuel": 2923, "wear": 1250, "total": 5323, "shares": {"A": 2662, "B": 2661}},
  {"name": "km rate",
   "input": {"distanceMeters": 250000, "roundTrip": false, "kmRate": 300,
             "driver": "A", "passengers": ["B", "C"], "driverCounts": false},
   "kmRateCents": 7500, "total": 7500, "shares": {"A": 0, "B": 3750, "C": 3750}}
]
```

Check: 250 km × 6.5 l/100 km = 16.25 l × 1.799 € = 29.23375 € → 2923 ct. Round trip: 58.4675 € → 5847 ct.

## FX conversion (P2-T08)

```dart
final class FxRate { final int ppm; }  // units of `to` major per 1 `from` major × 1e6; ppm > 0 else ArgumentError
Money convert(Money amount, Currency to, FxRate rate);
```

`result = roundHalfEven(cents × ppm × 10^to.minor / (10^6 × 10^from.minor))` using BigInt. The rate is frozen
on the expense by the caller.

<!-- examples:fx -->
```json
[
  {"cents": 10000, "from": "USD", "to": "EUR", "ppm": 920000,  "result": 9200},
  {"cents": 1000,  "from": "JPY", "to": "EUR", "ppm": 6200,    "result": 620},
  {"cents": 15,    "from": "USD", "to": "EUR", "ppm": 1100000, "result": 16},
  {"cents": 25,    "from": "USD", "to": "EUR", "ppm": 1100000, "result": 28},
  {"cents": 5,     "from": "USD", "to": "EUR", "ppm": 1100000, "result": 6},
  {"cents": 1234,  "from": "EUR", "to": "JPY", "ppm": 160000000, "result": 1974}
]
```

The half-even cases: 16.5 → 16, 27.5 → 28, 5.5 → 6. The last example is 12.34 € × 160 = 1974.4 → 1974 ¥.

## PayPal.Me link (P2-T09)

```dart
Result<Uri, PayPalError> buildPayPalMeLink({required String handle, required Money amount});
// PayPalError: InvalidHandle, NonPositiveAmount
```

- Normalise the handle: trim, strip a leading `@`, `https://`, `http://`, `www.` and `paypal.me/`
  (case-insensitive), strip one trailing `/`. The remainder must match `^[A-Za-z0-9]{1,20}$`.
- Amount: `cents > 0`. Format = major units with exactly `minorUnits` decimals and `.` as the separator,
  then the ISO code.
- Result: `https://paypal.me/<handle>/<amount><CODE>`.

<!-- examples:paypal -->
```json
[
  {"handle": "maxmuster",                    "cents": 1234, "currency": "EUR", "url": "https://paypal.me/maxmuster/12.34EUR"},
  {"handle": " @MaxMuster ",                 "cents": 5,    "currency": "EUR", "url": "https://paypal.me/MaxMuster/0.05EUR"},
  {"handle": "https://www.paypal.me/max42/", "cents": 1000, "currency": "JPY", "url": "https://paypal.me/max42/1000JPY"},
  {"handle": "max muster",                   "cents": 1234, "currency": "EUR", "error": "InvalidHandle"},
  {"handle": "",                             "cents": 1234, "currency": "EUR", "error": "InvalidHandle"},
  {"handle": "maxmuster",                    "cents": 0,    "currency": "EUR", "error": "NonPositiveAmount"}
]
```

## IBAN and EPC QR payload (P2-T10)

```dart
Result<String, IbanError> normalizeIban(String input);   // remove all whitespace, upper-case, validate
// IbanError: InvalidFormat, InvalidChecksum
Result<String, EpcError> buildEpcQrPayload({
  required String name, required String iban, String? bic, required Money amount, String remittance = '',
});
// EpcError: InvalidName, InvalidIban(IbanError), InvalidBic, NotEur, AmountOutOfRange, RemittanceTooLong, PayloadTooLarge(int bytes)
```

- **IBAN:** `^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$` (total 15–34). Mod-97: move the first 4 chars to the end,
  letters → numbers (A=10 … Z=35), compute the remainder mod 97 piecewise (no BigInt needed), and it must
  equal 1.
- **BIC (optional):** trim and upper-case; `^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$`; empty → omitted.
- **Name:** trimmed, 1–70 chars. **Remittance:** trimmed, ≤ 140 chars. **Amount:** EUR only;
  1 ≤ cents ≤ 99999999999.
- **Payload** (EPC069-12, version 002, UTF-8): these 11 lines, joined with `\n`, no trailing newline:
  `BCD`, `002`, `1`, `SCT`, BIC or empty, name, IBAN, `EUR` + amount with 2 decimals, purpose (empty),
  structured ref (empty), remittance text.
- Payload ≤ 331 UTF-8 bytes, else `PayloadTooLarge`, checked last (after all field checks).

<!-- examples:iban -->
```json
[
  {"input": "DE89370400440532013000",        "result": "DE89370400440532013000"},
  {"input": "de89 3704 0044 0532 0130 00",   "result": "DE89370400440532013000"},
  {"input": "GB82WEST12345698765432",        "result": "GB82WEST12345698765432"},
  {"input": "DE89370400440532013001",        "error": "InvalidChecksum"},
  {"input": "DE8937",                        "error": "InvalidFormat"}
]
```

<!-- examples:epc -->
```json
[
  {"name": "Max Mustermann", "iban": "DE89 3704 0044 0532 0130 00", "cents": 1234, "remittance": "mitlio: Urlaub",
   "payload": "BCD\n002\n1\nSCT\n\nMax Mustermann\nDE89370400440532013000\nEUR12.34\n\n\nmitlio: Urlaub"},
  {"name": "Max Mustermann", "iban": "DE89370400440532013000", "bic": "cobadeffxxx", "cents": 5,
   "payload": "BCD\n002\n1\nSCT\nCOBADEFFXXX\nMax Mustermann\nDE89370400440532013000\nEUR0.05\n\n\n"}
]
```
