// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Real car cost categories (ADR-25 §3).
enum UserVehicleCostCategory {
  insurance,
  tax,
  maintenance,
  tyres,
  repairs,
  loan,
  depreciation,
  parking,
  other,
}

/// Which costs the per-km share is based on (ADR-25 §3).
enum UserVehicleShareBasis { running, full }

/// Optional real costs of a personal vehicle: yearly cents per category.
/// Categories not in [annualCents] were skipped.
final class UserVehicleCostDetails {
  const UserVehicleCostDetails({
    required this.annualKm,
    this.shareBasis = UserVehicleShareBasis.running,
    this.annualCents = const {},
  });

  final int annualKm;
  final UserVehicleShareBasis shareBasis;
  final Map<UserVehicleCostCategory, int> annualCents;

  @override
  bool operator ==(Object other) =>
      other is UserVehicleCostDetails &&
      other.annualKm == annualKm &&
      other.shareBasis == shareBasis &&
      other.annualCents.length == annualCents.length &&
      annualCents.entries.every((e) => other.annualCents[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    annualKm,
    shareBasis,
    Object.hashAllUnordered(
      annualCents.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'UserVehicleCostDetails($annualKm km, $annualCents)';
}

/// Personal vehicles "Meine Autos" (ADR-25). Same value rules as group
/// vehicles; ordered by creation time, then id.
abstract interface class UserVehiclesRepository {
  Stream<List<Vehicle>> watchVehicles();

  Future<RepoResult<Vehicle>> get(String id);

  /// [name] is trimmed and must not be empty; numbers follow the [Vehicle]
  /// rules ([InvalidData] otherwise).
  Future<RepoResult<Vehicle>> add({
    required String name,
    required FuelType fuelType,
    required int consumptionMilliPer100km,
    int wearMilliPerKm = 0,
    int? kmRateMilliPerKm,
  });

  /// Replaces every field of the vehicle with [vehicle]'s id.
  Future<RepoResult<Vehicle>> update(Vehicle vehicle);

  /// Soft delete; call the returned [Undo] to bring the vehicle back.
  Future<RepoResult<Undo>> softDelete(String id);

  /// [NotFound] for unknown ids, [Conflict] if the vehicle is not deleted.
  Future<RepoResult<void>> restore(String id);

  /// Null if no costs were entered. [NotFound] for an unknown vehicle.
  Future<RepoResult<UserVehicleCostDetails?>> getCosts(String vehicleId);

  /// Replaces the costs. [InvalidData] for annual km <= 0 or a negative
  /// amount; [NotFound] for an unknown or deleted vehicle.
  Future<RepoResult<UserVehicleCostDetails>> saveCosts(
    String vehicleId,
    UserVehicleCostDetails costs,
  );

  /// Removes the costs; fine if there are none.
  Future<RepoResult<void>> clearCosts(String vehicleId);
}

/// [InvalidData] if the costs break the rules in [UserVehiclesRepository].
RepoResult<UserVehicleCostDetails> validateCosts(
  UserVehicleCostDetails costs,
) {
  if (costs.annualKm <= 0) return const Err(InvalidData('invalid: annualKm'));
  if (costs.annualCents.values.any((c) => c < 0)) {
    return const Err(InvalidData('invalid: annualCents'));
  }
  return Ok(costs);
}
