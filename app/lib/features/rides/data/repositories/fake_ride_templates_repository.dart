import 'dart:async';

import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_rides_refs.dart';
import 'package:mitlio/features/rides/data/repositories/ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [RideTemplatesRepository] with the same behaviour as the Drift
/// one. Group, member and vehicle lookups go through the given fakes.
class FakeRideTemplatesRepository implements RideTemplatesRepository {
  FakeRideTemplatesRepository({
    required this._groups,
    required this._members,
    required this._vehicles,
    required this._ids,
  });

  final GroupsRepository _groups;
  final MembersRepository _members;
  final VehiclesRepository _vehicles;
  final IdGenerator _ids;

  /// Insertion order equals creation order.
  final _templates = <String, RideTemplate>{};
  final _groupOf = <String, String>{};
  final _deleted = <String>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  RideTemplate? _live(String id) =>
      _deleted.contains(id) ? null : _templates[id];

  Iterable<String> _memberIds(RideTemplate t) => [
    ...?(t.defaultDriverId == null ? null : [t.defaultDriverId!]),
    ...t.defaultPassengerIds,
  ];

  @override
  Stream<List<RideTemplate>> watchTemplates(String groupId) => watchSnapshots(
    _changes.stream,
    () => [
      for (final t in _templates.values)
        if (_groupOf[t.id] == groupId && !_deleted.contains(t.id)) t,
    ],
  );

  @override
  Future<RepoResult<RideTemplate>> get(String id) async {
    final t = _live(id);
    return t == null ? Err(NotFound('ride template', id)) : Ok(t);
  }

  @override
  Future<RepoResult<RideTemplate>> add(
    String groupId,
    RideTemplate template,
  ) async {
    final id = _ids.newId();
    final built = buildTemplate(id, template);
    if (built case Err<RideTemplate, RepositoryError>(:final error)) {
      return Err(error);
    }
    final t = built.orThrow();
    final missing = await fakeMissingRef(
      groups: _groups,
      members: _members,
      vehicles: _vehicles,
      groupId: groupId,
      vehicleId: t.vehicleId,
      memberIds: _memberIds(t),
    );
    if (missing != null) return Err(missing);
    _templates[id] = t;
    _groupOf[id] = groupId;
    _changes.add(null);
    return Ok(t);
  }

  @override
  Future<RepoResult<RideTemplate>> update(RideTemplate template) async {
    final built = buildTemplate(template.id, template);
    if (built case Err<RideTemplate, RepositoryError>(:final error)) {
      return Err(error);
    }
    final t = built.orThrow();
    if (_live(t.id) == null) return Err(NotFound('ride template', t.id));
    final missing = await fakeMissingRef(
      groups: _groups,
      members: _members,
      vehicles: _vehicles,
      groupId: _groupOf[t.id]!,
      vehicleId: t.vehicleId,
      memberIds: _memberIds(t),
    );
    if (missing != null) return Err(missing);
    _templates[t.id] = t;
    _changes.add(null);
    return Ok(t);
  }

  @override
  Future<RepoResult<Undo>> softDelete(String id) async {
    if (_live(id) == null) return Err(NotFound('ride template', id));
    _deleted.add(id);
    _changes.add(null);
    return Ok(Undo(() => restore(id)));
  }

  @override
  Future<RepoResult<void>> restore(String id) async {
    if (!_templates.containsKey(id)) return Err(NotFound('ride template', id));
    if (!_deleted.remove(id)) {
      return const Err(Conflict('ride template is not deleted'));
    }
    _changes.add(null);
    return const Ok(null);
  }
}
