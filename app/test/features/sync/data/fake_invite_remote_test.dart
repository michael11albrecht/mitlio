import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
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
