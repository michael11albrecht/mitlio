import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/expense/expense.dart';
import 'package:mitlio_domain/src/expense/expense_error.dart';
import 'package:mitlio_domain/src/members/member.dart';
import 'package:mitlio_domain/src/money/currency.dart';
import 'package:mitlio_domain/src/rides/ride.dart';
import 'package:mitlio_domain/src/rides/ride_cost.dart';
import 'package:mitlio_domain/src/rides/ride_period.dart';
import 'package:mitlio_domain/src/rides/vehicle.dart';
import 'package:mitlio_domain/src/split/split_spec.dart';
import 'package:mitlio_domain/src/trip/trip_error.dart';

/// All rides of one driver in one period, with the summed per-member shares.
final class RideAggregate {
  const RideAggregate._({
    required this.driverId,
    required this.period,
    required this.rideIds,
    required this.totalCents,
    required this.shares,
  });

  final String driverId;
  final RidePeriod period;

  /// Ride ids in (date, id) order.
  final List<String> rideIds;
  final int totalCents;

  /// Member id to share cents for every member; sum equals [totalCents].
  final Map<String, int> shares;
}

/// Aggregates the rides inside [period] into one [RideAggregate] per driver,
/// ordered by `tieOrder(members)`. See docs/domain-rules.md, "Rides".
///
/// Every ride keeps the split it would have on its own: shares and totals are
/// summed, never re-allocated. The first ride error wins, rides taken in
/// (date, id) order. Throws [ArgumentError] if a ride's vehicle is missing
/// from [vehicles].
Result<List<RideAggregate>, TripError> aggregateRides({
  required Iterable<Ride> rides,
  required Map<String, Vehicle> vehicles,
  required Currency currency,
  required List<Member> members,
  required RidePeriod period,
}) {
  final inPeriod = rides.where((r) => period.contains(r.date)).toList()
    ..sort((a, b) {
      final byDate = dayNumber(a.date).compareTo(dayNumber(b.date));
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });

  final rideIds = <String, List<String>>{};
  final totals = <String, int>{};
  final shares = <String, Map<String, int>>{};
  for (final ride in inPeriod) {
    final vehicle = vehicles[ride.vehicleId];
    if (vehicle == null) {
      throw ArgumentError.value(
        ride.vehicleId,
        'vehicles',
        'no vehicle for ride ${ride.id}',
      );
    }
    switch (rideCost(ride, vehicle, currency, members)) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        (rideIds[ride.driverId] ??= []).add(ride.id);
        totals[ride.driverId] = (totals[ride.driverId] ?? 0) + value.totalCents;
        final sum = shares[ride.driverId] ??= {
          for (final m in members) m.id: 0,
        };
        value.shares.forEach((id, cents) => sum[id] = sum[id]! + cents);
    }
  }

  return Ok([
    for (final m in tieOrder(members))
      if (rideIds.containsKey(m.id))
        RideAggregate._(
          driverId: m.id,
          period: period,
          rideIds: List.unmodifiable(rideIds[m.id]!),
          totalCents: totals[m.id]!,
          shares: Map.unmodifiable(shares[m.id]!),
        ),
  ]);
}

/// Turns an aggregate into an [Expense]: the driver paid
/// [RideAggregate.totalCents] and the split is [RideAggregate.shares] (an
/// [ExactSplit]). The title is the caller's job (l10n). A total of zero yields
/// `InvalidSplit(AmountNotPositive)`.
///
/// [currency] is not in the spec's signature but `Expense` needs it.
Result<Expense, ExpenseError> rideAggregateToExpense({
  required String id,
  required String title,
  required DateTime date,
  required RideAggregate aggregate,
  required Currency currency,
  required List<Member> members,
}) {
  return Expense.create(
    id: id,
    title: title,
    amountCents: aggregate.totalCents,
    currency: currency,
    date: date,
    payers: {aggregate.driverId: aggregate.totalCents},
    split: ExactSplit(aggregate.shares),
    members: members,
  );
}
