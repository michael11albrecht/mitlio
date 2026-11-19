import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Who is connected to whom in one group, as this phone knows it (ADR-24 §1,
/// §5). People and accounts stay two things; "verbunden" is the only word.
class GroupConnections {
  const GroupConnections({
    required this.shared,
    required this.isOwner,
    required this.signedIn,
    required this.connectedIds,
    required this.myMemberId,
  });

  /// A local-only group: nothing to show, nothing to do.
  static const localOnly = GroupConnections(
    shared: false,
    isOwner: false,
    signedIn: false,
    connectedIds: {},
    myMemberId: null,
  );

  /// The group is shared (state `shared`); only then connections exist.
  final bool shared;

  /// `local_group_sync.role == owner`.
  final bool isOwner;

  /// This phone has an account.
  final bool signedIn;

  /// People with a connected account (`members.user_id` is set).
  final Set<String> connectedIds;

  /// The person this phone's account is connected to, or null.
  final String? myMemberId;

  /// "Das bin ich" is offered: a signed-in member of a shared group who is
  /// not connected to any person yet.
  bool get canClaimSelf => shared && signedIn && myMemberId == null;
}

/// Connections of a group and the two commands on them (P6-T14d). Failures
/// are [RemoteError]s; nothing throws.
abstract interface class ConnectionsRepository {
  /// Emits on every change of the group's sync state or its people.
  Stream<GroupConnections> watch(String groupId);

  /// Owner only: ends the account connected to [memberId]
  /// (`remove_membership`). The person and their expenses stay. A person
  /// nobody is connected to on the server is a no-op that clears the stale
  /// local link.
  Future<Result<void, RemoteError>> disconnect(
    String groupId,
    String memberId,
  );

  /// Connects this phone's account to [memberId] (`connect_member`, the path
  /// of the join flow).
  Future<Result<void, RemoteError>> connectMe(
    String groupId,
    String memberId,
  );

  /// Pulls again after a refused connect and returns the name of the person
  /// this phone is connected to, or null.
  Future<String?> refresh(String groupId);
}
