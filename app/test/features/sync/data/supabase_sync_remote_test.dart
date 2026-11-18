import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';
import 'package:mitlio/features/sync/data/services/supabase_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Seen {
  _Seen(this.method, this.uri, this.body);

  final String method;
  final Uri uri;
  final String body;
}

/// The Supabase sync remote against a loopback PostgREST stand-in: real
/// client, real HTTP, no network.
void main() {
  late HttpServer server;
  late List<_Seen> seen;
  late SupabaseClient client;
  // Answers by "METHOD path", first match wins; (status, body, contentType).
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
        final answer = request.uri.path.startsWith('/auth/')
            ? (200, session())
            : answers[key] ?? (200, '[]');
        if (!request.uri.path.startsWith('/auth/')) {
          seen.add(_Seen(request.method, request.uri, body));
        }
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
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  SupabaseSyncRemote remote() =>
      SupabaseSyncRemote(RemoteBackend.withClient(client));

  Future<void> signIn() => client.auth.signInAnonymously();

  Map<String, Object?> row(String id) => {
    'id': id,
    'group_id': 'g1',
    'updated_at': '0001',
  };

  const stale = (
    400,
    '{"code":"23514","message":"updated_at must not go backwards (a < b)"}',
  );

  group('upsertRows', () {
    test('posts the rows with on_conflict=id', () async {
      final r = await remote().upsertRows(DbTables.members, [row('m1')]);
      expect(r, const Ok<PushOutcome, RemoteError>(PushOutcome.applied));
      final req = seen.single;
      expect(req.method, 'POST');
      expect(req.uri.path, '/rest/v1/members');
      expect(req.uri.queryParameters['on_conflict'], 'id');
      expect(jsonDecode(req.body), [row('m1')]);
    });

    test('the LWW trigger refusal is stale, not an error', () async {
      answers['POST /rest/v1/members'] = stale;
      expect(
        await remote().upsertRows(DbTables.members, [row('m1')]),
        const Ok<PushOutcome, RemoteError>(PushOutcome.stale),
      );
    });

    test('a refused write maps through the error mapper', () async {
      answers['POST /rest/v1/members'] = (
        403,
        jsonEncode({
          'code': '42501',
          'message':
              'new row violates row-level security policy for table "members"',
        }),
      );
      expect(
        await remote().upsertRows(DbTables.members, [row('m1')]),
        const Err<PushOutcome, RemoteError>(NotMember()),
      );
    });

    test('an answer that is not JSON and 5xx is serverDown', () async {
      answers['POST /rest/v1/members'] = (502, 'Bad Gateway');
      expect(
        await remote().upsertRows(DbTables.members, [row('m1')]),
        const Err<PushOutcome, RemoteError>(ServerDown()),
      );
    });

    test('no server at all is offline', () async {
      await server.close(force: true);
      expect(
        await remote().upsertRows(DbTables.members, [row('m1')]),
        const Err<PushOutcome, RemoteError>(Offline()),
      );
    });

    group('groups', () {
      final group = {
        'id': 'g1',
        'name': 'Trip',
        'currency': 'EUR',
        'updated_at': '0001',
      };

      test('an existing group is updated and not inserted', () async {
        answers['PATCH /rest/v1/groups'] = (200, '[{"id":"g1"}]');
        final r = await remote().upsertRows(DbTables.groups, [group]);
        expect(r, const Ok<PushOutcome, RemoteError>(PushOutcome.applied));
        expect(seen.map((s) => s.method), ['PATCH']);
        expect(seen.single.uri.queryParameters['id'], 'eq.g1');
        expect(jsonDecode(seen.single.body), isNot(contains('created_by')));
      });

      test('a new group is inserted with the caller as creator', () async {
        await signIn();
        final r = await remote().upsertRows(DbTables.groups, [group]);
        expect(r, const Ok<PushOutcome, RemoteError>(PushOutcome.applied));
        expect(seen.map((s) => s.method), ['PATCH', 'POST']);
        expect(jsonDecode(seen.last.body), {...group, 'created_by': 'user-42'});
      });

      test('without a session the insert says so, never "offline"', () async {
        final r = await remote().upsertRows(DbTables.groups, [group]);
        expect(
          r,
          const Err<PushOutcome, RemoteError>(Rejected('not_authenticated')),
        );
        expect(seen.map((s) => s.method), ['PATCH']);
      });

      test('a stale group update is stale', () async {
        answers['PATCH /rest/v1/groups'] = stale;
        expect(
          await remote().upsertRows(DbTables.groups, [group]),
          const Ok<PushOutcome, RemoteError>(PushOutcome.stale),
        );
      });

      const duplicate = (
        409,
        '{"code":"23505","message":"duplicate key value violates unique '
            r'constraint \"groups_pkey\""}',
      );

      test('a replayed insert of my own group (not a member yet) is '
          'applied', () async {
        await signIn();
        answers['POST /rest/v1/groups'] = duplicate;
        answers['GET /rest/v1/groups'] = (200, '[{"id":"g1"}]');
        final r = await remote().upsertRows(DbTables.groups, [group]);
        expect(r, const Ok<PushOutcome, RemoteError>(PushOutcome.applied));
        final check = seen.last;
        expect(check.uri.queryParameters['created_by'], 'eq.user-42');
      });

      test(
        'a duplicate key on a group that is not mine stays an error',
        () async {
          await signIn();
          answers['POST /rest/v1/groups'] = duplicate;
          final r = await remote().upsertRows(DbTables.groups, [group]);
          expect(r, isA<Err<PushOutcome, RemoteError>>());
          expect(
            (r as Err<PushOutcome, RemoteError>).error,
            isNot(isA<Offline>()),
          );
        },
      );
    });
  });

  group('bootstrapMembership', () {
    test('inserts my own membership row', () async {
      await signIn();
      final r = await remote().bootstrapMembership('g1');
      expect(r, const Ok<bool, RemoteError>(true));
      expect(seen.map((s) => s.method), ['GET', 'POST']);
      expect(seen.last.uri.path, '/rest/v1/group_memberships');
      expect(jsonDecode(seen.last.body), {
        'group_id': 'g1',
        'user_id': 'user-42',
      });
    });

    test('already a member: done, no insert', () async {
      await signIn();
      answers['GET /rest/v1/group_memberships'] = (200, '[{"id":"m"}]');
      final r = await remote().bootstrapMembership('g1');
      expect(r, const Ok<bool, RemoteError>(false));
      expect(seen.map((s) => s.method), ['GET']);
    });

    test('a refused bootstrap is NotMember', () async {
      await signIn();
      answers['POST /rest/v1/group_memberships'] = (
        403,
        jsonEncode({
          'code': '42501',
          'message':
              'new row violates row-level security policy for table '
              '"group_memberships"',
        }),
      );
      expect(
        await remote().bootstrapMembership('g1'),
        const Err<bool, RemoteError>(NotMember()),
      );
    });

    test('without a session it says so, never "offline"', () async {
      expect(
        await remote().bootstrapMembership('g1'),
        const Err<bool, RemoteError>(Rejected('not_authenticated')),
      );
      expect(seen, isEmpty);
    });

    test('no server at all is offline', () async {
      await signIn();
      await server.close(force: true);
      expect(
        await remote().bootstrapMembership('g1'),
        const Err<bool, RemoteError>(Offline()),
      );
    });
  });

  group('upsertExpense', () {
    final payload = {
      'id': 'e1',
      'group_id': 'g1',
      'payers': <Object?>[],
      'shares': <Object?>[],
    };

    test('calls the RPC with the payload', () async {
      answers['POST /rest/v1/rpc/upsert_expense'] = (
        200,
        '{"applied":true,"expense":{}}',
      );
      expect(
        await remote().upsertExpense(payload),
        const Ok<PushOutcome, RemoteError>(PushOutcome.applied),
      );
      expect(jsonDecode(seen.single.body), {'payload': payload});
    });

    test('applied=false is stale', () async {
      answers['POST /rest/v1/rpc/upsert_expense'] = (
        200,
        '{"applied":false,"expense":{}}',
      );
      expect(
        await remote().upsertExpense(payload),
        const Ok<PushOutcome, RemoteError>(PushOutcome.stale),
      );
    });

    test('an invariant violation keeps its stable code', () async {
      answers['POST /rest/v1/rpc/upsert_expense'] = (
        400,
        '{"code":"23514","message":"payers_sum_mismatch"}',
      );
      expect(
        await remote().upsertExpense(payload),
        const Err<PushOutcome, RemoteError>(Rejected('payers_sum_mismatch')),
      );
    });

    test('not a member is notMember', () async {
      answers['POST /rest/v1/rpc/upsert_expense'] = (
        403,
        '{"code":"42501","message":"not a member of this group"}',
      );
      expect(
        await remote().upsertExpense(payload),
        const Err<PushOutcome, RemoteError>(NotMember()),
      );
    });
  });

  group('pull', () {
    test('filters by group and cursor, ordered, limited', () async {
      answers['GET /rest/v1/members'] = (200, '[{"id":"m1","server_seq":6}]');
      final r = await remote().pullChanges(
        groupId: 'g1',
        table: DbTables.members,
        afterSeq: 5,
        limit: 2,
      );
      expect((r as Ok<List<Map<String, Object?>>, RemoteError>).value, [
        {'id': 'm1', 'server_seq': 6},
      ]);
      final q = seen.single.uri.queryParameters;
      expect(q['group_id'], 'eq.g1');
      expect(q['server_seq'], 'gt.5');
      expect(q['order'], startsWith('server_seq.asc'));
      expect(q['limit'], '2');
    });

    test('the groups table is filtered by its own id', () async {
      await remote().pullChanges(
        groupId: 'g1',
        table: DbTables.groups,
        afterSeq: 0,
        limit: 10,
      );
      expect(seen.single.uri.queryParameters['id'], 'eq.g1');
    });

    test('a failure is mapped', () async {
      answers['GET /rest/v1/members'] = (
        403,
        '{"code":"42501","message":"not a member of this group"}',
      );
      final r = await remote().pullChanges(
        groupId: 'g1',
        table: DbTables.members,
        afterSeq: 0,
        limit: 10,
      );
      expect(
        r,
        const Err<List<Map<String, Object?>>, RemoteError>(NotMember()),
      );
    });
  });

  group('fetchExpenseChildren', () {
    test('groups payers and shares by expense', () async {
      answers['GET /rest/v1/expense_payers'] = (
        200,
        '[{"expense_id":"e1","member_id":"m1","paid_cents":5},'
            '{"expense_id":"e2","member_id":"m2","paid_cents":7}]',
      );
      answers['GET /rest/v1/expense_shares'] = (
        200,
        '[{"expense_id":"e1","member_id":"m1","share_cents":5}]',
      );
      final r = await remote().fetchExpenseChildren(['e1', 'e2']);
      final value = (r as Ok<Map<String, ExpenseChildren>, RemoteError>).value;
      expect(value['e1']!.payers.single['paid_cents'], 5);
      expect(value['e1']!.shares, hasLength(1));
      expect(value['e2']!.payers.single['paid_cents'], 7);
      expect(value['e2']!.shares, isEmpty);
    });

    test('no ids means no request', () async {
      final r = await remote().fetchExpenseChildren([]);
      expect(r, const Ok<Map<String, ExpenseChildren>, RemoteError>({}));
      expect(seen, isEmpty);
    });

    test('a failure is mapped', () async {
      answers['GET /rest/v1/expense_payers'] = (500, 'oops');
      final r = await remote().fetchExpenseChildren(['e1']);
      expect(
        r,
        const Err<Map<String, ExpenseChildren>, RemoteError>(ServerDown()),
      );
    });
  });

  test('without a backend every call says so', () async {
    const none = SupabaseSyncRemote(RemoteBackend.none());
    const gone = Rejected('backend_unavailable');
    expect(
      await none.upsertRows(DbTables.members, [row('m1')]),
      const Err<PushOutcome, RemoteError>(gone),
    );
    expect(
      await none.upsertExpense({}),
      const Err<PushOutcome, RemoteError>(gone),
    );
    expect(
      await none.pullChanges(
        groupId: 'g',
        table: DbTables.members,
        afterSeq: 0,
        limit: 1,
      ),
      const Err<List<Map<String, Object?>>, RemoteError>(gone),
    );
    expect(
      await none.fetchExpenseChildren(['e']),
      const Err<Map<String, ExpenseChildren>, RemoteError>(gone),
    );
  });
}
