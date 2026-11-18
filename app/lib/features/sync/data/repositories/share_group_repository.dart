// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/outbox_writer.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// Where a share stands: the group's [state] and how many of the [total]
/// entries (the group itself, members, vehicles, ride templates, expenses,
/// rides, settlements, live and deleted) the server holds.
class ShareProgress {
  const ShareProgress({
    required this.state,
    required this.uploaded,
    required this.total,
  });

  final SyncState state;
  final int uploaded;
  final int total;

  @override
  bool operator ==(Object other) =>
      other is ShareProgress &&
      other.state == state &&
      other.uploaded == uploaded &&
      other.total == total;

  @override
  int get hashCode => Object.hash(state, uploaded, total);

  @override
  String toString() => 'ShareProgress($state, $uploaded/$total)';
}

/// Why a group could not be shared (plain words in `share_error_text`).
sealed class ShareError {
  const ShareError();
}

/// The group is not on this phone.
final class ShareGroupMissing extends ShareError {
  const ShareGroupMissing();

  @override
  bool operator ==(Object other) => other is ShareGroupMissing;

  @override
  int get hashCode => (ShareGroupMissing).hashCode;

  @override
  String toString() => 'ShareGroupMissing()';
}

/// This phone was removed from the group; it cannot be shared again.
final class ShareGroupRemoved extends ShareError {
  const ShareGroupRemoved();

  @override
  bool operator ==(Object other) => other is ShareGroupRemoved;

  @override
  int get hashCode => (ShareGroupRemoved).hashCode;

  @override
  String toString() => 'ShareGroupRemoved()';
}

/// The upload stopped after [uploaded] of [total] entries because of [error].
/// Everything on this phone is unchanged; the rest goes out on the next try.
final class ShareUploadFailed extends ShareError {
  const ShareUploadFailed({
    required this.uploaded,
    required this.total,
    required this.error,
    this.title,
  });

  final int uploaded;
  final int total;
  final RemoteError error;

  /// The entry the server refused, for [Rejected].
  final String? title;

  @override
  bool operator ==(Object other) =>
      other is ShareUploadFailed &&
      other.uploaded == uploaded &&
      other.total == total &&
      other.error == error &&
      other.title == title;

  @override
  int get hashCode =>
      Object.hash(ShareUploadFailed, uploaded, total, error, title);

  @override
  String toString() => 'ShareUploadFailed($uploaded/$total, $error)';
}

/// Turns a local group into a shared one and uploads its whole history
/// (P6-T15, ADR-24, ADR-27).
///
/// Order matters, because the server authorises every group-scoped write with
/// `is_group_member(group_id)` (0001_core.sql):
/// 1. sign in (anonymous account, P6-T07);
/// 2. send the group row (the server stores the caller as `created_by`; the
///    caller is not a member yet) and then the bootstrap `group_memberships`
///    row, which makes the caller its `owner`. Both go straight to the
///    server. Only after the membership is committed is anything else
///    queued, so the first push can never be answered "not a member" (which
///    would mark the user's own new group `removed`);
/// 3. in ONE local transaction: set the local `created_by` to the account id
///    (new HLC), `local_group_sync = uploading/owner` and queue the full
///    history, live and soft-deleted rows, never local-only data (the full
///    IBAN and the `local_*` tables are not part of any payload);
/// 4. push through [SyncService]; `shared` once the group's outbox is empty.
///
/// Failure never changes local data. Before step 3 the group stays local only
/// (nothing is written); after it the group is `uploading` and everything
/// still waits in the outbox, so this call can simply be repeated or the
/// normal push continues (resumable after a kill). Already `shared`: no-op.
/// Calling it for an `uploading` group skips steps 2 and 3 (the membership is
/// committed by then) and finishes the push.
class ShareGroupRepository {
  ShareGroupRepository({
    required this._db,
    required this._auth,
    required this._remote,
    required this._sync,
    required Clock clock,
    required IdGenerator ids,
  }) : _clock = clock,
       _outbox = OutboxWriter(db: _db, clock: clock, ids: ids);

  final AppDatabase _db;
  final AuthRepository _auth;
  final SyncRemote _remote;
  final SyncService _sync;
  final Clock _clock;
  final OutboxWriter _outbox;

  SyncStateDao get _dao => _db.syncStateDao;

