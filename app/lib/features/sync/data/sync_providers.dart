import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/app_version.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_providers.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/drift_sync_coordinator.dart';
import 'package:mitlio/features/sync/data/drift_sync_state_repository.dart';
import 'package:mitlio/features/sync/data/repositories/join_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/repositories/version_gate.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio/features/sync/data/services/supabase_invite_remote.dart';
import 'package:mitlio/features/sync/data/services/supabase_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_coordinator.dart';
import 'package:mitlio/features/sync/data/sync_state_repository.dart';

final syncStateRepositoryProvider = Provider<SyncStateRepository>(
  (ref) => DriftSyncStateRepository(ref.watch(appDatabaseProvider)),
);

/// Supabase sync endpoints; tests and DebugDrive override it with
/// `FakeSyncRemote`.
final syncRemoteProvider = Provider<SyncRemote>(
  (ref) => SupabaseSyncRemote(ref.watch(remoteBackendProvider)),
);

/// The `app_config` endpoint (public read); tests and DebugDrive override it
/// with `FakeAppConfigRemote`.
final appConfigRemoteProvider = Provider<AppConfigRemote>(
  (ref) => SupabaseAppConfigRemote(ref.watch(remoteBackendProvider)),
);

/// Blocks sync (never local use) below the server's `min_supported_version`
/// (P6-T16).
final versionGateProvider = Provider<VersionGate>(
  (ref) => VersionGate(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(appConfigRemoteProvider),
    clock: ref.watch(clockProvider),
    launcher: ref.watch(linkLauncherProvider),
    currentVersion: ref.watch(appVersionProvider),
    platform: ref.watch(storePlatformProvider),
  ),
);

final shareGroupRepositoryProvider = Provider<ShareGroupRepository>(
  (ref) => ShareGroupRepository(
    db: ref.watch(appDatabaseProvider),
    auth: ref.watch(authRepositoryProvider),
    remote: ref.watch(syncRemoteProvider),
    sync: ref.watch(syncServiceProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
    gate: ref.watch(versionGateProvider),
  ),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(syncRemoteProvider),
    clock: ref.watch(clockProvider),
    random: ref.watch(randomProvider),
    ids: ref.watch(idGeneratorProvider),
    gate: ref.watch(versionGateProvider),
  ),
);

/// Supabase invite and membership endpoints; tests and DebugDrive override it
/// with `FakeInviteRemote`.
final inviteRemoteProvider = Provider<InviteRemote>(
  (ref) => SupabaseInviteRemote(ref.watch(remoteBackendProvider)),
);

/// Keychain / Keystore for invite links (secrets); tests override it.
final secretStoreProvider = Provider<SecretStore>(
  (ref) => const FlutterSecretStore(),
);

final shareLinkRepositoryProvider = Provider<ShareLinkRepository>(
  (ref) => ShareLinkRepository(
    remote: ref.watch(inviteRemoteProvider),
    auth: ref.watch(authRepositoryProvider),
    secrets: ref.watch(secretStoreProvider),
    logger: ref.watch(loggerProvider),
    share: ref.watch(shareServiceProvider),
    siteUrl: siteUrl,
  ),
);

final joinRepositoryProvider = Provider<JoinRepository>(
  (ref) => JoinRepository(
    db: ref.watch(appDatabaseProvider),
    auth: ref.watch(authRepositoryProvider),
    invites: ref.watch(inviteRemoteProvider),
    sync: ref.watch(syncServiceProvider),
    members: ref.watch(membersRepositoryProvider),
    links: ref.watch(shareLinkRepositoryProvider),
    logger: ref.watch(loggerProvider),
  ),
);

/// One coordinator per app. `main` calls `start()`; the group detail calls
/// `groupOpened`. Without a database (in-memory widget tests) override it
/// with `NoSyncCoordinator`.
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = DriftSyncCoordinator(
    db: ref.watch(appDatabaseProvider),
    service: ref.watch(syncServiceProvider),
    clock: ref.watch(clockProvider),
    lifecycle: ref.watch(lifecycleSourceProvider),
    // An interrupted share (state `uploading`) finishes through makeShared,
    // which resumes idempotently and flips the group to `shared`. Its failures
    // are already on the status line (last_error_code), so the result is not
    // needed here.
    resumeShare: (groupId) async {
      await ref.read(shareGroupRepositoryProvider).makeShared(groupId);
    },
    onError: (error, stack) =>
        ref.read(errorSinkProvider).record(error, stack, source: 'sync'),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
