import 'package:drift/drift.dart' show Value;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/rides_dao.dart';
import 'package:mitlio/features/rides/data/repositories/drift_rides_refs.dart';
import 'package:mitlio/features/rides/data/repositories/ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_codec.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// [RideTemplatesRepository] backed by Drift.
class DriftRideTemplatesRepository implements RideTemplatesRepository {
  DriftRideTemplatesRepository({
    required AppDatabase db,
    required this._clock,
    required this._ids,
  }) : _db = db,
       _dao = db.ridesDao;

  final AppDatabase _db;
  final RidesDao _dao;
  final Clock _clock;
  final IdGenerator _ids;

  RepoResult<RideTemplate> _map(RideTemplateRow row) {
    final passengers = decodeIds(row.defaultPassengerIds);
    if (passengers == null) {
      return Err(InvalidData('template ${row.id}: bad passenger ids'));
    }
    return Ok(
      RideTemplate(
        id: row.id,
        name: row.name,
        distanceMeters: row.distanceMeters,
        vehicleId: row.vehicleId,
        roundTrip: row.roundTrip,
        defaultDriverId: row.defaultDriverId,
        defaultPassengerIds: Set.unmodifiable(passengers),
        tollsCents: row.tollsCents,
      ),
    );
  }

  @override
  Stream<List<RideTemplate>> watchTemplates(String groupId) => _dao
      .watchTemplates(groupId)
      .map(
        (rows) => List.unmodifiable([for (final r in rows) _map(r).orThrow()]),
      );

  @override
  Future<RepoResult<RideTemplate>> get(String id) => guardStorage(() async {
    final row = await _dao.findTemplate(id);
    return row == null ? Err(NotFound('ride template', id)) : _map(row);
  });

  Iterable<String> _members(RideTemplate t) => [
    ...?(t.defaultDriverId == null ? null : [t.defaultDriverId!]),
    ...t.defaultPassengerIds,
  ];

  @override
  Future<RepoResult<RideTemplate>> add(
    String groupId,
    RideTemplate template,
  ) => guardStorage(() async {
    final id = _ids.newId();
    final built = buildTemplate(id, template);
    if (built case Err<RideTemplate, RepositoryError>(:final error)) {
      return Err(error);
    }
    final t = built.orThrow();
    final missing = await missingRef(
      _db,
      groupId,
      vehicleId: t.vehicleId,
      memberIds: _members(t),
    );
    if (missing != null) return Err(missing);
    await _dao.insertTemplate(
      RideTemplatesCompanion.insert(
        id: id,
        groupId: groupId,
        createdAt: _clock.now().toUtc(),
        updatedAt: Hlc.now(_clock),
        name: t.name,
        distanceMeters: t.distanceMeters,
        vehicleId: t.vehicleId,
        roundTrip: Value(t.roundTrip),
        defaultDriverId: Value(t.defaultDriverId),
        defaultPassengerIds: Value(encodeIds(t.defaultPassengerIds)),
        tollsCents: Value(t.tollsCents),
      ),
    );
    return get(id);
  });

  @override
  Future<RepoResult<RideTemplate>> update(RideTemplate template) =>
      guardStorage(() async {
        final built = buildTemplate(template.id, template);
        if (built case Err<RideTemplate, RepositoryError>(:final error)) {
          return Err(error);
        }
        final t = built.orThrow();
        final row = await _dao.findTemplate(t.id);
        if (row == null) return Err(NotFound('ride template', t.id));
        final missing = await missingRef(
          _db,
          row.groupId,
          vehicleId: t.vehicleId,
          memberIds: _members(t),
        );
        if (missing != null) return Err(missing);
        await _dao.updateTemplate(
          t.id,
          RideTemplatesCompanion(
            name: Value(t.name),
            distanceMeters: Value(t.distanceMeters),
            vehicleId: Value(t.vehicleId),
            roundTrip: Value(t.roundTrip),
            defaultDriverId: Value(t.defaultDriverId),
            defaultPassengerIds: Value(encodeIds(t.defaultPassengerIds)),
            tollsCents: Value(t.tollsCents),
            updatedAt: Value(Hlc.now(_clock)),
          ),
        );
        return get(t.id);
      });

  @override
  Future<RepoResult<Undo>> softDelete(String id) => guardStorage(() async {
    final ok = await _dao.softDeleteTemplate(
      id,
      _clock.now().toUtc(),
      Hlc.now(_clock),
    );
    return ok
        ? Ok(Undo(() => restore(id)))
        : Err(NotFound('ride template', id));
  });

  @override
  Future<RepoResult<void>> restore(String id) => guardStorage(() async {
    if (await _dao.restoreTemplate(id, Hlc.now(_clock))) {
      return const Ok(null);
    }
    return await _dao.findTemplate(id) != null
        ? const Err(Conflict('ride template is not deleted'))
        : Err(NotFound('ride template', id));
  });
}
