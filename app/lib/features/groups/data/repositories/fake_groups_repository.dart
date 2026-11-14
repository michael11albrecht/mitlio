import 'dart:async';

import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [GroupsRepository] with the same behaviour as the Drift one.
class FakeGroupsRepository implements GroupsRepository {
  FakeGroupsRepository({required this._clock, required this._ids});

  final Clock _clock;
  final IdGenerator _ids;
  final _groups = <String, Group>{};
  final _deleted = <String>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  @override
  Stream<List<Group>> watchGroups() => watchSnapshots(
    _changes.stream,
    () =>
        [
          for (final g in _groups.values)
            if (!_deleted.contains(g.id)) g,
        ]..sort((a, b) {
          final byTime = a.createdAt.compareTo(b.createdAt);
          return byTime != 0 ? byTime : a.id.compareTo(b.id);
        }),
  );

  Group? _live(String id) => _deleted.contains(id) ? null : _groups[id];

  @override
  Future<RepoResult<Group>> get(String id) async {
    final g = _live(id);
    return g == null ? Err(NotFound('group', id)) : Ok(g);
  }

  @override
  Future<RepoResult<Group>> create({
    required String name,
    required Currency currency,
    required String createdBy,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    final group = Group(
      id: _ids.newId(),
      name: trimmed,
      currency: currency,
      createdBy: createdBy,
      createdAt: _clock.now().toUtc(),
    );
    _groups[group.id] = group;
    _changes.add(null);
    return Ok(group);
  }

  @override
  Future<RepoResult<Group>> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    final g = _live(id);
    if (g == null) return Err(NotFound('group', id));
    final renamed = Group(
      id: g.id,
      name: trimmed,
      currency: g.currency,
      createdBy: g.createdBy,
      createdAt: g.createdAt,
    );
    _groups[id] = renamed;
    _changes.add(null);
    return Ok(renamed);
  }

  @override
  Future<RepoResult<Undo>> softDelete(String id) async {
    if (_live(id) == null) return Err(NotFound('group', id));
    _deleted.add(id);
    _changes.add(null);
    return Ok(Undo(() => restore(id)));
  }

  @override
  Future<RepoResult<void>> restore(String id) async {
    if (!_groups.containsKey(id)) return Err(NotFound('group', id));
    if (!_deleted.remove(id)) {
      return const Err(Conflict('group is not deleted'));
    }
    _changes.add(null);
    return const Ok(null);
  }
}
