import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Source of truth for a group's vehicles. Lists are ordered by creation
/// time, then id.
abstract interface class VehiclesRepository {
  /// Live vehicles; emits the current list first, then after every change.
  Stream<List<Vehicle>> watchVehicles(String groupId);

  Future<RepoResult<Vehicle>> get(String id);

  /// [name] is trimmed and must not be empty; numbers follow the [Vehicle]
  /// rules ([InvalidData] otherwise). The group must exist ([NotFound]).
  Future<RepoResult<Vehicle>> add(
    String groupId, {
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
}

/// Trims the name and runs the domain validation.
RepoResult<Vehicle> buildVehicle({
  required String id,
  required String name,
  required FuelType fuelType,
  required int consumptionMilliPer100km,
  required int wearMilliPerKm,
  required int? kmRateMilliPerKm,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return const Err(InvalidData('name must not be empty'));
  try {
    return Ok(
      Vehicle(
        id: id,
        name: trimmed,
        fuelType: fuelType,
        consumptionMilliPer100km: consumptionMilliPer100km,
        wearMilliPerKm: wearMilliPerKm,
        kmRateMilliPerKm: kmRateMilliPerKm,
      ),
    );
    // ignore: avoid_catching_errors, the domain signals bad values with ArgumentError
  } on ArgumentError catch (e) {
    return Err(InvalidData('vehicle $id: $e'));
  }
}
