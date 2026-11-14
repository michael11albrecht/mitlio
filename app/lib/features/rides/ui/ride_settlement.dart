import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Pure parts of the period settlement and the fairness view: no state, no
/// I/O (the ViewModels load, these compute).

/// What one driver gets back for a period: the rides they drove and who owes
/// what for them.
final class DriverSettlement {
  const DriverSettlement({required this.aggregate});

  final RideAggregate aggregate;

  String get driverId => aggregate.driverId;
  List<String> get rideIds => aggregate.rideIds;
  int get rideCount => aggregate.rideIds.length;
  int get totalCents => aggregate.totalCents;

  /// What each passenger owes the driver, in the order of [memberOrder]:
  /// members other than the driver with a share above zero.
  List<RideShare> sharesOf(List<String> memberOrder) => [
    for (final id in memberOrder)
      if (id != driverId && (aggregate.shares[id] ?? 0) > 0)
        RideShare(memberId: id, cents: aggregate.shares[id]!),
  ];
}

/// The preview of "Oktober abrechnen": one [DriverSettlement] per driver, in
/// the domain's tie order.
final class SettlementPlan {
  const SettlementPlan({required this.period, required this.drivers});

  final Month period;
  final List<DriverSettlement> drivers;

  int get rideCount => drivers.fold(0, (n, d) => n + d.rideCount);
  int get totalCents => drivers.fold(0, (n, d) => n + d.totalCents);
  bool get isEmpty => drivers.isEmpty;
}

/// Aggregates the [unsettled] rides of [month] through the domain. Null if
/// the domain rejects a ride or a ride's vehicle is unknown, so the screen
/// never offers a settlement it could not make.
SettlementPlan? planSettlement({
  required Iterable<Ride> unsettled,
  required Month month,
  required Map<String, Vehicle> vehicles,
  required Currency currency,
  required List<Member> members,
}) {
  final inMonth = [
    for (final r in unsettled)
      if (month.contains(r.date)) r,
  ];
  if (inMonth.any((r) => !vehicles.containsKey(r.vehicleId))) return null;
  final result = aggregateRides(
    rides: inMonth,
    vehicles: vehicles,
    currency: currency,
    members: members,
    period: month,
  );
  return switch (result) {
    Ok<List<RideAggregate>, TripError>(:final value) => SettlementPlan(
      period: month,
      drivers: [for (final a in value) DriverSettlement(aggregate: a)],
    ),
    Err<List<RideAggregate>, TripError>() => null,
  };
}

/// One person in the fairness view.
final class FairnessRow {
  const FairnessRow({
    required this.memberId,
    required this.metersDriven,
    required this.metersRidden,
    required this.netCents,
  });

  final String memberId;

  /// Metres this person drove (both ways for a round trip).
  final int metersDriven;

  /// Metres this person sat in somebody else's car.
  final int metersRidden;

  /// What the others owe this person for the period's rides (negative: this
  /// person owes). Sums to zero over the group.
  final int netCents;
}

/// Per member: metres driven, metres ridden and the net in cents over
/// [rides] (settled or not), all from the domain's ride costs. Rides whose
/// vehicle is unknown or that the domain rejects are left out.
List<FairnessRow> computeFairness({
  required Iterable<Ride> rides,
  required Map<String, Vehicle> vehicles,
  required Currency currency,
  required List<Member> members,
}) {
  final driven = {for (final m in members) m.id: 0};
  final ridden = {for (final m in members) m.id: 0};
  final net = {for (final m in members) m.id: 0};
  for (final r in rides) {
    final vehicle = vehicles[r.vehicleId];
    if (vehicle == null) continue;
    final cost = rideCost(r, vehicle, currency, members);
    if (cost is! Ok<TripCost, TripError>) continue;
    final meters = rideMeters(r);
    final shares = cost.value.shares;
    if (net.containsKey(r.driverId)) {
      driven[r.driverId] = driven[r.driverId]! + meters;
      // The driver paid the total and owes their own part.
      net[r.driverId] =
          net[r.driverId]! + cost.value.totalCents - (shares[r.driverId] ?? 0);
    }
    for (final p in r.passengerIds) {
      if (!net.containsKey(p) || p == r.driverId) continue;
      ridden[p] = ridden[p]! + meters;
      net[p] = net[p]! - (shares[p] ?? 0);
    }
  }
  return [
    for (final m in members)
      FairnessRow(
        memberId: m.id,
        metersDriven: driven[m.id]!,
        metersRidden: ridden[m.id]!,
        netCents: net[m.id]!,
      ),
  ];
}
