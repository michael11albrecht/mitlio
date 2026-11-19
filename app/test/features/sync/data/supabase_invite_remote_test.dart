import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio/features/sync/data/services/supabase_invite_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Seen {
  _Seen(this.method, this.uri, this.body);

  final String method;
  final Uri uri;
  final String body;
}

/// The Supabase invite remote against a loopback PostgREST stand-in: real
/// client, real HTTP, no network. The same behaviour is run against local
/// Supabase in P6-T13 through the contract suite.
void main() {
  late HttpServer server;
  late List<_Seen> seen;
  late SupabaseClient client;
  late Map<String, (int, String)> answers;

  String jwt() {
    String part(Object o) =>
        base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    final exp =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000;
    return '${part({'alg': 'HS256'})}.${part({'exp': exp, 'sub': 'u'})}.sig';
  }

  String session() => jsonEncode({
    'access_token': jwt(),
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh',
    'user': {
      'id': 'user-42',
      'aud': 'authenticated',
      'is_anonymous': true,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'created_at': '2026-11-16T10:00:00Z',
    },
  });

  setUp(() async {
    seen = [];
    answers = {};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.forEach((request) async {
        final body = await utf8.decoder.bind(request).join();
        final key = '${request.method} ${request.uri.path}';
        final isAuth = request.uri.path.startsWith('/auth/');
        final answer = isAuth ? (200, session()) : answers[key] ?? (200, '[]');
        if (!isAuth) seen.add(_Seen(request.method, request.uri, body));
        request.response.statusCode = answer.$1;
        request.response.headers.contentType = ContentType.json;
        request.response.write(answer.$2);
        await request.response.close();
      }),
    );
    client = SupabaseClient(
      'http://${server.address.host}:${server.port}',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await client.auth.signInAnonymously();
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  SupabaseInviteRemote remote() =>
      SupabaseInviteRemote(RemoteBackend.withClient(client));

  (int, String) error(String code, String message, {String? hint}) => (
    400,
    jsonEncode({'code': code, 'message': message, 'hint': ?hint}),
  );

  RemoteError errorOf<T>(Result<T, RemoteError> r) =>
      (r as Err<T, RemoteError>).error;

  group('createInvite', () {
    test('calls create_invite and returns the token', () async {
      answers['POST /rest/v1/rpc/create_invite'] = (200, '"tok-123"');
      final r = await remote().createInvite('g1');
      expect(r, const Ok<String, RemoteError>('tok-123'));
      expect(jsonDecode(seen.single.body), {'gid': 'g1'});
    });

    test('a refusal for a non-owner is NotOwner', () async {
      answers['POST /rest/v1/rpc/create_invite'] = error(
        '42501',
        'not the owner of this group',
      );
      expect(errorOf(await remote().createInvite('g1')), const NotOwner());
    });

    test('rate limit carries the wait', () async {
      answers['POST /rest/v1/rpc/create_invite'] = error(
        'P0429',
        'rate_limited',
        hint: 'retry_after_seconds=360',
      );
      expect(
        errorOf(await remote().createInvite('g1')),
        const RateLimitedRemote(Duration(minutes: 6)),
      );
    });

    test('an empty answer is rejected, not shown as a link', () async {
      answers['POST /rest/v1/rpc/create_invite'] = (200, '""');
      expect(
        errorOf(await remote().createInvite('g1')),
        const Rejected('invite_response'),
      );
    });

    test('no backend is reported, not thrown', () async {
      final r = await const SupabaseInviteRemote(
        RemoteBackend.none(),
      ).createInvite('g1');
      expect(errorOf(r), const Rejected('backend_unavailable'));
    });
  });

  group('joinGroup and connectMember', () {
    test('join sends the token and the person, parses the answer', () async {
      answers['POST /rest/v1/rpc/join_group'] = (
        200,
        jsonEncode({
          'group_id': 'g1',
          'membership_id': 'ms1',
          'member_id': 'm1',
          'already_member': true,
        }),
      );
      final r = await remote().joinGroup('tok', claimMemberId: 'm1');
      expect(
        r,
        const Ok<JoinOutcome, RemoteError>(
          JoinOutcome(
            groupId: 'g1',
            membershipId: 'ms1',
            memberId: 'm1',
            alreadyMember: true,
          ),
        ),
      );
      expect(jsonDecode(seen.single.body), {
        'token': 'tok',
        'claim_member_id': 'm1',
      });
    });

    test('an invalid link is InviteInvalid', () async {
      answers['POST /rest/v1/rpc/join_group'] = error(
        '22023',
        'invite_invalid',
      );
      expect(errorOf(await remote().joinGroup('x')), const InviteInvalid());
    });

    test('connect_member reads already_connected', () async {
      answers['POST /rest/v1/rpc/connect_member'] = (
        200,
        jsonEncode({
          'group_id': 'g1',
          'membership_id': 'ms1',
          'member_id': 'm1',
          'already_connected': true,
        }),
      );
      final r = await remote().connectMember('g1', 'm1');
      expect((r as Ok<JoinOutcome, RemoteError>).value.alreadyMember, isTrue);
      expect(jsonDecode(seen.single.body), {'gid': 'g1', 'member_id': 'm1'});
    });

    test('a person that is taken is MemberAlreadyClaimed', () async {
      answers['POST /rest/v1/rpc/connect_member'] = error(
        '23505',
        'member_already_claimed',
      );
      expect(
        errorOf(await remote().connectMember('g1', 'm1')),
        const MemberAlreadyClaimed(),
      );
    });
  });

  group('removeMembership', () {
    test('calls the RPC; owner removing self is CannotRemoveSelf', () async {
      expect(await remote().removeMembership('ms1'), isA<Ok<void, Object>>());
      expect(jsonDecode(seen.single.body), {'membership_id': 'ms1'});
      answers['POST /rest/v1/rpc/remove_membership'] = error(
        '23514',
        'cannot remove own membership',
      );
      expect(
        errorOf(await remote().removeMembership('ms1')),
        const CannotRemoveSelf(),
      );
    });
  });

  group('reads', () {
    test('listMemberships maps rows', () async {
      answers['GET /rest/v1/group_memberships'] = (
        200,
        jsonEncode([
          {'id': 'a', 'user_id': 'u1', 'member_id': null, 'role': 'owner'},
          {'id': 'b', 'user_id': 'u2', 'member_id': 'm1', 'role': 'member'},
        ]),
      );
      final r = await remote().listMemberships('g1');
      expect(
        (r as Ok<List<MembershipInfo>, RemoteError>).value,
        const [
          MembershipInfo(
            id: 'a',
            userId: 'u1',
            memberId: null,
            role: SyncRole.owner,
          ),
          MembershipInfo(
            id: 'b',
            userId: 'u2',
            memberId: 'm1',
            role: SyncRole.member,
          ),
        ],
      );
      expect(seen.single.uri.queryParameters['group_id'], 'eq.g1');
    });

    test('myRole: the own row, or NotMember without one', () async {
      answers['GET /rest/v1/group_memberships'] = (
        200,
        jsonEncode([
          {'role': 'owner'},
        ]),
      );
      expect(
        await remote().myRole('g1'),
        const Ok<SyncRole, RemoteError>(SyncRole.owner),
      );
      expect(seen.single.uri.queryParameters['user_id'], 'eq.user-42');
      answers['GET /rest/v1/group_memberships'] = (200, '[]');
      expect(errorOf(await remote().myRole('g1')), const NotMember());
    });

    test('isCurrentLink compares the SHA-256 of the token with the '
        'hashes of the active links', () async {
      final hash = await Sha256().hash(utf8.encode('tok-abc'));
      final hex = [
        for (final b in hash.bytes) b.toRadixString(16).padLeft(2, '0'),
      ].join();
      answers['GET /rest/v1/group_invites'] = (
        200,
        jsonEncode([
          {'token_hash': r'\x' + hex},
        ]),
      );
      expect(
        await remote().isCurrentLink('g1', 'tok-abc'),
        const Ok<bool, RemoteError>(true),
      );
      expect(
        await remote().isCurrentLink('g1', 'tok-other'),
        const Ok<bool, RemoteError>(false),
      );
      expect(seen.first.uri.queryParameters['revoked_at'], 'is.null');
      // The token itself never goes over the wire here.
      expect(seen.map((s) => s.uri.toString()).join(), isNot(contains('tok-')));
    });
  });
}
