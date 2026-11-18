import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/sync/data/drift_sync_state_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
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

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(syncRemoteProvider),
    clock: ref.watch(clockProvider),
    random: ref.watch(randomProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
