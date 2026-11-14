import 'dart:async';

import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [VehiclesRepository] with the same behaviour as the Drift one.
class FakeVehiclesRepository implements VehiclesRepository {
  FakeVehiclesRepository({required this._groups, required this._ids});

  final GroupsRepository _groups;
  final IdGenerator _ids;

  /// Insertion order equals creation order.
  final _vehicles = <String, Vehicle>{};
  final _groupOf = <String, String>{};
  final _deleted = <String>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  Vehicle? _live(String id) => _deleted.contains(id) ? null : _vehicles[id];

  @override
  Stream<List<Vehicle>> watchVehicles(String groupId) => watchSnapshots(
    _changes.stream,
    () => [
      for (final v in _vehicles.values)
        if (_groupOf[v.id] == groupId && !_deleted.contains(v.id)) v,
    ],
  );

  @override
  Future<RepoResult<Vehicle>> get(String id) async {
    final v = _live(id);
    return v == null ? Err(NotFound('vehicle', id)) : Ok(v);
  }

  @override
  Future<RepoResult<Vehicle>> add(
    String groupId, {
    required String name,
    required FuelType fuelType,
    required int consumptionMilliPer100km,
    int wearMilliPerKm = 0,
    int? kmRateMilliPerKm,
  }) async {
    final id = _ids.newId();
    final built = buildVehicle(
      id: id,
      name: name,
      fuelType: fuelType,
      consumptionMilliPer100km: consumptionMilliPer100km,
      wearMilliPerKm: wearMilliPerKm,
      kmRateMilliPerKm: kmRateMilliPerKm,
    );
    if (built case Err<Vehicle, RepositoryError>(:final error)) {
      return Err(error);
    }
    if (await _groups.get(groupId) case Err<Group, RepositoryError>(
      :final error,
    )) {
      return Err(error);
    }
    final v = built.orThrow();
    _vehicles[id] = v;
    _groupOf[id] = groupId;
    _changes.add(null);
    return Ok(v);
  }

  @override
  Future<RepoResult<Vehicle>> update(Vehicle vehicle) async {
    final built = buildVehicle(
      id: vehicle.id,
      name: vehicle.name,
      fuelType: vehicle.fuelType,
      consumptionMilliPer100km: vehicle.consumptionMilliPer100km,
      wearMilliPerKm: vehicle.wearMilliPerKm,
      kmRateMilliPerKm: vehicle.kmRateMilliPerKm,
    );
    if (built case Err<Vehicle, RepositoryError>(:final error)) {
      return Err(error);
    }
    if (_live(vehicle.id) == null) return Err(NotFound('vehicle', vehicle.id));
    final v = built.orThrow();
    _vehicles[v.id] = v;
    _changes.add(null);
    return Ok(v);
  }

  @override
  Future<RepoResult<Undo>> softDelete(String id) async {
    if (_live(id) == null) return Err(NotFound('vehicle', id));
    _deleted.add(id);
    _changes.add(null);
    return Ok(Undo(() => restore(id)));
  }

  @override
  Future<RepoResult<void>> restore(String id) async {
    if (!_vehicles.containsKey(id)) return Err(NotFound('vehicle', id));
    if (!_deleted.remove(id)) {
      return const Err(Conflict('vehicle is not deleted'));
    }
    _changes.add(null);
    return const Ok(null);
  }
}
