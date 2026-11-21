import 'package:mitlio_domain/src/trip/trip_cost.dart';
import 'package:mitlio_domain/src/trip/trip_input.dart';

/// A likely typo found by [operatingCostCheck].
enum PlausibilityIssue {
  /// The whole trip costs more than `implausibleMilliPerKm` per km.
  costPerKmTooHigh,

  /// Consumption is above 30 l (or kWh) per 100 km.
  consumptionTooHigh,
}

/// Result of [operatingCostCheck]. Hints only: nothing here blocks saving.
final class OperatingCostCheck {
  const OperatingCostCheck({
    required this.passengersPayCents,
    required this.operatingCostCents,
    required this.plausibility,
  });

  /// What the passengers together pay (the driver's own share excluded).
  final int passengersPayCents;

  /// Fuel plus running costs of the trip; `null` if unknown (km-rate mode
  /// without a reference).
  final int? operatingCostCents;

  /// Likely typos, in [PlausibilityIssue] order.
  final List<PlausibilityIssue> plausibility;

  /// Passengers pay more than the operating cost (PBefG §1 Abs. 2 Nr. 1).
  bool get exceedsOperatingCost =>
      operatingCostCents != null && passengersPayCents > operatingCostCents!;

  /// Whether any hint should be shown.
  bool get hasHint => exceedsOperatingCost || plausibility.isNotEmpty;
}

// Round half up for non-negative numerator and positive denominator.
BigInt _roundHalfUp(BigInt n, BigInt d) =>
    (n * BigInt.two + d) ~/ (d * BigInt.two);

/// Checks a computed trip against the PBefG operating-cost limit and for
/// likely typos. See docs/domain-rules.md, "Operating-cost check".
///
/// Operating cost = fuel + running wear. Tolls and ferry are not part of it.
/// [runningWearMilliPerKm] is the running-only part of the wear rate (e.g.
/// from `vehicleExtraCostPerKm` with `CostBasis.running`); `null` counts the
/// whole wear of [input] as running, and a value above the wear of [input] is
/// capped to it. In km-rate mode fuel and wear are unknown; pass
/// [operatingMilliPerKm] (fuel + running wear of the vehicle) to get a limit,
/// otherwise [OperatingCostCheck.operatingCostCents] is `null`.
///
/// [implausibleMilliPerKm] (default 1 major unit per km) is the total cost per
/// km above which [PlausibilityIssue.costPerKmTooHigh] is reported; scale it
/// for currencies far from the euro.
OperatingCostCheck operatingCostCheck(
  TripInput input,
  TripCost cost, {
  int? runningWearMilliPerKm,
  int? operatingMilliPerKm,
  int implausibleMilliPerKm = 1000,
}) {
  final shares = cost.shares;
  var passengers = 0;
  for (final id in input.passengerIds) {
    passengers += shares[id] ?? 0;
  }

  final k = BigInt.from(10).pow(3 - input.currency.minorUnits);
  final d =
      BigInt.from(input.distanceMeters) * BigInt.from(input.roundTrip ? 2 : 1);
  BigInt perKm(int milli) =>
      _roundHalfUp(d * BigInt.from(milli), BigInt.from(1000) * k);

  final mode = input.mode;
  int? operating;
  var consumptionTooHigh = false;
  switch (mode) {
    case Consumption():
      final running =
          runningWearMilliPerKm == null ||
              runningWearMilliPerKm > mode.wearMilliPerKm
          ? mode.wearMilliPerKm
          : runningWearMilliPerKm;
      operating = cost.fuelCents + perKm(running).toInt();
      consumptionTooHigh = mode.consumptionMilliPer100km > 30000;
    case KmRate():
      if (operatingMilliPerKm != null) {
        operating = perKm(operatingMilliPerKm).toInt();
      }
  }

  // total / km > limit  <=>  totalCents * k * 1000 > limit * distanceMeters
  final tooExpensive =
      BigInt.from(cost.totalCents) * k * BigInt.from(1000) >
      BigInt.from(implausibleMilliPerKm) * d;

  return OperatingCostCheck(
    passengersPayCents: passengers,
    operatingCostCents: operating,
    plausibility: [
      if (tooExpensive) PlausibilityIssue.costPerKmTooHigh,
      if (consumptionTooHigh) PlausibilityIssue.consumptionTooHigh,
    ],
  );
}
