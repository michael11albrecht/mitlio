import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late SyncStateDao dao;
  setUp(() async {
    db = openTestDb();
    dao = db.syncStateDao;
    await db.groupsDao.insertGroup(newGroup('g1'));
    await db.groupsDao.insertGroup(newGroup('g2'));
  });
  tearDown(() => db.close());

  final t1 = DateTime.utc(2026, 3);
  final t2 = DateTime.utc(2026, 3, 2);

  group('group sync state', () {
    test('no row means local only', () async {
      expect(await dao.groupSync('g1'), isNull);
    });

    test('transitions: uploading -> shared -> removed, role kept', () async {
      await dao.setState('g1', SyncState.uploading, role: SyncRole.owner);
      var row = (await dao.groupSync('g1'))!;
      expect((row.state, row.role), ('uploading', 'owner'));

      await dao.setState('g1', SyncState.shared);
      row = (await dao.groupSync('g1'))!;
      expect((row.state, row.role), ('shared', 'owner'));

      await dao.setState('g1', SyncState.removed);
      expect((await dao.groupSync('g1'))!.state, 'removed');
      expect(await dao.groupSync('g2'), isNull);
    });

    test('setRole updates an existing row and ignores a missing one', () async {
      await dao.setRole('g1', SyncRole.member);
      expect(await dao.groupSync('g1'), isNull);
      await dao.setState('g1', SyncState.shared);
      expect((await dao.groupSync('g1'))!.role, isNull);
      await dao.setRole('g1', SyncRole.member);
      expect((await dao.groupSync('g1'))!.role, 'member');
    });

    test('push and pull times are recorded independently', () async {
      await dao.setState('g1', SyncState.shared);
      await dao.markPushed('g1', t1);
      await dao.markPulled('g1', t2);
      final row = (await dao.groupSync('g1'))!;
      expect((row.lastPushAt, row.lastPullAt), (t1, t2));
    });

    test('an error is kept until the next push or state change', () async {
      await dao.setState('g1', SyncState.shared);
      await dao.recordError('g1', 'offline', t1);
      var row = (await dao.groupSync('g1'))!;
      expect((row.lastErrorCode, row.lastErrorAt), ('offline', t1));

      await dao.markPulled('g1', t2);
      row = (await dao.groupSync('g1'))!;
      expect(row.lastErrorCode, 'offline', reason: 'a pull does not clear it');

      await dao.markPushed('g1', t2);
      row = (await dao.groupSync('g1'))!;
      expect((row.lastErrorCode, row.lastErrorAt), (null, null));

      await dao.recordError('g1', 'offline', t1);
      await dao.setState('g1', SyncState.uploading);
      expect((await dao.groupSync('g1'))!.lastErrorCode, isNull);
    });

    test('clearError forgets the error and nothing else', () async {
      await dao.setState('g1', SyncState.shared);
      await dao.recordError('g1', 'offline', t1);
      await dao.clearError('g1');
      final row = (await dao.groupSync('g1'))!;
      expect((row.lastErrorCode, row.lastErrorAt), (null, null));
      expect(row.state, SyncState.shared.name);
    });

    test('watchGroupSync emits changes', () async {
      final states = <String?>[];
      final sub = dao.watchGroupSync('g1').listen((r) => states.add(r?.state));
      await pumpEventQueue();
      await dao.setState('g1', SyncState.shared);
      await pumpEventQueue();
      await sub.cancel();
      expect(states, [null, 'shared']);
    });

    test('clearGroup drops state and cursors of that group only', () async {
      await dao.setState('g1', SyncState.shared);
      await dao.setState('g2', SyncState.shared);
      await dao.setCursor('g1', 'expenses', 5);
      await dao.setCursor('g2', 'expenses', 7);
      await dao.clearGroup('g1');
      expect(await dao.groupSync('g1'), isNull);
      expect(await dao.cursorsOf('g1'), isEmpty);
      expect(await dao.groupSync('g2'), isNotNull);
      expect(await dao.cursorsOf('g2'), {'expenses': 7});
    });

    test('a sync row needs an existing group', () async {
      await expectLater(
        dao.setState('nope', SyncState.shared),
        throwsA(anything),
      );
    });
  });

  group('pull cursors', () {
    test('default 0, upsert overwrites, keyed by group and table', () async {
      expect(await dao.cursorOf('g1', 'expenses'), 0);
      await dao.setCursor('g1', 'expenses', 10);
      await dao.setCursor('g1', 'expenses', 12);
      await dao.setCursor('g1', 'members', 3);
      await dao.setCursor('g2', 'expenses', 99);
      expect(await dao.cursorOf('g1', 'expenses'), 12);
      expect(await dao.cursorsOf('g1'), {'expenses': 12, 'members': 3});
      expect(await dao.cursorOf('g2', 'members'), 0);
    });

    test('a negative cursor is rejected loudly', () {
      expect(() => dao.setCursor('g1', 'expenses', -1), throwsArgumentError);
    });
  });

  group('settings and node id', () {
    test('put and read back, overwrite', () async {
      expect(await dao.setting('k'), isNull);
      await dao.putSetting('k', 'a');
      await dao.putSetting('k', 'b');
      expect(await dao.setting('k'), 'b');
    });

    test('node id is created once and then stable', () async {
      final ids = SequentialIdGenerator(prefix: 'node');
      final first = await dao.hlcNodeId(ids);
      expect(first, 'node-1');
      expect(await dao.hlcNodeId(ids), first);
      expect(await dao.setting(hlcNodeIdKey), first);
    });

    test('node id survives reopening the database file', () async {
      final dir = Directory.systemTemp.createTempSync('mitlio_node_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/db.sqlite');

      final a = AppDatabase(NativeDatabase(file));
      final id = await a.syncStateDao.hlcNodeId(
        SequentialIdGenerator(prefix: 'first'),
      );
      await a.close();

      final b = AppDatabase(NativeDatabase(file));
      addTearDown(b.close);
      expect(
        await b.syncStateDao.hlcNodeId(SequentialIdGenerator(prefix: 'other')),
        id,
      );
    });

    test('a fresh install gets a different node id', () async {
      final other = openTestDb();
      addTearDown(other.close);
      final a = await dao.hlcNodeId(SequentialIdGenerator(prefix: 'a'));
      final b = await other.syncStateDao.hlcNodeId(
        SequentialIdGenerator(prefix: 'b'),
      );
      expect(a, isNot(b));
    });
  });

  group('outbox', () {
    LocalOutboxCompanion op(String opId, String groupId) =>
        LocalOutboxCompanion.insert(
          opId: opId,
          groupId: groupId,
          entity: 'expense',
          entityId: 'e1',
          op: 'upsert',
          payload: '{}',
          createdAt: t1,
        );

    test('counts pending operations per group', () async {
      expect(await dao.pendingOutboxCount('g1'), 0);
      await db.into(db.localOutbox).insert(op('o1', 'g1'));
      await db.into(db.localOutbox).insert(op('o2', 'g1'));
      await db.into(db.localOutbox).insert(op('o3', 'g2'));
      expect(await dao.pendingOutboxCount('g1'), 2);
      expect(await dao.pendingOutboxCount('g2'), 1);
    });

    test('op_id is unique (idempotency key)', () async {
      await db.into(db.localOutbox).insert(op('o1', 'g1'));
      await expectLater(
        db.into(db.localOutbox).insert(op('o1', 'g1')),
        throwsA(anything),
      );
    });

    test('retry columns default to none', () async {
      await db.into(db.localOutbox).insert(op('o1', 'g1'));
      final row = await db.select(db.localOutbox).getSingle();
      expect(
        (row.attempts, row.nextAttemptAt, row.lastErrorCode),
        (
          0,
          null,
          null,
        ),
      );
    });
  });
}
