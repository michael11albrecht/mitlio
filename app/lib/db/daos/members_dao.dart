import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'members_dao.g.dart';

@DriftAccessor(tables: [Members])
class MembersDao extends DatabaseAccessor<AppDatabase> with _$MembersDaoMixin {
  MembersDao(super.attachedDatabase);

  Future<void> insertMember(MembersCompanion member) =>
      into(members).insert(member);

  Future<MemberRow?> findById(String id) => (select(
    members,
  )..where((m) => m.id.equals(id) & m.deletedAt.isNull())).getSingleOrNull();

  /// Live members of [groupId] ordered by position, then id.
  Future<List<MemberRow>> listByGroup(String groupId) =>
      _byGroup(groupId).get();

  Stream<List<MemberRow>> watchByGroup(String groupId) =>
      _byGroup(groupId).watch();

  SimpleSelectStatement<$MembersTable, MemberRow> _byGroup(String groupId) =>
      select(members)
        ..where((m) => m.groupId.equals(groupId) & m.deletedAt.isNull())
        ..orderBy([
          (m) => OrderingTerm.asc(m.position),
          (m) => OrderingTerm.asc(m.id),
        ]);

  Future<bool> updateMember({
    required String id,
    required String name,
    required int position,
    required String updatedAt,
    String? paypalMe,
    String? ibanHint,
  }) async {
    final n =
        await (update(
          members,
        )..where((m) => m.id.equals(id) & m.deletedAt.isNull())).write(
          MembersCompanion(
            name: Value(name),
            position: Value(position),
            paypalMe: Value(paypalMe),
            ibanHint: Value(ibanHint),
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
          members,
        )..where((m) => m.id.equals(id) & m.deletedAt.isNull())).write(
          MembersCompanion(
            deletedAt: Value(deletedAt),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }
}
