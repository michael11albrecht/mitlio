import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/pull_applier.dart';
import 'package:mitlio/features/sync/data/repositories/version_gate.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Push order of the synced tables: parents before children.
///
/// Derived from the foreign keys in `supabase/migrations/0001_core.sql`
/// (`sync_service_test.dart` re-derives it from the SQL and fails when a new
/// FK breaks it):
/// - every table points at `groups`;
/// - `members` points only at `groups`; `vehicles` likewise;
/// - `ride_templates` -> `vehicles`, `members`;
/// - `expenses` -> `groups` (payers and shares travel inside the expense and
///   point at `members`);
/// - `rides` -> `vehicles`, `members` and **`expenses`** (`settled_expense_id`:
///   a settled ride points at its expense, not the other way round);
/// - `settlements` -> `members`.
/// So: group, member, vehicle, ride template, expense, ride, settlement.
///
/// The outbox queue order is NOT dependency order: coalescing moves a
/// re-edited aggregate to the end (see `OutboxWriter`), so a member renamed
/// after an expense for it was added queues behind that expense.
const pushRank = <String, int>{
  DbTables.groups: 0,
  DbTables.members: 1,
  DbTables.vehicles: 2,
  DbTables.rideTemplates: 3,
  DbTables.expenses: 4,
  DbTables.rides: 5,
  DbTables.settlements: 6,
};

/// First retry delay; doubles with every attempt up to [maxBackoff].
const baseBackoff = Duration(seconds: 2);

/// Longest wait between two attempts of an op.
const maxBackoff = Duration(minutes: 5);

/// Rows asked per pull request (ADR-07).
const pullPageSize = 500;

/// `local_settings` key holding the title of the entry the server refused last
/// (the schema has no column for it; `last_error_code` stays the case name).
String rejectedTitleKey(String groupId) => 'sync_rejected_title.$groupId';

/// Uploads the outbox of a shared group (P6-T10, ADR-07, ADR-27 §3).
///
/// Per op, in [pushRank] order then queue order:
/// - applied: the op is deleted;
/// - stale (the server has a newer version): the op is deleted and *not*
///   surfaced; the next pull brings the newer row. This is the one documented
///   exception to "never swallow" (ADR-27 §3);
/// - offline / server down / app too old: the op stays, `attempts` grows and
///   it is retried after an exponential backoff with jitter (cap 5 min);
///   later ops wait too, because they may depend on it;
/// - rate limited: retried after the server's wait;
/// - not a member: the group becomes `removed`, nothing more is pushed, all
///   data and ops are kept;
/// - anything else the server refuses: the op is deleted (it would be refused
///   forever), the refusal is stored as `rejected:<code>` with the entry title
///   and shown through [SyncStatus]. The data stays on this phone.
///
/// An op can be replaced by a newer write (new `op_id`) while it is in flight:
/// only the sent `op_id` is deleted or penalised, the newer op stays and goes
/// out in the next round.
class SyncService {
  SyncService({
    required this._db,
    required this._remote,
    required this._clock,
    required this._random,
    required IdGenerator ids,
    this._gate,
  }) : _applier = PullApplier(db: _db, clock: _clock, ids: ids);

  final AppDatabase _db;
  final SyncRemote _remote;
  final Clock _clock;
  final Random _random;
  final PullApplier _applier;

  /// The version gate (P6-T16, ADR-27 §2.3): an app below the server's
  /// `min_supported_version` neither pushes nor pulls; every shared group
  /// shows [VersionTooOld]. Local data and ops are untouched. Null: no gate.
  final VersionGate? _gate;

  final _running = <String, Completer<void>>{};
  final _pulling = <String, Completer<void>>{};
  final _again = <String>{};
  final _changes = StreamController<String>.broadcast();

  /// The last error with its wait, which the stored case name has lost.
  final _liveErrors = <String, RemoteError>{};

  SyncStateDao get _dao => _db.syncStateDao;

  /// The delay before attempt number [attempts] (1 = first retry): doubles
  /// from [baseBackoff], capped at [maxBackoff], then jittered into
  /// [50 %, 100 %) so devices do not retry in step.
  Duration backoff(int attempts) {
    final doubled = baseBackoff.inMicroseconds * (1 << min(attempts - 1, 20));
    final capped = min(doubled, maxBackoff.inMicroseconds);
    final jitter = 0.5 + 0.5 * _random.nextDouble();
    return Duration(microseconds: (capped * jitter).round());
  }

