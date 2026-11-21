import 'package:mitlio/features/rides/ui/rides_calculator.dart'
    show defaultPriceMilli;
import 'package:mitlio_domain/mitlio_domain.dart';

/// Pure helpers behind the car flow (PU-T08, PU-T09, ADR-25 §3): typical
/// consumption, the flat wear default and the reference ride the "ct/km"
/// result is computed on. No state, no I/O.

/// Body type: only used to suggest a typical consumption for "weiß ich
/// nicht"; it is not stored with the car.
enum CarType { small, compact, suv, van }

/// The flat extra cost per km (thousandths of the major unit) for "Pauschale":
/// 5 ct/km wear on top of fuel. Owner to confirm the value (see PR body).
const int flatWearMilliPerKm = 50;

/// Personal cars have no group, so no group currency yet.
const Currency carCurrency = Currency.eur;

/// Distance of the reference ride: 100 km, so total cents = ct/km x 100.
const int _referenceMeters = 100000;

/// Rough everyday consumption per 100 km (l, or kWh for electric), in
/// thousandths, by body type and fuel. Shown as "typisch", never as fact.
int typicalConsumptionMilli(CarType type, FuelType fuel) {
  final base = switch (fuel) {
    FuelType.diesel => const {
      CarType.small: 4800,
      CarType.compact: 5500,
      CarType.suv: 6800,
      CarType.van: 7500,
    },
    FuelType.electric => const {
      CarType.small: 14000,
      CarType.compact: 16000,
      CarType.suv: 20000,
      CarType.van: 24000,
    },
    FuelType.petrol || FuelType.other => const {
      CarType.small: 5500,
      CarType.compact: 6500,
      CarType.suv: 8000,
      CarType.van: 8500,
    },
  };
  return base[type]!;
}

/// Slider range for the consumption step, in thousandths per 100 km.
({int min, int max}) consumptionRangeMilli(FuelType fuel) =>
    fuel == FuelType.electric
    ? (min: 8000, max: 35000)
    : (min: 3000, max: 20000);

/// `235` -> `23,5` (tenths of a cent per km, one decimal).
String formatTenths(int tenths, String separator) =>
    '${tenths ~/ 10}$separator${tenths % 10}';

/// Fuel price used for the result: the app's per-fuel default (live prices
/// are not worth a network call in a setup flow).
int referencePriceMilli(FuelType fuel) => defaultPriceMilli(fuel);

const _members = [
  Member(id: 'driver', position: 0),
  Member(id: 'passenger', position: 1),
];

/// What a 100 km ride with [vehicle] costs, computed by `rideCost` itself
/// so the flow shows exactly what a logged ride would. [meters] and
/// [roundTrip] describe the ride (default: 100 km one way).
///
/// Throws [StateError] when `rideCost` refuses: the vehicle is validated
/// before, so this is a bug, not a user error.
TripCost referenceRideCost(
  Vehicle vehicle, {
  int? priceMilli,
  int meters = _referenceMeters,
  bool roundTrip = false,
}) {
  final result = rideCost(
    Ride(
      id: 'reference',
      date: DateTime.utc(2000),
      distanceMeters: meters,
      roundTrip: roundTrip,
      vehicleId: vehicle.id,
      driverId: 'driver',
      passengerIds: const {'passenger'},
      pricePerUnitMilli: priceMilli ?? referencePriceMilli(vehicle.fuelType),
    ),
    vehicle,
    carCurrency,
    _members,
  );
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('reference ride failed: $error'),
  };
}

/// The operating-cost and plausibility hints for [vehicle] on the reference
/// ride, where the passenger pays the whole trip (the strictest case).
/// [runningWearMilliPerKm] is the running-only part of the vehicle's wear.
OperatingCostCheck referenceCheck(
  Vehicle vehicle, {
  required int runningWearMilliPerKm,
  int? priceMilli,
}) {
  final input = TripInput(
    distanceMeters: _referenceMeters,
    roundTrip: false,
    currency: carCurrency,
    mode: Consumption(
      consumptionMilliPer100km: vehicle.consumptionMilliPer100km,
      pricePerUnitMilli: priceMilli ?? referencePriceMilli(vehicle.fuelType),
      wearMilliPerKm: vehicle.wearMilliPerKm,
    ),
    driverId: 'driver',
    passengerIds: const {'passenger'},
    driverCounts: false,
  );
  final cost = switch (computeTripCost(input, _members)) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('reference trip failed: $error'),
  };
  return operatingCostCheck(
    input,
    cost,
    runningWearMilliPerKm: runningWearMilliPerKm,
  );
}
