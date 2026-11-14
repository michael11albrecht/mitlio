import 'package:drift/drift.dart' show Value;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/rides_dao.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// [VehiclesRepository] backed by Drift.
class DriftVehiclesRepository implements VehiclesRepository {
  DriftVehiclesRepository({
    required AppDatabase db,
    required this._clock,
    required this._ids,
  }) : _db = db,
       _dao = db.ridesDao;

  final AppDatabase _db;
  final RidesDao _dao;
  final Clock _clock;
  final IdGenerator _ids;

  RepoResult<Vehicle> _map(VehicleRow row) {
    final fuel = FuelType.values.asNameMap()[row.fuelType];
    if (fuel == null) {
      return Err(InvalidData('vehicle ${row.id}: bad fuel ${row.fuelType}'));
    }
    return buildVehicle(
      id: row.id,
      name: row.name,
      fuelType: fuel,
      consumptionMilliPer100km: row.consumptionMilliPer100km,
      wearMilliPerKm: row.wearMilliPerKm,
      kmRateMilliPerKm: row.kmRateMilliPerKm,
    );
  }

  @override
  Stream<List<Vehicle>> watchVehicles(String groupId) => _dao
      .watchVehicles(groupId)
      .map(
        (rows) => List.unmodifiable([for (final r in rows) _map(r).orThrow()]),
      );

  @override
  Future<RepoResult<Vehicle>> get(String id) => guardStorage(() async {
    final row = await _dao.findVehicle(id);
    return row == null ? Err(NotFound('vehicle', id)) : _map(row);
  });

  @override
  Future<RepoResult<Vehicle>> add(
    String groupId, {
    required String name,
    required FuelType fuelType,
    required int consumptionMilliPer100km,
    int wearMilliPerKm = 0,
    int? kmRateMilliPerKm,
  }) => guardStorage(() async {
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
    if (await _db.groupsDao.findById(groupId) == null) {
      return Err(NotFound('group', groupId));
    }
    final v = built.orThrow();
    await _dao.insertVehicle(
      VehiclesCompanion.insert(
        id: id,
        groupId: groupId,
        createdAt: _clock.now().toUtc(),
        updatedAt: Hlc.now(_clock),
        name: v.name,
        fuelType: v.fuelType.name,
        consumptionMilliPer100km: v.consumptionMilliPer100km,
        wearMilliPerKm: Value(v.wearMilliPerKm),
        kmRateMilliPerKm: Value(v.kmRateMilliPerKm),
      ),
    );
    return get(id);
  });

  @override
  Future<RepoResult<Vehicle>> update(Vehicle vehicle) => guardStorage(() async {
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
    final v = built.orThrow();
    final ok = await _dao.updateVehicle(
      v.id,
      VehiclesCompanion(
        name: Value(v.name),
        fuelType: Value(v.fuelType.name),
        consumptionMilliPer100km: Value(v.consumptionMilliPer100km),
        wearMilliPerKm: Value(v.wearMilliPerKm),
        kmRateMilliPerKm: Value(v.kmRateMilliPerKm),
        updatedAt: Value(Hlc.now(_clock)),
      ),
    );
    return ok ? get(v.id) : Err(NotFound('vehicle', v.id));
  });

  @override
  Future<RepoResult<Undo>> softDelete(String id) => guardStorage(() async {
    final ok = await _dao.softDeleteVehicle(
      id,
      _clock.now().toUtc(),
      Hlc.now(_clock),
    );
    return ok ? Ok(Undo(() => restore(id))) : Err(NotFound('vehicle', id));
  });

  @override
  Future<RepoResult<void>> restore(String id) => guardStorage(() async {
    if (await _dao.restoreVehicle(id, Hlc.now(_clock))) {
      return const Ok(null);
    }
    return await _dao.findVehicle(id) != null
        ? const Err(Conflict('vehicle is not deleted'))
        : Err(NotFound('vehicle', id));
  });
}
