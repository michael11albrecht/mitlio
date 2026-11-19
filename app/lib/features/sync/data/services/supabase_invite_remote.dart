import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_mapper.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _membershipsTable = 'group_memberships';
const _invitesTable = 'group_invites';

/// [InviteRemote] on the RPCs of migrations 0003, 0010 and 0012 and two
/// RLS-guarded reads. Failures go through the `core/remote` mapper. Tokens
/// are sent but never logged, stored or put into an error.
class SupabaseInviteRemote implements InviteRemote {
  const SupabaseInviteRemote(this._backend);

  final RemoteBackend _backend;

  static const _unavailable = Rejected('backend_unavailable');

  SupabaseClient? get _client => switch (_backend.client()) {
    Ok(:final value) => value,
    Err() => null,
  };

  @override
  Future<Result<String, RemoteError>> createInvite(String groupId) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final token = await client.rpc<Object?>(
        'create_invite',
        params: {'gid': groupId},
      );
      if (token is! String || token.isEmpty) {
        return const Err(Rejected('invite_response'));
      }
      return Ok(token);
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<JoinOutcome, RemoteError>> joinGroup(
    String token, {
    String? claimMemberId,
  }) => _outcome(
    'join_group',
    {'token': token, 'claim_member_id': claimMemberId},
  );

  @override
  Future<Result<JoinOutcome, RemoteError>> connectMember(
    String groupId,
    String memberId,
  ) => _outcome('connect_member', {'gid': groupId, 'member_id': memberId});

  Future<Result<JoinOutcome, RemoteError>> _outcome(
    String rpc,
    Map<String, Object?> params,
  ) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final r = await client.rpc<Object?>(rpc, params: params);
      if (r is! Map<String, Object?>) {
        return Err(Rejected('${rpc}_response'));
      }
      return Ok(
        JoinOutcome(
          groupId: r['group_id']! as String,
          membershipId: r['membership_id']! as String,
          memberId: r['member_id'] as String?,
          alreadyMember:
              (r['already_member'] ?? r['already_connected']) == true,
        ),
      );
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<void, RemoteError>> removeMembership(
    String membershipId,
  ) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      await client.rpc<Object?>(
        'remove_membership',
        params: {'membership_id': membershipId},
      );
      return const Ok(null);
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<List<MembershipInfo>, RemoteError>> listMemberships(
    String groupId,
  ) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final rows = await client
          .from(_membershipsTable)
          .select('id, user_id, member_id, role')
          .eq('group_id', groupId);
      return Ok([
        for (final r in rows)
          MembershipInfo(
            id: r['id'] as String,
            userId: r['user_id'] as String,
            memberId: r['member_id'] as String?,
            role: _role(r['role']),
          ),
      ]);
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<SyncRole, RemoteError>> myRole(String groupId) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final uid = client.auth.currentUser?.id;
      if (uid == null) return const Err(Rejected('not_authenticated'));
      final rows = await client
          .from(_membershipsTable)
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', uid);
      if (rows.isEmpty) return const Err(NotMember());
      return Ok(_role(rows.first['role']));
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<bool, RemoteError>> isCurrentLink(
    String groupId,
    String token,
  ) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final rows = await client
          .from(_invitesTable)
          .select('token_hash')
          .eq('group_id', groupId)
          .filter('revoked_at', 'is', null);
      final mine = await _hashHex(token);
      return Ok([for (final r in rows) _hex(r['token_hash'])].contains(mine));
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  static SyncRole _role(Object? v) =>
      v == SyncRole.owner.name ? SyncRole.owner : SyncRole.member;

  static Future<String> _hashHex(String token) async {
    final hash = await Sha256().hash(utf8.encode(token));
    return [
      for (final b in hash.bytes) b.toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  /// PostgREST renders `bytea` as `\x<hex>`.
  static String _hex(Object? bytea) {
    final s = '$bytea'.toLowerCase();
    return s.startsWith(r'\x') ? s.substring(2) : s;
  }
}
