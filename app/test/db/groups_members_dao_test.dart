import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/db/app_database.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  group('GroupsDao', () {
    test('insert, find, list, update', () async {
      await db.groupsDao.insertGroup(newGroup('g1'));
      await db.groupsDao.insertGroup(newGroup('g2', name: 'Flat'));

      expect((await db.groupsDao.findById('g1'))!.name, 'Trip');
      expect(await db.groupsDao.findById('nope'), isNull);
      expect(await db.groupsDao.listGroups(), hasLength(2));

      expect(
        await db.groupsDao.updateGroup(
          id: 'g1',
          name: 'Ski',
          updatedAt: '0002',
        ),
        isTrue,
      );
      final g = (await db.groupsDao.findById('g1'))!;
      expect(g.name, 'Ski');
      expect(g.updatedAt, '0002');
      expect(
        await db.groupsDao.updateGroup(id: 'x', name: 'a', updatedAt: '3'),
        isFalse,
      );
    });

    test('soft delete hides the row but keeps it stored', () async {
      await db.groupsDao.insertGroup(newGroup('g1'));
      expect(
        await db.groupsDao.softDelete(
          id: 'g1',
          deletedAt: deletedAt,
          updatedAt: '0002',
        ),
        isTrue,
      );
      expect(await db.groupsDao.findById('g1'), isNull);
      expect(await db.groupsDao.listGroups(), isEmpty);
      expect(await db.select(db.groups).get(), hasLength(1));
      // Already deleted: no-op, and updates do not resurrect it.
      expect(
        await db.groupsDao.softDelete(
          id: 'g1',
          deletedAt: deletedAt,
          updatedAt: '0003',
        ),
        isFalse,
      );
      expect(
        await db.groupsDao.updateGroup(id: 'g1', name: 'z', updatedAt: '4'),
        isFalse,
      );
    });

    test('watchGroups emits on change', () async {
      final stream = db.groupsDao.watchGroups();
      final future = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      await db.groupsDao.insertGroup(newGroup('g1'));
      await future;
    });
  });

  group('MembersDao', () {
    setUp(() => db.groupsDao.insertGroup(newGroup('g1')));

    test('insert, find, list ordered by position, update', () async {
      await db.membersDao.insertMember(newMember('m2', 'g1', position: 1));
      await db.membersDao.insertMember(newMember('m1', 'g1'));

      final list = await db.membersDao.listByGroup('g1');
      expect(list.map((m) => m.id), ['m1', 'm2']);
      expect((await db.membersDao.findById('m1'))!.paypalMe, isNull);
      expect(await db.membersDao.findById('x'), isNull);

      expect(
        await db.membersDao.updateMember(
          id: 'm1',
          name: 'Ann',
          position: 2,
          updatedAt: '0002',
          paypalMe: 'ann',
          ibanHint: '…1234',
        ),
        isTrue,
      );
      final m = (await db.membersDao.findById('m1'))!;
      expect(
        [m.name, m.position, m.paypalMe, m.ibanHint],
        [
          'Ann',
          2,
          'ann',
          '…1234',
        ],
      );
      expect(
        (await db.membersDao.listByGroup('g1')).map((m) => m.id),
        ['m2', 'm1'],
      );
      expect(
        await db.membersDao.updateMember(
          id: 'x',
          name: 'a',
          position: 0,
          updatedAt: '3',
        ),
        isFalse,
      );
    });

    test('list is scoped to group and excludes soft deleted', () async {
      await db.groupsDao.insertGroup(newGroup('g2'));
      await db.membersDao.insertMember(newMember('m1', 'g1'));
      await db.membersDao.insertMember(newMember('m2', 'g1', position: 1));
      await db.membersDao.insertMember(newMember('m3', 'g2'));

      expect(
        await db.membersDao.softDelete(
          id: 'm2',
          deletedAt: deletedAt,
          updatedAt: '0002',
        ),
        isTrue,
      );
      expect(
        await db.membersDao.softDelete(
          id: 'm2',
          deletedAt: deletedAt,
          updatedAt: '0003',
        ),
        isFalse,
      );
      expect((await db.membersDao.listByGroup('g1')).map((m) => m.id), ['m1']);
      expect(await db.membersDao.findById('m2'), isNull);
      expect(await db.select(db.members).get(), hasLength(3));
      expect(await db.membersDao.watchByGroup('g1').first, hasLength(1));
    });

    test('foreign keys are enforced', () async {
      await expectLater(
        db.membersDao.insertMember(newMember('m9', 'missing-group')),
        throwsA(anything),
      );
      final pragma = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(pragma.data.values.single, 1);
    });
  });
}
