import 'package:mitlio_domain/src/core/result.dart';
import 'package:mitlio_domain/src/members/member.dart';
import 'package:mitlio_domain/src/money/currency.dart';
import 'package:mitlio_domain/src/rides/ride.dart';
import 'package:mitlio_domain/src/rides/vehicle.dart';
import 'package:mitlio_domain/src/trip/trip_cost.dart';
import 'package:mitlio_domain/src/trip/trip_error.dart';
import 'package:mitlio_domain/src/trip/trip_input.dart';

/// Cost of one ride, computed exactly like a one-off trip with the same
/// inputs. See docs/domain-rules.md, "Rides".
///
/// Throws [ArgumentError] if `ride.vehicleId != vehicle.id`. Returns
/// [MissingKmRate] if `ride.useKmRate` and the vehicle has no km rate;
/// otherwise the errors of [computeTripCost].
Result<TripCost, TripError> rideCost(
  Ride ride,
  Vehicle vehicle,
  Currency currency,
  List<Member> members,
) {
  if (ride.vehicleId != vehicle.id) {
    throw ArgumentError.value(
      vehicle.id,
      'vehicle',
      'does not match ride.vehicleId ${ride.vehicleId}',
    );
  }
  final TripCostMode mode;
  if (ride.useKmRate) {
    final rate = vehicle.kmRateMilliPerKm;
    if (rate == null) return const Err(MissingKmRate());
    mode = KmRate(rate);
  } else {
    mode = Consumption(
      consumptionMilliPer100km: vehicle.consumptionMilliPer100km,
      pricePerUnitMilli: ride.pricePerUnitMilli,
      wearMilliPerKm: vehicle.wearMilliPerKm,
    );
  }
  return computeTripCost(
    TripInput(
      distanceMeters: ride.distanceMeters,
      roundTrip: ride.roundTrip,
      currency: currency,
      mode: mode,
      tollsCents: ride.tollsCents,
      driverId: ride.driverId,
      passengerIds: ride.passengerIds,
      driverCounts: ride.driverCounts,
    ),
    members,
  );
}
