import 'package:mitlio/features/sync/data/sync_status.dart';

/// What one sync of a group did: [ran] is false when the group is not synced
/// at all (local only or removed); then [status] is [SyncIdle].
class SyncStats {
  const SyncStats({
    required this.groupId,
    required this.status,
    required this.ran,
  });

  final String groupId;
  final SyncStatus status;
  final bool ran;
}

/// Decides when a shared group syncs (P6-T12, ADR-27 §2.1; no realtime):
/// app start and resume, group opened, 2 s after a local write, and on the
/// user's pull-to-refresh or retry. Local-only groups never reach the network.
abstract interface class SyncCoordinator {
  /// Begins listening (resume, local writes) and syncs every shared group
  /// once. Without shared groups nothing touches the network.
  Future<void> start();

  /// The group detail was opened. Fire and forget; failures show in the
  /// group's status line.
  void groupOpened(String groupId);

  /// Pushes, then pulls [groupId]. One sync per group at a time: a call while
  /// one runs makes it go one more round and returns that run's result.
  /// [force] (an explicit user action) retries ops that wait for a backoff.
  Future<SyncStats> syncNow(String groupId, {bool force = false});

  /// Pull-to-refresh of the group list: [syncNow] with force for every shared
  /// group.
  Future<List<SyncStats>> refreshAll();

  /// What the status line of [groupId] shows; `null` for a local-only group
  /// (no line at all).
  Stream<SyncStatus?> watchLine(String groupId);

  /// The user has seen a refused change: forgets that error.
  Future<void> acknowledge(String groupId);

  void dispose();
}

/// Used where there is no database (widget tests with in-memory
/// repositories): nothing is shared, nothing syncs.
class NoSyncCoordinator implements SyncCoordinator {
  const NoSyncCoordinator();

  @override
  Future<void> start() async {}

  @override
  void groupOpened(String groupId) {}

  @override
  Future<SyncStats> syncNow(String groupId, {bool force = false}) async =>
      SyncStats(groupId: groupId, status: const SyncIdle(), ran: false);

  @override
  Future<List<SyncStats>> refreshAll() async => const [];

  @override
  Stream<SyncStatus?> watchLine(String groupId) => Stream.value(null);

  @override
  Future<void> acknowledge(String groupId) async {}

  @override
  void dispose() {}
}
