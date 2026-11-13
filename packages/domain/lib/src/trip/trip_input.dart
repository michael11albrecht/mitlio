import 'package:mitlio_domain/src/money/currency.dart';

/// How the fuel/driving cost of a trip is determined.
sealed class TripCostMode {
  const TripCostMode();
}

/// Fuel cost from consumption and price, plus optional wear.
final class Consumption extends TripCostMode {
  /// Creates a consumption based mode.
  const Consumption({
    required this.consumptionMilliPer100km,
    required this.pricePerUnitMilli,
    this.wearMilliPerKm = 0,
  });

  /// Thousandths of a litre (or kWh) per 100 km.
  final int consumptionMilliPer100km;

  /// Thousandths of the major currency unit per litre (or kWh).
  final int pricePerUnitMilli;

  /// Thousandths of the major currency unit per km.
  final int wearMilliPerKm;
}

/// A flat rate per km that replaces fuel and wear.
final class KmRate extends TripCostMode {
  /// Creates a km-rate mode.
  const KmRate(this.kmRateMilliPerKm);

  /// Thousandths of the major currency unit per km.
  final int kmRateMilliPerKm;
}

/// Everything needed to compute the cost of a trip.
final class TripInput {
  /// Creates a trip input. Validation happens in `computeTripCost`.
  const TripInput({
    required this.distanceMeters,
    required this.roundTrip,
    required this.currency,
    required this.mode,
    required this.driverId,
    required this.passengerIds,
    required this.driverCounts,
    this.tollsCents = 0,
    this.ferryCents = 0,
  });

  /// One-way distance in metres.
  final int distanceMeters;
  final bool roundTrip;
  final Currency currency;
  final TripCostMode mode;

  /// Tolls for the whole trip in minor units (not doubled for round trips).
  final int tollsCents;

  /// Ferry costs for the whole trip in minor units (not doubled).
  final int ferryCents;
  final String driverId;
  final Set<String> passengerIds;

  /// Whether the driver pays a share of the cost too.
  final bool driverCounts;
}
