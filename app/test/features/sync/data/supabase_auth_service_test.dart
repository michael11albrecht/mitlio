import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/services/auth_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase service against a loopback GoTrue stand-in: real client,
/// real HTTP, no network.
void main() {
  late HttpServer server;
  late List<HttpRequest> seen;
  var status = 200;
  var body = '';

  String jwt() {
    String part(Object o) =>
        base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    final exp =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000;
    return '${part({'alg': 'HS256'})}.${part({'exp': exp, 'sub': 'u'})}.sig';
  }

  String session(String id) => jsonEncode({
    'access_token': jwt(),
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh',
    'user': {
      'id': id,
      'aud': 'authenticated',
      'is_anonymous': true,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'created_at': '2026-11-16T10:00:00Z',
    },
  });

  setUp(() async {
    seen = [];
    status = 200;
    body = session('3f2a9c1e-0000-4000-8000-000000000001');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.forEach((request) async {
        seen.add(request);
        request.response.statusCode = request.uri.path.endsWith('/logout')
            ? 204
            : status;
        request.response.headers.contentType = ContentType.json;
        if (!request.uri.path.endsWith('/logout')) request.response.write(body);
        await request.response.close();
      }),
    );
  });
  tearDown(() => server.close(force: true));

  SupabaseAuthService service() => SupabaseAuthService(
    RemoteBackend.withClient(
      SupabaseClient(
        'http://${server.address.host}:${server.port}',
        'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    ),
  );

  void failWith(int code, String errorCode) {
    status = code;
    body = jsonEncode({
      'code': code,
      'error_code': errorCode,
      'msg': 'nope',
    });
  }

  test('without a backend: nothing signed in, a clear failure', () async {
    const s = SupabaseAuthService(RemoteBackend.none());
    expect(s.currentUserId, isNull);
    expect(
      await s.ensureSignedIn(),
      const Err<String, RemoteError>(Rejected('backend_unavailable')),
    );
    await s.clearLocalSession();
    expect(await s.userChanges.isEmpty, isTrue);
  });

  test('signs in anonymously once, then reuses the session', () async {
    final s = service();
    expect(s.currentUserId, isNull);
    final first = await s.ensureSignedIn();
    final second = await s.ensureSignedIn();
    const id = '3f2a9c1e-0000-4000-8000-000000000001';
    expect(first, const Ok<String, RemoteError>(id));
    expect(second, first);
    expect(s.currentUserId, id);
    expect(seen, hasLength(1));
    expect(seen.single.uri.path, '/auth/v1/signup');
  });

  test('a sign-in answer without a user is a rejection', () async {
    body = jsonEncode({'access_token': jwt()});
    final r = await service().ensureSignedIn();
    expect(r, isA<Err<String, RemoteError>>());
  });

  test('429 is rateLimited', () async {
    failWith(429, 'over_request_rate_limit');
    expect(
      await service().ensureSignedIn(),
      const Err<String, RemoteError>(RateLimitedRemote(null)),
    );
  });

  test('anonymous sign-ins disabled is serverDown', () async {
    failWith(422, 'anonymous_provider_disabled');
    expect(
      await service().ensureSignedIn(),
      const Err<String, RemoteError>(ServerDown()),
    );
  });

  test('5xx is serverDown', () async {
    failWith(503, 'unexpected_failure');
    expect(
      await service().ensureSignedIn(),
      const Err<String, RemoteError>(ServerDown()),
    );
  });

  test('no connection is offline', () async {
    final s = service();
    await server.close(force: true);
    expect(
      await s.ensureSignedIn(),
      const Err<String, RemoteError>(Offline()),
    );
    // Re-bind so the tearDown has something to close.
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  test('clearLocalSession drops the session', () async {
    final s = service();
    await s.ensureSignedIn();
    await s.clearLocalSession();
    expect(s.currentUserId, isNull);
    // Signing in again is possible (a new account).
    expect(await s.ensureSignedIn(), isA<Ok<String, RemoteError>>());
  });

  test('clearLocalSession works when the server revoke fails', () async {
    final s = service();
    await s.ensureSignedIn();
    await server.close(force: true);
    await s.clearLocalSession();
    expect(s.currentUserId, isNull);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  test('userChanges reports the id and its end', () async {
    final s = service();
    final seenIds = <String?>[];
    final sub = s.userChanges.listen(seenIds.add);
    await s.ensureSignedIn();
    await s.clearLocalSession();
    await pumpEventQueue();
    await sub.cancel();
    expect(seenIds, ['3f2a9c1e-0000-4000-8000-000000000001', null]);
  });
}
