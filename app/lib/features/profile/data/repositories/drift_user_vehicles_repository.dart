import 'package:drift/drift.dart' show Value;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/user_vehicles_dao.dart';
import 'package:mitlio/features/profile/data/repositories/user_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// [UserVehiclesRepository] backed by Drift (local only, no outbox).
class DriftUserVehiclesRepository implements UserVehiclesRepository {
  DriftUserVehiclesRepository({
    required AppDatabase db,
    required this._clock,
    required this._ids,
  }) : _dao = db.userVehiclesDao;

  final UserVehiclesDao _dao;
  final Clock _clock;
  final IdGenerator _ids;

  RepoResult<Vehicle> _map(UserVehicleRow row) {
    final fuel = FuelType.values.asNameMap()[row.fuelType];
    if (fuel == null) {
      return Err(
        InvalidData('user vehicle ${row.id}: bad fuel ${row.fuelType}'),
      );
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
  Stream<List<Vehicle>> watchVehicles() => _dao.watchVehicles().map(
    (rows) => List.unmodifiable([for (final r in rows) _map(r).orThrow()]),
  );

  Future<UserVehicleRow?> _live(String id) async {
    final row = await _dao.findVehicle(id);
    return row == null || row.deletedAt != null ? null : row;
  }

  @override
  Future<RepoResult<Vehicle>> get(String id) => guardStorage(() async {
    final row = await _live(id);
    return row == null ? Err(NotFound('user vehicle', id)) : _map(row);
  });

  @override
  Future<RepoResult<Vehicle>> add({
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
    final v = built.orThrow();
    await _dao.insertVehicle(
      UserVehiclesCompanion.insert(
        id: id,
        createdAt: _clock.now().toUtc(),
        updatedAt: Hlc.now(_clock),
        name: v.name,
        fuelType: v.fuelType.name,
        consumptionMilliPer100km: v.consumptionMilliPer100km,
        wearMilliPerKm: Value(v.wearMilliPerKm),
        kmRateMilliPerKm: Value(v.kmRateMilliPerKm),
      ),
    );
    return Ok(v);
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
      UserVehiclesCompanion(
        name: Value(v.name),
        fuelType: Value(v.fuelType.name),
        consumptionMilliPer100km: Value(v.consumptionMilliPer100km),
        wearMilliPerKm: Value(v.wearMilliPerKm),
        kmRateMilliPerKm: Value(v.kmRateMilliPerKm),
        updatedAt: Value(Hlc.now(_clock)),
      ),
    );
    return ok ? Ok(v) : Err(NotFound('user vehicle', v.id));
  });

  @override
  Future<RepoResult<Undo>> softDelete(String id) => guardStorage(() async {
    final ok = await _dao.softDeleteVehicle(
      id,
      _clock.now().toUtc(),
      Hlc.now(_clock),
    );
    return ok ? Ok(Undo(() => restore(id))) : Err(NotFound('user vehicle', id));
  });

  @override
  Future<RepoResult<void>> restore(String id) => guardStorage(() async {
    if (await _dao.restoreVehicle(id, Hlc.now(_clock))) {
      return const Ok(null);
    }
    return await _dao.findVehicle(id) != null
        ? const Err(Conflict('vehicle is not deleted'))
        : Err(NotFound('user vehicle', id));
  });

  @override
  Future<RepoResult<UserVehicleCostDetails?>> getCosts(String vehicleId) =>
      guardStorage(() async {
        if (await _dao.findVehicle(vehicleId) == null) {
          return Err(NotFound('user vehicle', vehicleId));
        }
        final row = await _dao.findCosts(vehicleId);
        return Ok(row == null ? null : _mapCosts(row));
      });

  @override
  Future<RepoResult<UserVehicleCostDetails>> saveCosts(
    String vehicleId,
    UserVehicleCostDetails costs,
  ) => guardStorage(() async {
    final valid = validateCosts(costs);
    if (valid case Err<UserVehicleCostDetails, RepositoryError>(:final error)) {
      return Err(error);
    }
    if (await _live(vehicleId) == null) {
      return Err(NotFound('user vehicle', vehicleId));
    }
    Value<int?> cents(UserVehicleCostCategory k) => Value(costs.annualCents[k]);
    await _dao.upsertCosts(
      UserVehicleCostsCompanion(
        userVehicleId: Value(vehicleId),
        annualKm: Value(costs.annualKm),
        shareBasis: Value(costs.shareBasis.name),
        insuranceCents: cents(UserVehicleCostCategory.insurance),
        taxCents: cents(UserVehicleCostCategory.tax),
        maintenanceCents: cents(UserVehicleCostCategory.maintenance),
        tyresCents: cents(UserVehicleCostCategory.tyres),
        repairsCents: cents(UserVehicleCostCategory.repairs),
        loanCents: cents(UserVehicleCostCategory.loan),
        depreciationCents: cents(UserVehicleCostCategory.depreciation),
        parkingCents: cents(UserVehicleCostCategory.parking),
        otherCents: cents(UserVehicleCostCategory.other),
        updatedAt: Value(Hlc.now(_clock)),
      ),
    );
    return Ok(costs);
  });

  @override
  Future<RepoResult<void>> clearCosts(String vehicleId) =>
      guardStorage(() async {
        await _dao.deleteCosts(vehicleId);
        return const Ok(null);
      });

  UserVehicleCostDetails _mapCosts(UserVehicleCostsRow r) {
    final byCategory = <UserVehicleCostCategory, int?>{
      UserVehicleCostCategory.insurance: r.insuranceCents,
      UserVehicleCostCategory.tax: r.taxCents,
      UserVehicleCostCategory.maintenance: r.maintenanceCents,
      UserVehicleCostCategory.tyres: r.tyresCents,
      UserVehicleCostCategory.repairs: r.repairsCents,
      UserVehicleCostCategory.loan: r.loanCents,
      UserVehicleCostCategory.depreciation: r.depreciationCents,
      UserVehicleCostCategory.parking: r.parkingCents,
      UserVehicleCostCategory.other: r.otherCents,
    };
    return UserVehicleCostDetails(
      annualKm: r.annualKm,
      shareBasis: UserVehicleShareBasis.values.byName(r.shareBasis),
      annualCents: {
        for (final e in byCategory.entries)
          if (e.value != null) e.key: e.value!,
      },
    );
  }
}