  /// Uploads what is due for [groupId] and returns the resulting status.
  /// Calls while a push of the same group runs do not run in parallel; they
  /// make that push take one more round, so nothing queued meanwhile waits.
  Future<SyncStatus> push(String groupId) async {
    final running = _running[groupId];
    if (running != null) {
      _again.add(groupId);
      await running.future;
      return status(groupId);
    }
    final done = Completer<void>();
    _running[groupId] = done;
    _announce(groupId);
    try {
      do {
        _again.remove(groupId);
        await _drain(groupId);
      } while (_again.contains(groupId));
    } finally {
      _running.remove(groupId);
      done.complete();
      _announce(groupId);
    }
    return status(groupId);
  }

  /// Downloads what other devices changed in [groupId] and returns the
  /// resulting status (P6-T11, ADR-07, ADR-27).
  ///
  /// Tables are pulled in [pushRank] order (parents first; Drift enforces the
  /// foreign keys), each by its own `server_seq` cursor in pages of
  /// [pullPageSize]. A page is applied in one transaction by [PullApplier]
  /// together with its cursor; applying never queues outbox ops.
  ///
  /// Failures stay visible through [status] and stop the pull; the cursor
  /// stays at the last applied page, so the next pull resumes there:
  /// - not a member: the group becomes `removed`, all data is kept;
  /// - offline / server down / rate limited / app too old: stored as the
  ///   error, nothing of the failed page is applied;
  /// - a page that cannot be applied locally: `pullFailed:<reason>`.
  /// A second call while a pull of the group runs waits for that one.
  Future<SyncStatus> pull(String groupId) async {
    final running = _pulling[groupId];
    if (running != null) {
      await running.future;
      return status(groupId);
    }
    final done = Completer<void>();
    _pulling[groupId] = done;
    _announce(groupId);
    try {
      await _pullTables(groupId);
    } finally {
      _pulling.remove(groupId);
      done.complete();
      _announce(groupId);
    }
    return status(groupId);
  }

