import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What editing a personal car did: how many groups follow it now, and the
/// way back (ADR-25 §2: "In 3 Gruppen aktualisiert · Rückgängig").
final class PersonalCarUpdate {
  const PersonalCarUpdate({
    required this.car,
    required this.groups,
    required this.undo,
  });

  final Vehicle car;

  /// Groups whose copy of the car was updated; 0 if it is used nowhere.
  final int groups;

  /// Restores the personal car and every copy to the values before.
  final Undo undo;
}

/// Links personal cars ("Meine Autos") to their copies in groups (ADR-25
/// §2). A copy is a normal group vehicle with a source id, so rides and
/// closed periods work as before: a closed period is already expenses and
/// no edit reaches it.
class PersonalCarLinksRepository {
  PersonalCarLinksRepository({
    required this._personal,
    required this._groupVehicles,
  });

  final UserVehiclesRepository _personal;
  final VehiclesRepository _groupVehicles;

  /// The copy of personal car [personalId] in [groupId]: the existing live
  /// one, or a new linked one. [NotFound] for an unknown car or group.
  Future<RepoResult<Vehicle>> useInGroup(
    String groupId,
    String personalId,
  ) async {
    final car = await _personal.get(personalId);
    if (car case Err<Vehicle, RepositoryError>(:final error)) {
      return Err(error);
    }
    final copies = await _groupVehicles.linkedCopies(personalId);
    switch (copies) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        for (final c in value) {
          if (c.groupId == groupId) return Ok(c.vehicle);
        }
    }
    return _groupVehicles.addLinked(
      groupId,
      sourceUserVehicleId: personalId,
      template: car.orThrow(),
    );
  }

  /// Saves [car] and carries its values to every linked copy. All or
  /// nothing: if a copy cannot be written, everything is put back and the
  /// write error returned.
  Future<RepoResult<PersonalCarUpdate>> update(Vehicle car) async {
    final before = await _personal.get(car.id);
    if (before case Err<Vehicle, RepositoryError>(:final error)) {
      return Err(error);
    }
    final copies = await _groupVehicles.linkedCopies(car.id);
    if (copies case Err<List<LinkedVehicle>, RepositoryError>(:final error)) {
      return Err(error);
    }
    final linked = copies.orThrow();
    final saved = await _personal.update(car);
    if (saved case Err<Vehicle, RepositoryError>(:final error)) {
      return Err(error);
    }
    final done = <Vehicle>[];
    for (final copy in linked) {
      final written = await _groupVehicles.update(
        _asCopy(copy.vehicle.id, saved.orThrow()),
      );
      if (written case Err<Vehicle, RepositoryError>(:final error)) {
        // Best effort: the caller sees the write error, not a rollback one.
        await _restore(before.orThrow(), done);
        return Err(error);
      }
      done.add(copy.vehicle);
    }
    final previous = before.orThrow();
    final previousCopies = [for (final c in linked) c.vehicle];
    return Ok(
      PersonalCarUpdate(
        car: saved.orThrow(),
        groups: {for (final c in linked) c.groupId}.length,
        undo: Undo(() => _restoreStrict(previous, previousCopies)),
      ),
    );
  }

  Vehicle _asCopy(String id, Vehicle car) => Vehicle(
    id: id,
    name: car.name,
    fuelType: car.fuelType,
    consumptionMilliPer100km: car.consumptionMilliPer100km,
    wearMilliPerKm: car.wearMilliPerKm,
    kmRateMilliPerKm: car.kmRateMilliPerKm,
  );

  Future<void> _restore(Vehicle personal, List<Vehicle> copies) async {
    await _personal.update(personal);
    for (final c in copies) {
      await _groupVehicles.update(c);
    }
  }

  Future<RepoResult<void>> _restoreStrict(
    Vehicle personal,
    List<Vehicle> copies,
  ) async {
    final p = await _personal.update(personal);
    if (p case Err<Vehicle, RepositoryError>(:final error)) {
      return Err(error);
    }
    for (final c in copies) {
      final r = await _groupVehicles.update(c);
      if (r case Err<Vehicle, RepositoryError>(:final error)) {
        return Err(error);
      }
    }
    return const Ok(null);
  }
}
