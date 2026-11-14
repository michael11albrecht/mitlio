import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../db/test_support.dart' as raw;
import 'repo_test_support.dart';

/// Drift-only behaviour: corrupted rows and storage failures.
void main() {
  late Repos r;
  setUp(() async {
    r = await driftRepos();
    await raw.seedGroup(r.db!);
  });

  group('corrupted rows surface as errors', () {
    test('expense with payers not summing to the amount', () async {
      await r.db!.expensesDao.insertExpense(
        raw.newExpense('e1', 'g1'),
        [raw.newPayer('g1', 'e1', 'm1', paid: 400)],
        [raw.newShare('g1', 'e1', 'm1'), raw.newShare('g1', 'e1', 'm2')],
      );
      expect(err(await r.expenses.get('e1')), isA<InvalidData>());

      final probe = StreamProbe(r.expenses.watchExpenses('g1'));
      expect(await probe.nextError(), isA<InvalidData>());
    });

    test('expense with shares not summing to the amount', () async {
      await r.db!.expensesDao.insertExpense(
        raw.newExpense('e1', 'g1'),
        [raw.newPayer('g1', 'e1', 'm1')],
        [raw.newShare('g1', 'e1', 'm1', cents: 100)],
      );
      expect(err(await r.expenses.get('e1')), isA<InvalidData>());
    });

    test('expense with an unknown currency', () async {
      await r.db!.expensesDao.insertExpense(
        raw.newExpense('e1', 'g1').copyWith(currency: const Value('XXX')),
        [raw.newPayer('g1', 'e1', 'm1')],
        [raw.newShare('g1', 'e1', 'm1', cents: 1000)],
      );
      expect(err(await r.expenses.get('e1')), isA<InvalidData>());
    });

    test('settlement with an unknown currency', () async {
      await r.db!.settlementsDao.insertSettlement(
        raw
            .newSettlement('s1', 'g1', 'm1', 'm2')
            .copyWith(
              currency: const Value('XXX'),
            ),
      );
      expect(err(await r.settlements.get('s1')), isA<InvalidData>());
      final probe = StreamProbe(r.settlements.watchSettlements('g1'));
      expect(await probe.nextError(), isA<InvalidData>());
    });

    test('settlement referencing a member outside the group', () async {
      await r.db!.groupsDao.insertGroup(raw.newGroup('g2'));
      await r.db!.membersDao.insertMember(raw.newMember('m9', 'g2'));
      await r.db!.settlementsDao.insertSettlement(
        raw.newSettlement('s1', 'g1', 'm1', 'm9'),
      );
      expect(err(await r.settlements.get('s1')), isA<InvalidData>());
    });

    test('group with an unknown currency', () async {
      await r.db!.groupsDao.insertGroup(
        raw.newGroup('g2').copyWith(currency: const Value('XXX')),
      );
      expect(err(await r.groups.get('g2')), isA<InvalidData>());
      final probe = StreamProbe(r.groups.watchGroups());
      expect(await probe.nextError(), isA<InvalidData>());

      final draft = ExpenseDraft(
        title: 'x',
        amountCents: 100,
        currency: eur,
        date: DateTime.utc(2026),
        payers: {'m1': 100},
        split: EqualSplit({'m1'}),
      );
      expect(err(await r.expenses.create('g2', draft)), isA<InvalidData>());
      final settle = SettlementDraft(
        fromId: 'm1',
        toId: 'm2',
        amountCents: 100,
        currency: eur,
        date: DateTime.utc(2026),
        method: SettlementMethod.cash,
      );
      expect(err(await r.settlements.create('g2', settle)), isA<InvalidData>());
    });
  });

  test('storage failures come back as Storage, never thrown', () async {
    await r.db!.close();
    expect(err(await r.groups.get('g1')), isA<Storage>());
    expect(
      err(await r.members.add('g1', name: 'Ann')),
      isA<Storage>(),
    );
    expect(err(await r.expenses.get('e1')), isA<Storage>());
    expect(err(await r.settlements.get('s1')), isA<Storage>());
    expect(err(await r.groups.softDelete('g1')), isA<Storage>());
  });
}
