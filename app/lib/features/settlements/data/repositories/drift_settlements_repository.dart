import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// [SettlementsRepository] backed by Drift. Values are rebuilt through
/// `Settlement.create` on every read.
class DriftSettlementsRepository implements SettlementsRepository {
  DriftSettlementsRepository({
    required this._db,
    required this._clock,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  Future<List<Member>> _members(String groupId) async => [
    for (final m in await _db.membersDao.listAllByGroup(groupId))
      Member(id: m.id, position: m.position),
  ];

  RepoResult<SettlementEntry> _map(SettlementRow row, List<Member> members) {
    final currency = Currency.tryParse(row.currency);
    final method = SettlementMethod.tryParse(row.method);
    if (currency == null || method == null) {
      return Err(
        InvalidData(
          'settlement ${row.id}: bad currency ${row.currency} '
          'or method ${row.method}',
        ),
      );
    }
    final built = buildSettlement(
      id: row.id,
      fromId: row.fromMember,
      toId: row.toMember,
      amountCents: row.amountCents,
      currency: currency,
      date: row.date,
      groupCurrency: currency,
      members: members,
    );
    return switch (built) {
      Ok<Settlement, RepositoryError>(:final value) => Ok(
        SettlementEntry(
          groupId: row.groupId,
          settlement: value,
          method: method,
          createdAt: row.createdAt.toUtc(),
        ),
      ),
      Err<Settlement, RepositoryError>(:final error) => Err(
        InvalidData('settlement ${row.id}: $error'),
      ),
    };
  }

  @override
  Stream<List<SettlementEntry>> watchSettlements(String groupId) =>
      _db.settlementsDao.watchByGroup(groupId).asyncMap((rows) async {
        final members = await _members(groupId);
        return List<SettlementEntry>.unmodifiable([
          for (final r in rows) _map(r, members).orThrow(),
        ]);
      });

  Future<RepoResult<SettlementEntry>> _load(String id) async {
    final row = await _db.settlementsDao.findById(id);
    if (row == null) return Err(NotFound('settlement', id));
    return _map(row, await _members(row.groupId));
  }

  @override
  Future<RepoResult<SettlementEntry>> get(String id) =>
      guardStorage(() => _load(id));

  @override
  Future<RepoResult<SettlementEntry>> create(
    String groupId,
    SettlementDraft draft,
  ) => guardStorage(() async {
    final group = await _db.groupsDao.findById(groupId);
    if (group == null) return Err(NotFound('group', groupId));
    final groupCurrency = Currency.tryParse(group.currency);
    if (groupCurrency == null) {
      return Err(
        InvalidData('group $groupId: unknown currency ${group.currency}'),
      );
    }
    final id = _ids.newId();
    final built = buildSettlement(
      id: id,
      fromId: draft.fromId,
      toId: draft.toId,
      amountCents: draft.amountCents,
      currency: draft.currency,
      date: draft.date,
      groupCurrency: groupCurrency,
      members: [
        for (final m in await _db.membersDao.listByGroup(groupId))
          Member(id: m.id, position: m.position),
      ],
    );
    if (built case Err<Settlement, RepositoryError>(:final error)) {
      return Err(error);
    }
    await _db.settlementsDao.insertSettlement(
      SettlementsCompanion.insert(
        id: id,
        groupId: groupId,
        createdAt: _clock.now().toUtc(),
        updatedAt: Hlc.now(_clock),
        fromMember: draft.fromId,
        toMember: draft.toId,
        amountCents: draft.amountCents,
        currency: draft.currency.code,
        date: draft.date.toUtc(),
        method: draft.method.name,
      ),
    );
    return _load(id);
  });

  @override
  Future<RepoResult<SettlementEntry>> update(
    String id, {
    required int amountCents,
    required SettlementMethod method,
    required DateTime date,
  }) => guardStorage(() async {
    final current = await _load(id);
    final SettlementEntry entry;
    switch (current) {
      case Err<SettlementEntry, RepositoryError>(:final error):
        return Err(error);
      case Ok<SettlementEntry, RepositoryError>(:final value):
        entry = value;
    }
    final s = entry.settlement;
    final built = buildSettlement(
      id: id,
      fromId: s.fromId,
      toId: s.toId,
      amountCents: amountCents,
      currency: s.currency,
      date: date,
      groupCurrency: s.currency,
      members: await _members(entry.groupId),
    );
    if (built case Err<Settlement, RepositoryError>(:final error)) {
      return Err(error);
    }
    await _db.settlementsDao.updateSettlement(
      id: id,
      amountCents: amountCents,
      method: method.name,
      date: date.toUtc(),
      updatedAt: Hlc.now(_clock),
    );
    return _load(id);
  });

  @override
  Future<RepoResult<Undo>> softDelete(String id) => guardStorage(() async {
    final ok = await _db.settlementsDao.softDelete(
      id: id,
      deletedAt: _clock.now().toUtc(),
      updatedAt: Hlc.now(_clock),
    );
    return ok ? Ok(Undo(() => restore(id))) : Err(NotFound('settlement', id));
  });

  @override
  Future<RepoResult<void>> restore(String id) => guardStorage(() async {
    final ok = await _db.settlementsDao.restore(
      id: id,
      updatedAt: Hlc.now(_clock),
    );
    if (ok) return const Ok(null);
    return await _db.settlementsDao.findById(id) != null
        ? const Err(Conflict('settlement is not deleted'))
        : Err(NotFound('settlement', id));
  });
}