  /// Joining: writes the group's own row (its name and currency) before there
  /// is a `local_group_sync` row, which [pull] needs and which points at the
  /// group row. Nothing is written when the server does not answer.
  Future<Result<void, RemoteError>> fetchGroupRow(String groupId) async {
    final fetched = await _remote.pullChanges(
      groupId: groupId,
      table: DbTables.groups,
      afterSeq: 0,
      limit: 1,
    );
    final List<Map<String, Object?>> rows;
    switch (fetched) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        rows = value;
    }
    if (rows.isEmpty) return const Err(PullFailed('group_row_missing'));
    try {
      await _applier.applyPage(
        groupId: groupId,
        table: DbTables.groups,
        rows: rows,
      );
    } on PullAbort catch (abort) {
      return Err(abort.error);
    } on Exception {
      // Rolled back; the caller shows it, nothing is half written.
      return const Err(PullFailed('local_apply_failed'));
    }
    return const Ok(null);
  }

  Future<void> _pullTables(String groupId) async {
    final sync = await _dao.groupSync(groupId);
    if (sync == null || sync.state == SyncState.removed.name) return;
    if (await _blockedByVersion(groupId)) return;
    final tables = pushRank.keys.toList()
      ..sort((a, b) => pushRank[a]!.compareTo(pushRank[b]!));
    for (final table in tables) {
      while (true) {
        final cursor = await _dao.cursorOf(groupId, table);
        final fetched = await _remote.pullChanges(
          groupId: groupId,
          table: table,
          afterSeq: cursor,
          limit: pullPageSize,
        );
        final List<Map<String, Object?>> rows;
        switch (fetched) {
          case Err(:final error):
            return _onPullFailure(groupId, error);
          case Ok(:final value):
            rows = value;
        }
        if (rows.isEmpty) break;
        var children = const <String, ExpenseChildren>{};
        if (table == DbTables.expenses) {
          final kids = await _remote.fetchExpenseChildren([
            for (final r in rows) r[DbExpensesCols.id]! as String,
          ]);
          switch (kids) {
            case Err(:final error):
              return _onPullFailure(groupId, error);
            case Ok(:final value):
              children = value;
          }
        }
        try {
          await _applier.applyPage(
            groupId: groupId,
            table: table,
            rows: rows,
            children: children,
          );
        } on PullAbort catch (abort) {
          return _onPullFailure(groupId, abort.error);
        } on Exception {
          // The page was rolled back. Not swallowed: shown as pullFailed.
          return _onPullFailure(
            groupId,
            const PullFailed('local_apply_failed'),
          );
        }
        if (await _dao.cursorOf(groupId, table) <= cursor) {
          // The server sent rows that do not advance the cursor; looping
          // would never end.
          return _onPullFailure(groupId, const PullFailed('cursor_stuck'));
        }
        if (rows.length < pullPageSize) break;
      }
    }
    await _dao.markPulled(groupId, _clock.now());
    // A good pull shows the server answers, so a connection error is stale.
    // Kept: a refusal of a push (it stays until the user has seen it) and
    // any error while ops still wait (the next push settles it).
    final current = (await _dao.groupSync(groupId))?.lastErrorCode;
    if (current != null &&
        !current.startsWith('rejected:') &&
        await _dao.pendingOutboxCount(groupId) == 0) {
      await _dao.clearError(groupId);
      _liveErrors.remove(groupId);
    }
  }

  /// True (and the group shows [VersionTooOld]) when the app is too old to
  /// sync. No network call for the group follows; the ops stay queued.
  Future<bool> _blockedByVersion(String groupId) async {
    final gate = _gate;
    if (gate == null || !(await gate.check()).blocked) return false;
    await _record(groupId, const VersionTooOld());
    return true;
  }

  Future<void> _onPullFailure(String groupId, RemoteError error) async {
    if (error is NotMember) {
      // Removed from the group: keep every row and op, stop syncing.
      await _dao.setState(groupId, SyncState.removed);
    }
    await _record(groupId, error);
  }

  /// Syncing > error > pending > idle.
  Future<SyncStatus> status(String groupId) async {
    if (_running.containsKey(groupId) || _pulling.containsKey(groupId)) {
      return const SyncSyncing();
    }
    final code = (await _dao.groupSync(groupId))?.lastErrorCode;
    if (code != null) {
      final live = _liveErrors[groupId];
      final error = live != null && live.storedCode == code
          ? live
          : remoteErrorFromCaseName(code);
      final title = await _dao.setting(rejectedTitleKey(groupId));
      return SyncError(
        error,
        title: error is Rejected && title != null && title.isNotEmpty
            ? title
            : null,
      );
    }
    final pending = await _dao.pendingOutboxCount(groupId);
    return pending > 0 ? SyncPending(pending) : const SyncIdle();
  }

  /// The status now and on every change of the outbox, the group's sync row or
  /// a running push.
  Stream<SyncStatus> watchStatus(String groupId) {
    late final StreamController<SyncStatus> out;
    final subs = <StreamSubscription<Object?>>[];
    Future<void> emit() async {
      final s = await status(groupId);
      if (!out.isClosed) out.add(s);
    }

    out = StreamController<SyncStatus>(
      onListen: () {
        subs
          ..add(
            _db
                .tableUpdates(
                  TableUpdateQuery.onAllTables([
                    _db.localOutbox,
                    _db.localGroupSync,
                    _db.localSettings,
                  ]),
                )
                .listen((_) => unawaited(emit())),
          )
          ..add(
            _changes.stream
                .where((id) => id == groupId)
                .listen((_) => unawaited(emit())),
          );
        unawaited(emit());
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        await out.close();
      },
    );
    return out.stream.distinct();
  }

  void _announce(String groupId) => _changes.add(groupId);

  Future<void> _drain(String groupId) async {
    final sync = await _dao.groupSync(groupId);
    if (sync == null || sync.state == SyncState.removed.name) return;
    if (await _blockedByVersion(groupId)) return;
    final pass = _Pass();
    while (!pass.stopped) {
      final ops = _inPushOrder(await _dao.outboxOf(groupId));
      var sent = 0;
      for (final op in ops) {
        final due = op.nextAttemptAt;
        if (due != null && due.isAfter(_clock.now())) {
          // Waiting for its retry; ops behind it may depend on it.
          pass.stopped = true;
          break;
        }
        final result = await _send(op);
        switch (result) {
          case Ok():
            // Applied or stale: both end the op (ADR-27 §3). Only this op_id;
            // a newer write of the aggregate has another one and stays.
            await _dao.deleteOutboxOp(op.opId);
            sent++;
            pass.pushed = true;
          case Err(:final error):
            await _onFailure(groupId, op, error, pass);
        }
        if (pass.stopped) break;
      }
      if (sent == 0) break;
    }
    await _finish(groupId, pass);
  }

  Future<Result<PushOutcome, RemoteError>> _send(LocalOutboxRow op) {
    final payload = jsonDecode(op.payload) as Map<String, Object?>;
    return op.entity == DbTables.expenses
        ? _remote.upsertExpense(payload)
        : _remote.upsertRows(op.entity, [payload]);
  }

  Future<void> _onFailure(
    String groupId,
    LocalOutboxRow op,
    RemoteError error,
    _Pass pass,
  ) async {
    switch (error) {
      case NotMember():
        // Removed from the group: stop for good, keep every row and op.
        await _dao.setState(groupId, SyncState.removed);
        await _record(groupId, error);
        pass
          ..stopped = true
          ..removed = true;
      case Offline() || ServerDown() || VersionTooOld():
        await _defer(op, error.storedCode, backoff(op.attempts + 1));
        pass
          ..stopped = true
          ..stopError = error;
      case RateLimitedRemote(:final wait):
        await _defer(
          op,
          error.storedCode,
          wait ?? backoff(op.attempts + 1),
        );
        pass
          ..stopped = true
          ..stopError = error;
      default:
        // Refused for good: it would be refused again. Drop the op, say so.
        await _dao.deleteOutboxOp(op.opId);
        final stored = error is Rejected ? error : Rejected(error.caseName);
        await _record(groupId, stored, title: _titleOf(op));
        pass.rejected = true;
    }
  }

  Future<void> _defer(
    LocalOutboxRow op,
    String code,
    Duration wait,
  ) => _dao.deferOutboxOp(
    op.opId,
    attempts: op.attempts + 1,
    nextAttemptAt: _clock.now().add(wait),
    errorCode: code,
  );

  Future<void> _finish(String groupId, _Pass pass) async {
    if (pass.removed) return;
    if (pass.rejected) {
      // The refusal stays on screen; only stamp the push.
      if (pass.pushed) {
        await _dao.markPushed(groupId, _clock.now(), keepError: true);
      }
      return;
    }
    final stop = pass.stopError;
    if (stop != null) {
      await _record(groupId, stop);
      return;
    }
    if (!pass.pushed) return;
    final current = (await _dao.groupSync(groupId))?.lastErrorCode;
    // A refusal stays visible until something else clears it.
    await _dao.markPushed(
      groupId,
      _clock.now(),
      keepError: current != null && current.startsWith('rejected:'),
    );
    if (current != null && !current.startsWith('rejected:')) {
      _liveErrors.remove(groupId);
    }
  }

  Future<void> _record(
    String groupId,
    RemoteError error, {
    String? title,
  }) async {
    _liveErrors[groupId] = error;
    await _dao.recordError(groupId, error.storedCode, _clock.now());
    await _dao.putSetting(rejectedTitleKey(groupId), title ?? '');
  }

  static String? _titleOf(LocalOutboxRow op) {
    final payload = jsonDecode(op.payload) as Map<String, Object?>;
    final title = payload[DbExpensesCols.title] ?? payload[DbGroupsCols.name];
    return title is String && title.isNotEmpty ? title : null;
  }

  static List<LocalOutboxRow> _inPushOrder(List<LocalOutboxRow> ops) =>
      List.of(ops)..sort((a, b) {
        final byRank = _rank(a).compareTo(_rank(b));
        return byRank != 0 ? byRank : a.seq.compareTo(b.seq);
      });

  // Unknown tables go last; the server refuses them and the user hears so.
  static int _rank(LocalOutboxRow op) => pushRank[op.entity] ?? pushRank.length;
}

/// What one drain learned.
class _Pass {
  bool stopped = false;
  bool pushed = false;
  bool rejected = false;
  bool removed = false;
  RemoteError? stopError;
}
