// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// What a vehicle runs on.
enum FuelType { petrol, diesel, electric, other }

/// A vehicle whose rides are logged. See docs/domain-rules.md, "Rides".
final class Vehicle {
  /// Creates a vehicle. Throws [ArgumentError] if
  /// [consumptionMilliPer100km] <= 0, [wearMilliPerKm] < 0 or
  /// [kmRateMilliPerKm] < 0.
  Vehicle({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.consumptionMilliPer100km,
    this.wearMilliPerKm = 0,
    this.kmRateMilliPerKm,
  }) {
    if (consumptionMilliPer100km <= 0) {
      throw ArgumentError.value(
        consumptionMilliPer100km,
        'consumptionMilliPer100km',
        'must be > 0',
      );
    }
    if (wearMilliPerKm < 0) {
      throw ArgumentError.value(
        wearMilliPerKm,
        'wearMilliPerKm',
        'must be >= 0',
      );
    }
    final rate = kmRateMilliPerKm;
    if (rate != null && rate < 0) {
      throw ArgumentError.value(rate, 'kmRateMilliPerKm', 'must be >= 0');
    }
  }

  final String id;
  final String name;
  final FuelType fuelType;

  /// Litres or kWh per 100 km times 1000.
  final int consumptionMilliPer100km;

  /// Thousandths of the major currency unit per km.
  final int wearMilliPerKm;

  /// If set, rides with this vehicle default to km-rate mode.
  final int? kmRateMilliPerKm;

  @override
  bool operator ==(Object other) =>
      other is Vehicle &&
      other.id == id &&
      other.name == name &&
      other.fuelType == fuelType &&
      other.consumptionMilliPer100km == consumptionMilliPer100km &&
      other.wearMilliPerKm == wearMilliPerKm &&
      other.kmRateMilliPerKm == kmRateMilliPerKm;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    fuelType,
    consumptionMilliPer100km,
    wearMilliPerKm,
    kmRateMilliPerKm,
  );

  @override
  String toString() => 'Vehicle($id, $name)';
}
