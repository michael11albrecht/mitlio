import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// [MembersRepository] backed by Drift.
class DriftMembersRepository implements MembersRepository {
  DriftMembersRepository({
    required this._db,
    required this._clock,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  static GroupMember _map(MemberRow r) => GroupMember(
    id: r.id,
    groupId: r.groupId,
    name: r.name,
    position: r.position,
    paypalMe: r.paypalMe,
    ibanHint: r.ibanHint,
  );

  @override
  Stream<List<GroupMember>> watchMembers(String groupId) => _db.membersDao
      .watchByGroup(groupId)
      .map((rows) => List.unmodifiable(rows.map(_map)));

  @override
  Future<RepoResult<List<GroupMember>>> list(
    String groupId, {
    bool includeDeleted = false,
  }) => guardStorage(() async {
    final rows = includeDeleted
        ? await _db.membersDao.listAllByGroup(groupId)
        : await _db.membersDao.listByGroup(groupId);
    return Ok(List.unmodifiable(rows.map(_map)));
  });

  Future<RepoResult<GroupMember>> _get(String id) async {
    final row = await _db.membersDao.findById(id);
    return row == null ? Err(NotFound('member', id)) : Ok(_map(row));
  }

  @override
  Future<RepoResult<GroupMember>> add(
    String groupId, {
    required String name,
    String? paypalMe,
    String? ibanHint,
  }) => guardStorage(() async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    if (await _db.groupsDao.findById(groupId) == null) {
      return Err(NotFound('group', groupId));
    }
    final existing = await _db.membersDao.listAllByGroup(groupId);
    final position = existing.isEmpty ? 0 : existing.last.position + 1;
    final id = _ids.newId();
    await _db.membersDao.insertMember(
      MembersCompanion.insert(
        id: id,
        groupId: groupId,
        createdAt: _clock.now().toUtc(),
        updatedAt: Hlc.now(_clock),
        name: trimmed,
        position: position,
        paypalMe: Value(paypalMe),
        ibanHint: Value(ibanHint),
      ),
    );
    return _get(id);
  });

  @override
  Future<RepoResult<GroupMember>> update(
    String id, {
    required String name,
    String? paypalMe,
    String? ibanHint,
  }) => guardStorage(() async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    final current = await _db.membersDao.findById(id);
    if (current == null) return Err(NotFound('member', id));
    await _db.membersDao.updateMember(
      id: id,
      name: trimmed,
      position: current.position,
      paypalMe: paypalMe,
      ibanHint: ibanHint,
      updatedAt: Hlc.now(_clock),
    );
    return _get(id);
  });

  @override
  Future<RepoResult<Undo>> softDelete(String id) => guardStorage(() async {
    final ok = await _db.membersDao.softDelete(
      id: id,
      deletedAt: _clock.now().toUtc(),
      updatedAt: Hlc.now(_clock),
    );
    return ok ? Ok(Undo(() => restore(id))) : Err(NotFound('member', id));
  });

  @override
  Future<RepoResult<void>> restore(String id) => guardStorage(() async {
    final ok = await _db.membersDao.restore(id: id, updatedAt: Hlc.now(_clock));
    if (ok) return const Ok(null);
    return await _db.membersDao.findById(id) != null
        ? const Err(Conflict('member is not deleted'))
        : Err(NotFound('member', id));
  });
}
