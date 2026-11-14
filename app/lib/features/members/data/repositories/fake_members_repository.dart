import 'dart:async';

import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [MembersRepository] with the same behaviour as the Drift one.
/// Checks group existence through the groups repository, like the foreign
/// key in Drift.
class FakeMembersRepository implements MembersRepository {
  FakeMembersRepository({
    required this._groups,
    required this._ids,
  });

  final GroupsRepository _groups;
  final IdGenerator _ids;
  final _members = <String, GroupMember>{};
  final _deleted = <String>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  List<GroupMember> _of(String groupId, {required bool includeDeleted}) =>
      [
        for (final m in _members.values)
          if (m.groupId == groupId &&
              (includeDeleted || !_deleted.contains(m.id)))
            m,
      ]..sort((a, b) {
        final byPos = a.position.compareTo(b.position);
        return byPos != 0 ? byPos : a.id.compareTo(b.id);
      });

  GroupMember? _live(String id) => _deleted.contains(id) ? null : _members[id];

  @override
  Stream<List<GroupMember>> watchMembers(String groupId) => watchSnapshots(
    _changes.stream,
    () => _of(groupId, includeDeleted: false),
  );

  @override
  Future<RepoResult<List<GroupMember>>> list(
    String groupId, {
    bool includeDeleted = false,
  }) async =>
      Ok(List.unmodifiable(_of(groupId, includeDeleted: includeDeleted)));

  @override
  Future<RepoResult<GroupMember>> add(
    String groupId, {
    required String name,
    String? paypalMe,
    String? ibanHint,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    if (await _groups.get(groupId) is! Ok) {
      return Err(NotFound('group', groupId));
    }
    final existing = _of(groupId, includeDeleted: true);
    final member = GroupMember(
      id: _ids.newId(),
      groupId: groupId,
      name: trimmed,
      position: existing.isEmpty ? 0 : existing.last.position + 1,
      paypalMe: paypalMe,
      ibanHint: ibanHint,
    );
    _members[member.id] = member;
    _changes.add(null);
    return Ok(member);
  }

  @override
  Future<RepoResult<GroupMember>> update(
    String id, {
    required String name,
    String? paypalMe,
    String? ibanHint,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    final m = _live(id);
    if (m == null) return Err(NotFound('member', id));
    final updated = GroupMember(
      id: id,
      groupId: m.groupId,
      name: trimmed,
      position: m.position,
      paypalMe: paypalMe,
      ibanHint: ibanHint,
    );
    _members[id] = updated;
    _changes.add(null);
    return Ok(updated);
  }

  @override
  Future<RepoResult<Undo>> softDelete(String id) async {
    if (_live(id) == null) return Err(NotFound('member', id));
    _deleted.add(id);
    _changes.add(null);
    return Ok(Undo(() => restore(id)));
  }

  @override
  Future<RepoResult<void>> restore(String id) async {
    if (!_members.containsKey(id)) return Err(NotFound('member', id));
    if (!_deleted.remove(id)) {
      return const Err(Conflict('member is not deleted'));
    }
    _changes.add(null);
    return const Ok(null);
  }
}
