import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/lifecycle.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/sync_coordinator.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';

/// Quiet time after the last local write before it is pushed (P6-T12).
const localWriteDebounce = Duration(seconds: 2);

/// [SyncCoordinator] on the Drift database and [SyncService].
///
/// Triggers: [start] (app start), resume, [groupOpened], a local write (any
/// change of the outbox, then [localWriteDebounce] of quiet), the retry time
/// of an op that waits for its backoff, and the user ([syncNow] with force).
/// Every trigger ends in [syncNow]: push, then pull. A sync of a group that is
/// not `shared`/`uploading` returns at once without a network call.
class DriftSyncCoordinator implements SyncCoordinator {
  DriftSyncCoordinator({
    required this._db,
    required this._service,
    required this._clock,
    required this._lifecycle,
    this.debounce = localWriteDebounce,
    this._onError,
    this._resumeShare,
  });

  final AppDatabase _db;
  final SyncService _service;
  final Clock _clock;
  final LifecycleSource _lifecycle;
  final Duration debounce;
  final void Function(Object error, StackTrace stack)? _onError;

  /// Finishes the share of a group in state `uploading` (idempotent; only
  /// `makeShared` flips the group to `shared`). Null: a plain push is used.
  final Future<void> Function(String groupId)? _resumeShare;

  final _inFlight = <String, Future<SyncStats>>{};
  final _again = <String>{};
  final _retryTimers = <String, Timer>{};
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _debounceTimer;
  var _started = false;
  var _disposed = false;

  SyncStateDao get _dao => _db.syncStateDao;

