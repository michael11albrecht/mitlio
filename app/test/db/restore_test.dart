import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = openTestDb();
    await seedGroup(db);
    await db.expensesDao.insertExpense(
      newExpense('e1', 'g1'),
      [newPayer('g1', 'e1', 'm1')],
      [newShare('g1', 'e1', 'm1'), newShare('g1', 'e1', 'm2')],
    );
    await db.settlementsDao.insertSettlement(
      newSettlement('s1', 'g1', 'm1', 'm2'),
    );
  });
  tearDown(() => db.close());

  test('restore revives only soft-deleted rows', () async {
    const hlc2 = '0002';
    expect(await db.groupsDao.restore(id: 'g1', updatedAt: hlc2), isFalse);
    await db.groupsDao.softDelete(
      id: 'g1',
      deletedAt: deletedAt,
      updatedAt: hlc2,
    );
    expect(await db.groupsDao.findById('g1'), isNull);
    expect(await db.groupsDao.restore(id: 'g1', updatedAt: '0003'), isTrue);
    expect((await db.groupsDao.findById('g1'))!.updatedAt, '0003');

    await db.membersDao.softDelete(
      id: 'm1',
      deletedAt: deletedAt,
      updatedAt: hlc2,
    );
    expect(await db.membersDao.restore(id: 'm1', updatedAt: '0003'), isTrue);
    expect(await db.membersDao.restore(id: 'm1', updatedAt: '0004'), isFalse);

    await db.expensesDao.softDelete(
      id: 'e1',
      deletedAt: deletedAt,
      updatedAt: hlc2,
    );
    expect(await db.expensesDao.restore(id: 'e1', updatedAt: '0003'), isTrue);
    expect((await db.expensesDao.findById('e1'))!.payers, hasLength(1));

    await db.settlementsDao.softDelete(
      id: 's1',
      deletedAt: deletedAt,
      updatedAt: hlc2,
    );
    expect(
      await db.settlementsDao.restore(id: 's1', updatedAt: '0003'),
      isTrue,
    );
  });

  test('listAllByGroup includes soft-deleted members', () async {
    await db.membersDao.softDelete(
      id: 'm1',
      deletedAt: deletedAt,
      updatedAt: '0002',
    );
    expect(await db.membersDao.listByGroup('g1'), hasLength(1));
    expect(await db.membersDao.listAllByGroup('g1'), hasLength(2));
  });
}
