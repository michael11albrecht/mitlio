import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/sync_state_repository.dart';

class DriftSyncStateRepository implements SyncStateRepository {
  DriftSyncStateRepository(AppDatabase db) : _dao = db.syncStateDao;

  final SyncStateDao _dao;

  @override
  Future<GroupSyncSnapshot> snapshot(String groupId) async {
    final row = await _dao.groupSync(groupId);
    final state = row?.state;
    final role = row?.role;
    return GroupSyncSnapshot(
      groupId: groupId,
      state: state == null ? null : SyncState.values.byName(state),
      role: role == null ? null : SyncRole.values.byName(role),
      cursors: await _dao.cursorsOf(groupId),
      pendingOutbox: await _dao.pendingOutboxCount(groupId),
      lastPushAt: row?.lastPushAt,
      lastPullAt: row?.lastPullAt,
      lastErrorCode: row?.lastErrorCode,
      lastErrorAt: row?.lastErrorAt,
    );
  }
}
