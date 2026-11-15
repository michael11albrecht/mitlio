import 'package:mitlio/db/daos/sync_state_dao.dart';

/// What this device knows about syncing one group.
class GroupSyncSnapshot {
  const GroupSyncSnapshot({
    required this.groupId,
    required this.state,
    required this.role,
    required this.cursors,
    required this.pendingOutbox,
    this.lastPushAt,
    this.lastPullAt,
    this.lastErrorCode,
    this.lastErrorAt,
  });

  final String groupId;

  /// Null: the group is local only.
  final SyncState? state;
  final SyncRole? role;

  /// Last applied `server_seq` by table.
  final Map<String, int> cursors;

  /// Operations waiting to be pushed.
  final int pendingOutbox;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;
  final String? lastErrorCode;
  final DateTime? lastErrorAt;
}

/// Read access to the local sync state (P6-T09a). Writers (push, pull) come
/// with their own tasks.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class SyncStateRepository {
  Future<GroupSyncSnapshot> snapshot(String groupId);
}
