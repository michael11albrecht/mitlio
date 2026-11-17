import 'package:drift/drift.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/tables.dart';

part 'sync_state_dao.g.dart';

/// Sync state of a group on this device. No row (`null` from
/// [SyncStateDao.groupSync]) means local only.
enum SyncState { shared, uploading, removed }

/// The user's role in a shared group.
enum SyncRole { owner, member }

/// `local_settings` key of the per-install HLC node id.
const hlcNodeIdKey = 'hlc_node_id';

/// Typed access to the client-only sync tables (schema v6): group sync state,
/// pull cursors and install settings. Never joins synced data.
@DriftAccessor(
  tables: [LocalGroupSync, LocalSyncCursor, LocalSettings, LocalOutbox],
)
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.attachedDatabase);

  // -- group sync state ----------------------------------------------------

  Future<LocalGroupSyncRow?> groupSync(String groupId) => (select(
    localGroupSync,
  )..where((r) => r.groupId.equals(groupId))).getSingleOrNull();

  Stream<LocalGroupSyncRow?> watchGroupSync(String groupId) => (select(
    localGroupSync,
  )..where((r) => r.groupId.equals(groupId))).watchSingleOrNull();

  /// Moves [groupId] to [state] (creates the row on first use). [role] is kept
  /// when null. Entering `shared` or `uploading` clears the last error; the
  /// caller records a failure with [recordError].
  Future<void> setState(
    String groupId,
    SyncState state, {
    SyncRole? role,
  }) => into(localGroupSync).insert(
    LocalGroupSyncCompanion.insert(
      groupId: groupId,
      state: state.name,
      role: Value(role?.name),
    ),
    onConflict: DoUpdate(
      (old) => LocalGroupSyncCompanion(
        state: Value(state.name),
        role: role == null ? const Value.absent() : Value(role.name),
        lastErrorCode: const Value(null),
        lastErrorAt: const Value(null),
      ),
    ),
  );

  /// Sets [role] on an existing row; no-op without one.
  Future<void> setRole(String groupId, SyncRole role) =>
      (update(localGroupSync)..where((r) => r.groupId.equals(groupId))).write(
        LocalGroupSyncCompanion(role: Value(role.name)),
      );

  Future<void> markPushed(String groupId, DateTime at) =>
      (update(localGroupSync)..where((r) => r.groupId.equals(groupId))).write(
        LocalGroupSyncCompanion(
          lastPushAt: Value(at),
          lastErrorCode: const Value(null),
          lastErrorAt: const Value(null),
        ),
      );

  Future<void> markPulled(String groupId, DateTime at) =>
      (update(localGroupSync)..where((r) => r.groupId.equals(groupId))).write(
        LocalGroupSyncCompanion(lastPullAt: Value(at)),
      );

  /// Remembers a stable error case name (ADR-27 §3) for the group.
  Future<void> recordError(String groupId, String code, DateTime at) =>
      (update(localGroupSync)..where((r) => r.groupId.equals(groupId))).write(
        LocalGroupSyncCompanion(
          lastErrorCode: Value(code),
          lastErrorAt: Value(at),
        ),
      );

  /// Back to local only: drops the sync row and the cursors of [groupId].
  Future<void> clearGroup(String groupId) => transaction(() async {
    await (delete(
      localSyncCursor,
    )..where((r) => r.groupId.equals(groupId))).go();
    await (delete(
      localGroupSync,
    )..where((r) => r.groupId.equals(groupId))).go();
  });

  // -- pull cursors --------------------------------------------------------

  /// Last applied `server_seq` of [tableName] in [groupId]; 0 before the
  /// first pull.
  Future<int> cursorOf(String groupId, String tableName) async {
    final row =
        await (select(localSyncCursor)..where(
              (r) =>
                  r.groupId.equals(groupId) & r.syncedTable.equals(tableName),
            ))
            .getSingleOrNull();
    return row?.cursor ?? 0;
  }

  /// All cursors of [groupId] by table name.
  Future<Map<String, int>> cursorsOf(String groupId) async {
    final rows = await (select(
      localSyncCursor,
    )..where((r) => r.groupId.equals(groupId))).get();
    return {for (final r in rows) r.syncedTable: r.cursor};
  }

  /// Upserts the cursor. A negative [cursor] is a programming error.
  Future<void> setCursor(String groupId, String tableName, int cursor) {
    if (cursor < 0) throw ArgumentError.value(cursor, 'cursor', 'negative');
    return into(localSyncCursor).insertOnConflictUpdate(
      LocalSyncCursorCompanion.insert(
        groupId: groupId,
        syncedTable: tableName,
        cursor: Value(cursor),
      ),
    );
  }

  // -- settings ------------------------------------------------------------

  Future<String?> setting(String key) async {
    final row = await (select(
      localSettings,
    )..where((r) => r.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> putSetting(String key, String value) =>
      into(localSettings).insertOnConflictUpdate(
        LocalSettingsCompanion.insert(key: key, value: value),
      );

  /// The install's HLC node id: read once, created with [ids] on the first
  /// call and never changed afterwards.
  Future<String> hlcNodeId(IdGenerator ids) => transaction(() async {
    final existing = await setting(hlcNodeIdKey);
    if (existing != null) return existing;
    final created = ids.newId();
    await putSetting(hlcNodeIdKey, created);
    return created;
  });

  // -- outbox --------------------------------------------------------------

  /// Unpushed operations of [groupId] in queue order.
  Future<List<LocalOutboxRow>> outboxOf(String groupId) =>
      (select(localOutbox)
            ..where((o) => o.groupId.equals(groupId))
            ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
          .get();

  /// Number of unpushed operations of [groupId].
  Future<int> pendingOutboxCount(String groupId) async {
    final count = countAll();
    final q = selectOnly(localOutbox)
      ..addColumns([count])
      ..where(localOutbox.groupId.equals(groupId));
    return (await q.getSingle()).read(count) ?? 0;
  }
}
