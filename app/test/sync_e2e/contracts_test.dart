@Tags(['supabase'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';

import '../features/sync/support/app_config_remote_contract.dart';
import '../features/sync/support/invite_remote_contract.dart';
import '../features/sync/support/sync_remote_contract.dart';
import 'support/local_supabase.dart';

/// The exported contract suites, against the real local backend. The same
/// suites run against the in-memory fakes in `make test`, so a fake cannot
/// drift from the server (ADR-27 §4).
void main() {
  final server = LocalSupabase.instance;

  runSyncRemoteContract('SupabaseSyncRemote (local Supabase)', () async {
    await server.wipe();
    final owner = await Account.create();
    final stranger = await Account.create();
    return SyncRemoteFixture(owner: owner.sync, stranger: stranger.sync);
  });

  runInviteRemoteContract('SupabaseInviteRemote (local Supabase)', () async {
    await server.wipe();
    final owner = await Account.create();
    final joiner = await Account.create();
    final other = await Account.create();
    final stranger = await Account.create();
    return InviteRemoteFixture(
      owner: owner.invite,
      ownerSync: owner.sync,
      joiner: joiner.invite,
      other: other.invite,
      stranger: stranger.invite,
    );
  });

  runAppConfigRemoteContract(
    'SupabaseAppConfigRemote (local Supabase)',
    () async {
      await server.wipe();
      final client = server.newClient();
      return AppConfigFixture(
        remote: SupabaseAppConfigRemote(RemoteBackend.withClient(client)),
        seed: server.seedAppConfig,
      );
    },
  );
}
