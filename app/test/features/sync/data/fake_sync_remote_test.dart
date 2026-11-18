import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/sync_remote_contract.dart';

Map<String, Object?> _row(String id, String groupId, {String v = '0001'}) => {
  'id': id,
  'group_id': groupId,
  'updated_at': v,
};

void main() {
  runSyncRemoteContract('FakeSyncRemote', () async {
    final owner = FakeSyncRemote(userId: 'owner');
    return SyncRemoteFixture(
      owner: owner,
      stranger: FakeSyncRemote.sharing(owner, userId: 'stranger'),
    );
  });

  group('FakeSyncRemote scripting', () {
    late FakeSyncRemote remote;
    setUp(() => remote = FakeSyncRemote());

    Map<String, Object?> group() => {
      'id': 'g1',
      'name': 'Trip',
      'currency': 'EUR',
      'updated_at': '0001',
    };

    test('offline fails every call with Offline and keeps no row', () async {
      remote.offline = true;
      final r = await remote.upsertRows(DbTables.groups, [group()]);
      expect((r as Err<PushOutcome, RemoteError>).error, const Offline());
      expect(remote.count(DbTables.groups), 0);
      expect(remote.calls, 1);
    });

    test('failNext fails that many calls, then recovers', () async {
      remote.failNext(const ServerDown(), times: 2);
      for (var i = 0; i < 2; i++) {
        expect(
          await remote.upsertRows(DbTables.groups, [group()]),
          const Err<PushOutcome, RemoteError>(ServerDown()),
        );
      }
      expect(
        await remote.upsertRows(DbTables.groups, [group()]),
        const Ok<PushOutcome, RemoteError>(PushOutcome.applied),
      );
    });

    test('fail applies until cleared; rate limit carries its wait', () async {
      remote.fail = const RateLimitedRemote(Duration(minutes: 2));
      expect(
        await remote.upsertRows(DbTables.groups, [group()]),
        const Err<PushOutcome, RemoteError>(
          RateLimitedRemote(Duration(minutes: 2)),
        ),
      );
      remote.fail = null;
      expect(
        await remote.upsertRows(DbTables.groups, [group()]),
        const Ok<PushOutcome, RemoteError>(PushOutcome.applied),
      );
    });

    test(
      'a row whose parent the server lacks is a foreign key error',
      () async {
        await remote.upsertRows(DbTables.groups, [group()]);
        final r = await remote.upsertRows(DbTables.settlements, [
          {
            ..._row('s1', 'g1'),
            'from_member': 'nobody',
            'to_member': 'nobody',
          },
        ]);
        expect(
          (r as Err<PushOutcome, RemoteError>).error,
          const Rejected('foreign_key_violation'),
        );
      },
    );

    test('a member row for a group the server lacks is refused', () async {
      final r = await remote.upsertRows(DbTables.members, [_row('m1', 'gx')]);
      expect((r as Err<PushOutcome, RemoteError>).error, const NotMember());
    });

    test(
      'removeMember turns the same account away, addMember lets in',
      () async {
        await remote.upsertRows(DbTables.groups, [group()]);
        remote.removeMember('g1');
        expect(
          await remote.upsertRows(DbTables.members, [_row('m1', 'g1')]),
          const Err<PushOutcome, RemoteError>(NotMember()),
        );
        remote.addMember('g1');
        expect(
          await remote.upsertRows(DbTables.members, [_row('m1', 'g1')]),
          const Ok<PushOutcome, RemoteError>(PushOutcome.applied),
        );
      },
    );

    test('fetchExpenseChildren skips unknown and foreign expenses', () async {
      final r = await remote.fetchExpenseChildren(['nope']);
      expect(
        (r as Ok<Map<String, ExpenseChildren>, RemoteError>).value,
        isEmpty,
      );
    });
  });
}
