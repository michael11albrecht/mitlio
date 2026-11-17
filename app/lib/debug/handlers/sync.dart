import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';

/// `ext.mitlio.sync.outbox` `{groupId}` (read-only): the pending ops in queue
/// order (`entity`, `id`, `opId`, `op`, `attempts`, `lastErrorCode`); never the
/// payload.
///
/// `ext.mitlio.sync.state` (read-only): what this device knows about syncing
/// a group. `state` is `local` when the group was never shared. Keys without
/// the `ext.mitlio.` prefix.
Map<String, DriveHandler> syncDriveHandlers(ProviderContainer c) => {
  'sync.state': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final s = await c.read(syncStateRepositoryProvider).snapshot(groupId);
    return {
      'groupId': s.groupId,
      'state': s.state?.name ?? 'local',
      'role': s.role?.name,
      'cursors': s.cursors,
      'pendingOutbox': s.pendingOutbox,
      'lastPushAt': s.lastPushAt?.toIso8601String(),
      'lastPullAt': s.lastPullAt?.toIso8601String(),
      'lastErrorCode': s.lastErrorCode,
      'lastErrorAt': s.lastErrorAt?.toIso8601String(),
    };
  },
  'sync.outbox': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final rows = await c
        .read(appDatabaseProvider)
        .syncStateDao
        .outboxOf(groupId);
    return {
      'groupId': groupId,
      'ops': [
        for (final r in rows)
          {
            'entity': r.entity,
            'id': r.entityId,
            'opId': r.opId,
            'op': r.op,
            'attempts': r.attempts,
            'lastErrorCode': r.lastErrorCode,
          },
      ],
    };
  },
};
