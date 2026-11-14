import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/groups_dao.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// [GroupsRepository] backed by Drift.
class DriftGroupsRepository implements GroupsRepository {
  DriftGroupsRepository({
    required AppDatabase db,
    required this._clock,
    required this._ids,
  }) : _dao = db.groupsDao;

  final GroupsDao _dao;
  final Clock _clock;
  final IdGenerator _ids;

  RepoResult<Group> _map(GroupRow row) {
    final currency = Currency.tryParse(row.currency);
    if (currency == null) {
      return Err(
        InvalidData('group ${row.id}: unknown currency ${row.currency}'),
      );
    }
    return Ok(
      Group(
        id: row.id,
        name: row.name,
        currency: currency,
        createdBy: row.createdBy,
        createdAt: row.createdAt.toUtc(),
      ),
    );
  }

  @override
  Stream<List<Group>> watchGroups() => _dao.watchGroups().map(
    (rows) => List.unmodifiable(
      rows.map((r) => _map(r).orThrow()).toList()..sort(
        (a, b) {
          final byTime = a.createdAt.compareTo(b.createdAt);
          return byTime != 0 ? byTime : a.id.compareTo(b.id);
        },
      ),
    ),
  );

  @override
  Future<RepoResult<Group>> get(String id) => guardStorage(() async {
    final row = await _dao.findById(id);
    return row == null ? Err(NotFound('group', id)) : _map(row);
  });

  @override
  Future<RepoResult<Group>> create({
    required String name,
    required Currency currency,
    required String createdBy,
  }) => guardStorage(() async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    final id = _ids.newId();
    await _dao.insertGroup(
      GroupsCompanion.insert(
        id: id,
        name: trimmed,
        currency: currency.code,
        createdBy: createdBy,
        createdAt: _clock.now().toUtc(),
        updatedAt: Hlc.now(_clock),
      ),
    );
    return get(id);
  });

  @override
  Future<RepoResult<Group>> rename(String id, String name) =>
      guardStorage(() async {
        final trimmed = name.trim();
        if (trimmed.isEmpty) {
          return const Err(InvalidData('name must not be empty'));
        }
        final ok = await _dao.updateGroup(
          id: id,
          name: trimmed,
          updatedAt: Hlc.now(_clock),
        );
        return ok ? get(id) : Err(NotFound('group', id));
      });

  @override
  Future<RepoResult<Undo>> softDelete(String id) => guardStorage(() async {
    final ok = await _dao.softDelete(
      id: id,
      deletedAt: _clock.now().toUtc(),
      updatedAt: Hlc.now(_clock),
    );
    return ok ? Ok(Undo(() => restore(id))) : Err(NotFound('group', id));
  });

  @override
  Future<RepoResult<void>> restore(String id) => guardStorage(() async {
    final ok = await _dao.restore(id: id, updatedAt: Hlc.now(_clock));
    if (ok) return const Ok(null);
    final live = await _dao.findById(id);
    return live != null
        ? const Err(Conflict('group is not deleted'))
        : Err(NotFound('group', id));
  });
}
