import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/groups/ui/group_detail_view.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';

import '../features/groups/ui/groups_fixtures.dart';
import '../features/sync/ui/sync_fixtures.dart';
import 'golden_matrix.dart';

const _width = 360.0;

Future<void> main() async {
  Future<void> line(String name, SyncStatus status, {double height = 240}) =>
      matrixGolden(
        'sync_line_$name',
        () => syncLine(status),
        width: _width,
        height: height,
      );

  await line('idle', const SyncIdle(), height: 80);
  await line('sending', const SyncSyncing(), height: 80);
  await line('pending', const SyncPending(3), height: 80);
  await line('uploading', const SyncUploading(remaining: 12), height: 120);
  await line('error_offline', const SyncError(Offline()));
  await line('error_server_down', const SyncError(ServerDown()));
  await line(
    'error_rejected',
    const SyncError(Rejected('payers_sum_mismatch'), title: 'Pizza'),
  );

  // The line in its place: under the app bar of a shared group.
  await matrixGolden(
    'group_detail_shared_pending',
    () => scoped([
      ...detailStateOverride(sampleDetail),
      ...syncLineOverride(const SyncPending(3)),
    ], const GroupDetailView(groupId: 'g-1')),
    width: _width,
    height: 640,
  );
}
