import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/expenses_dao.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// [ExpensesRepository] backed by Drift. Aggregates are rebuilt through
/// `Expense.create` on every read.
class DriftExpensesRepository implements ExpensesRepository {
  DriftExpensesRepository({
    required this._db,
    required this._clock,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  ExpensesDao get _dao => _db.expensesDao;

  static const _unitFxPpm = 1000000;

  /// Rebuilds the aggregate. Shares are replayed as an exact split of the
  /// stored cents (so later member re-ordering cannot change history); the
  /// stored weights only feed [ExpenseEntry.split].
  RepoResult<ExpenseEntry> _map(
    ExpenseWithChildren stored,
    List<Member> members,
  ) {
    final row = stored.expense;
    final currency = Currency.tryParse(row.currency);
    if (currency == null) {
      return Err(
        InvalidData('expense ${row.id}: unknown currency ${row.currency}'),
      );
    }
    final split = splitFromWeights(row.splitMode, {
      for (final s in stored.shares) s.memberId: s.weight,
    });
    if (split == null) {
      return Err(
        InvalidData('expense ${row.id}: unknown split mode ${row.splitMode}'),
      );
    }
    final result = Expense.create(
      id: row.id,
      title: row.title,
      amountCents: row.amountCents,
      currency: currency,
      date: row.date.toUtc(),
      payers: {for (final p in stored.payers) p.memberId: p.paidCents},
      split: ExactSplit({
        for (final s in stored.shares) s.memberId: s.shareCents,
      }),
      members: members,
    );
    return switch (result) {
      Ok<Expense, ExpenseError>(:final value) => Ok(
        ExpenseEntry(
          groupId: row.groupId,
          expense: value,
          split: split,
          category: row.category,
          tripMeta: row.tripMeta,
          createdAt: row.createdAt.toUtc(),
        ),
      ),
      Err<Expense, ExpenseError>(:final error) => Err(
        InvalidData('expense ${row.id}: $error'),
      ),
    };
  }

  Future<List<Member>> _allMembers(String groupId) async => [
    for (final m in await _db.membersDao.listAllByGroup(groupId))
      Member(id: m.id, position: m.position),
  ];

  Future<RepoResult<ExpenseEntry>> _load(String id) async {
    final stored = await _dao.findById(id);
    if (stored == null) return Err(NotFound('expense', id));
    return _map(stored, await _allMembers(stored.expense.groupId));
  }

  @override
  Stream<List<ExpenseEntry>> watchExpenses(String groupId) =>
      _dao.watchByGroup(groupId).asyncMap((_) async {
        final members = await _allMembers(groupId);
        return List<ExpenseEntry>.unmodifiable([
          for (final stored in await _dao.listByGroup(groupId))
            _map(stored, members).orThrow(),
        ]);
      });

  @override
  Future<RepoResult<ExpenseEntry>> get(String id) =>
      guardStorage(() => _load(id));

  /// Validates [draft] against the live members of [groupId] and builds the
  /// companions to persist.
  Future<
    RepoResult<
      ({
        ExpensesCompanion root,
        List<ExpensePayersCompanion> payers,
        List<ExpenseSharesCompanion> shares,
      })
    >
  >
  _prepare(String groupId, String id, ExpenseDraft draft) async {
    final group = await _db.groupsDao.findById(groupId);
    if (group == null) return Err(NotFound('group', groupId));
    final groupCurrency = Currency.tryParse(group.currency);
    if (groupCurrency == null) {
      return Err(
        InvalidData('group $groupId: unknown currency ${group.currency}'),
      );
    }
    final members = await _db.membersDao.listByGroup(groupId);
    final built = buildExpense(
      id: id,
      draft: draft,
      groupCurrency: groupCurrency,
      members: [
        for (final m in members) Member(id: m.id, position: m.position),
      ],
    );
    final Expense expense;
    switch (built) {
      case Err<Expense, RepositoryError>(:final error):
        return Err(error);
      case Ok<Expense, RepositoryError>(:final value):
        expense = value;
    }
    return Ok((
      root: ExpensesCompanion(
        title: Value(expense.title),
        amountCents: Value(expense.amountCents),
        currency: Value(expense.currency.code),
        fxRatePpm: const Value(_unitFxPpm),
        groupAmountCents: Value(expense.amountCents),
        date: Value(expense.date),
        category: Value(draft.category),
        type: Value(draft.tripMeta == null ? 'regular' : 'trip'),
        tripMeta: Value(draft.tripMeta),
        splitMode: Value(splitModeOf(draft.split)),
        updatedAt: Value(Hlc.now(_clock)),
      ),
      payers: [
        for (final p in expense.payers.entries)
          ExpensePayersCompanion.insert(
            groupId: groupId,
            expenseId: id,
            memberId: p.key,
            paidCents: p.value,
          ),
      ],
      shares: [
        for (final s in expense.shares.entries)
          ExpenseSharesCompanion.insert(
            groupId: groupId,
            expenseId: id,
            memberId: s.key,
            shareCents: s.value,
            weight: splitWeightOf(draft.split, s.key),
          ),
      ],
    ));
  }

  @override
  Future<RepoResult<ExpenseEntry>> create(String groupId, ExpenseDraft draft) =>
      guardStorage(() async {
        final id = _ids.newId();
        final prepared = await _prepare(groupId, id, draft);
        switch (prepared) {
          case Err<dynamic, RepositoryError>(:final error):
            return Err(error);
          case Ok(:final value):
            await _dao.insertExpense(
              value.root.copyWith(
                id: Value(id),
                groupId: Value(groupId),
                createdAt: Value(_clock.now().toUtc()),
              ),
              value.payers,
              value.shares,
            );
            return _load(id);
        }
      });

  @override
  Future<RepoResult<ExpenseEntry>> update(String id, ExpenseDraft draft) =>
      guardStorage(() async {
        final current = await _dao.findById(id);
        if (current == null) return Err(NotFound('expense', id));
        final prepared = await _prepare(current.expense.groupId, id, draft);
        switch (prepared) {
          case Err<dynamic, RepositoryError>(:final error):
            return Err(error);
          case Ok(:final value):
            await _dao.replaceExpense(
              id,
              value.root,
              value.payers,
              value.shares,
            );
            return _load(id);
        }
      });

  @override
  Future<RepoResult<Undo>> softDelete(String id) => guardStorage(() async {
    final ok = await _dao.softDelete(
      id: id,
      deletedAt: _clock.now().toUtc(),
      updatedAt: Hlc.now(_clock),
    );
    return ok ? Ok(Undo(() => restore(id))) : Err(NotFound('expense', id));
  });

  @override
  Future<RepoResult<void>> restore(String id) => guardStorage(() async {
    final ok = await _dao.restore(id: id, updatedAt: Hlc.now(_clock));
    if (ok) return const Ok(null);
    return await _dao.findById(id) != null
        ? const Err(Conflict('expense is not deleted'))
        : Err(NotFound('expense', id));
  });
}
