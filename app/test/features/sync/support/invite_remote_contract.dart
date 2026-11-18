import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Four accounts on one server: [owner] creates the group, [joiner] and
/// [other] join it by link, [stranger] never does.
class InviteRemoteFixture {
  const InviteRemoteFixture({
    required this.owner,
    required this.ownerSync,
    required this.joiner,
    required this.other,
    required this.stranger,
  });

  final InviteRemote owner;

  /// The owner's sync endpoints, to create the group and its people.
  final SyncRemote ownerSync;
  final InviteRemote joiner;
  final InviteRemote other;
  final InviteRemote stranger;
}

const _g = '00000000-0000-4000-8000-00000000000a';
const _m1 = '00000000-0000-4000-8000-000000000001';
const _m2 = '00000000-0000-4000-8000-000000000002';
const _ghost = '00000000-0000-4000-8000-0000000000ff';

const _hlc = '2026-03-01T00:00:00.000Z-0001-a';

Map<String, Object?> _group() => {
  DbGroupsCols.id: _g,
  DbGroupsCols.name: 'Trip',
  DbGroupsCols.currency: 'EUR',
  DbGroupsCols.createdAt: '2026-03-01T00:00:00.000Z',
  DbGroupsCols.updatedAt: _hlc,
  DbGroupsCols.deletedAt: null,
};

Map<String, Object?> _member(String id, int position) => {
  DbMembersCols.id: id,
  DbMembersCols.groupId: _g,
  DbMembersCols.name: 'P$position',
  DbMembersCols.position: position,
  DbMembersCols.paypalMe: null,
  DbMembersCols.ibanHint: null,
  DbMembersCols.canDrive: true,
  DbMembersCols.createdAt: '2026-03-01T00:00:00.000Z',
  DbMembersCols.updatedAt: _hlc,
  DbMembersCols.deletedAt: null,
};

T _ok<T>(Result<T, RemoteError> r) {
  expect(r, isA<Ok<T, RemoteError>>(), reason: '$r');
  return (r as Ok<T, RemoteError>).value;
}

RemoteError _err<T>(Result<T, RemoteError> r) {
  expect(r, isA<Err<T, RemoteError>>(), reason: '$r');
  return (r as Err<T, RemoteError>).error;
}

