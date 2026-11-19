import 'dart:async';

import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/repositories/connections_repository.dart';
import 'package:mitlio/features/sync/data/repositories/join_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// [ConnectionsRepository] on the local database and the invite endpoints.
/// Connecting reuses [JoinRepository.connect], so the join flow and
/// "Das bin ich" cannot drift apart.
class DriftConnectionsRepository implements ConnectionsRepository {
  DriftConnectionsRepository({
    required this._db,
    required this._auth,
    required this._invites,
    required this._join,
    required this._sync,
    required this._logger,
  });

  final AppDatabase _db;
  final AuthRepository _auth;
  final InviteRemote _invites;
  final JoinRepository _join;
  final SyncService _sync;
  final Logger _logger;

  @override
  Stream<GroupConnections> watch(String groupId) => Stream.multi((out) {
    LocalGroupSyncRow? sync;
    var syncSeen = false;
    List<MemberRow>? people;
    void emit() {
      if (!syncSeen || people == null) return;
      out.add(_compute(sync, people!));
    }

    final subs = [
      _db.syncStateDao.watchGroupSync(groupId).listen(
        (row) {
          sync = row;
          syncSeen = true;
          emit();
        },
        onError: out.addError,
      ),
      _db.membersDao.watchByGroup(groupId).listen(
        (rows) {
          people = rows;
          emit();
        },
        onError: out.addError,
      ),
    ];
    out.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
  });

  GroupConnections _compute(LocalGroupSyncRow? sync, List<MemberRow> people) {
    if (sync == null || sync.state != SyncState.shared.name) {
      return GroupConnections.localOnly;
    }
    final me = _auth.currentUserId;
    return GroupConnections(
      shared: true,
      isOwner: sync.role == SyncRole.owner.name,
      signedIn: me != null,
      connectedIds: {
        for (final p in people)
          if (p.userId != null) p.id,
      },
      myMemberId: me == null
          ? null
          : people.where((p) => p.userId == me).firstOrNull?.id,
    );
  }

  @override
  Future<Result<void, RemoteError>> disconnect(
    String groupId,
    String memberId,
  ) async {
    final listed = await _invites.listMemberships(groupId);
    final List<MembershipInfo> memberships;
    switch (listed) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        memberships = value;
    }
    final target = memberships.where((m) => m.memberId == memberId).firstOrNull;
    if (target != null) {
      // The server refuses it too; this keeps the call from being made.
      if (target.userId == _auth.currentUserId) {
        return const Err(CannotRemoveSelf());
      }
      final removed = await _invites.removeMembership(target.id);
      if (removed case Err(:final error)) return Err(error);
    }
    try {
      await _db.membersDao.setUserId(memberId, null);
    } on Object catch (e, st) {
      // The server did what was asked; the next pull brings the link back to
      // the truth. Nothing to tell the user.
      _logger.warn('disconnect: local link not cleared', e, st);
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, RemoteError>> connectMe(
    String groupId,
    String memberId,
  ) => _join.connect(groupId, memberId);

  @override
  Future<String?> refresh(String groupId) async {
    // A failed pull shows on the status line; the people stay as they are.
    await _sync.pull(groupId);
    final me = _auth.currentUserId;
    if (me == null) return null;
    final people = await _db.membersDao.listByGroup(groupId);
    return people.where((p) => p.userId == me).firstOrNull?.name;
  }
}
