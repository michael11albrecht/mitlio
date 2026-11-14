import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = openTestDb();
    await seedGroup(db);
  });
  tearDown(() => db.close());

  Future<void> insertDefault({String id = 'e1', DateTime? date}) =>
      db.expensesDao.insertExpense(
        newExpense(id, 'g1', date: date),
        [newPayer('g1', id, 'm1')],
        [
          newShare('g1', id, 'm1'),
          newShare('g1', id, 'm2'),
        ],
      );

  test('insert writes expense with payers and shares', () async {
    await insertDefault();
    final e = (await db.expensesDao.findById('e1'))!;
    expect(e.expense.amountCents, 1000);
    expect(e.expense.date.toUtc(), DateTime.utc(2026));
    expect(e.payers.map((p) => p.paidCents), [1000]);
    expect(e.shares.map((s) => s.memberId), ['m1', 'm2']);
    expect(await db.expensesDao.findById('nope'), isNull);
  });

  test('rolls back the expense when a share insert fails', () async {
    await expectLater(
      db.expensesDao.insertExpense(
        newExpense('e1', 'g1'),
        [newPayer('g1', 'e1', 'm1')],
        [
          newShare('g1', 'e1', 'm1'),
          newShare('g1', 'e1', 'ghost-member'), // FK violation
        ],
      ),
      throwsA(anything),
    );
    expect(await db.select(db.expenses).get(), isEmpty);
    expect(await db.select(db.expensePayers).get(), isEmpty);
    expect(await db.select(db.expenseShares).get(), isEmpty);
  });

  test('check constraint rejects amount <= 0', () async {
    await expectLater(
      db.expensesDao.insertExpense(newExpense('e1', 'g1', amount: 0), [], []),
      throwsA(anything),
    );
    expect(await db.select(db.expenses).get(), isEmpty);
  });

  test(
    'check constraints reject bad enum, payer and settlement values',
    () async {
      await expectLater(
        db
            .into(db.expenses)
            .insert(
              newExpense('e1', 'g1').copyWith(type: const Value('bogus')),
            ),
        throwsA(anything),
      );
      await db.expensesDao.insertExpense(newExpense('e2', 'g1'), [], []);
      await expectLater(
        db.into(db.expensePayers).insert(newPayer('g1', 'e2', 'm1', paid: 0)),
        throwsA(anything),
      );
      await expectLater(
        db.into(db.expenseShares).insert(newShare('g1', 'e2', 'm1', cents: -1)),
        throwsA(anything),
      );
    },
  );

  test('duplicate (expense, member) child rows are rejected', () async {
    await db.expensesDao.insertExpense(newExpense('e1', 'g1'), [], []);
    await expectLater(
      db.expensesDao.insertExpense(
        newExpense('e2', 'g1'),
        [newPayer('g1', 'e2', 'm1'), newPayer('g1', 'e2', 'm1')],
        [],
      ),
      throwsA(anything),
    );
    expect(await db.expensesDao.findById('e2'), isNull);
  });

  test('replaceExpense can remove and re-add the same member', () async {
    await insertDefault();
    Future<bool> replace(List<String> memberIds) =>
        db.expensesDao.replaceExpense(
          'e1',
          const ExpensesCompanion(updatedAt: Value('0002')),
          [newPayer('g1', 'e1', 'm1')],
          [for (final m in memberIds) newShare('g1', 'e1', m)],
        );

    expect(await replace(['m1']), isTrue);
    expect(
      (await db.expensesDao.findById('e1'))!.shares.map((s) => s.memberId),
      ['m1'],
    );
    expect(await replace(['m1', 'm2']), isTrue);
    expect(
      (await db.expensesDao.findById('e1'))!.shares.map((s) => s.memberId),
      ['m1', 'm2'],
    );
  });

  test('created_at keeps millisecond precision', () async {
    final at = DateTime.utc(2026, 5, 6, 7, 8, 9, 123);
    await db.expensesDao.insertExpense(
      newExpense('e1', 'g1').copyWith(createdAt: Value(at)),
      [],
      [],
    );
    final row = (await db.expensesDao.findById('e1'))!.expense;
    expect(row.createdAt.toUtc(), at);
    final raw = await db
        .customSelect('SELECT created_at FROM expenses')
        .getSingle();
    expect(raw.data['created_at'], '2026-05-06T07:08:09.123Z');
  });

  test('replaceExpense swaps root and children atomically', () async {
    await insertDefault();
    final ok = await db.expensesDao.replaceExpense(
      'e1',
      const ExpensesCompanion(
        title: Value('Lunch'),
        amountCents: Value(600),
        groupAmountCents: Value(600),
        updatedAt: Value('0002'),
      ),
      [newPayer('g1', 'e1', 'm2', paid: 600)],
      [newShare('g1', 'e1', 'm2', cents: 600)],
    );
    expect(ok, isTrue);
    final e = (await db.expensesDao.findById('e1'))!;
    expect(e.expense.title, 'Lunch');
    expect(e.payers.single.memberId, 'm2');
    expect(e.shares.single.shareCents, 600);
  });

  test(
    'replaceExpense rolls back everything when children are invalid',
    () async {
      await insertDefault();
      await expectLater(
        db.expensesDao.replaceExpense(
          'e1',
          const ExpensesCompanion(title: Value('Changed')),
          [newPayer('g1', 'e1', 'ghost')],
          [],
        ),
        throwsA(anything),
      );
      final e = (await db.expensesDao.findById('e1'))!;
      expect(e.expense.title, 'Dinner');
      expect(e.payers.single.paidCents, 1000);
      expect(e.shares, hasLength(2));
    },
  );

  test('replaceExpense returns false for missing or deleted expense', () async {
    expect(
      await db.expensesDao.replaceExpense(
        'nope',
        const ExpensesCompanion(),
        [],
        [],
      ),
      isFalse,
    );
    await insertDefault();
    await db.expensesDao.softDelete(
      id: 'e1',
      deletedAt: deletedAt,
      updatedAt: '0002',
    );
    expect(
      await db.expensesDao.replaceExpense(
        'e1',
        const ExpensesCompanion(),
        [],
        [],
      ),
      isFalse,
    );
  });

  test('soft delete hides expense from default queries', () async {
    await insertDefault();
    await insertDefault(id: 'e2', date: DateTime.utc(2026, 3));
    expect(
      (await db.expensesDao.listByGroup('g1')).map((e) => e.expense.id),
      ['e2', 'e1'],
    );

    expect(
      await db.expensesDao.softDelete(
        id: 'e1',
        deletedAt: deletedAt,
        updatedAt: '0002',
      ),
      isTrue,
    );
    expect(
      await db.expensesDao.softDelete(
        id: 'e1',
        deletedAt: deletedAt,
        updatedAt: '0003',
      ),
      isFalse,
    );
    expect(await db.expensesDao.findById('e1'), isNull);
    expect(
      (await db.expensesDao.listByGroup('g1')).map((e) => e.expense.id),
      ['e2'],
    );
    expect(await db.expensesDao.watchByGroup('g1').first, hasLength(1));
    expect(await db.select(db.expenses).get(), hasLength(2));
    expect(await db.select(db.expenseShares).get(), hasLength(4));
  });
}
