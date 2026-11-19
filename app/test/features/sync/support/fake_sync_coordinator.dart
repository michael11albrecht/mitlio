import 'dart:async';

import 'package:mitlio/features/sync/data/sync_coordinator.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';

/// A coordinator the test drives by hand: it records the commands and shows
/// whatever status the test pushes with [show].
class FakeSyncCoordinator implements SyncCoordinator {
  final _line = StreamController<SyncStatus?>.broadcast();

  /// Groups opened, in order.
  final opened = <String>[];

  /// `syncNow` calls as `groupId` or `groupId!` (forced).
  final synced = <String>[];
  final acknowledged = <String>[];
  int refreshedAll = 0;
  int started = 0;

  /// What `syncNow` and `refreshAll` answer.
  SyncStatus result = const SyncIdle();
  bool ran = true;

  /// Shared groups for [refreshAll].
  List<String> shared = const [];

  void show(SyncStatus? status) => _line.add(status);

  /// The status stream fails (a local database error).
  void fail(Object error) => _line.addError(error);

  @override
  Future<void> start() async => started++;

  @override
  void groupOpened(String groupId) => opened.add(groupId);

  @override
  Future<SyncStats> syncNow(String groupId, {bool force = false}) async {
    synced.add(force ? '$groupId!' : groupId);
    return SyncStats(groupId: groupId, status: result, ran: ran);
  }

  @override
  Future<List<SyncStats>> refreshAll() async {
    refreshedAll++;
    return [
      for (final id in shared) SyncStats(groupId: id, status: result, ran: ran),
    ];
  }

  @override
  Stream<SyncStatus?> watchLine(String groupId) => _line.stream;

  @override
  Future<void> acknowledge(String groupId) async => acknowledged.add(groupId);

  @override
  void dispose() => unawaited(_line.close());
}
