import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/auth.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;
  late Map<String, DriveHandler> h;

  Map<String, DriveHandler> handlersFor(FakeAuthService service) {
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    return authDriveHandlers(container);
  }

  setUp(() {
    auth = FakeAuthService();
    h = handlersFor(auth);
  });

  test('status: signed out, and it never signs in', () async {
    expect(await h['auth.status']!({}), {
      'signedIn': false,
      'userIdPrefix': null,
    });
    expect(auth.signInCalls, 0);
  });

  test('signIn then status: signed in, only a prefix of the id', () async {
    expect(await h['auth.signIn']!({}), {
      'signedIn': true,
      'userIdPrefix': 'fake-use',
    });
    expect(await h['auth.status']!({}), {
      'signedIn': true,
      'userIdPrefix': 'fake-use',
    });
  });

  test('a short id is reported whole', () async {
    final r = await handlersFor(FakeAuthService(userId: 'abc'))['auth.status']!(
      {},
    );
    expect(r['userIdPrefix'], 'abc');
  });

  test('signIn failure: the RemoteError case name', () async {
    for (final (error, name) in <(RemoteError, String)>[
      (const Offline(), 'offline'),
      (const RateLimitedRemote(null), 'rateLimited'),
      (const ServerDown(), 'serverDown'),
    ]) {
      auth.failWith = error;
      final r = await h['auth.signIn']!({});
      expect(r['error'], name);
      expect(r['message'], isNotEmpty);
    }
    expect((await h['auth.status']!({}))['signedIn'], isFalse);
  });
}
