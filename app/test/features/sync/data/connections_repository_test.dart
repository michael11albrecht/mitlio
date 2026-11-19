import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/repositories/connections_repository.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio/features/sync/data/services/fake_invite_remote.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/share_support.dart';

/// The owner's server view, but removing an account fails.
class _FailingRemove extends FakeInviteRemote {
  _FailingRemove(super.other, this.error) : super.sharing(sync: other.sync);

  final RemoteError error;
  int removeCalls = 0;

  @override
  Future<Result<void, RemoteError>> removeMembership(String id) async {
    removeCalls++;
    return Err(error);
  }
}

/// The owner's phone (account `owner-1`, group g1 with people m1 and m2) and
/// Bob's phone on the same fake server.
void main() {
  late ShareWorld w;
  late ProviderContainer c;
  late ConnectionsRepository repo;
  late FakeInviteRemote bob;
  late String token;

  Future<void> share() async {
    // The fixture people carry a stamp that is no HLC; the server and the
    // pull need real ones.
    await w.db.customStatement(
      'update members set updated_at = ?',
      ['2026-03-01T00:00:00.000Z-0001-a'],
    );
    await c.read(shareGroupRepositoryProvider).makeShared(shareGroupId);
    token = ((await w.invites.createInvite(
      shareGroupId,
    )) as Ok<String, RemoteError>).value;
    bob = FakeInviteRemote.sharing(
      w.invites,
      sync: FakeSyncRemote.sharing(w.remote, userId: 'bob-1'),
    );
  }

  Future<String?> localUser(String id) async =>
      (await w.db.membersDao.findById(id))!.userId;

  Future<List<String>> accounts() async => [
    for (final m in ((await w.invites.listMemberships(
      shareGroupId,
    )) as Ok<List<MembershipInfo>, RemoteError>).value)
      m.userId,
  ];

  setUp(() async {
    w = await ShareWorld.create();
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(w.db),
        syncRemoteProvider.overrideWithValue(w.remote),
        inviteRemoteProvider.overrideWithValue(w.invites),
        authServiceProvider.overrideWithValue(
          FakeAuthService(userId: 'owner-1'),
        ),
        secretStoreProvider.overrideWithValue(w.store),
        clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 3))),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
    );
    addTearDown(c.dispose);
    repo = c.read(connectionsRepositoryProvider);
  });

  group('watch', () {
    test('a local group has no connections', () async {
      final first = await repo.watch(shareGroupId).first;
      expect(first.shared, isFalse);
      expect(first.canClaimSelf, isFalse);
      expect(first.connectedIds, isEmpty);
    });

    test('a shared group: owner, signed in, nobody connected', () async {
      await share();
      final s = await repo.watch(shareGroupId).first;
      expect(s.shared, isTrue);
      expect(s.isOwner, isTrue);
      expect(s.signedIn, isTrue);
      expect(s.connectedIds, isEmpty);
      expect(s.myMemberId, isNull);
      expect(s.canClaimSelf, isTrue);
    });

    test('follows the people: a pull brings the other phone', () async {
      await share();
      final seen = <GroupConnections>[];
      final sub = repo.watch(shareGroupId).listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      await bob.joinGroup(token, claimMemberId: 'm2');
      await repo.refresh(shareGroupId);
      await pumpEventQueue();
      expect(seen.last.connectedIds, {'m2'});
      expect(await localUser('m2'), 'bob-1');
    });
  });

  group('connectMe', () {
    test('uses the join path and the badge is there at once', () async {
      await share();
      expect(
        await repo.connectMe(shareGroupId, 'm1'),
        isA<Ok<void, Object?>>(),
      );
      final s = await repo.watch(shareGroupId).first;
      expect(s.myMemberId, 'm1');
      expect(s.canClaimSelf, isFalse);
      expect(await localUser('m1'), 'owner-1');
    });

    test('a refusal changes nothing here', () async {
      await share();
      await bob.joinGroup(token, claimMemberId: 'm2');
      final result = await repo.connectMe(shareGroupId, 'm2');
      expect(result, isA<Err<void, RemoteError>>());
      expect(
        (result as Err<void, RemoteError>).error,
        isA<MemberAlreadyClaimed>(),
      );
      expect(await localUser('m2'), isNull);
    });

    test('refresh names the person you are', () async {
      await share();
      await repo.connectMe(shareGroupId, 'm1');
      expect(await repo.refresh(shareGroupId), isNotNull);
    });
  });

  group('disconnect', () {
    setUp(() async {
      await share();
      await bob.joinGroup(token, claimMemberId: 'm2');
      await repo.refresh(shareGroupId);
    });

    test('ends the account, the person and the group stay', () async {
      expect(await accounts(), contains('bob-1'));
      final result = await repo.disconnect(shareGroupId, 'm2');
      expect(result, isA<Ok<void, Object?>>());
      expect(await accounts(), isNot(contains('bob-1')));
      expect(await localUser('m2'), isNull);
      expect(await w.db.membersDao.findById('m2'), isNotNull);
      expect(
        (await bob.myRole(shareGroupId) as Err<Object?, RemoteError>).error,
        isA<NotMember>(),
      );
    });

    test('they can be connected again through the link', () async {
      await repo.disconnect(shareGroupId, 'm2');
      final again = await bob.joinGroup(token, claimMemberId: 'm2');
      expect(again, isA<Ok<JoinOutcome, RemoteError>>());
    });

    test(
      'nobody connected on the server: a no-op that clears the link',
      () async {
        await repo.disconnect(shareGroupId, 'm2');
        await w.db.membersDao.setUserId('m2', 'bob-1'); // a stale local link
        expect(
          await repo.disconnect(shareGroupId, 'm2'),
          isA<Ok<void, Object?>>(),
        );
        expect(await localUser('m2'), isNull);
      },
    );

    test('never your own account', () async {
      await repo.connectMe(shareGroupId, 'm1');
      final result = await repo.disconnect(shareGroupId, 'm1');
      expect((result as Err<void, RemoteError>).error, isA<CannotRemoveSelf>());
      expect(await accounts(), contains('owner-1'));
      expect(await localUser('m1'), 'owner-1');
    });

    for (final error in const <RemoteError>[
      Offline(),
      ServerDown(),
      NotOwner(),
    ]) {
      test('$error on the first call: nothing changes', () async {
        w.invites.failNext(error);
        final result = await repo.disconnect(shareGroupId, 'm2');
        expect((result as Err<void, RemoteError>).error, error);
        expect(await accounts(), contains('bob-1'));
        expect(await localUser('m2'), 'bob-1');
      });

      test('$error on the removal: nothing changes', () async {
        final failing = _FailingRemove(w.invites, error);
        final c2 = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(w.db),
            syncRemoteProvider.overrideWithValue(w.remote),
            inviteRemoteProvider.overrideWithValue(failing),
            authServiceProvider.overrideWithValue(
              FakeAuthService(userId: 'owner-1'),
            ),
            secretStoreProvider.overrideWithValue(w.store),
            clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 3))),
            idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
          ],
        );
        addTearDown(c2.dispose);
        final result = await c2
            .read(connectionsRepositoryProvider)
            .disconnect(shareGroupId, 'm2');
        expect((result as Err<void, RemoteError>).error, error);
        expect(failing.removeCalls, 1);
        expect(await accounts(), contains('bob-1'));
        expect(await localUser('m2'), 'bob-1');
      });
    }
  });
}
