import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/services/supabase_push_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Seen {
  _Seen(this.method, this.uri, this.body);

  final String method;
  final Uri uri;
  final String body;
}

/// The Supabase push remote against a loopback PostgREST stand-in: real
/// client, real HTTP, no network. Names are those of migration 0015.
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

  SupabasePushRemote remote() =>
      SupabasePushRemote(RemoteBackend.withClient(client));

  RemoteError errorOf<T>(Result<T, RemoteError> r) =>
      (r as Err<T, RemoteError>).error;

  (int, String) error(String code, String message) =>
      (400, jsonEncode({'code': code, 'message': message}));

  group('registerToken', () {
    test('calls register_device_token with the four parameters', () async {
      answers['POST /rest/v1/rpc/register_device_token'] = (204, '');
      final r = await remote().registerToken(
        token: 'tok',
        platform: 'ios',
        locale: 'de-DE',
        appVersion: '0.3.0',
      );
      expect(r, isA<Ok<void, RemoteError>>());
      expect(jsonDecode(seen.single.body), {
        'p_token': 'tok',
        'p_platform': 'ios',
        'p_locale': 'de-DE',
        'p_app_version': '0.3.0',
      });
    });

    test('a refused token is Rejected with the server words', () async {
      answers['POST /rest/v1/rpc/register_device_token'] = error(
        '23514',
        'invalid_token',
      );
      expect(
        errorOf(
          await remote().registerToken(
            token: '',
            platform: 'ios',
            locale: 'de',
          ),
        ),
        const Rejected('invalid_token'),
      );
    });

    test('a rate limit carries the wait', () async {
      answers['POST /rest/v1/rpc/register_device_token'] = (
        400,
        jsonEncode({
          'code': 'P0429',
          'message': 'rate_limited',
          'hint': 'retry_after_seconds=120',
        }),
      );
      expect(
        errorOf(
          await remote().registerToken(
            token: 't',
            platform: 'ios',
            locale: 'de',
          ),
        ),
        const RateLimitedRemote(Duration(minutes: 2)),
      );
    });

    test('no backend is reported, not thrown', () async {
      final r = await const SupabasePushRemote(RemoteBackend.none())
          .registerToken(token: 't', platform: 'ios', locale: 'de');
      expect(errorOf(r), const Rejected('backend_unavailable'));
    });
  });

  group('unregisterToken', () {
    test('calls unregister_device_token', () async {
      answers['POST /rest/v1/rpc/unregister_device_token'] = (204, '');
      final r = await remote().unregisterToken('tok');
      expect(r, isA<Ok<void, RemoteError>>());
      expect(jsonDecode(seen.single.body), {'p_token': 'tok'});
    });

    test('failures and no backend', () async {
      answers['POST /rest/v1/rpc/unregister_device_token'] = error(
        '42501',
        'not authenticated',
      );
      expect(
        errorOf(await remote().unregisterToken('t')),
        const Rejected('not authenticated'),
      );
      expect(
        errorOf(
          await const SupabasePushRemote(
            RemoteBackend.none(),
          ).unregisterToken('t'),
        ),
        const Rejected('backend_unavailable'),
      );
    });
  });

  group('loadPrefs', () {
    test('no row: the defaults', () async {
      final r = await remote().loadPrefs('g1');
      expect(
        (r as Ok<NotificationPrefs, RemoteError>).value,
        const NotificationPrefs(),
      );
      expect(seen.single.uri.queryParameters['group_id'], 'eq.g1');
    });

    test('a row: level, quiet hours, hide amounts', () async {
      answers['GET /rest/v1/notification_prefs'] = (
        200,
        jsonEncode([
          {
            'level': 'mine',
            'quiet_hours': {
              'start': '22:00',
              'end': '07:00',
              'utc_offset_minutes': 60,
            },
            'hide_amounts': true,
          },
        ]),
      );
      final r = await remote().loadPrefs('g1');
      expect(
        (r as Ok<NotificationPrefs, RemoteError>).value,
        const NotificationPrefs(
          level: NotificationLevel.mine,
          quietHours: QuietHours(
            startMinutes: 22 * 60,
            endMinutes: 7 * 60,
            utcOffsetMinutes: 60,
          ),
          hideAmounts: true,
        ),
      );
    });

    test('server error and no backend', () async {
      answers['GET /rest/v1/notification_prefs'] = (
        503,
        jsonEncode({'code': 'PGRST000', 'message': 'down'}),
      );
      expect(errorOf(await remote().loadPrefs('g1')), const Rejected('down'));
      expect(
        errorOf(
          await const SupabasePushRemote(RemoteBackend.none()).loadPrefs('g'),
        ),
        const Rejected('backend_unavailable'),
      );
    });
  });

  group('savePrefs', () {
    test('upserts the own row by user and group', () async {
      answers['POST /rest/v1/notification_prefs'] = (201, '');
      final r = await remote().savePrefs(
        'g1',
        const NotificationPrefs(
          level: NotificationLevel.none,
          quietHours: QuietHours(
            startMinutes: 60,
            endMinutes: 120,
            utcOffsetMinutes: 120,
          ),
          hideAmounts: true,
        ),
        updatedAt: DateTime.utc(2026, 11, 21, 10),
      );
      expect(r, isA<Ok<void, RemoteError>>());
      expect(
        seen.single.uri.queryParameters['on_conflict'],
        'user_id,group_id',
      );
      expect(jsonDecode(seen.single.body), {
        'user_id': 'user-42',
        'group_id': 'g1',
        'level': 'none',
        'quiet_hours': {
          'start': '01:00',
          'end': '02:00',
          'utc_offset_minutes': 120,
        },
        'hide_amounts': true,
        'updated_at': '2026-11-21T10:00:00.000Z',
      });
    });

    test('a group the account is not in is NotMember', () async {
      answers['POST /rest/v1/notification_prefs'] = error(
        '42501',
        'new row violates row-level security policy for table '
            '"notification_prefs"',
      );
      expect(
        errorOf(
          await remote().savePrefs(
            'g1',
            const NotificationPrefs(),
            updatedAt: DateTime.utc(2026),
          ),
        ),
        const NotMember(),
      );
    });

    test('no session and no backend', () async {
      await client.auth.signOut();
      expect(
        errorOf(
          await remote().savePrefs(
            'g1',
            const NotificationPrefs(),
            updatedAt: DateTime.utc(2026),
          ),
        ),
        const Rejected('not_authenticated'),
      );
      expect(
        errorOf(
          await const SupabasePushRemote(RemoteBackend.none()).savePrefs(
            'g',
            const NotificationPrefs(),
            updatedAt: DateTime.utc(2026),
          ),
        ),
        const Rejected('backend_unavailable'),
      );
    });
  });
}
