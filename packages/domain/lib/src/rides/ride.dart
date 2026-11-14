/// One logged drive. See docs/domain-rules.md, "Rides".
final class Ride {
  /// Creates a ride. Validation happens in `rideCost`.
  const Ride({
    required this.id,
    required this.date,
    required this.distanceMeters,
    required this.vehicleId,
    required this.driverId,
    required this.pricePerUnitMilli,
    this.roundTrip = false,
    this.tollsCents = 0,
    this.passengerIds = const {},
    this.driverCounts = true,
    this.useKmRate = false,
  });

  final String id;

  /// Calendar date: only year, month and day are used.
  final DateTime date;

  /// One-way distance in metres.
  final int distanceMeters;
  final bool roundTrip;
  final int tollsCents;
  final String vehicleId;
  final String driverId;
  final Set<String> passengerIds;
  final bool driverCounts;

  /// Fuel price per litre or kWh in thousandths, frozen when logged.
  final int pricePerUnitMilli;

  /// If true the vehicle's km rate replaces fuel and wear.
  final bool useKmRate;
}
