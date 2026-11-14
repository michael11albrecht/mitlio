import 'dart:async';

import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [SettlementsRepository] with the same behaviour as the Drift
/// one. Group and member lookups go through the given fakes.
class FakeSettlementsRepository implements SettlementsRepository {
  FakeSettlementsRepository({
    required this._groups,
    required this._members,
    required this._clock,
    required this._ids,
  });

  final GroupsRepository _groups;
  final MembersRepository _members;
  final Clock _clock;
  final IdGenerator _ids;
  final _entries = <String, SettlementEntry>{};
  final _deleted = <String>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  SettlementEntry? _live(String id) =>
      _deleted.contains(id) ? null : _entries[id];

  Future<List<Member>> _domainMembers(
    String groupId, {
    required bool includeDeleted,
  }) async => switch (await _members.list(
    groupId,
    includeDeleted: includeDeleted,
  )) {
    Ok<List<GroupMember>, RepositoryError>(:final value) => [
      for (final m in value) m.toDomain(),
    ],
    Err<List<GroupMember>, RepositoryError>() => const <Member>[],
  };

  @override
  Stream<List<SettlementEntry>> watchSettlements(String groupId) =>
      watchSnapshots(
        _changes.stream,
        () =>
            [
              for (final e in _entries.values)
                if (e.groupId == groupId && !_deleted.contains(e.settlement.id))
                  e,
            ]..sort((a, b) {
              final byDate = a.settlement.date.compareTo(b.settlement.date);
              return byDate != 0
                  ? byDate
                  : a.settlement.id.compareTo(b.settlement.id);
            }),
      );

  @override
  Future<RepoResult<SettlementEntry>> get(String id) async {
    final e = _live(id);
    return e == null ? Err(NotFound('settlement', id)) : Ok(e);
  }

  @override
  Future<RepoResult<SettlementEntry>> create(
    String groupId,
    SettlementDraft draft,
  ) async {
    final group = switch (await _groups.get(groupId)) {
      Ok<Group, RepositoryError>(:final value) => value,
      Err<Group, RepositoryError>() => null,
    };
    if (group == null) return Err(NotFound('group', groupId));
    final id = _ids.newId();
    final built = buildSettlement(
      id: id,
      fromId: draft.fromId,
      toId: draft.toId,
      amountCents: draft.amountCents,
      currency: draft.currency,
      date: draft.date,
      groupCurrency: group.currency,
      members: await _domainMembers(groupId, includeDeleted: false),
    );
    final Settlement settlement;
    switch (built) {
      case Err<Settlement, RepositoryError>(:final error):
        return Err(error);
      case Ok<Settlement, RepositoryError>(:final value):
        settlement = value;
    }
    final entry = SettlementEntry(
      groupId: groupId,
      settlement: settlement,
      method: draft.method,
      createdAt: _clock.now().toUtc(),
    );
    _entries[id] = entry;
    _changes.add(null);
    return Ok(entry);
  }

  @override
  Future<RepoResult<SettlementEntry>> update(
    String id, {
    required int amountCents,
    required SettlementMethod method,
    required DateTime date,
  }) async {
    final current = _live(id);
    if (current == null) return Err(NotFound('settlement', id));
    final s = current.settlement;
    final built = buildSettlement(
      id: id,
      fromId: s.fromId,
      toId: s.toId,
      amountCents: amountCents,
      currency: s.currency,
      date: date,
      groupCurrency: s.currency,
      members: await _domainMembers(current.groupId, includeDeleted: true),
    );
    final Settlement settlement;
    switch (built) {
      case Err<Settlement, RepositoryError>(:final error):
        return Err(error);
      case Ok<Settlement, RepositoryError>(:final value):
        settlement = value;
    }
    final entry = SettlementEntry(
      groupId: current.groupId,
      settlement: settlement,
      method: method,
      createdAt: current.createdAt,
    );
    _entries[id] = entry;
    _changes.add(null);
    return Ok(entry);
  }

  @override
  Future<RepoResult<Undo>> softDelete(String id) async {
    if (_live(id) == null) return Err(NotFound('settlement', id));
    _deleted.add(id);
    _changes.add(null);
    return Ok(Undo(() => restore(id)));
  }

  @override
  Future<RepoResult<void>> restore(String id) async {
    if (!_entries.containsKey(id)) return Err(NotFound('settlement', id));
    if (!_deleted.remove(id)) {
      return const Err(Conflict('settlement is not deleted'));
    }
    _changes.add(null);
    return const Ok(null);
  }
}
