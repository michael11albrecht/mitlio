import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/push/data/push_providers.dart';
import 'package:mitlio/features/push/data/push_state_store.dart';
import 'package:mitlio/features/push/data/services/fake_push_service.dart';
import 'package:mitlio/features/push/ui/push_notices_view_model.dart';
import 'package:mitlio/features/sync/ui/join_view_model.dart';
import 'package:mitlio/features/sync/ui/share_view_model.dart';

import '../../sync/support/join_support.dart';
import '../../sync/support/share_support.dart';

/// Notifications are offered contextually: after the first share or join, not
/// on first launch (plan P6b, design rules).
void main() {
  late FakePushService push;
  late MemoryPushStateStore store;

  setUp(() {
    push = FakePushService();
    store = MemoryPushStateStore();
    addTearDown(push.dispose);
  });

  ProviderContainer container(List<Override> base) {
    final c = ProviderContainer(
      overrides: [
        ...base,
        pushServiceProvider.overrideWithValue(push),
        pushStateStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(c.dispose);
    c.listen(pushNoticesViewModelProvider, (_, _) {});
    return c;
  }

  test('nothing is offered before the first share or join', () async {
    final w = await ShareWorld.create();
    final c = container(w.overrides);
    await pumpEventQueue();
    expect(c.read(pushNoticesViewModelProvider), isNull);
    expect(push.permissionRequests, 0);
  });

  test('the first successful share offers notifications', () async {
    final w = await ShareWorld.create();
    final c = container(w.overrides);
    final provider = shareViewModelProvider(shareGroupId);
    c.listen(provider, (_, _) {});
    await c.read(provider.notifier).share();
    await pumpEventQueue();
    expect(c.read(provider), isA<ShareReady>());
    expect(c.read(pushNoticesViewModelProvider), isA<PushNoticeOffer>());
    // Asking is the user's call: the OS was not asked yet.
    expect(push.permissionRequests, 0);
  });

  test('a failed share offers nothing', () async {
    final w = await ShareWorld.create(hasBackend: false);
    final c = container(w.overrides);
    final provider = shareViewModelProvider(shareGroupId);
    c.listen(provider, (_, _) {});
    w.remote.offline = true;
    await c.read(provider.notifier).share();
    await pumpEventQueue();
    expect(c.read(provider), isNot(isA<ShareReady>()));
    expect(c.read(pushNoticesViewModelProvider), isNull);
  });

  test('a share when the user was already asked offers nothing', () async {
    store.wasAsked = true;
    final w = await ShareWorld.create();
    final c = container(w.overrides);
    final provider = shareViewModelProvider(shareGroupId);
    c.listen(provider, (_, _) {});
    await c.read(provider.notifier).share();
    await pumpEventQueue();
    expect(c.read(pushNoticesViewModelProvider), isNull);
  });

  test('joining a group offers notifications once it is done', () async {
    final w = await JoinWorld.create();
    final c = container(w.overrides);
    final provider = joinViewModelProvider(w.token);
    c.listen(provider, (_, _) {});
    final vm = c.read(provider.notifier);
    await vm.start();
    await pumpEventQueue();
    // Still choosing who you are: not yet.
    expect(c.read(pushNoticesViewModelProvider), isNull);
    vm.skip();
    await pumpEventQueue();
    expect(c.read(provider), isA<JoinDone>());
    expect(c.read(pushNoticesViewModelProvider), isA<PushNoticeOffer>());
  });
}
