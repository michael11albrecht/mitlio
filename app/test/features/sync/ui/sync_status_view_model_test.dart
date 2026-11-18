import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio/features/sync/ui/sync_status_view_model.dart';

import '../../../support/capturing_logger.dart';
import '../support/fake_sync_coordinator.dart';

void main() {
  late FakeSyncCoordinator coordinator;
  late ProviderContainer container;
  late ErrorSink sink;

  SyncStatusViewModel vm() =>
      container.read(syncStatusViewModelProvider('g').notifier);
  SyncLineState state() => container.read(syncStatusViewModelProvider('g'));

  Future<SyncLineState> show(SyncStatus? status) async {
    coordinator.show(status);
    await pumpEventQueue();
    return state();
  }

  setUp(() async {
    coordinator = FakeSyncCoordinator();
    sink = ErrorSink(
      clock: FixedClock(DateTime.utc(2026)),
      logger: CapturingLogger(),
    );
    container = ProviderContainer(
      overrides: [
        syncCoordinatorProvider.overrideWithValue(coordinator),
        errorSinkProvider.overrideWithValue(sink),
      ],
    );
    addTearDown(container.dispose);
    container.listen(syncStatusViewModelProvider('g'), (_, _) {});
    await pumpEventQueue();
  });

  test('starts hidden; a local-only group (null) stays hidden', () async {
    expect(state(), const SyncLineHidden());
    expect(await show(null), const SyncLineHidden());
    expect(vm().debugSnapshot(), {'groupId': 'g', 'status': 'hidden'});
  });

  group('success', () {
    test('idle, sending, pending', () async {
      final idle = await show(const SyncIdle()) as SyncLineShown;
      expect(idle.kind, SyncLineKind.upToDate);
      expect(idle.action, isNull);
      expect(idle.error, isNull);

      final sending = await show(const SyncSyncing()) as SyncLineShown;
      expect(sending.kind, SyncLineKind.sending);

      final pending = await show(const SyncPending(3)) as SyncLineShown;
      expect(pending.kind, SyncLineKind.pending);
      expect(pending.pendingCount, 3);
      expect(pending.action, isNull);
      expect(vm().debugSnapshot(), {
        'groupId': 'g',
        'status': 'pending',
        'pending': 3,
        'action': null,
      });
    });

    test('the line goes away when the group stops being shared', () async {
      await show(const SyncIdle());
      expect(await show(null), const SyncLineHidden());
    });
  });

  group('failure: one action per RemoteError case (ADR-27 §3)', () {
    const expected = <(RemoteError, SyncLineAction?)>[
      (Offline(), null),
      (NotMember(), null),
      (ServerDown(), SyncLineAction.retry),
      (RateLimitedRemote(null), SyncLineAction.retry),
      (RateLimitedRemote(Duration(minutes: 3)), SyncLineAction.retry),
      (PullFailed('local_apply_failed'), SyncLineAction.retry),
      (Rejected('payers_sum_mismatch'), SyncLineAction.showRejected),
      (VersionTooOld(), null),
      (InviteInvalid(), null),
      (MemberAlreadyClaimed(), null),
      (AlreadyConnected(), null),
      (MemberGone(), null),
      (NotOwner(), null),
      (CannotRemoveSelf(), null),
    ];

    for (final (error, action) in expected) {
      test('$error offers ${action?.name ?? 'nothing'}', () async {
        final shown = await show(SyncError(error, title: 'Pizza'));
        expect(shown, isA<SyncLineShown>());
        shown as SyncLineShown;
        expect(shown.kind, SyncLineKind.error);
        expect(shown.error, error);
        expect(shown.title, 'Pizza');
        expect(shown.action, action);
        final snap = vm().debugSnapshot();
        expect(snap['status'], 'error');
        expect(snap['error'], error.storedCode);
        expect(snap['action'], action?.name);
      });
    }
  });

  group('commands', () {
    test('retry syncs the group now, forced', () async {
      await show(const SyncError(ServerDown()));
      await vm().retry();
      expect(coordinator.synced, ['g!']);
    });

    test('acknowledge forgets the refused change', () async {
      await show(const SyncError(Rejected('x'), title: 'Pizza'));
      await vm().acknowledge();
      expect(coordinator.acknowledged, ['g']);
    });
  });

  test('a stream error goes to the error sink and the line stays', () async {
    await show(const SyncPending(2));
    coordinator.fail(StateError('db closed'));
    await pumpEventQueue();
    expect(state(), const SyncLineShown(SyncPending(2)));
    expect(sink.errors.single.error, isA<StateError>());
    expect(sink.errors.single.source, 'sync-status');
  });

  test('equality of shown lines', () {
    expect(
      const SyncLineShown(SyncIdle()),
      const SyncLineShown(SyncIdle()),
    );
    expect(
      const SyncLineShown(SyncIdle()).hashCode,
      const SyncLineShown(SyncIdle()).hashCode,
    );
    expect(
      const SyncLineShown(SyncIdle()),
      isNot(const SyncLineShown(SyncSyncing())),
    );
  });
}
