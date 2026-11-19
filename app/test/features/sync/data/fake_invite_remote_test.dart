import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/fake_invite_remote.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/invite_remote_contract.dart';

void main() {
  runInviteRemoteContract('FakeInviteRemote', () async {
    final ownerSync = FakeSyncRemote(userId: 'owner');
    final owner = FakeInviteRemote(sync: ownerSync);
    FakeInviteRemote account(String id) => FakeInviteRemote.sharing(
      owner,
      sync: FakeSyncRemote.sharing(ownerSync, userId: id),
    );
    return InviteRemoteFixture(
      owner: owner,
      ownerSync: ownerSync,
      joiner: account('joiner'),
      other: account('other'),
      stranger: account('stranger'),
    );
  });

  group('members.user_id follows the connection (as the server does)', () {
    test('connect sets it, remove_membership clears it', () async {
      const hlc = '2026-03-01T00:00:00.000Z-0001-a';
      final ownerSync = FakeSyncRemote(userId: 'owner');
      final owner = FakeInviteRemote(sync: ownerSync);
      await ownerSync.upsertRows(DbTables.groups, [
        {
          DbGroupsCols.id: 'g',
          DbGroupsCols.name: 'Trip',
          DbGroupsCols.currency: 'EUR',
          DbGroupsCols.createdAt: '2026-03-01T00:00:00.000Z',
          DbGroupsCols.updatedAt: hlc,
          DbGroupsCols.deletedAt: null,
        },
      ]);
      await ownerSync.bootstrapMembership('g');
      await ownerSync.upsertRows(DbTables.members, [
        {
          DbMembersCols.id: 'p1',
          DbMembersCols.groupId: 'g',
          DbMembersCols.name: 'Pia',
          DbMembersCols.position: 0,
          DbMembersCols.canDrive: true,
          DbMembersCols.createdAt: '2026-03-01T00:00:00.000Z',
          DbMembersCols.updatedAt: hlc,
          DbMembersCols.deletedAt: null,
        },
      ]);
      final token =
          ((await owner.createInvite('g')) as Ok<String, RemoteError>).value;
      final joiner = FakeInviteRemote.sharing(
        owner,
        sync: FakeSyncRemote.sharing(ownerSync, userId: 'joiner'),
      );
      await joiner.joinGroup(token, claimMemberId: 'p1');
      final seqBefore =
          ownerSync.row(DbTables.members, 'p1')![DbGroupsCols.serverSeq]!
              as int;
      expect(
        ownerSync.row(DbTables.members, 'p1')![DbMembersCols.userId],
        'joiner',
      );

      final list = ((await owner.listMemberships(
        'g',
      )) as Ok<List<MembershipInfo>, RemoteError>).value;
      final theirs = list.firstWhere((m) => m.userId == 'joiner');
      await owner.removeMembership(theirs.id);
      final row = ownerSync.row(DbTables.members, 'p1')!;
      expect(row[DbMembersCols.userId], isNull);
      expect(row[DbMembersCols.updatedAt], hlc);
      expect(row[DbGroupsCols.serverSeq]! as int, greaterThan(seqBefore));
    });
  });

  group('scripted failures', () {
    test('offline, failNext and fail reach every call', () async {
      final remote = FakeInviteRemote(sync: FakeSyncRemote())..offline = true;
      expect(
        await remote.createInvite('g'),
        const Err<String, RemoteError>(Offline()),
      );
      remote
        ..offline = false
        ..failNext(const RateLimitedRemote(Duration(minutes: 2)));
      expect(
        (await remote.joinGroup(
          't',
        ) as Err<JoinOutcome, RemoteError>).error,
        const RateLimitedRemote(Duration(minutes: 2)),
      );
      remote.fail = const ServerDown();
      expect(
        (await remote.myRole('g') as Err<Object?, RemoteError>).error,
        const ServerDown(),
      );
      expect(remote.calls, 3);
    });
  });
}
