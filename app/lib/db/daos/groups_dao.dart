import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'groups_dao.g.dart';

@DriftAccessor(tables: [Groups])
class GroupsDao extends DatabaseAccessor<AppDatabase> with _$GroupsDaoMixin {
  GroupsDao(super.attachedDatabase);

  Future<void> insertGroup(GroupsCompanion group) => into(groups).insert(group);

  /// Returns the live (not soft-deleted) group or null.
  Future<GroupRow?> findById(String id) => (select(
    groups,
  )..where((g) => g.id.equals(id) & g.deletedAt.isNull())).getSingleOrNull();

  Future<List<GroupRow>> listGroups() =>
      (select(groups)..where((g) => g.deletedAt.isNull())).get();

  Stream<List<GroupRow>> watchGroups() =>
      (select(groups)..where((g) => g.deletedAt.isNull())).watch();

  /// Returns true if a live row was updated. A null [currency] keeps it.
  Future<bool> updateGroup({
    required String id,
    required String name,
    required String updatedAt,
    String? currency,
  }) async {
    final n =
        await (update(
          groups,
        )..where((g) => g.id.equals(id) & g.deletedAt.isNull())).write(
          GroupsCompanion(
            name: Value(name),
            currency: currency == null ? const Value.absent() : Value(currency),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }

  /// Soft delete. Returns true if a live row was marked deleted.
  Future<bool> softDelete({
    required String id,
    required DateTime deletedAt,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          groups,
        )..where((g) => g.id.equals(id) & g.deletedAt.isNull())).write(
          GroupsCompanion(
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
          groups,
        )..where((r) => r.id.equals(id) & r.deletedAt.isNotNull())).write(
          GroupsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }
}