  /// Shares [groupId]; see the class comment.
  Future<Result<ShareProgress, ShareError>> makeShared(String groupId) async {
    final group = await (_db.select(
      _db.groups,
    )..where((g) => g.id.equals(groupId))).getSingleOrNull();
    if (group == null) return const Err(ShareGroupMissing());
    final state = (await _dao.groupSync(groupId))?.state;
    if (state == SyncState.removed.name) return const Err(ShareGroupRemoved());

    final history = await _history(groupId);
    final total = history.length;
    if (state == SyncState.shared.name) {
      return Ok(
        ShareProgress(
          state: SyncState.shared,
          uploaded: total - await _dao.pendingOutboxCount(groupId),
          total: total,
        ),
      );
    }

    ShareUploadFailed failed(RemoteError e, int uploaded) =>
        ShareUploadFailed(uploaded: uploaded, total: total, error: e);

    if (state != SyncState.uploading.name) {
      final signedIn = await _auth.ensureSignedIn();
      if (signedIn case Err(:final error)) return Err(failed(error, 0));
      final uid = (signedIn as Ok<String, RemoteError>).value;
      final bootstrapped = await _bootstrap(groupId);
      if (bootstrapped != null) return Err(failed(bootstrapped, 0));
      await _convert(groupId, uid, history);
    }
    return _upload(groupId, total);
  }

  /// Group row first, then the bootstrap membership; null when both are on
  /// the server. Both calls are replays when an earlier try got this far.
  Future<RemoteError?> _bootstrap(String groupId) async {
    final payload = await _outbox.payloadOf(OutboxEntity.group, groupId);
    final sent = await _remote.upsertRows(OutboxEntity.group.table, [payload]);
    if (sent case Err(:final error)) return error;
    final member = await _remote.bootstrapMembership(groupId);
    if (member case Err(:final error)) return error;
    return null;
  }

  /// One transaction: local `created_by`, `uploading`/`owner`, full history
  /// in the outbox.
  Future<void> _convert(
    String groupId,
    String uid,
    List<({OutboxEntity entity, String id})> history,
  ) => _db.transaction(() async {
    await (_db.update(_db.groups)..where((g) => g.id.equals(groupId))).write(
      GroupsCompanion(createdBy: Value(uid), updatedAt: Value(Hlc.now(_clock))),
    );
    await _dao.setState(groupId, SyncState.uploading, role: SyncRole.owner);
    for (final h in history) {
      await _outbox.enqueue(h.entity, h.id);
    }
  });

  Future<Result<ShareProgress, ShareError>> _upload(
    String groupId,
    int total,
  ) async {
    final status = await _sync.push(groupId);
    final pending = await _dao.pendingOutboxCount(groupId);
    final uploaded = (total - pending).clamp(0, total);
    if (status case SyncError(:final error, :final title)) {
      return Err(
        ShareUploadFailed(
          uploaded: error is Rejected && uploaded > 0 ? uploaded - 1 : uploaded,
          total: total,
          error: error,
          title: title,
        ),
      );
    }
    if (await _dao.groupSync(groupId) case LocalGroupSyncRow(:final state)
        when state == SyncState.removed.name) {
      return const Err(ShareGroupRemoved());
    }
    if (pending == 0) {
      await _dao.setState(groupId, SyncState.shared);
      return Ok(
        ShareProgress(
          state: SyncState.shared,
          uploaded: total,
          total: total,
        ),
      );
    }
    return Ok(
      ShareProgress(
        state: SyncState.uploading,
        uploaded: uploaded,
        total: total,
      ),
    );
  }

  /// Every row of the group in push order, deleted ones included.
  Future<List<({OutboxEntity entity, String id})>> _history(
    String groupId,
  ) async {
    Future<List<String>> ids<T extends HasResultSet, D>(
      ResultSetImplementation<T, D> table,
      GeneratedColumn<String> idCol,
      GeneratedColumn<String> groupCol,
    ) async {
      final rows =
          await (_db.selectOnly(table)
                ..addColumns([idCol])
                ..where(groupCol.equals(groupId))
                ..orderBy([OrderingTerm.asc(idCol)]))
              .get();
      return [for (final r in rows) r.read(idCol)!];
    }

    return [
      (entity: OutboxEntity.group, id: groupId),
      for (final id in await ids(
        _db.members,
        _db.members.id,
        _db.members.groupId,
      ))
        (entity: OutboxEntity.member, id: id),
      for (final id in await ids(
        _db.vehicles,
        _db.vehicles.id,
        _db.vehicles.groupId,
      ))
        (entity: OutboxEntity.vehicle, id: id),
      for (final id in await ids(
        _db.rideTemplates,
        _db.rideTemplates.id,
        _db.rideTemplates.groupId,
      ))
        (entity: OutboxEntity.rideTemplate, id: id),
      for (final id in await ids(
        _db.expenses,
        _db.expenses.id,
        _db.expenses.groupId,
      ))
        (entity: OutboxEntity.expense, id: id),
      for (final id in await ids(_db.rides, _db.rides.id, _db.rides.groupId))
        (entity: OutboxEntity.ride, id: id),
      for (final id in await ids(
        _db.settlements,
        _db.settlements.id,
        _db.settlements.groupId,
      ))
        (entity: OutboxEntity.settlement, id: id),
    ];
  }
}
