import 'package:drift/drift.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'members_dao.g.dart';

@DriftAccessor(tables: [Members, LocalDriverPrompts])
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

  /// All members of [groupId] including soft-deleted ones: expenses keep
  /// referencing deleted members.
  Future<List<MemberRow>> listAllByGroup(String groupId) =>
      _allByGroup(groupId).get();

  /// Like [listAllByGroup], live.
  Stream<List<MemberRow>> watchAllByGroup(String groupId) =>
      _allByGroup(groupId).watch();

  SimpleSelectStatement<$MembersTable, MemberRow> _allByGroup(String groupId) =>
      select(members)
        ..where((m) => m.groupId.equals(groupId))
        ..orderBy([
          (m) => OrderingTerm.asc(m.position),
          (m) => OrderingTerm.asc(m.id),
        ]);

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

  /// Sets [canDrive]. Returns true if a live row changed.
  Future<bool> setCanDrive({
    required String id,
    required bool canDrive,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          members,
        )..where((m) => m.id.equals(id) & m.deletedAt.isNull())).write(
          MembersCompanion(
            canDrive: Value(canDrive),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }

  /// Sets or clears the account link of [id] (server-owned, so no
  /// `updatedAt`, no upload). Returns true if a row changed.
  Future<bool> setUserId(String id, String? userId) async {
    final n = await (update(members)..where((m) => m.id.equals(id))).write(
      MembersCompanion(userId: Value(userId)),
    );
    return n > 0;
  }

  /// Ids of the members already asked whether they drive (local only).
  Future<Set<String>> askedDriverPrompts() async => {
    for (final r in await select(localDriverPrompts).get()) r.memberId,
  };

  Future<void> markDriverPromptAsked(String memberId, String at) =>
      into(localDriverPrompts).insertOnConflictUpdate(
        LocalDriverPromptsCompanion.insert(memberId: memberId, askedAt: at),
      );

  /// Moves a live member to [position]. Returns true if a live row changed.
  Future<bool> setPosition({
    required String id,
    required int position,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          members,
        )..where((m) => m.id.equals(id) & m.deletedAt.isNull())).write(
          MembersCompanion(
            position: Value(position),
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

  /// Undoes [softDelete]. Returns true if a soft-deleted row was revived.
  Future<bool> restore({
    required String id,
    required String updatedAt,
  }) async {
    final n =
        await (update(
          members,
        )..where((r) => r.id.equals(id) & r.deletedAt.isNotNull())).write(
          MembersCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(updatedAt),
          ),
        );
    return n > 0;
  }
}
