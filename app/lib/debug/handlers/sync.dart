import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio/features/sync/ui/sync_status_line.dart';
import 'package:mitlio/features/sync/ui/sync_status_view_model.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';

/// The line's words in German, as the app shows them.
String _words(SyncStatus status) =>
    syncStatusText(AppLocalizationsDe(), SyncLineShown(status));

/// `ext.mitlio.sync.now` `{groupId}`: pushes then pulls the group now (as
/// "Nochmal versuchen" does) and returns `ran`, the status case (`status`:
/// idle/syncing/pending/error, `error` the stable case name, `title`),
/// `pendingOutbox`, `lastPushAt`, `lastPullAt`. `ran` is false for a group
/// that is local only or removed: it never touches the network.
///
/// `ext.mitlio.sync.status` `{groupId}` (read-only): `line` (the status case,
/// null for a local group, which has no status line) and `text` (the line's
/// words in German).
///
/// `ext.mitlio.sync.outbox` `{groupId}` (read-only): the pending ops in queue
/// order (`entity`, `id`, `opId`, `op`, `attempts`, `lastErrorCode`); never the
/// payload.
///
/// `ext.mitlio.sync.state` (read-only): what this device knows about syncing
/// a group. `state` is `local` when the group was never shared. Keys without
/// the `ext.mitlio.` prefix.
Map<String, DriveHandler> syncDriveHandlers(ProviderContainer c) => {
  'sync.now': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final stats = await c
        .read(syncCoordinatorProvider)
        .syncNow(groupId, force: true);
    final snap = await c.read(syncStateRepositoryProvider).snapshot(groupId);
    return {
      'groupId': groupId,
      'ran': stats.ran,
      ...syncStatusJson(stats.status),
      'pendingOutbox': snap.pendingOutbox,
      'lastPushAt': snap.lastPushAt?.toIso8601String(),
      'lastPullAt': snap.lastPullAt?.toIso8601String(),
    };
  },
  'sync.status': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final status = await c.read(syncServiceProvider).status(groupId);
    final snap = await c.read(syncStateRepositoryProvider).snapshot(groupId);
    final shared = snap.state != null;
    return {
      'groupId': groupId,
      'state': snap.state?.name ?? 'local',
      // The status line shows only for shared groups.
      'line': shared ? syncStatusJson(status) : null,
      'text': shared ? _words(status) : null,
    };
  },
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
