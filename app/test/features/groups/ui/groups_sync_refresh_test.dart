import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';

import '../../../helpers/fake_app.dart';
import '../../sync/support/fake_sync_coordinator.dart';

void main() {
  late FakeSyncCoordinator coordinator;
  late ProviderContainer container;

  setUp(() {
    coordinator = FakeSyncCoordinator();
    container = (FakeApp()..sync = coordinator).container();
    addTearDown(container.dispose);
  });

  group('group detail', () {
    test('opening a group tells the coordinator, once per build', () async {
      container.listen(groupDetailViewModelProvider('g1'), (_, _) {});
      await pumpEventQueue();
      expect(coordinator.opened, ['g1']);
    });

    test('refresh syncs that group now (forced)', () async {
      final vm = container.read(groupDetailViewModelProvider('g1').notifier);
      final stats = await vm.refresh();
      expect(coordinator.synced, ['g1!']);
      expect(stats.status, const SyncIdle());
    });
  });

  group('groups list refresh', () {
    test('success: no error, every shared group synced', () async {
      coordinator.shared = ['a', 'b'];
      final vm = container.read(groupsViewModelProvider.notifier);
      expect(await vm.refresh(), isNull);
      expect(coordinator.refreshedAll, 1);
    });

    test('nothing shared: no error', () async {
      expect(
        await container.read(groupsViewModelProvider.notifier).refresh(),
        isNull,
      );
    });

    for (final error in const [
      Offline(),
      ServerDown(),
      RateLimitedRemote(Duration(minutes: 3)),
      VersionTooOld(),
      NotMember(),
    ]) {
      test('failure $error is returned for the list to show', () async {
        coordinator
          ..shared = ['a']
          ..result = SyncError(error);
        final failed = await container
            .read(groupsViewModelProvider.notifier)
            .refresh();
        expect(failed?.error, error);
      });
    }
  });
}
