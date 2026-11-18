import 'dart:collection';

import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/fake_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

class _Invite {
  _Invite(this.groupId, this.token);

  final String groupId;
  final String token;
  bool revoked = false;
}

class _World {
  final invites = <_Invite>[];

  /// `groupId` -> account -> connected person (null: none yet).
  final claims = <String, Map<String, String?>>{};
  int issued = 0;
}

/// In-memory invite server for tests and DebugDrive (ADR-27 §4). It sits on a
/// [FakeSyncRemote] (the same server and account) and mirrors migrations
/// 0003, 0010 and 0012:
/// - `create_invite` is for the group's creator (the owner) only and revokes
///   every other active link of the group;
/// - `join_group` accepts only the active link, is idempotent, and can claim
///   an unclaimed person of the group;
/// - `connect_member` / `remove_membership` follow the 0010 rules.
/// Failures are scripted with [failNext], [offline] and [fail].
class FakeInviteRemote implements InviteRemote {
  FakeInviteRemote({required this.sync}) : _world = _World();

  /// Another account on the same server; [sync] is that account's view.
  FakeInviteRemote.sharing(FakeInviteRemote other, {required this.sync})
    : _world = other._world;

  /// This account's view of the shared server (membership, groups, people).
  final FakeSyncRemote sync;
  final _World _world;

  /// While true every call fails with [Offline].
  bool offline = false;

  /// While set, every call fails with this.
  RemoteError? fail;

  final Queue<RemoteError> _scripted = Queue();

  /// Calls attempted, including failed ones.
  int calls = 0;

  /// Makes the next [times] calls fail with [error], then behaves normally.
  void failNext(RemoteError error, {int times = 1}) {
    for (var i = 0; i < times; i++) {
      _scripted.add(error);
    }
  }

  String get _me => sync.userId;

  RemoteError? _gate() {
    calls++;
    if (offline) return const Offline();
    if (_scripted.isNotEmpty) return _scripted.removeFirst();
    return fail;
  }

  /// Account -> connected person; the owner is always listed.
  Map<String, String?> _claimsOf(String groupId) {
    final claims = _world.claims[groupId] ??= {};
    final owner = sync.creatorOf(groupId);
    if (owner != null) claims.putIfAbsent(owner, () => null);
    return claims;
  }

  bool _isOwner(String groupId) => sync.creatorOf(groupId) == _me;

  bool _isMember(String groupId) => sync.membersOf(groupId).contains(_me);

  String _membershipId(String groupId, String user) => 'ms-$groupId-$user';

  @override
  Future<Result<String, RemoteError>> createInvite(String groupId) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    if (!_isOwner(groupId) || !_isMember(groupId)) return const Err(NotOwner());
    _claimsOf(groupId);
    for (final i in _world.invites.where((i) => i.groupId == groupId)) {
      i.revoked = true;
    }
    final token = 'fake${(++_world.issued).toString().padLeft(39, '0')}';
    _world.invites.add(_Invite(groupId, token));
    return Ok(token);
  }

  @override
  Future<Result<JoinOutcome, RemoteError>> joinGroup(
    String token, {
    String? claimMemberId,
  }) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    final invite = _world.invites
        .where((i) => i.token == token && !i.revoked)
        .firstOrNull;
    if (invite == null) return const Err(InviteInvalid());
    final gid = invite.groupId;
    final claims = _claimsOf(gid);
    final already = _isMember(gid);
    if (already) {
      final current = claims[_me];
      if (claimMemberId != null && current != claimMemberId) {
        if (current != null) return const Err(AlreadyConnected());
        final e = _claim(gid, claimMemberId);
        if (e != null) return Err(e);
        claims[_me] = claimMemberId;
      }
    } else {
      if (claimMemberId != null) {
        final e = _claim(gid, claimMemberId);
        if (e != null) return Err(e);
      }
      sync.addMember(gid);
      claims[_me] = claimMemberId;
    }
    return Ok(_outcome(gid, alreadyMember: already));
  }

  @override
  Future<Result<JoinOutcome, RemoteError>> connectMember(
    String groupId,
    String memberId,
  ) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    if (!_isMember(groupId)) return const Err(NotMember());
    final claims = _claimsOf(groupId);
    final current = claims[_me];
    if (current == memberId) {
      return Ok(_outcome(groupId, alreadyMember: true));
    }
    if (current != null) return const Err(AlreadyConnected());
    final e = _claim(groupId, memberId);
    if (e != null) return Err(e);
    claims[_me] = memberId;
    return Ok(_outcome(groupId, alreadyMember: false));
  }

  /// The person must exist in the group, live, and not be connected yet.
  RemoteError? _claim(String groupId, String memberId) {
    final row = sync.row(DbTables.members, memberId);
    if (row == null ||
        row[DbMembersCols.groupId] != groupId ||
        row[DbMembersCols.deletedAt] != null) {
      return const MemberGone();
    }
    final taken = (_world.claims[groupId] ?? {}).values.contains(memberId);
    return taken ? const MemberAlreadyClaimed() : null;
  }

  JoinOutcome _outcome(String groupId, {required bool alreadyMember}) =>
      JoinOutcome(
        groupId: groupId,
        membershipId: _membershipId(groupId, _me),
        memberId: _world.claims[groupId]?[_me],
        alreadyMember: alreadyMember,
      );

  @override
  Future<Result<void, RemoteError>> removeMembership(
    String membershipId,
  ) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    for (final entry in _world.claims.entries) {
      for (final user in entry.value.keys) {
        if (_membershipId(entry.key, user) != membershipId) continue;
        if (!_isOwner(entry.key)) return const Err(NotOwner());
        if (user == _me) return const Err(CannotRemoveSelf());
        sync.removeMember(entry.key, user: user);
        entry.value.remove(user);
        return const Ok(null);
      }
    }
    // Unknown and foreign look the same (0010).
    return const Err(NotOwner());
  }

  @override
  Future<Result<List<MembershipInfo>, RemoteError>> listMemberships(
    String groupId,
  ) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    if (!_isMember(groupId)) return const Ok([]);
    _claimsOf(groupId);
    return Ok([
      for (final user in sync.membersOf(groupId).toList()..sort())
        MembershipInfo(
          id: _membershipId(groupId, user),
          userId: user,
          memberId: _world.claims[groupId]?[user],
          role: sync.creatorOf(groupId) == user
              ? SyncRole.owner
              : SyncRole.member,
        ),
    ]);
  }

  @override
  Future<Result<SyncRole, RemoteError>> myRole(String groupId) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    if (!_isMember(groupId)) return const Err(NotMember());
    return Ok(_isOwner(groupId) ? SyncRole.owner : SyncRole.member);
  }

  @override
  Future<Result<bool, RemoteError>> isCurrentLink(
    String groupId,
    String token,
  ) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    if (!_isMember(groupId)) return const Ok(false);
    return Ok(
      _world.invites.any(
        (i) => i.groupId == groupId && i.token == token && !i.revoked,
      ),
    );
  }
}
