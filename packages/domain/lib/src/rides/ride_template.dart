/// Defaults for two-tap ride logging ("Arbeit", "Training", ...).
final class RideTemplate {
  /// Creates a template.
  const RideTemplate({
    required this.id,
    required this.name,
    required this.distanceMeters,
    required this.vehicleId,
    this.roundTrip = false,
    this.defaultDriverId,
    this.defaultPassengerIds = const {},
    this.tollsCents = 0,
  });

  final String id;
  final String name;

  /// One-way distance in metres.
  final int distanceMeters;
  final bool roundTrip;
  final String vehicleId;
  final String? defaultDriverId;
  final Set<String> defaultPassengerIds;
  final int tollsCents;
}
