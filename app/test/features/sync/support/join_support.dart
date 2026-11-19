import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio/features/sync/data/services/fake_invite_remote.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../db/test_support.dart';
import 'share_support.dart';

const joinGroupId = 'g-join';
const joinGroupName = 'Urlaub Kroatien';

const _stamp = '2026-03-01T00:00:00.000Z-0001-a';

/// The owner's server with a group of three people, one of them (Bob) already
/// connected to another phone, and a phone that opens the link.
class JoinWorld {
  JoinWorld._(
    this.db,
    this.owner,
    this.ownerInvites,
    this.remote,
    this.invites,
    this.token,
  );

  final AppDatabase db;
  final FakeSyncRemote owner;
  final FakeInviteRemote ownerInvites;

  /// The joiner's views of the server.
  final FakeSyncRemote remote;
  final FakeInviteRemote invites;

  /// Clearly fake, low entropy invite token (gitleaks scans history).
  final String token;

  final auth = FakeAuthService(userId: 'joiner-1');
  final store = MemorySecretStore();

  static Future<JoinWorld> create() async {
    final db = openTestDb();
    addTearDown(db.close);
    final owner = FakeSyncRemote(userId: 'owner-1');
    final ownerInvites = FakeInviteRemote(sync: owner);
    await owner.upsertRows(DbTables.groups, [
      {
        DbGroupsCols.id: joinGroupId,
        DbGroupsCols.name: joinGroupName,
        DbGroupsCols.currency: 'EUR',
        DbGroupsCols.createdAt: '2026-03-01T00:00:00.000Z',
        DbGroupsCols.updatedAt: _stamp,
        DbGroupsCols.deletedAt: null,
      },
    ]);
    await owner.bootstrapMembership(joinGroupId);
    var position = 0;
    for (final name in ['Peter', 'Bob', 'Jonas']) {
      await owner.upsertRows(DbTables.members, [
        {
          DbMembersCols.id: 'm-${name.toLowerCase()}',
          DbMembersCols.groupId: joinGroupId,
          DbMembersCols.name: name,
          DbMembersCols.position: position++,
          DbMembersCols.canDrive: true,
          DbMembersCols.createdAt: '2026-03-01T00:00:00.000Z',
          DbMembersCols.updatedAt: _stamp,
          DbMembersCols.deletedAt: null,
        },
      ]);
    }
    final created = await ownerInvites.createInvite(joinGroupId);
    final token = (created as Ok<String, Object?>).value;
    // Bob's phone.
    final bob = FakeInviteRemote.sharing(
      ownerInvites,
      sync: FakeSyncRemote.sharing(owner, userId: 'bob-1'),
    );
    await bob.joinGroup(token, claimMemberId: 'm-bob');
    final remote = FakeSyncRemote.sharing(owner, userId: 'joiner-1');
    return JoinWorld._(
      db,
      owner,
      ownerInvites,
      remote,
      FakeInviteRemote.sharing(ownerInvites, sync: remote),
      token,
    );
  }

  /// Another phone on the same server.
  FakeInviteRemote otherPhone(String user) => FakeInviteRemote.sharing(
    ownerInvites,
    sync: FakeSyncRemote.sharing(owner, userId: user),
  );

  List<Override> get overrides => [
    appDatabaseProvider.overrideWithValue(db),
    syncRemoteProvider.overrideWithValue(remote),
    inviteRemoteProvider.overrideWithValue(invites),
    authServiceProvider.overrideWithValue(auth),
    secretStoreProvider.overrideWithValue(store),
    clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 3))),
    idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides);
    addTearDown(c.dispose);
    return c;
  }
}
