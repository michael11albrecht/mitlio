# Equivalent mutants (packages/domain)

Surviving mutants that no behavioural test can distinguish from the original.
Source: `make mutate` (mutation_test 1.8.1). Review this list when the tool
or the domain code changes; a new survivor must be killed or added here with a reason.

## `hashCode` argument order (30 mutants)

Mutation: reorder the arguments of `Object.hash(...)` in a `hashCode` getter
(`Object.hash(a, b)` becomes `Object.hash(b, a)`).

Why equivalent: the contract of `hashCode` is "equal objects have equal hashes".
Both orders satisfy it, and the concrete hash value is an unspecified
implementation detail (it can differ per VM run). Only a test that pins a
literal hash value could tell them apart, which would assert the implementation
rather than behaviour. Equality and hash consistency are already tested.

Files: `core/result.dart` (2), `expense/expense_error.dart` (5),
`expense/settlement_error.dart` (1), `members/member.dart` (1),
`money/money.dart` (1), `payment/epc_qr.dart` (2), `rides/ride_period.dart` (4),
`settle/simplify_debts.dart` (2), `split/split_error.dart` (5),
`sync/hlc_error.dart` (3), `sync/hlc.dart` (2), `trip/trip_error.dart` (2).

## Modulo by a negated constant (3 mutants)

- `payment/epc_qr.dart` `amount.cents % 100` becomes `% -100`.
- `payment/iban.dart` `... % 97` becomes `% -97` (two places).

Why equivalent: Dart's `%` is the Euclidean modulo, whose result depends only on
the absolute value of the divisor (`a % -n == a % n`).

## Sum sign in `simplifyDebts` (1 mutant)

`settle/simplify_debts.dart:50`: `s + BigInt.from(v)` becomes `s - BigInt.from(v)`.

Why equivalent: the sum is only compared to zero, and `-x == 0` iff `x == 0`.
The sum is not used afterwards.

## Counter overflow guard `>=` vs `==` (1 mutant)

`sync/hlc.dart:113`: `counter >= maxCounter` becomes `counter == maxCounter`.

Why equivalent: `counter` is always the counter of an existing `Hlc`, or the max
of two, and the `Hlc` constructor rejects values above `maxCounter`. So
`counter > maxCounter` is unreachable.
