import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';

/// The synced aggregates. The stored `entity` is the server table name.
enum OutboxEntity {
  group(DbTables.groups),
  member(DbTables.members),
  expense(DbTables.expenses),
  settlement(DbTables.settlements),
  vehicle(DbTables.vehicles),
  rideTemplate(DbTables.rideTemplates),
  ride(DbTables.rides);

  const OutboxEntity(this.table);

  /// Server table name, stored in `local_outbox.entity`.
  final String table;
}

/// Every outbox op is an upsert of the full aggregate; a soft delete or a
/// restore is an upsert with `deleted_at` set or cleared.
const outboxOpUpsert = 'upsert';

/// Queues the aggregate written by a repository for upload (P6-T09, ADR-07).
///
/// Call [enqueue] inside the Drift transaction of the write, after it: the
/// payload is read back from the row just written, so `updated_at` is the HLC
/// of that write. A group that is not `shared`/`uploading` queues nothing. A
/// newer write of the same (entity, id) replaces the pending op (coalescing)
/// and moves it to the end of the queue with a new `op_id`. Queue order is
/// therefore NOT dependency order (rename a member after adding an expense for
/// it and the member op lands behind the expense op); the push (P6-T10) must
/// send ops ordered by entity (group, member, vehicle, ride template, expense,
/// ride, settlement), then by queue order.
///
/// Payloads use server column names only. Local-only data (`local_*` tables,
/// the full IBAN) is never read here; `user_id` and `created_by` are
/// server-assigned and left out.
class OutboxWriter {
  OutboxWriter({
    required this._db,
    required this._clock,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  /// Queues [entity] [id] if its group is shared. Throws [StateError] when
  /// the row does not exist (a programming error: call it after the write).
  Future<void> enqueue(OutboxEntity entity, String id) async {
    final groupId = await _groupIdOf(entity, id);
    final sync = await _db.syncStateDao.groupSync(groupId);
    final state = sync?.state;
    if (state != SyncState.shared.name && state != SyncState.uploading.name) {
      return;
    }
    final payload = await payloadOf(entity, id);
    await _db.transaction(() async {
      await (_db.delete(_db.localOutbox)..where(
            (o) => o.entity.equals(entity.table) & o.entityId.equals(id),
          ))
          .go();
      await _db
          .into(_db.localOutbox)
          .insert(
            LocalOutboxCompanion.insert(
              opId: _ids.newId(),
              groupId: groupId,
              entity: entity.table,
              entityId: id,
              op: outboxOpUpsert,
              payload: jsonEncode(payload),
              createdAt: _clock.now().toUtc(),
            ),
          );
    });
  }

  Future<String> _groupIdOf(OutboxEntity entity, String id) async {
    final groupId = switch (entity) {
      OutboxEntity.group => id,
      OutboxEntity.member => (await (_db.select(
        _db.members,
      )..where((r) => r.id.equals(id))).getSingleOrNull())?.groupId,
      OutboxEntity.expense => (await (_db.select(
        _db.expenses,
      )..where((r) => r.id.equals(id))).getSingleOrNull())?.groupId,
      OutboxEntity.settlement => (await (_db.select(
        _db.settlements,
      )..where((r) => r.id.equals(id))).getSingleOrNull())?.groupId,
      OutboxEntity.vehicle => (await (_db.select(
        _db.vehicles,
      )..where((r) => r.id.equals(id))).getSingleOrNull())?.groupId,
      OutboxEntity.rideTemplate => (await (_db.select(
        _db.rideTemplates,
      )..where((r) => r.id.equals(id))).getSingleOrNull())?.groupId,
      OutboxEntity.ride => (await (_db.select(
        _db.rides,
      )..where((r) => r.id.equals(id))).getSingleOrNull())?.groupId,
    };
    if (groupId == null) {
      throw StateError('outbox: ${entity.table} $id was not written');
    }
    return groupId;
  }

  /// The full aggregate in server column names.
  Future<Map<String, Object?>> payloadOf(OutboxEntity entity, String id) async {
    switch (entity) {
      case OutboxEntity.group:
        final r = await (_db.select(
          _db.groups,
        )..where((t) => t.id.equals(id))).getSingle();
        return {
          DbGroupsCols.id: r.id,
          DbGroupsCols.name: r.name,
          DbGroupsCols.currency: r.currency,
          DbGroupsCols.createdAt: _ts(r.createdAt),
          DbGroupsCols.updatedAt: r.updatedAt,
          DbGroupsCols.deletedAt: _tsOrNull(r.deletedAt),
        };
      case OutboxEntity.member:
        final r = await (_db.select(
          _db.members,
        )..where((t) => t.id.equals(id))).getSingle();
        return {
          DbMembersCols.id: r.id,
          DbMembersCols.groupId: r.groupId,
          DbMembersCols.name: r.name,
          DbMembersCols.position: r.position,
          DbMembersCols.paypalMe: r.paypalMe,
          DbMembersCols.ibanHint: r.ibanHint,
          DbMembersCols.canDrive: r.canDrive,
          DbMembersCols.createdAt: _ts(r.createdAt),
          DbMembersCols.updatedAt: r.updatedAt,
          DbMembersCols.deletedAt: _tsOrNull(r.deletedAt),
        };
      case OutboxEntity.expense:
        return _expense(id);
      case OutboxEntity.settlement:
        final r = await (_db.select(
          _db.settlements,
        )..where((t) => t.id.equals(id))).getSingle();
        return {
          DbSettlementsCols.id: r.id,
          DbSettlementsCols.groupId: r.groupId,
          DbSettlementsCols.fromMember: r.fromMember,
          DbSettlementsCols.toMember: r.toMember,
          DbSettlementsCols.amountCents: r.amountCents,
          DbSettlementsCols.currency: r.currency,
          DbSettlementsCols.date: _ts(r.date),
          DbSettlementsCols.method: r.method,
          DbSettlementsCols.createdAt: _ts(r.createdAt),
          DbSettlementsCols.updatedAt: r.updatedAt,
          DbSettlementsCols.deletedAt: _tsOrNull(r.deletedAt),
        };
      case OutboxEntity.vehicle:
        final r = await (_db.select(
          _db.vehicles,
        )..where((t) => t.id.equals(id))).getSingle();
        return {
          DbVehiclesCols.id: r.id,
          DbVehiclesCols.groupId: r.groupId,
          DbVehiclesCols.name: r.name,
          DbVehiclesCols.fuelType: r.fuelType,
          DbVehiclesCols.consumptionMilliPer100km: r.consumptionMilliPer100km,
          DbVehiclesCols.wearMilliPerKm: r.wearMilliPerKm,
          DbVehiclesCols.kmRateMilliPerKm: r.kmRateMilliPerKm,
          DbVehiclesCols.createdAt: _ts(r.createdAt),
          DbVehiclesCols.updatedAt: r.updatedAt,
          DbVehiclesCols.deletedAt: _tsOrNull(r.deletedAt),
        };
      case OutboxEntity.rideTemplate:
        final r = await (_db.select(
          _db.rideTemplates,
        )..where((t) => t.id.equals(id))).getSingle();
        return {
          DbRideTemplatesCols.id: r.id,
          DbRideTemplatesCols.groupId: r.groupId,
          DbRideTemplatesCols.name: r.name,
          DbRideTemplatesCols.distanceMeters: r.distanceMeters,
          DbRideTemplatesCols.roundTrip: r.roundTrip,
          DbRideTemplatesCols.vehicleId: r.vehicleId,
          DbRideTemplatesCols.defaultDriverId: r.defaultDriverId,
          DbRideTemplatesCols.defaultPassengerIds: jsonDecode(
            r.defaultPassengerIds,
          ),
          DbRideTemplatesCols.tollsCents: r.tollsCents,
          DbRideTemplatesCols.createdAt: _ts(r.createdAt),
          DbRideTemplatesCols.updatedAt: r.updatedAt,
          DbRideTemplatesCols.deletedAt: _tsOrNull(r.deletedAt),
        };
      case OutboxEntity.ride:
        final r = await (_db.select(
          _db.rides,
        )..where((t) => t.id.equals(id))).getSingle();
        return {
          DbRidesCols.id: r.id,
          DbRidesCols.groupId: r.groupId,
          DbRidesCols.date: _ts(r.date),
          DbRidesCols.distanceMeters: r.distanceMeters,
          DbRidesCols.roundTrip: r.roundTrip,
          DbRidesCols.tollsCents: r.tollsCents,
          DbRidesCols.vehicleId: r.vehicleId,
          DbRidesCols.driverId: r.driverId,
          DbRidesCols.passengerIds: jsonDecode(r.passengerIds),
          DbRidesCols.driverCounts: r.driverCounts,
          DbRidesCols.pricePerUnitMilli: r.pricePerUnitMilli,
          DbRidesCols.useKmRate: r.useKmRate,
          DbRidesCols.settledExpenseId: r.settledExpenseId,
          DbRidesCols.createdAt: _ts(r.createdAt),
          DbRidesCols.updatedAt: r.updatedAt,
          DbRidesCols.deletedAt: _tsOrNull(r.deletedAt),
        };
    }
  }

  /// The `upsert_expense` payload (`0002_upsert_expense.sql` header).
  Future<Map<String, Object?>> _expense(String id) async {
    final e = await (_db.select(
      _db.expenses,
    )..where((t) => t.id.equals(id))).getSingle();
    final payers =
        await (_db.select(_db.expensePayers)
              ..where((t) => t.expenseId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.memberId)]))
            .get();
    final shares =
        await (_db.select(_db.expenseShares)
              ..where((t) => t.expenseId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.memberId)]))
            .get();
    final trip = e.tripMeta;
    return {
      DbExpensesCols.id: e.id,
      DbExpensesCols.groupId: e.groupId,
      DbExpensesCols.title: e.title,
      DbExpensesCols.amountCents: e.amountCents,
      DbExpensesCols.currency: e.currency,
      DbExpensesCols.fxRatePpm: e.fxRatePpm,
      DbExpensesCols.groupAmountCents: e.groupAmountCents,
      DbExpensesCols.date: _ts(e.date),
      DbExpensesCols.category: e.category,
      DbExpensesCols.type: e.type,
      DbExpensesCols.splitMode: e.splitMode,
      DbExpensesCols.tripMeta: trip == null ? null : jsonDecode(trip),
      DbExpensesCols.updatedAt: e.updatedAt,
      DbExpensesCols.deletedAt: _tsOrNull(e.deletedAt),
      'payers': [
        for (final p in payers)
          {
            DbExpensePayersCols.memberId: p.memberId,
            DbExpensePayersCols.paidCents: p.paidCents,
          },
      ],
      'shares': [
        for (final s in shares)
          {
            DbExpenseSharesCols.memberId: s.memberId,
            DbExpenseSharesCols.shareCents: s.shareCents,
            DbExpenseSharesCols.weight: s.weight,
          },
      ],
    };
  }

  static String _ts(DateTime t) => t.toUtc().toIso8601String();
  static String? _tsOrNull(DateTime? t) => t == null ? null : _ts(t);
}
