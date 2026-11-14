import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'settlements_dao.g.dart';

@DriftAccessor(tables: [Settlements])
class SettlementsDao extends DatabaseAccessor<AppDatabase>
    with _$SettlementsDaoMixin {
  SettlementsDao(super.attachedDatabase);

  Future<void> insertSettlement(SettlementsCompanion settlement) =>
      into(settlements).insert(settlement);

  Future<SettlementRow?> findById(String id) => (select(
    settlements,
  )..where((s) => s.id.equals(id) & s.deletedAt.isNull())).getSingleOrNull();

  /// Live settlements of [groupId], oldest first.
  Future<List<SettlementRow>> listByGroup(String groupId) =>
      _byGroup(groupId).get();

  Stream<List<SettlementRow>> watchByGroup(String groupId) =>
      _byGroup(groupId).watch();

  SimpleSelectStatement<$SettlementsTable, SettlementRow> _byGroup(
    String groupId,
  ) => select(settlements)
    ..where((s) => s.groupId.equals(groupId) & s.deletedAt.isNull())
    ..orderBy([
      (s) => OrderingTerm.asc(s.date),
      (s) => OrderingTerm.asc(s.id),
    ]);

  Future<bool> updateSettlement({
    required String id,
    required int amountCents,
    required String method,
    required DateTime date,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          settlements,
        )..where((s) => s.id.equals(id) & s.deletedAt.isNull())).write(
          SettlementsCompanion(
            amountCents: Value(amountCents),
            method: Value(method),
            date: Value(date),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }

  Future<bool> softDelete({
    required String id,
    required DateTime deletedAt,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          settlements,
        )..where((s) => s.id.equals(id) & s.deletedAt.isNull())).write(
          SettlementsCompanion(
            deletedAt: Value(deletedAt),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }

  /// Undoes [softDelete]. Returns true if a soft-deleted row was revived.
  Future<bool> restore({
    required String id,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          settlements,
        )..where((r) => r.id.equals(id) & r.deletedAt.isNotNull())).write(
          SettlementsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }
}
