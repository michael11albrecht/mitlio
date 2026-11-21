import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitlio/core/app_version.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/push/data/push_state_store.dart';
import 'package:mitlio/features/push/data/repositories/push_repository.dart';
import 'package:mitlio/features/push/data/repositories/push_routing.dart';
import 'package:mitlio/features/push/data/services/push_remote.dart';
import 'package:mitlio/features/push/data/services/push_service.dart';
import 'package:mitlio/features/push/data/services/supabase_push_remote.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';

/// The platform side of push. Default: [UnavailablePushService] (no Firebase
/// config, P6b-T01 pending): the app works, the settings say that push is not
/// available. The Firebase implementation is registered in `main` only when
/// the flavor has a Firebase config; tests and DebugDrive use
/// `FakePushService`.
final pushServiceProvider = Provider<PushService>(
  (ref) => const UnavailablePushService(),
);

/// Device tokens and per-group prefs on the server; tests override it with
/// `FakePushRemote`.
final pushRemoteProvider = Provider<PushRemote>(
  (ref) => SupabasePushRemote(ref.watch(remoteBackendProvider)),
);

/// The asked flag and registered token. `main` overrides it with the file
/// store.
final pushStateStoreProvider = Provider<PushStateStore>(
  (ref) => MemoryPushStateStore(),
);

/// BCP-47 tag of the phone's language, for formatting amounts server side.
final deviceLocaleTagProvider = Provider<String>(
  (ref) => PlatformDispatcher.instance.locale.toLanguageTag(),
);

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  final repo = PushRepository(
    service: ref.watch(pushServiceProvider),
    remote: ref.watch(pushRemoteProvider),
    auth: ref.watch(authRepositoryProvider),
    store: ref.watch(pushStateStoreProvider),
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider),
    localeTag: () => ref.read(deviceLocaleTagProvider),
    appVersion: () => ref.read(appVersionProvider),
    onError: (e, st) =>
        ref.read(errorSinkProvider).record(e, st, source: 'push'),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Routes taps, foreground and background messages to the router and
/// `SyncService.pull`. `PushHost` starts it.
final pushRoutingProvider = Provider<PushRouting>((ref) {
  final router = ref.watch(routerProvider);
  final routing = PushRouting(
    service: ref.watch(pushServiceProvider),
    pull: (groupId) async {
      await ref.read(syncServiceProvider).pull(groupId);
    },
    navigate: (locations) => _show(router, locations),
    onError: (e, st) =>
        ref.read(errorSinkProvider).record(e, st, source: 'push'),
  );
  ref.onDispose(routing.dispose);
  return routing;
});

void _show(GoRouter router, List<String> locations) {
  router.go(locations.first);
  for (final l in locations.skip(1)) {
    router.push<void>(l).ignore();
  }
}
