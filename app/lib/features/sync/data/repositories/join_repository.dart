import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/data/repositories/sync_service.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// One person of the group as the "Wer bist du?" picker shows them.
class JoinPerson {
  const JoinPerson({
    required this.id,
    required this.name,
    required this.connected,
  });

  final String id;
  final String name;

  /// Another account is already connected to this person.
  final bool connected;
}

/// The group this account is in after a join, with its people.
class JoinedGroup {
  const JoinedGroup({
    required this.groupId,
    required this.groupName,
    required this.alreadyMember,
    required this.myMemberId,
    required this.people,
    this.createdHere = false,
  });

  final String groupId;
  final String groupName;

  /// The account was in the group before this call.
  final bool alreadyMember;

  /// The person this account is connected to, or null.
  final String? myMemberId;

  /// Live people of the group in list order.
  final List<JoinPerson> people;

  /// The group was put on this phone by this call (it was not here before).
  final bool createdHere;
}

/// Why a join step failed (plain words in `JoinViewModel`).
sealed class JoinFailure {
  const JoinFailure();
}

/// The server said no or did not answer. [localCreated]: the group already
/// exists on this phone (the join itself worked, the first sync did not);
/// false means nothing was created here.
final class JoinRemoteFailure extends JoinFailure {
  const JoinRemoteFailure(this.error, {this.localCreated = false});

  final RemoteError error;
  final bool localCreated;
}

/// This phone's database refused the group or the person.
final class JoinLocalFailure extends JoinFailure {
  const JoinLocalFailure();
}

/// Joins a shared group with its invite link and connects the account to a
/// person (P6-T14b, ADR-24 §1/§5, ADR-27 §3).
///
/// [join]: sign in; `join_group` without a claim (a joiner cannot read the
/// people before joining); then, when the group is not on this phone yet,
/// its row is fetched, `local_group_sync` is created (`shared`, role from
/// `myRole`) and the first pull runs. Failures before the group row is
/// written leave this phone untouched. A repeat is a no-op on the server and
/// skips what is already here, so retrying after any failure is safe.
class JoinRepository {
  JoinRepository({
    required this._db,
    required this._auth,
    required this._invites,
    required this._sync,
    required this._members,
    required this._links,
    required this._logger,
  });

  final AppDatabase _db;
  final AuthRepository _auth;
  final InviteRemote _invites;
  final SyncService _sync;
  final MembersRepository _members;
  final ShareLinkRepository _links;
  final Logger _logger;

  SyncStateDao get _dao => _db.syncStateDao;

  /// Joins the group of [token]; see the class comment. The token is a
  /// secret and never logged.
  Future<Result<JoinedGroup, JoinFailure>> join(String token) async {
    JoinFailure remote(RemoteError e, {bool local = false}) =>
        JoinRemoteFailure(e, localCreated: local);

    final signedIn = await _auth.ensureSignedIn();
    if (signedIn case Err(:final error)) return Err(remote(error));
    final joined = await _invites.joinGroup(token);
    final JoinOutcome outcome;
    switch (joined) {
      case Err(:final error):
        return Err(remote(error));
      case Ok(:final value):
        outcome = value;
    }
    final groupId = outcome.groupId;

    var created = false;
    try {
      final sync = await _dao.groupSync(groupId);
      if (sync == null || sync.state == SyncState.removed.name) {
        final myRole = await _invites.myRole(groupId);
        final SyncRole role;
        switch (myRole) {
          case Err(:final error):
            return Err(remote(error));
          case Ok(:final value):
            role = value;
        }
        if (await _db.groupsDao.findById(groupId) == null) {
          final fetched = await _sync.fetchGroupRow(groupId);
          if (fetched case Err(:final error)) return Err(remote(error));
        }
        created = true;
        await _dao.setState(groupId, SyncState.shared, role: role);
      }
    } on Object catch (e, st) {
      _logger.warn('join: local group not created', e, st);
      return const Err(JoinLocalFailure());
    }

    final status = await _sync.pull(groupId);
    if (status case SyncError(:final error)) {
      return Err(remote(error, local: created));
    }
    if (!await _links.saveToken(groupId, token)) {
      _logger.warn('join: invite link not kept on this phone');
    }
    return _load(
      groupId,
      alreadyMember: outcome.alreadyMember,
      createdHere: created,
    );
  }

