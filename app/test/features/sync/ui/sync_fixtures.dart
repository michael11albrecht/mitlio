import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/sync_coordinator.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio/features/sync/ui/sync_status_line.dart';
import 'package:mitlio/features/sync/ui/sync_status_view_model.dart';

/// A status line with a fixed state; commands still reach the coordinator.
class StubSyncStatusViewModel extends SyncStatusViewModel {
  StubSyncStatusViewModel(super.groupId, this.fixed);

  final SyncLineState fixed;

  @override
  SyncLineState build() => fixed;
}

List<Override> syncLineOverride(
  SyncStatus? status, {
  SyncCoordinator? coordinator,
}) => [
  if (coordinator != null)
    syncCoordinatorProvider.overrideWithValue(coordinator),
  syncStatusViewModelProvider.overrideWith2(
    (id) => StubSyncStatusViewModel(
      id,
      status == null ? const SyncLineHidden() : SyncLineShown(status),
    ),
  ),
];

/// The line on its own, as the group detail header shows it.
Widget syncLine(
  SyncStatus? status, {
  SyncCoordinator coordinator = const NoSyncCoordinator(),
}) => ProviderScope(
  overrides: syncLineOverride(status, coordinator: coordinator),
  child: const SyncStatusLine(groupId: 'g'),
);

/// Every case the line can show: name and status. Offline has no action;
/// the others have one (see `SyncLineShown.action`).
const syncLineCases = <(String, SyncStatus)>[
  ('idle', SyncIdle()),
  ('sending', SyncSyncing()),
  ('pending', SyncPending(3)),
  ('uploading', SyncUploading(remaining: 12)),
  ('uploading unknown', SyncUploading()),
  ('error offline', SyncError(Offline())),
  ('error server down', SyncError(ServerDown())),
  ('error rate limited', SyncError(RateLimitedRemote(Duration(minutes: 4)))),
  ('error version too old', SyncError(VersionTooOld())),
  ('error not member', SyncError(NotMember())),
  ('error pull failed', SyncError(PullFailed('local_apply_failed'))),
  (
    'error rejected',
    SyncError(Rejected('payers_sum_mismatch'), title: 'Pizza'),
  ),
];