/// Behaviour every [InviteRemote] must show (ADR-24, ADR-27 §3). Runs against
/// the fake now and, in P6-T13, against local Supabase. [create] builds a
/// fresh server per test.
void runInviteRemoteContract(
  String name,
  Future<InviteRemoteFixture> Function() create,
) {
  group('InviteRemote contract: $name', () {
    late InviteRemoteFixture f;

    setUp(() async {
      f = await create();
      _ok(await f.ownerSync.upsertRows('groups', [_group()]));
      _ok(await f.ownerSync.bootstrapMembership(_g));
      _ok(
        await f.ownerSync.upsertRows('members', [
          _member(_m1, 0),
          _member(_m2, 1),
        ]),
      );
    });

    test('the owner creates a link that lets someone join', () async {
      final token = _ok(await f.owner.createInvite(_g));
      expect(token, isNotEmpty);
      final joined = _ok(await f.joiner.joinGroup(token));
      expect(joined.groupId, _g);
      expect(joined.alreadyMember, isFalse);
      expect(joined.memberId, isNull);
      expect(_ok(await f.joiner.myRole(_g)), SyncRole.member);
    });

    test('creating a link again revokes the old one', () async {
      final old = _ok(await f.owner.createInvite(_g));
      final fresh = _ok(await f.owner.createInvite(_g));
      expect(fresh, isNot(old));
      expect(_err(await f.joiner.joinGroup(old)), const InviteInvalid());
      _ok(await f.joiner.joinGroup(fresh));
    });

    test('only the owner can create a link', () async {
      final token = _ok(await f.owner.createInvite(_g));
      _ok(await f.joiner.joinGroup(token));
      expect(_err(await f.joiner.createInvite(_g)), const NotOwner());
      expect(_err(await f.stranger.createInvite(_g)), const NotOwner());
    });

    test('an unknown token is invalid', () async {
      expect(_err(await f.joiner.joinGroup('nope')), const InviteInvalid());
    });

    test('joining twice is a no-op', () async {
      final token = _ok(await f.owner.createInvite(_g));
      final first = _ok(await f.joiner.joinGroup(token));
      final again = _ok(await f.joiner.joinGroup(token));
      expect(again.alreadyMember, isTrue);
      expect(again.membershipId, first.membershipId);
    });

    test(
      'joining can connect to a person; that person is then taken',
      () async {
        final token = _ok(await f.owner.createInvite(_g));
        final joined = _ok(await f.joiner.joinGroup(token, claimMemberId: _m2));
        expect(joined.memberId, _m2);
        expect(
          _err(await f.other.joinGroup(token, claimMemberId: _m2)),
          const MemberAlreadyClaimed(),
        );
        expect(
          _err(await f.other.joinGroup(token, claimMemberId: _ghost)),
          const MemberGone(),
        );
      },
    );

    test(
      'connectMember connects once, repeats are fine, changing is not',
      () async {
        final token = _ok(await f.owner.createInvite(_g));
        _ok(await f.joiner.joinGroup(token));
        expect(_ok(await f.joiner.connectMember(_g, _m1)).memberId, _m1);
        expect(
          _ok(await f.joiner.connectMember(_g, _m1)).alreadyMember,
          isTrue,
        );
        expect(
          _err(await f.joiner.connectMember(_g, _m2)),
          const AlreadyConnected(),
        );
        _ok(await f.other.joinGroup(token));
        expect(
          _err(await f.other.connectMember(_g, _m1)),
          const MemberAlreadyClaimed(),
        );
        expect(
          _err(await f.stranger.connectMember(_g, _m2)),
          const NotMember(),
        );
      },
    );

    test('myRole: owner, member, and not a member', () async {
      _ok(await f.owner.createInvite(_g));
      expect(_ok(await f.owner.myRole(_g)), SyncRole.owner);
      expect(_err(await f.stranger.myRole(_g)), const NotMember());
    });

    test('isCurrentLink is true until the link is replaced', () async {
      final old = _ok(await f.owner.createInvite(_g));
      _ok(await f.joiner.joinGroup(old));
      expect(_ok(await f.joiner.isCurrentLink(_g, old)), isTrue);
      expect(_ok(await f.joiner.isCurrentLink(_g, 'other')), isFalse);
      final fresh = _ok(await f.owner.createInvite(_g));
      expect(_ok(await f.joiner.isCurrentLink(_g, old)), isFalse);
      expect(_ok(await f.joiner.isCurrentLink(_g, fresh)), isTrue);
      expect(_ok(await f.stranger.isCurrentLink(_g, fresh)), isFalse);
    });

    test('the owner lists accounts and removes a member', () async {
      final token = _ok(await f.owner.createInvite(_g));
      _ok(await f.joiner.joinGroup(token, claimMemberId: _m1));
      final all = _ok(await f.owner.listMemberships(_g));
      expect(
        all.map((m) => m.role),
        unorderedEquals([SyncRole.owner, SyncRole.member]),
      );
      final joinerMembership = all.firstWhere((m) => m.memberId == _m1);

      expect(
        _err(await f.joiner.removeMembership(joinerMembership.id)),
        const NotOwner(),
      );
      _ok(await f.owner.removeMembership(joinerMembership.id));
      expect(_err(await f.joiner.myRole(_g)), const NotMember());
      // The person stays and can be taken again.
      _ok(await f.other.joinGroup(token, claimMemberId: _m1));
    });

    test('the owner cannot remove their own membership', () async {
      final own = _ok(await f.owner.listMemberships(_g)).single;
      expect(
        _err(await f.owner.removeMembership(own.id)),
        const CannotRemoveSelf(),
      );
    });
  });
}