  /// Pulls again and reads the people anew (after a person vanished or was
  /// taken). Always leaves the group on this phone as it is.
  Future<Result<JoinedGroup, JoinFailure>> refresh(String groupId) async {
    final status = await _sync.pull(groupId);
    if (status case SyncError(:final error)) {
      return Err(JoinRemoteFailure(error, localCreated: true));
    }
    return _load(groupId, alreadyMember: true);
  }

  Future<Result<JoinedGroup, JoinFailure>> _load(
    String groupId, {
    required bool alreadyMember,
    bool createdHere = false,
  }) async {
    final accounts = await _invites.listMemberships(groupId);
    final List<MembershipInfo> memberships;
    switch (accounts) {
      case Err(:final error):
        return Err(JoinRemoteFailure(error, localCreated: true));
      case Ok(:final value):
        memberships = value;
    }
    try {
      final me = _auth.currentUserId;
      final connected = {
        for (final m in memberships)
          if (m.memberId != null) m.memberId!,
      };
      final mine = memberships
          .where((m) => m.userId == me)
          .map((m) => m.memberId)
          .firstOrNull;
      final people = await _db.membersDao.listByGroup(groupId);
      final group = await _db.groupsDao.findById(groupId);
      return Ok(
        JoinedGroup(
          groupId: groupId,
          groupName: group?.name ?? '',
          alreadyMember: alreadyMember,
          createdHere: createdHere,
          myMemberId: mine,
          people: [
            for (final p in people)
              JoinPerson(
                id: p.id,
                name: p.name,
                connected: connected.contains(p.id) || p.userId != null,
              ),
          ],
        ),
      );
    } on Object catch (e, st) {
      _logger.warn('join: people not readable', e, st);
      return const Err(JoinLocalFailure());
    }
  }

  /// Connects this account to the person [memberId] (`connect_member`).
  Future<Result<void, RemoteError>> connect(
    String groupId,
    String memberId,
  ) async {
    final result = await _invites.connectMember(groupId, memberId);
    switch (result) {
      case Err(:final error):
        return Err(error);
      case Ok():
        await _markConnected(memberId);
        return const Ok(null);
    }
  }

  /// The server set `members.user_id`; mirror it here at once so the badge
  /// does not wait for the next pull.
  Future<void> _markConnected(String memberId) async {
    final me = _auth.currentUserId;
    if (me == null) return;
    try {
      await _db.membersDao.setUserId(memberId, me);
    } on Object catch (e, st) {
      // Connected on the server; the next pull brings the link here.
      _logger.warn('connect: local link not set', e, st);
    }
  }

  /// A new person for the joiner, written locally like any other member
  /// (queued for upload). Returns the person's id.
  Future<Result<String, JoinFailure>> createPerson(
    String groupId,
    String name,
  ) async {
    final added = await _members.add(groupId, name: name);
    switch (added) {
      case Ok(:final value):
        return Ok(value.id);
      case Err(:final error):
        _logger.warn('join: person not created ($error)');
        return const Err(JoinLocalFailure());
    }
  }

  /// Gives the not yet connected new person [personId] the name [name].
  Future<Result<void, JoinFailure>> renamePerson(
    String personId,
    String name,
  ) async {
    final updated = await _members.update(personId, name: name);
    switch (updated) {
      case Ok():
        return const Ok(null);
      case Err(:final error):
        _logger.warn('join: person not renamed ($error)');
        return const Err(JoinLocalFailure());
    }
  }

  /// Uploads what waits for [groupId], so a new person exists on the server
  /// before `connect_member` names it. Err: it is not there yet.
  Future<Result<void, RemoteError>> upload(String groupId) async {
    final status = await _sync.push(groupId);
    return switch (status) {
      SyncIdle() => const Ok(null),
      SyncError(:final error) => Err(error),
      // Waiting for a retry without a recorded error: it did not go out.
      _ => const Err(Offline()),
    };
  }
}
