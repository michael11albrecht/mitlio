import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'user_vehicles_dao.g.dart';

/// Personal vehicles and their optional cost details (ADR-25).
@DriftAccessor(tables: [UserVehicles, UserVehicleCosts])
class UserVehiclesDao extends DatabaseAccessor<AppDatabase>
    with _$UserVehiclesDaoMixin {
  UserVehiclesDao(super.attachedDatabase);

  Future<void> insertVehicle(UserVehiclesCompanion v) =>
      into(userVehicles).insert(v);

  Future<UserVehicleRow?> findVehicle(String id) => (select(
    userVehicles,
  )..where((v) => v.id.equals(id))).getSingleOrNull();

  /// Live vehicles by creation time, then id.
  Stream<List<UserVehicleRow>> watchVehicles() =>
      (select(userVehicles)
            ..where((v) => v.deletedAt.isNull())
            ..orderBy([
              (v) => OrderingTerm.asc(v.createdAt),
              (v) => OrderingTerm.asc(v.id),
            ]))
          .watch();

  Future<bool> updateVehicle(String id, UserVehiclesCompanion change) async =>
      (await (update(
        userVehicles,
      )..where((v) => v.id.equals(id) & v.deletedAt.isNull())).write(change)) >
      0;

  Future<bool> softDeleteVehicle(String id, DateTime at, String hlc) async =>
      (await (update(
        userVehicles,
      )..where((v) => v.id.equals(id) & v.deletedAt.isNull())).write(
        UserVehiclesCompanion(deletedAt: Value(at), updatedAt: Value(hlc)),
      )) >
      0;

  Future<bool> restoreVehicle(String id, String hlc) async =>
      (await (update(
        userVehicles,
      )..where((v) => v.id.equals(id) & v.deletedAt.isNotNull())).write(
        UserVehiclesCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(hlc),
        ),
      )) >
      0;

  Future<void> upsertCosts(UserVehicleCostsCompanion row) =>
      into(userVehicleCosts).insertOnConflictUpdate(row);

  Future<UserVehicleCostsRow?> findCosts(String userVehicleId) => (select(
    userVehicleCosts,
  )..where((c) => c.userVehicleId.equals(userVehicleId))).getSingleOrNull();

  Future<void> deleteCosts(String userVehicleId) => (delete(
    userVehicleCosts,
  )..where((c) => c.userVehicleId.equals(userVehicleId))).go();
}
