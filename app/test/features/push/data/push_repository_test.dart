import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/push_state_store.dart';
import 'package:mitlio/features/push/data/repositories/push_repository.dart';
import 'package:mitlio/features/push/data/services/fake_push_remote.dart';
import 'package:mitlio/features/push/data/services/fake_push_service.dart';
import 'package:mitlio/features/push/data/services/push_service.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../support/capturing_logger.dart';

void main() {
  late FakePushService service;
  late FakePushRemote remote;
  late FakeAuthService authService;
  late MemoryPushStateStore store;
  late CapturingLogger logger;
  late List<Object> errors;
  late PushRepository repo;

  PushRepository build({PushService? withService}) => PushRepository(
    service: withService ?? service,
    remote: remote,
    auth: AuthRepository(authService),
    store: store,
    clock: FixedClock(DateTime.utc(2026, 11, 21, 10)),
    logger: logger,
    localeTag: () => 'de-DE',
    appVersion: () => '0.3.0',
    onError: (e, _) => errors.add(e),
  );

  setUp(() {
    service = FakePushService();
    remote = FakePushRemote(groups: {'g1'});
    authService = FakeAuthService(userId: 'fake-user-1');
    store = MemoryPushStateStore();
    logger = CapturingLogger();
    errors = [];
    repo = build();
  });
  tearDown(() async {
    await repo.dispose();
    await service.dispose();
  });

  group('shouldOffer', () {
    test('once, when push exists and the OS has not decided', () async {
      expect(await repo.shouldOffer(), isTrue);
    });

    test('not without push in this build', () async {
      repo = build(withService: const UnavailablePushService());
      expect(repo.isAvailable, isFalse);
      expect(await repo.shouldOffer(), isFalse);
    });

    test('not when asked before, or when the OS decided', () async {
      await repo.markAsked();
      expect(await repo.shouldOffer(), isFalse);
      store.wasAsked = false;
      service.permissionState = PushPermission.granted;
      expect(await repo.shouldOffer(), isFalse);
      service.permissionState = PushPermission.denied;
      expect(await repo.shouldOffer(), isFalse);
    });

    test(
      'an unreadable flag or permission means no offer, and is logged',
      () async {
        store.failWith = const FileSystemException('disk');
        expect(await repo.shouldOffer(), isFalse);
        expect(logger.output, contains('cannot read the asked flag'));
        store.failWith = null;
        service.failWith = const PushPlatformError('boom');
        expect(await repo.shouldOffer(), isFalse);
        expect(logger.output, contains('permission unreadable'));
      },
    );

    test('markAsked survives a broken disk, and logs it', () async {
      store.failWith = const FileSystemException('full');
      await repo.markAsked();
      expect(logger.output, contains('cannot save the asked flag'));
    });
  });

  group('enable', () {
    test(
      'granted: asks the OS once, registers the token with the account',
      () async {
        final r = await repo.enable();
        expect(r, isA<Ok<PushPermission, PushError>>());
        expect(
          (r as Ok<PushPermission, PushError>).value,
          PushPermission.granted,
        );
        expect(service.permissionRequests, 1);
        expect(store.wasAsked, isTrue);
        expect(store.token, 'fake-token-1');
        final row = remote.tokens.single;
        expect(row.userId, 'fake-user-1');
        expect(row.token, 'fake-token-1');
        expect(row.platform, 'android');
        expect(row.locale, 'de-DE');
        expect(row.appVersion, '0.3.0');
      },
    );

    test('denied: nothing is registered, the answer says denied', () async {
      service.permissionAnswer = PushPermission.denied;
      final r = await repo.enable();
      expect((r as Ok<PushPermission, PushError>).value, PushPermission.denied);
      expect(remote.tokens, isEmpty);
      expect(remote.calls, 0);
      expect(store.token, isNull);
    });

    test('signs in first when there is no account yet', () async {
      authService = FakeAuthService();
      repo = build();
      remote.userId = 'fake-user-1';
      final r = await repo.enable();
      expect(r, isA<Ok<PushPermission, PushError>>());
      expect(authService.signInCalls, 1);
    });

    test('a failed sign-in is an error with the remote case', () async {
      authService = FakeAuthService()..failWith = const Offline();
      repo = build();
      final r = await repo.enable();
      expect(
        (r as Err<PushPermission, PushError>).error,
        isA<PushRemoteError>().having((e) => e.error, 'error', const Offline()),
      );
      expect(remote.calls, 0);
    });

    test('an offline server is an error, nothing is remembered', () async {
      remote.offline = true;
      final r = await repo.enable();
      expect(
        ((r as Err<PushPermission, PushError>).error as PushRemoteError).error,
        const Offline(),
      );
      expect(store.token, isNull);
    });

    test('a rate limit keeps its wait', () async {
      remote.failNext(const RateLimitedRemote(Duration(minutes: 3)));
      final r = await repo.enable();
      expect(
        ((r as Err<PushPermission, PushError>).error as PushRemoteError).error,
        const RateLimitedRemote(Duration(minutes: 3)),
      );
    });

    test('OS failure comes back as the error', () async {
      service.failWith = const PushPlatformError('apns');
      final r = await repo.enable();
      expect(
        (r as Err<PushPermission, PushError>).error,
        isA<PushPlatformError>(),
      );
    });
  });

  group('register', () {
    test('without push: unavailable', () async {
      repo = build(withService: const UnavailablePushService());
      expect(
        (await repo.register() as Err<bool, PushError>).error,
        isA<PushUnavailable>(),
      );
    });

    test('a platform that is neither android nor ios: unavailable', () async {
      service.platform = null;
      expect(
        (await repo.register() as Err<bool, PushError>).error,
        isA<PushUnavailable>(),
      );
    });

    test('permission not granted: nothing registered, no error', () async {
      expect((await repo.register() as Ok<bool, PushError>).value, isFalse);
      expect(remote.calls, 0);
    });

    test('no token yet: error no_token', () async {
      service
        ..permissionState = PushPermission.granted
        ..currentToken = null;
      final e = (await repo.register() as Err<bool, PushError>).error;
      expect((e as PushPlatformError).code, 'no_token');
    });

    test('permission or token failures are passed on', () async {
      service
        ..permissionState = PushPermission.granted
        ..failWith = const PushPlatformError('x');
      expect(await repo.register(), isA<Err<bool, PushError>>());
      service
        ..failWith = null
        ..permissionState = PushPermission.granted;
      final failing = _FailingTokenService();
      repo = build(withService: failing);
      expect(await repo.register(), isA<Err<bool, PushError>>());
    });

    test('repeating it keeps one row and refreshes it', () async {
      service.permissionState = PushPermission.granted;
      await repo.register();
      await repo.register();
      expect(remote.tokens, hasLength(1));
      expect(remote.tokens.single.seen, 2);
    });

    test(
      'a broken disk does not undo the registration, and is logged',
      () async {
        service.permissionState = PushPermission.granted;
        store.failWith = const FileSystemException('full');
        expect((await repo.register() as Ok<bool, PushError>).value, isTrue);
        expect(logger.output, contains('cannot remember the registered token'));
        expect(remote.tokens, hasLength(1));
      },
    );
  });

  group('refresh while started', () {
    test('a rotated token is registered when one was before', () async {
      await repo.enable();
      await repo.start();
      service.emitTokenRefresh('fake-token-2');
      await pumpEventQueue();
      expect(remote.tokensOf('fake-user-1'), contains('fake-token-2'));
      expect(store.token, 'fake-token-2');
    });

    test('a rotated token is ignored while nothing was registered', () async {
      await repo.start();
      service.emitTokenRefresh('fake-token-2');
      await pumpEventQueue();
      expect(remote.calls, 0);
    });

    test('a failed rotation goes to the error sink, not away', () async {
      await repo.enable();
      await repo.start();
      remote.offline = true;
      service.emitTokenRefresh('fake-token-2');
      await pumpEventQueue();
      expect(errors.single, isA<PushRemoteError>());
    });

    test('start re-registers the current token once when registered', () async {
      await repo.enable();
      remote.calls = 0;
      await repo.start();
      await repo.start();
      expect(remote.calls, 1);
      expect(remote.tokens.single.seen, 2);
    });

    test(
      'start does nothing without a registered token or without push',
      () async {
        await repo.start();
        expect(remote.calls, 0);
        repo = build(withService: const UnavailablePushService());
        await repo.start();
        expect(remote.calls, 0);
      },
    );

    test('a failing start refresh goes to the error sink', () async {
      await repo.enable();
      remote.offline = true;
      await repo.start();
      expect(errors.single, isA<PushRemoteError>());
    });

    test('an unreadable state at start goes to the error sink', () async {
      store.failWith = const FileSystemException('gone');
      await repo.start();
      expect(errors.single, isA<FileSystemException>());
    });
  });

  group('unregister', () {
    test(
      'removes the server row, the stored token and the device token',
      () async {
        await repo.enable();
        final r = await repo.unregister();
        expect(r, isA<Ok<void, PushError>>());
        expect(remote.tokens, isEmpty);
        expect(store.token, isNull);
        expect(service.deleteTokenCalls, 1);
      },
    );

    test('never registered: no server call', () async {
      await repo.unregister();
      expect(remote.calls, 0);
    });

    test('signed out already: only the local side is cleaned', () async {
      store.token = 'fake-token-1';
      authService = FakeAuthService();
      repo = build();
      await repo.unregister();
      expect(remote.calls, 0);
      expect(store.token, isNull);
    });

    test(
      'a server failure is returned and the token stays for a retry',
      () async {
        await repo.enable();
        remote.offline = true;
        final r = await repo.unregister();
        expect(
          ((r as Err<void, PushError>).error as PushRemoteError).error,
          const Offline(),
        );
        expect(store.token, 'fake-token-1');
      },
    );

    test('a broken disk is an error', () async {
      store.token = 'x';
      authService = FakeAuthService();
      repo = build();
      // Reads fail (logged), the write then fails too.
      store.failWith = const FileSystemException('gone');
      final r = await repo.unregister();
      expect((r as Err<void, PushError>).error, isA<PushPlatformError>());
      expect(logger.output, contains('cannot read the registered token'));
    });

    test('without push: only the state is cleared', () async {
      repo = build(withService: const UnavailablePushService());
      expect(await repo.unregister(), isA<Ok<void, PushError>>());
    });
  });

  group('prefs', () {
    test('load defaults, then what was saved', () async {
      final first = await repo.loadPrefs('g1');
      expect(
        (first as Ok<NotificationPrefs, PushError>).value,
        const NotificationPrefs(),
      );
      const saved = NotificationPrefs(
        level: NotificationLevel.mine,
        hideAmounts: true,
      );
      await repo.savePrefs('g1', saved);
      final again = await repo.loadPrefs('g1');
      expect((again as Ok<NotificationPrefs, PushError>).value, saved);
    });

    test(
      'save stamps quiet hours with this phone offset and the time',
      () async {
        const quiet = QuietHours(
          startMinutes: 22 * 60,
          endMinutes: 7 * 60,
          utcOffsetMinutes: 0,
        );
        await repo.savePrefs(
          'g1',
          const NotificationPrefs(quietHours: quiet),
        );
        final stored = remote.prefs['fake-user-1|g1']!;
        expect(stored.quietHours!.startMinutes, 22 * 60);
        expect(stored.quietHours!.endMinutes, 7 * 60);
        expect(stored.quietHours!.utcOffsetMinutes, 0);
        expect(remote.lastUpdatedAt, DateTime.utc(2026, 11, 21, 10));
      },
    );

    test('not a member: the remote case comes back', () async {
      final r = await repo.savePrefs('other', const NotificationPrefs());
      expect(
        ((r as Err<void, PushError>).error as PushRemoteError).error,
        const NotMember(),
      );
    });

    test('failures: sign-in and server', () async {
      authService = FakeAuthService()..failWith = const Offline();
      repo = build();
      expect(
        await repo.loadPrefs('g1'),
        isA<Err<NotificationPrefs, PushError>>(),
      );
      expect(
        await repo.savePrefs('g1', const NotificationPrefs()),
        isA<Err<void, PushError>>(),
      );
      authService = FakeAuthService(userId: 'fake-user-1');
      repo = build();
      remote.offline = true;
      expect(
        await repo.loadPrefs('g1'),
        isA<Err<NotificationPrefs, PushError>>(),
      );
    });
  });

  group('FilePushStateStore', () {
    late Directory dir;
    late FilePushStateStore file;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('push_state_test');
      file = FilePushStateStore(File('${dir.path}/push_state.json'));
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('starts empty, remembers both values across instances', () async {
      expect(await file.asked(), isFalse);
      expect(await file.registeredToken(), isNull);
      await file.setAsked();
      await file.setRegisteredToken('t');
      final reopened = FilePushStateStore(File('${dir.path}/push_state.json'));
      expect(await reopened.asked(), isTrue);
      expect(await reopened.registeredToken(), 't');
      await reopened.setRegisteredToken(null);
      expect(await reopened.registeredToken(), isNull);
      expect(await reopened.asked(), isTrue);
    });

    test('a damaged file reads as empty', () async {
      File('${dir.path}/push_state.json').writeAsStringSync('{nope');
      expect(await file.asked(), isFalse);
      File('${dir.path}/push_state.json').writeAsStringSync('[1]');
      expect(await file.registeredToken(), isNull);
    });
  });

  group('services', () {
    test('the unavailable service is inert and says so', () async {
      const s = UnavailablePushService();
      expect(s.isAvailable, isFalse);
      expect(s.platform, isNull);
      expect(
        (await s.permission() as Err<PushPermission, PushError>).error,
        isA<PushUnavailable>(),
      );
      expect(
        await s.requestPermission(),
        isA<Err<PushPermission, PushError>>(),
      );
      expect(await s.token(), isA<Err<String?, PushError>>());
      expect(await s.deleteToken(), isA<Err<void, PushError>>());
      expect(await s.initialMessage(), isNull);
      expect(await s.tokenRefreshes.isEmpty, isTrue);
      expect(await s.foregroundMessages.isEmpty, isTrue);
      expect(await s.backgroundMessages.isEmpty, isTrue);
      expect(await s.openedMessages.isEmpty, isTrue);
    });

    test('the fake: unavailable answers, launch message once', () async {
      service.available = false;
      expect(await service.permission(), isA<Err<PushPermission, PushError>>());
      service
        ..available = true
        ..launchMessage = const PushMessage({'group_id': 'g'});
      expect(await service.initialMessage(), isNotNull);
      expect(await service.initialMessage(), isNull);
    });

    test(
      'the fake remote mirrors the server: moves tokens, keeps newest 20',
      () async {
        remote.userId = 'a';
        await remote.registerToken(token: 't0', platform: 'ios', locale: 'de');
        remote.userId = 'b';
        await remote.registerToken(
          token: 't0',
          platform: 'android',
          locale: 'en',
        );
        expect(remote.tokensOf('a'), isEmpty);
        expect(remote.tokensOf('b'), ['t0']);
        for (var i = 1; i <= 21; i++) {
          await remote.registerToken(
            token: 'n$i',
            platform: 'ios',
            locale: 'de',
          );
        }
        expect(remote.tokensOf('b'), hasLength(20));
        expect(remote.tokensOf('b'), isNot(contains('t0')));
        // Unregistering a token of someone else removes nothing.
        remote.userId = 'a';
        await remote.unregisterToken('n21');
        expect(remote.tokensOf('b'), contains('n21'));
      },
    );
  });
}

/// Permission granted, but the token cannot be read.
class _FailingTokenService extends FakePushService {
  _FailingTokenService() : super(permissionState: PushPermission.granted);

  @override
  Future<Result<String?, PushError>> token() async =>
      const Err(PushPlatformError('token'));
}
