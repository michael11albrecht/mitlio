import 'package:mitlio_domain/src/allocation/allocate.dart';
import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/expense/expense.dart';
import 'package:mitlio_domain/src/expense/expense_error.dart';
import 'package:mitlio_domain/src/members/member.dart';
import 'package:mitlio_domain/src/money/money.dart';
import 'package:mitlio_domain/src/split/split_spec.dart';
import 'package:mitlio_domain/src/trip/trip_error.dart';
import 'package:mitlio_domain/src/trip/trip_input.dart';

/// The computed cost of a trip and how it is shared.
final class TripCost {
  const TripCost._({
    required this.fuelCents,
    required this.wearCents,
    required this.kmRateCents,
    required this.tollsCents,
    required this.ferryCents,
    required this.totalCents,
    required this.shares,
  });

  final int fuelCents;
  final int wearCents;
  final int kmRateCents;
  final int tollsCents;
  final int ferryCents;

  /// Sum of all components.
  final int totalCents;

  /// Member id to share cents for every member; sum equals [totalCents].
  final Map<String, int> shares;
}

// Round half up for non-negative numerator and positive denominator.
BigInt _roundHalfUp(BigInt n, BigInt d) =>
    (n * BigInt.two + d) ~/ (d * BigInt.two);

/// Computes the cost of a trip. See docs/domain-rules.md, "Trip cost".
///
/// Validation order (the first failure wins): currency
/// ([UnsupportedCurrency]), distance ([NonPositiveDistance]), negative values
/// ([TripNegativeValue], in the order consumption, price, wear, km rate,
/// tolls, ferry), unknown ids ([TripUnknownMember], smallest id by
/// `String.compareTo`, driver included), driver listed as passenger
/// ([DriverIsPassenger]), then no participants ([TripNoParticipants]).
///
/// Throws [MoneyOverflow] if the total exceeds [Money.maxAbsCents] (results
/// beyond that are not exact on dart2js).
///
/// [UnsupportedCurrency] cannot occur with the built-in currencies because
/// `Currency` has a private constructor; the check guards future additions.
Result<TripCost, TripError> computeTripCost(
  TripInput input,
  List<Member> members,
) {
  final minorUnits = input.currency.minorUnits;
  if (minorUnits > 3) return const Err(UnsupportedCurrency());
  if (input.distanceMeters <= 0) return const Err(NonPositiveDistance());

  final mode = input.mode;
  final checks = <String, int>{
    if (mode is Consumption) ...{
      'consumptionMilliPer100km': mode.consumptionMilliPer100km,
      'pricePerUnitMilli': mode.pricePerUnitMilli,
      'wearMilliPerKm': mode.wearMilliPerKm,
    },
    if (mode is KmRate) 'kmRateMilliPerKm': mode.kmRateMilliPerKm,
    'tollsCents': input.tollsCents,
    'ferryCents': input.ferryCents,
  };
  for (final e in checks.entries) {
    if (e.value < 0) return Err(TripNegativeValue(e.key));
  }

  final memberIds = members.map((m) => m.id).toSet();
  final unknown = [
    input.driverId,
    ...input.passengerIds,
  ].where((id) => !memberIds.contains(id)).toList()..sort();
  if (unknown.isNotEmpty) return Err(TripUnknownMember(unknown.first));
  if (input.passengerIds.contains(input.driverId)) {
    return const Err(DriverIsPassenger());
  }
  final participants = {
    ...input.passengerIds,
    if (input.driverCounts) input.driverId,
  };
  if (participants.isEmpty) return const Err(TripNoParticipants());

  final d =
      BigInt.from(input.distanceMeters) * BigInt.from(input.roundTrip ? 2 : 1);
  final k = BigInt.from(10).pow(3 - minorUnits);
  var fuel = BigInt.zero;
  var wear = BigInt.zero;
  var kmRate = BigInt.zero;
  switch (mode) {
    case Consumption():
      fuel = _roundHalfUp(
        d *
            BigInt.from(mode.consumptionMilliPer100km) *
            BigInt.from(mode.pricePerUnitMilli),
        BigInt.from(100000000) * k,
      );
      wear = _roundHalfUp(
        d * BigInt.from(mode.wearMilliPerKm),
        BigInt.from(1000) * k,
      );
    case KmRate():
      kmRate = _roundHalfUp(
        d * BigInt.from(mode.kmRateMilliPerKm),
        BigInt.from(1000) * k,
      );
  }
  final total =
      fuel +
      wear +
      kmRate +
      BigInt.from(input.tollsCents) +
      BigInt.from(input.ferryCents);
  if (total > BigInt.from(Money.maxAbsCents)) {
    throw const MoneyOverflow(Money.maxAbsCents + 1);
  }

  final totalCents = total.toInt();
  final ordered = tieOrder(members);
  final allocated = allocate(totalCents, [
    for (final m in ordered)
      if (participants.contains(m.id)) 1 else 0,
  ]);
  return Ok(
    TripCost._(
      fuelCents: fuel.toInt(),
      wearCents: wear.toInt(),
      kmRateCents: kmRate.toInt(),
      tollsCents: input.tollsCents,
      ferryCents: input.ferryCents,
      totalCents: totalCents,
      shares: Map.unmodifiable({
        for (var i = 0; i < ordered.length; i++) ordered[i].id: allocated[i],
      }),
    ),
  );
}

/// Turns a computed trip into an [Expense]: the driver paid
/// [TripCost.totalCents] and the split is [TripCost.shares] (an [ExactSplit]).
///
/// A trip with a total of zero yields `InvalidSplit(AmountNotPositive)`.
Result<Expense, ExpenseError> tripToExpense({
  required String id,
  required String title,
  required DateTime date,
  required TripInput input,
  required TripCost cost,
  required List<Member> members,
}) {
  return Expense.create(
    id: id,
    title: title,
    amountCents: cost.totalCents,
    currency: input.currency,
    date: date,
    payers: {input.driverId: cost.totalCents},
    split: ExactSplit(cost.shares),
    members: members,
  );
}
