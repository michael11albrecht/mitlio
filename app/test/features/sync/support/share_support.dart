import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio/features/sync/data/services/fake_invite_remote.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/ui/share_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../db/test_support.dart';
import '../../../helpers/fake_platform.dart';

/// The group the tests share.
const shareGroupId = 'g1';

/// Where the share sheet keeps the invite link of [shareGroupId].
const inviteKey = 'mitlio.invite.$shareGroupId';

/// In-memory secure storage; reads, writes and deletes can be made to fail.
class MemorySecretStore implements SecretStore {
  final values = <String, String>{};
  Exception? failRead;
  Exception? failWrite;
  Exception? failDelete;

  @override
  Future<String?> read(String key) async {
    if (failRead != null) throw failRead!;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite != null) throw failWrite!;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDelete != null) throw failDelete!;
    values.remove(key);
  }
}

/// One phone (database, secure storage, account) and a fake server, set up
/// for the share sheet. [create] is a phone with a local group that has not
/// been shared; [createMember] a phone that joined a group someone else owns.
class ShareWorld {
  ShareWorld._({
    required this.db,
    required this.remote,
    required this.invites,
    required this.auth,
    required this.store,
    required this.share,
    required this.server,
    required this.serverInvites,
    required this.hasBackend,
  });

  final AppDatabase db;

  /// This phone's view of the server.
  final FakeSyncRemote remote;
  final FakeInviteRemote invites;
  final FakeAuthService auth;
  final MemorySecretStore store;
  final FakeShareService share;

  /// The owner's view of the same server (the same as [remote] for an owner
  /// phone).
  final FakeSyncRemote server;
  final FakeInviteRemote serverInvites;
  final bool hasBackend;

  static Future<ShareWorld> create({
    String user = 'owner-1',
    bool hasBackend = true,
  }) async {
    final db = openTestDb();
    addTearDown(db.close);
    await seedGroup(db);
    final remote = FakeSyncRemote(userId: user);
    return ShareWorld._(
      db: db,
      remote: remote,
      invites: FakeInviteRemote(sync: remote),
      auth: FakeAuthService(),
      store: MemorySecretStore(),
      share: FakeShareService(),
      server: remote,
      serverInvites: FakeInviteRemote(sync: remote),
      hasBackend: hasBackend,
    );
  }

  /// A phone of someone who joined with the owner's link and keeps it.
  static Future<ShareWorld> createMember({bool keepLink = true}) async {
    final db = openTestDb();
    addTearDown(db.close);
    await seedGroup(db);
    final owner = FakeSyncRemote(userId: 'owner-1');
    final ownerInvites = FakeInviteRemote(sync: owner);
    await owner.upsertRows(DbTables.groups, [
      {
        DbGroupsCols.id: shareGroupId,
        DbGroupsCols.name: 'Trip',
        DbGroupsCols.currency: 'EUR',
        DbGroupsCols.createdAt: '2026-03-01T00:00:00.000Z',
        DbGroupsCols.updatedAt: '2026-03-01T00:00:00.000Z-0001-a',
        DbGroupsCols.deletedAt: null,
      },
    ]);
    await owner.bootstrapMembership(shareGroupId);
    final token = ((await ownerInvites.createInvite(
      shareGroupId,
    )) as Ok<String, Object?>).value;
    final remote = FakeSyncRemote.sharing(owner, userId: 'member-1');
    final invites = FakeInviteRemote.sharing(ownerInvites, sync: remote);
    await invites.joinGroup(token);
    await db.syncStateDao.setState(
      shareGroupId,
      SyncState.shared,
      role: SyncRole.member,
    );
    final store = MemorySecretStore();
    if (keepLink) store.values[inviteKey] = token;
    return ShareWorld._(
      db: db,
      remote: remote,
      invites: invites,
      auth: FakeAuthService(userId: 'member-1'),
      store: store,
      share: FakeShareService(),
      server: owner,
      serverInvites: ownerInvites,
      hasBackend: true,
    );
  }

  /// The token the app kept for [shareGroupId].
  String? get storedToken => store.values[inviteKey];

  List<Override> get overrides => [
    appDatabaseProvider.overrideWithValue(db),
    syncRemoteProvider.overrideWithValue(remote),
    inviteRemoteProvider.overrideWithValue(invites),
    authServiceProvider.overrideWithValue(auth),
    secretStoreProvider.overrideWithValue(store),
    shareServiceProvider.overrideWithValue(share),
    clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 3))),
    idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
    shareAvailableProvider.overrideWithValue(hasBackend),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides);
    addTearDown(c.dispose);
    return c;
  }
}
