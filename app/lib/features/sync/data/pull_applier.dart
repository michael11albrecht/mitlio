import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart' as clock_hlc;
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/expenses_dao.dart';
import 'package:mitlio/features/expenses/data/expense_revision.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart' as domain;

/// A page that cannot be applied. Thrown inside the page transaction so
/// nothing of the page stays; `SyncService.pull` shows [error].
class PullAbort implements Exception {
  const PullAbort(this.error);

  final RemoteError error;

  @override
  String toString() => 'PullAbort($error)';
}

/// Writes pulled server rows into Drift (P6-T11, ADR-07).
///
/// - **No echo.** It writes the tables directly. It never calls a repository
///   and never touches `OutboxWriter`, so applying a remote row queues
///   nothing. The only outbox write is deleting a superseded pending op.
/// - **One transaction per page**: decisions, row writes, dropped ops and the
///   cursor. A failure rolls the page back, the cursor stays and the same
///   page is fetched again.
/// - **LWW by [domain.decide]** on the HLC in `updated_at`, with the pending
///   outbox op of the aggregate (if any) as the third party. Everything is
///   read inside the transaction, so a local write that lands between the
///   fetch and the apply is seen.
/// - **Pending ops.** Only the op row that lost is deleted, by `op_id`. A
///   push that already sent that op is harmless: the server holds a version
///   at least as new (that is why the op lost), so its `enforce_lww` /
///   `upsert_expense` answer is `stale`, and the push's delete by `op_id` is a
///   no-op because the row is gone. A newer local write has another `op_id`
///   and survives.
/// - **Local-only data stays.** Server payloads only have server columns;
///   `local_*` tables (full IBAN, places, prompts) are never read or written.
/// - **Clock.** Every remote `updated_at` goes through the local HLC. A
///   `ClockDrift` (remote more than a minute ahead) keeps the local clock
///   unchanged and still applies the row: the server is the truth, and
///   refusing it would freeze the group. An unreadable `updated_at` aborts the
///   page.
/// - **Foreign keys.** Drift enforces them (`PRAGMA foreign_keys = ON`), so
///   the caller pulls the tables in `pushRank` order: parents first.
class PullApplier {
  PullApplier({
    required this._db,
    required this._clock,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  /// Applies [rows] of [table] (ascending `server_seq`) and moves the cursor
  /// of ([groupId], [table]) to the highest `server_seq` of the page.
  /// [children] holds payers and shares for an expense page.
  Future<void> applyPage({
    required String groupId,
    required String table,
    required List<Map<String, Object?>> rows,
    Map<String, ExpenseChildren> children = const {},
  }) => _db.transaction(() async {
    for (final row in rows) {
      await _applyRow(table, row, children);
    }
    final top = rows
        .map((r) => r[DbGroupsCols.serverSeq]! as int)
        .reduce((a, b) => a > b ? a : b);
    await _db.syncStateDao.setCursor(groupId, table, top);
  });

  Future<void> _applyRow(
    String table,
    Map<String, Object?> row,
    Map<String, ExpenseChildren> children,
  ) async {
    final id = row[DbGroupsCols.id]! as String;
    final updatedAt = row[DbGroupsCols.updatedAt];
    final remoteHlc = _parse(updatedAt);
    // Moves the local clock past the remote one. Drift: documented above.
    clock_hlc.Hlc.receive(updatedAt! as String, _clock);

    final local = await _localVersion(table, id);
    final pending = await _pending(table, id);
    final decision = domain.decide(
      remote: domain.SyncVersion(
        updatedAt: remoteHlc,
        deletedAt: _tsOrNull(row[DbGroupsCols.deletedAt]),
      ),
      local: local,
      pendingLocal: pending?.hlc,
    );
    switch (decision) {
      case domain.MergeDecision.keepLocal || domain.MergeDecision.same:
        // The account link is server-owned and changes without a new
        // `updated_at`; take it even when the person itself did not change,
        // or "verbunden" would never reach the other phones.
        if (table == DbTables.members &&
            local != null &&
            row.containsKey(DbMembersCols.userId)) {
          await _db.membersDao.setUserId(
            id,
            row[DbMembersCols.userId] as String?,
          );
        }
        return;
      case domain.MergeDecision.applyRemoteDropPending:
        await (_db.delete(
          _db.localOutbox,
        )..where((o) => o.opId.equals(pending!.opId))).go();
      case domain.MergeDecision.applyRemote:
        break;
    }
    await _write(table, row, children, hadLocal: local != null);
  }

  domain.Hlc _parse(Object? raw) {
    final text = raw is String ? raw : '';
    return switch (domain.Hlc.parse(text)) {
      domain.Ok(:final value) => value,
      domain.Err() => throw const PullAbort(PullFailed('invalid_updated_at')),
    };
  }

  Future<domain.SyncVersion?> _localVersion(String table, String id) async {
    final stamp = await _localStamp(table, id);
    if (stamp == null) return null;
    final parsed = domain.Hlc.parse(stamp.updatedAt);
    // A local stamp we cannot read never beats the server's.
    if (parsed is! domain.Ok<domain.Hlc, domain.HlcError>) return null;
    return domain.SyncVersion(
      updatedAt: parsed.value,
      deletedAt: stamp.deletedAt,
    );
  }

  Future<({String updatedAt, DateTime? deletedAt})?> _localStamp(
    String table,
    String id,
  ) async {
    switch (table) {
      case DbTables.groups:
        final r = await (_db.select(
          _db.groups,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return r == null
            ? null
            : (updatedAt: r.updatedAt, deletedAt: r.deletedAt);
      case DbTables.members:
        final r = await (_db.select(
          _db.members,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return r == null
            ? null
            : (updatedAt: r.updatedAt, deletedAt: r.deletedAt);
      case DbTables.vehicles:
        final r = await (_db.select(
          _db.vehicles,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return r == null
            ? null
            : (updatedAt: r.updatedAt, deletedAt: r.deletedAt);
      case DbTables.rideTemplates:
        final r = await (_db.select(
          _db.rideTemplates,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return r == null
            ? null
            : (updatedAt: r.updatedAt, deletedAt: r.deletedAt);
      case DbTables.expenses:
        final r = await (_db.select(
          _db.expenses,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return r == null
            ? null
            : (updatedAt: r.updatedAt, deletedAt: r.deletedAt);
      case DbTables.rides:
        final r = await (_db.select(
          _db.rides,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return r == null
            ? null
            : (updatedAt: r.updatedAt, deletedAt: r.deletedAt);
      case DbTables.settlements:
        final r = await (_db.select(
          _db.settlements,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        return r == null
            ? null
            : (updatedAt: r.updatedAt, deletedAt: r.deletedAt);
      default:
        throw PullAbort(PullFailed('unknown_table_$table'));
    }
  }

  Future<({String opId, domain.Hlc hlc})?> _pending(
    String table,
    String id,
  ) async {
    final op =
        await (_db.select(_db.localOutbox)
              ..where((o) => o.entity.equals(table) & o.entityId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    if (op == null) return null;
    final payload = jsonDecode(op.payload) as Map<String, Object?>;
    final hlc = domain.Hlc.parse(payload[DbGroupsCols.updatedAt]! as String);
    // An op without a readable stamp cannot win; it is replaced.
    return (
      opId: op.opId,
      hlc: switch (hlc) {
        domain.Ok(:final value) => value,
        domain.Err() => domain.Hlc(wallMillis: 0, counter: 0, nodeId: 'none'),
      },
    );
  }

  // -- writes ---------------------------------------------------------------

  Future<void> _write(
    String table,
    Map<String, Object?> r,
    Map<String, ExpenseChildren> children, {
    required bool hadLocal,
  }) async {
    switch (table) {
      case DbTables.groups:
        await _writeGroup(r);
      case DbTables.members:
        await _db
            .into(_db.members)
            .insertOnConflictUpdate(
              MembersCompanion(
                id: Value(r[DbMembersCols.id]! as String),
                groupId: Value(r[DbMembersCols.groupId]! as String),
                name: Value(r[DbMembersCols.name]! as String),
                position: Value(r[DbMembersCols.position]! as int),
                paypalMe: Value(r[DbMembersCols.paypalMe] as String?),
                ibanHint: Value(r[DbMembersCols.ibanHint] as String?),
                canDrive: Value(r[DbMembersCols.canDrive] as bool? ?? true),
                // The account link is server-owned; keep ours when the
                // payload does not carry it.
                userId: r.containsKey(DbMembersCols.userId)
                    ? Value(r[DbMembersCols.userId] as String?)
                    : const Value.absent(),
                createdAt: Value(_created(r)),
                updatedAt: Value(r[DbMembersCols.updatedAt]! as String),
                deletedAt: Value(_tsOrNull(r[DbMembersCols.deletedAt])),
              ),
            );
      case DbTables.vehicles:
        await _db
            .into(_db.vehicles)
            .insertOnConflictUpdate(
              VehiclesCompanion(
                id: Value(r[DbVehiclesCols.id]! as String),
                groupId: Value(r[DbVehiclesCols.groupId]! as String),
                name: Value(r[DbVehiclesCols.name]! as String),
                fuelType: Value(r[DbVehiclesCols.fuelType]! as String),
                consumptionMilliPer100km: Value(
                  r[DbVehiclesCols.consumptionMilliPer100km]! as int,
                ),
                wearMilliPerKm: Value(
                  r[DbVehiclesCols.wearMilliPerKm] as int? ?? 0,
                ),
                kmRateMilliPerKm: Value(
                  r[DbVehiclesCols.kmRateMilliPerKm] as int?,
                ),
                createdAt: Value(_created(r)),
                updatedAt: Value(r[DbVehiclesCols.updatedAt]! as String),
                deletedAt: Value(_tsOrNull(r[DbVehiclesCols.deletedAt])),
              ),
            );
      case DbTables.rideTemplates:
        await _db
            .into(_db.rideTemplates)
            .insertOnConflictUpdate(
              RideTemplatesCompanion(
                id: Value(r[DbRideTemplatesCols.id]! as String),
                groupId: Value(r[DbRideTemplatesCols.groupId]! as String),
                name: Value(r[DbRideTemplatesCols.name]! as String),
                distanceMeters: Value(
                  r[DbRideTemplatesCols.distanceMeters]! as int,
                ),
                roundTrip: Value(
                  r[DbRideTemplatesCols.roundTrip] as bool? ?? false,
                ),
                vehicleId: Value(r[DbRideTemplatesCols.vehicleId]! as String),
                defaultDriverId: Value(
                  r[DbRideTemplatesCols.defaultDriverId] as String?,
                ),
                defaultPassengerIds: Value(
                  _jsonText(r[DbRideTemplatesCols.defaultPassengerIds]) ?? '[]',
                ),
                tollsCents: Value(
                  r[DbRideTemplatesCols.tollsCents] as int? ?? 0,
                ),
                createdAt: Value(_created(r)),
                updatedAt: Value(r[DbRideTemplatesCols.updatedAt]! as String),
                deletedAt: Value(_tsOrNull(r[DbRideTemplatesCols.deletedAt])),
              ),
            );
      case DbTables.expenses:
        await _writeExpense(
          r,
          children[r[DbExpensesCols.id]! as String],
          hadLocal,
        );
      case DbTables.rides:
        await _db
            .into(_db.rides)
            .insertOnConflictUpdate(
              RidesCompanion(
                id: Value(r[DbRidesCols.id]! as String),
                groupId: Value(r[DbRidesCols.groupId]! as String),
                date: Value(_ts(r[DbRidesCols.date])),
                distanceMeters: Value(r[DbRidesCols.distanceMeters]! as int),
                roundTrip: Value(r[DbRidesCols.roundTrip] as bool? ?? false),
                tollsCents: Value(r[DbRidesCols.tollsCents] as int? ?? 0),
                vehicleId: Value(r[DbRidesCols.vehicleId]! as String),
                driverId: Value(r[DbRidesCols.driverId]! as String),
                passengerIds: Value(
                  _jsonText(r[DbRidesCols.passengerIds]) ?? '[]',
                ),
                driverCounts: Value(
                  r[DbRidesCols.driverCounts] as bool? ?? true,
                ),
                pricePerUnitMilli: Value(
                  r[DbRidesCols.pricePerUnitMilli]! as int,
                ),
                useKmRate: Value(r[DbRidesCols.useKmRate] as bool? ?? false),
                settledExpenseId: Value(
                  r[DbRidesCols.settledExpenseId] as String?,
                ),
                createdAt: Value(_created(r)),
                updatedAt: Value(r[DbRidesCols.updatedAt]! as String),
                deletedAt: Value(_tsOrNull(r[DbRidesCols.deletedAt])),
              ),
            );
      case DbTables.settlements:
        await _db
            .into(_db.settlements)
            .insertOnConflictUpdate(
              SettlementsCompanion(
                id: Value(r[DbSettlementsCols.id]! as String),
                groupId: Value(r[DbSettlementsCols.groupId]! as String),
                fromMember: Value(r[DbSettlementsCols.fromMember]! as String),
                toMember: Value(r[DbSettlementsCols.toMember]! as String),
                amountCents: Value(r[DbSettlementsCols.amountCents]! as int),
                currency: Value(r[DbSettlementsCols.currency]! as String),
                date: Value(_ts(r[DbSettlementsCols.date])),
                method: Value(r[DbSettlementsCols.method]! as String),
                createdAt: Value(_created(r)),
                updatedAt: Value(r[DbSettlementsCols.updatedAt]! as String),
                deletedAt: Value(_tsOrNull(r[DbSettlementsCols.deletedAt])),
              ),
            );
      default:
        throw PullAbort(PullFailed('unknown_table_$table'));
    }
  }

  /// A remote soft delete of the group archives it locally (`deleted_at`);
  /// no row is removed.
  Future<void> _writeGroup(Map<String, Object?> r) async {
    final id = r[DbGroupsCols.id]! as String;
    final existing = await (_db.select(
      _db.groups,
    )..where((g) => g.id.equals(id))).getSingleOrNull();
    await _db
        .into(_db.groups)
        .insertOnConflictUpdate(
          GroupsCompanion(
            id: Value(id),
            name: Value(r[DbGroupsCols.name]! as String),
            currency: Value(r[DbGroupsCols.currency]! as String),
            createdBy: Value(
              r[DbGroupsCols.createdBy] as String? ?? existing?.createdBy ?? '',
            ),
            createdAt: Value(_created(r)),
            updatedAt: Value(r[DbGroupsCols.updatedAt]! as String),
            deletedAt: Value(_tsOrNull(r[DbGroupsCols.deletedAt])),
          ),
        );
  }

  Future<void> _writeExpense(
    Map<String, Object?> r,
    ExpenseChildren? kids,
    bool hadLocal,
  ) async {
    final id = r[DbExpensesCols.id]! as String;
    final groupId = r[DbExpensesCols.groupId]! as String;
    if (kids == null || kids.payers.isEmpty || kids.shares.isEmpty) {
      // An expense without payers or shares is not a valid aggregate.
      throw const PullAbort(PullFailed('expense_children_missing'));
    }
    if (hadLocal) {
      // Like a local edit: keep the version this pull overwrites.
      final before = await _storedExpense(id);
      if (before != null) {
        await _db.expensesDao.addRevision(
          id: _ids.newId(),
          expenseId: id,
          groupId: groupId,
          changedAt: _clock.now().toUtc(),
          snapshot: jsonEncode(ExpenseSnapshot.ofStored(before).toJson()),
          keep: expenseRevisionLimit,
        );
      }
    }
    await _db
        .into(_db.expenses)
        .insertOnConflictUpdate(
          ExpensesCompanion(
            id: Value(id),
            groupId: Value(groupId),
            title: Value(r[DbExpensesCols.title]! as String),
            amountCents: Value(r[DbExpensesCols.amountCents]! as int),
            currency: Value(r[DbExpensesCols.currency]! as String),
            fxRatePpm: Value(r[DbExpensesCols.fxRatePpm]! as int),
            groupAmountCents: Value(r[DbExpensesCols.groupAmountCents]! as int),
            date: Value(_ts(r[DbExpensesCols.date])),
            category: Value(r[DbExpensesCols.category] as String?),
            type: Value(r[DbExpensesCols.type]! as String),
            splitMode: Value(r[DbExpensesCols.splitMode]! as String),
            tripMeta: Value(_jsonText(r[DbExpensesCols.tripMeta])),
            createdAt: Value(_created(r)),
            updatedAt: Value(r[DbExpensesCols.updatedAt]! as String),
            deletedAt: Value(_tsOrNull(r[DbExpensesCols.deletedAt])),
          ),
        );
    await (_db.delete(
      _db.expensePayers,
    )..where((p) => p.expenseId.equals(id))).go();
    await (_db.delete(
      _db.expenseShares,
    )..where((s) => s.expenseId.equals(id))).go();
    for (final p in kids.payers) {
      await _db
          .into(_db.expensePayers)
          .insert(
            ExpensePayersCompanion.insert(
              groupId: groupId,
              expenseId: id,
              memberId: p[DbExpensePayersCols.memberId]! as String,
              paidCents: p[DbExpensePayersCols.paidCents]! as int,
            ),
          );
    }
    for (final s in kids.shares) {
      await _db
          .into(_db.expenseShares)
          .insert(
            ExpenseSharesCompanion.insert(
              groupId: groupId,
              expenseId: id,
              memberId: s[DbExpenseSharesCols.memberId]! as String,
              shareCents: s[DbExpenseSharesCols.shareCents]! as int,
              weight: s[DbExpenseSharesCols.weight] as int? ?? 0,
            ),
          );
    }
  }

  /// The expense with children, deleted or not.
  Future<ExpenseWithChildren?> _storedExpense(String id) async {
    final root = await (_db.select(
      _db.expenses,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (root == null) return null;
    return ExpenseWithChildren(
      expense: root,
      payers:
          await (_db.select(_db.expensePayers)
                ..where((p) => p.expenseId.equals(id))
                ..orderBy([(p) => OrderingTerm.asc(p.memberId)]))
              .get(),
      shares:
          await (_db.select(_db.expenseShares)
                ..where((s) => s.expenseId.equals(id))
                ..orderBy([(s) => OrderingTerm.asc(s.memberId)]))
              .get(),
    );
  }

  static DateTime _ts(Object? v) => v is String
      ? DateTime.parse(v).toUtc()
      : throw const PullAbort(PullFailed('invalid_timestamp'));

  /// `created_at`, or the wall time of `updated_at` when the row has none
  /// (the server fills it with `now()` on insert; an older payload may omit
  /// it).
  static DateTime _created(Map<String, Object?> r) {
    final v = r[DbGroupsCols.createdAt];
    if (v != null) return _ts(v);
    return DateTime.fromMillisecondsSinceEpoch(
      (domain.Hlc.parse(
        r[DbGroupsCols.updatedAt]! as String,
      ) as domain.Ok<domain.Hlc, domain.HlcError>).value.wallMillis,
      isUtc: true,
    );
  }

  static DateTime? _tsOrNull(Object? v) => v == null ? null : _ts(v);

  /// jsonb comes back decoded; the local columns hold JSON text.
  static String? _jsonText(Object? v) => switch (v) {
    null => null,
    final String s => s,
    final Object o => jsonEncode(o),
  };
}
