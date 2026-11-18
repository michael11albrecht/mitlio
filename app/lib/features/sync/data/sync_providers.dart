import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_providers.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/drift_sync_state_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_group_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio/features/sync/data/services/supabase_invite_remote.dart';
import 'package:mitlio/features/sync/data/services/supabase_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_state_repository.dart';

final syncStateRepositoryProvider = Provider<SyncStateRepository>(
  (ref) => DriftSyncStateRepository(ref.watch(appDatabaseProvider)),
);

/// Supabase sync endpoints; tests and DebugDrive override it with
/// `FakeSyncRemote`.
final syncRemoteProvider = Provider<SyncRemote>(
  (ref) => SupabaseSyncRemote(ref.watch(remoteBackendProvider)),
);

final shareGroupRepositoryProvider = Provider<ShareGroupRepository>(
  (ref) => ShareGroupRepository(
    db: ref.watch(appDatabaseProvider),
    auth: ref.watch(authRepositoryProvider),
    remote: ref.watch(syncRemoteProvider),
    sync: ref.watch(syncServiceProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(syncRemoteProvider),
    clock: ref.watch(clockProvider),
    random: ref.watch(randomProvider),
    ids: ref.watch(idGeneratorProvider),
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
    siteUrl: siteUrl,
  ),
);

/// Whether sharing is offered at all: not without a backend (plan §2.6).
final shareAvailableProvider = Provider<bool>(
  (ref) => ref.watch(remoteBackendProvider).isAvailable,
);
