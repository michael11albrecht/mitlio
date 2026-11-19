// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What `join_group` / `connect_member` answered: the caller's membership.
class JoinOutcome {
  const JoinOutcome({
    required this.groupId,
    required this.membershipId,
    required this.memberId,
    required this.alreadyMember,
  });

  final String groupId;
  final String membershipId;

  /// The person the account is connected to, or null (not chosen yet).
  final String? memberId;

  /// The account was in the group before this call (idempotent repeat).
  final bool alreadyMember;

  @override
  bool operator ==(Object other) =>
      other is JoinOutcome &&
      other.groupId == groupId &&
      other.membershipId == membershipId &&
      other.memberId == memberId &&
      other.alreadyMember == alreadyMember;

  @override
  int get hashCode =>
      Object.hash(groupId, membershipId, memberId, alreadyMember);

  @override
  String toString() =>
      'JoinOutcome($groupId, $membershipId, $memberId, $alreadyMember)';
}

/// One account in a group (a `group_memberships` row).
class MembershipInfo {
  const MembershipInfo({
    required this.id,
    required this.userId,
    required this.memberId,
    required this.role,
  });

  final String id;
  final String userId;

  /// The person this account is connected to, or null.
  final String? memberId;
  final SyncRole role;

  @override
  bool operator ==(Object other) =>
      other is MembershipInfo &&
      other.id == id &&
      other.userId == userId &&
      other.memberId == memberId &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, userId, memberId, role);

  @override
  String toString() => 'MembershipInfo($id, $memberId, ${role.name})';
}

/// The invite and membership endpoints (ADR-24, ADR-27 §4; RPCs of
/// migrations 0003, 0010, 0012). Every failure is a [RemoteError]; nothing
/// throws. The Supabase implementation is `SupabaseInviteRemote`, the
/// in-memory one `FakeInviteRemote`; both run the shared contract suite.
///
/// Invite tokens are secrets: the server keeps only their hash, so the app
/// stores the one it got. Never log or print a token.
abstract interface class InviteRemote {
  /// Owner only. Makes a new link and revokes every other active link of the
  /// group in the same step (`create_invite`); returns the token, once.
  /// [NotOwner] for everyone else.
  Future<Result<String, RemoteError>> createInvite(String groupId);

  /// Joins the group the [token] belongs to (`join_group`), optionally
  /// connecting to the person [claimMemberId]. Repeating it is a no-op
  /// ([JoinOutcome.alreadyMember]). [InviteInvalid] for an unknown, expired
  /// or revoked token, deliberately without telling which.
  Future<Result<JoinOutcome, RemoteError>> joinGroup(
    String token, {
    String? claimMemberId,
  });

  /// Connects the caller's own membership to the person [memberId]
  /// (`connect_member`).
  Future<Result<JoinOutcome, RemoteError>> connectMember(
    String groupId,
    String memberId,
  );

  /// Owner only: removes an account from the group (`remove_membership`);
  /// the person and their expenses stay. [CannotRemoveSelf] for the owner's
  /// own membership.
  Future<Result<void, RemoteError>> removeMembership(String membershipId);

  /// The accounts of [groupId] the caller may see (members only).
  Future<Result<List<MembershipInfo>, RemoteError>> listMemberships(
    String groupId,
  );

  /// The caller's role in [groupId]; [NotMember] when there is none.
  Future<Result<SyncRole, RemoteError>> myRole(String groupId);

  /// Whether [token] is still the active link of [groupId]. Members can read
  /// the hashes of a group's links, so this needs no `join_group` call (which
  /// is rate limited). `Ok(false)` also for a caller who is not a member.
  Future<Result<bool, RemoteError>> isCurrentLink(
    String groupId,
    String token,
  );
}