  @override
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _subs
      ..add(_lifecycle.onResume.listen((_) => unawaited(_syncAll())))
      ..add(
        _db
            .tableUpdates(TableUpdateQuery.onTable(_db.localOutbox))
            .listen((_) => _scheduleLocalWrite()),
      );
    await _syncAll();
  }

  @override
  void groupOpened(String groupId) => unawaited(_guarded(syncNow(groupId)));

  @override
  Future<SyncStats> syncNow(String groupId, {bool force = false}) async {
    final running = _inFlight[groupId];
    if (running != null) {
      // Not parallel: the running sync takes one more round, which also
      // carries what changed since it began.
      _again.add(groupId);
      return running;
    }
    final run = Completer<SyncStats>();
    _inFlight[groupId] = run.future;
    try {
      run.complete(await _run(groupId, force));
    } on Object catch (e, s) {
      run.completeError(e, s);
    } finally {
      unawaited(_inFlight.remove(groupId));
    }
    return run.future;
  }

  @override
  Future<List<SyncStats>> refreshAll() async {
    final ids = await _dao.syncGroupIds();
    return Future.wait([for (final id in ids) syncNow(id, force: true)]);
  }

  @override
  Stream<SyncStatus?> watchLine(String groupId) {
    late final StreamController<SyncStatus?> out;
    StreamSubscription<Object?>? rowSub;
    StreamSubscription<Object?>? statusSub;
    var rowKnown = false;
    var isSynced = false;
    var uploading = false;
    SyncStatus? status;
    void emit() {
      if (!rowKnown || status == null || out.isClosed) return;
      final s = status;
      if (!isSynced) {
        out.add(null);
      } else if (uploading && s is! SyncError) {
        // Honest while the history goes out: not "up to date" yet.
        out.add(SyncUploading(remaining: s is SyncPending ? s.count : null));
      } else {
        out.add(s);
      }
    }

    out = StreamController<SyncStatus?>(
      onListen: () {
        rowSub = _dao.watchGroupSync(groupId).listen(
          (row) {
            rowKnown = true;
            isSynced = row != null;
            uploading = row?.state == SyncState.uploading.name;
            emit();
          },
          onError: out.addError,
        );
        statusSub = _service.watchStatus(groupId).listen(
          (s) {
            status = s;
            emit();
          },
          onError: out.addError,
        );
      },
      onCancel: () async {
        await rowSub?.cancel();
        await statusSub?.cancel();
        await out.close();
      },
    );
    return out.stream.distinct();
  }

  @override
  Future<void> acknowledge(String groupId) => _dao.clearError(groupId);

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    for (final t in _retryTimers.values) {
      t.cancel();
    }
    _retryTimers.clear();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }

  // -- internals -----------------------------------------------------------

  Future<void> _syncAll() async {
    final ids = await _guarded(_dao.syncGroupIds()) ?? const <String>[];
    await Future.wait([for (final id in ids) _guarded(syncNow(id))]);
  }

  /// Runs a trigger nobody awaits: a failure is reported, never dropped.
  Future<T?> _guarded<T>(Future<T> work) async {
    try {
      return await work;
    } on Object catch (e, s) {
      final report = _onError;
      if (report == null) rethrow;
      if (!_disposed) report(e, s);
      return null;
    }
  }

  void _scheduleLocalWrite() {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(_syncDue()));
  }

  /// After a quiet moment: every group that has ops which are due now. Ops
  /// that wait for a backoff are left to their retry timer, so the outbox
  /// changes of a failed push do not loop.
  Future<void> _syncDue() async {
    final ids = await _guarded(_dao.syncGroupIds()) ?? const <String>[];
    for (final id in ids) {
      final ops = await _guarded(_dao.outboxOf(id)) ?? const [];
      final now = _clock.now();
      final due = ops.any((o) => o.nextAttemptAt?.isAfter(now) != true);
      if (due) unawaited(_guarded(syncNow(id)));
    }
  }

  Future<SyncStats> _run(String groupId, bool force) async {
    var forced = force;
    SyncStats stats;
    do {
      _again.remove(groupId);
      stats = await _once(groupId, forced);
      forced = false;
    } while (_again.contains(groupId) && !_disposed);
    return stats;
  }

  Future<SyncStats> _once(String groupId, bool force) async {
    final sync = await _dao.groupSync(groupId);
    final active =
        sync != null &&
        (sync.state == SyncState.shared.name ||
            sync.state == SyncState.uploading.name);
    if (!active) {
      return SyncStats(
        groupId: groupId,
        status: await _service.status(groupId),
        ran: false,
      );
    }
    if (force) await _dao.resetBackoff(groupId);
    final resume = _resumeShare;
    final uploading = sync.state == SyncState.uploading.name;
    // An interrupted share finishes by itself: makeShared resumes where it
    // stopped and flips the group to `shared` once the outbox is empty.
    final shareRuns = uploading && resume != null;
    if (shareRuns) await resume(groupId);
    final pushed = shareRuns
        ? await _service.status(groupId)
        : await _service.push(groupId);
    // Still uploading (ops wait, or an error): no pull yet.
    if ((await _dao.groupSync(groupId))?.state == SyncState.uploading.name &&
        shareRuns) {
      await _scheduleRetry(groupId);
      return SyncStats(groupId: groupId, status: pushed, ran: true);
    }
    // A server that did not answer or refused us will not answer a pull
    // either; the error stays on the status line. A refused op (Rejected)
    // says nothing about pulling.
    final blocked = pushed is SyncError && pushed.error is! Rejected;
    final status = blocked ? pushed : await _service.pull(groupId);
    await _scheduleRetry(groupId);
    return SyncStats(groupId: groupId, status: status, ran: true);
  }

  /// Wakes up when the earliest waiting op is due.
  Future<void> _scheduleRetry(String groupId) async {
    _retryTimers.remove(groupId)?.cancel();
    if (_disposed) return;
    final ops = await _dao.outboxOf(groupId);
    DateTime? next;
    for (final o in ops) {
      final at = o.nextAttemptAt;
      if (at != null && (next == null || at.isBefore(next))) next = at;
    }
    if (next == null) return;
    final wait = next.difference(_clock.now());
    _retryTimers[groupId] = Timer(
      wait.isNegative ? Duration.zero : wait,
      () => unawaited(_guarded(syncNow(groupId))),
    );
  }
}
