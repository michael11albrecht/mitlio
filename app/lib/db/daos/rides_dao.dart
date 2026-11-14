import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'rides_dao.g.dart';

/// Vehicles, ride templates and rides (P3r-T03).
@DriftAccessor(tables: [Vehicles, RideTemplates, Rides])
class RidesDao extends DatabaseAccessor<AppDatabase> with _$RidesDaoMixin {
  RidesDao(super.attachedDatabase);

  // Vehicles

  Future<void> insertVehicle(VehiclesCompanion v) => into(vehicles).insert(v);

  Future<VehicleRow?> findVehicle(String id) => (select(
    vehicles,
  )..where((v) => v.id.equals(id) & v.deletedAt.isNull())).getSingleOrNull();

  Stream<List<VehicleRow>> watchVehicles(String groupId) =>
      (select(vehicles)
            ..where((v) => v.groupId.equals(groupId) & v.deletedAt.isNull())
            ..orderBy([
              (v) => OrderingTerm.asc(v.createdAt),
              (v) => OrderingTerm.asc(v.id),
            ]))
          .watch();

  Future<bool> updateVehicle(String id, VehiclesCompanion change) async =>
      await (update(
        vehicles,
      )..where((v) => v.id.equals(id) & v.deletedAt.isNull())).write(
        change,
      ) >
      0;

  Future<bool> softDeleteVehicle(String id, DateTime at, String hlc) =>
      updateVehicle(
        id,
        VehiclesCompanion(deletedAt: Value(at), updatedAt: Value(hlc)),
      );

  Future<bool> restoreVehicle(String id, String hlc) async =>
      await (update(
        vehicles,
      )..where((v) => v.id.equals(id) & v.deletedAt.isNotNull())).write(
        VehiclesCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(hlc),
        ),
      ) >
      0;

  // Ride templates

  Future<void> insertTemplate(RideTemplatesCompanion t) =>
      into(rideTemplates).insert(t);

  Future<RideTemplateRow?> findTemplate(String id) => (select(
    rideTemplates,
  )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

  Stream<List<RideTemplateRow>> watchTemplates(String groupId) =>
      (select(rideTemplates)
            ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Future<bool> updateTemplate(String id, RideTemplatesCompanion change) async =>
      await (update(
        rideTemplates,
      )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
        change,
      ) >
      0;

  Future<bool> softDeleteTemplate(String id, DateTime at, String hlc) =>
      updateTemplate(
        id,
        RideTemplatesCompanion(deletedAt: Value(at), updatedAt: Value(hlc)),
      );

  Future<bool> restoreTemplate(String id, String hlc) async =>
      await (update(
        rideTemplates,
      )..where((t) => t.id.equals(id) & t.deletedAt.isNotNull())).write(
        RideTemplatesCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(hlc),
        ),
      ) >
      0;

  // Rides

  Future<void> insertRide(RidesCompanion r) => into(rides).insert(r);

  /// Any ride row, live or soft deleted.
  Future<RideRow?> findRideAny(String id) =>
      (select(rides)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<RideRow?> findRide(String id) => (select(
    rides,
  )..where((r) => r.id.equals(id) & r.deletedAt.isNull())).getSingleOrNull();

  /// Live rides of [groupId], oldest first.
  Stream<List<RideRow>> watchRides(String groupId) =>
      (select(rides)
            ..where((r) => r.groupId.equals(groupId) & r.deletedAt.isNull())
            ..orderBy([
              (r) => OrderingTerm.asc(r.date),
              (r) => OrderingTerm.asc(r.id),
            ]))
          .watch();

  Future<bool> updateRide(String id, RidesCompanion change) async =>
      await (update(
        rides,
      )..where((r) => r.id.equals(id) & r.deletedAt.isNull())).write(
        change,
      ) >
      0;

  Future<bool> restoreRide(String id, String hlc) async =>
      await (update(
        rides,
      )..where((r) => r.id.equals(id) & r.deletedAt.isNotNull())).write(
        RidesCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(hlc),
        ),
      ) >
      0;

  Future<List<RideRow>> findRides(List<String> ids) =>
      (select(rides)..where((r) => r.id.isIn(ids))).get();
}
