import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

class _MemoryStore implements SecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late _MemoryStore store;
  late FakeAuthService service;
  late AuthRepository repo;

  setUp(() {
    store = _MemoryStore();
    service = FakeAuthService(store: store);
    repo = AuthRepository(service);
  });

  test('app start never signs in', () {
    expect(repo.isSignedIn, isFalse);
    expect(repo.currentUserId, isNull);
    expect(service.signInCalls, 0);
  });

  test('first call signs in, the second does not hit the service', () async {
    final first = await repo.ensureSignedIn();
    final second = await repo.ensureSignedIn();
    expect(first, const Ok<String, RemoteError>('fake-user-1'));
    expect(second, first);
    expect(service.signInCalls, 1);
    expect(repo.isSignedIn, isTrue);
    expect(repo.currentUserId, 'fake-user-1');
  });

  test('two calls at once share one sign-in', () async {
    final results = await Future.wait([
      repo.ensureSignedIn(),
      repo.ensureSignedIn(),
    ]);
    expect(results[0], results[1]);
    expect(service.signInCalls, 1);
  });

  test('session is restored after a restart', () async {
    await repo.ensureSignedIn();
    final restarted = AuthRepository(await FakeAuthService.restore(store));
    expect(restarted.currentUserId, 'fake-user-1');
    final again = await restarted.ensureSignedIn();
    expect(again, const Ok<String, RemoteError>('fake-user-1'));
  });

  test('a restart without a session stays signed out', () async {
    final restarted = AuthRepository(await FakeAuthService.restore(store));
    expect(restarted.isSignedIn, isFalse);
  });

  group('failures are passed on and retried', () {
    for (final error in <RemoteError>[
      const Offline(),
      const RateLimitedRemote(null),
      const ServerDown(),
    ]) {
      test(error.caseName, () async {
        service.failWith = error;
        expect(
          await repo.ensureSignedIn(),
          Err<String, RemoteError>(error),
        );
        expect(repo.isSignedIn, isFalse);
        // Not remembered: the next tap tries again and can succeed.
        service.failWith = null;
        expect(await repo.ensureSignedIn(), isA<Ok<String, RemoteError>>());
        expect(service.signInCalls, 2);
      });
    }
  });

  test('userChanges reports sign-in and cleared session', () async {
    final seen = <String?>[];
    final sub = repo.userChanges.listen(seen.add);
    await repo.ensureSignedIn();
    await repo.clearLocalSession();
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, ['fake-user-1', null]);
  });

  test('clearLocalSession forgets the session and the stored copy', () async {
    await repo.ensureSignedIn();
    await repo.clearLocalSession();
    expect(repo.currentUserId, isNull);
    expect(store.values, isEmpty);
    // A later share signs in again, as a new account.
    expect(
      await repo.ensureSignedIn(),
      const Ok<String, RemoteError>('fake-user-2'),
    );
  });

  test('a failing clearLocalSession throws, the session stays', () async {
    await repo.ensureSignedIn();
    service.clearFailWith = Exception('keychain locked');
    await expectLater(repo.clearLocalSession(), throwsException);
    expect(repo.currentUserId, 'fake-user-1');
  });

  group('case names', () {
    test('are stable', () {
      expect(
        [
          const Offline(),
          const RateLimitedRemote(null),
          const InviteInvalid(),
          const MemberAlreadyClaimed(),
          const AlreadyConnected(),
          const MemberGone(),
          const NotOwner(),
          const NotMember(),
          const CannotRemoveSelf(),
          const VersionTooOld(),
          const ServerDown(),
          const Rejected('x'),
        ].map((e) => e.caseName),
        [
          'offline',
          'rateLimited',
          'inviteInvalid',
          'memberAlreadyClaimed',
          'alreadyConnected',
          'memberGone',
          'notOwner',
          'notMember',
          'cannotRemoveSelf',
          'versionTooOld',
          'serverDown',
          'rejected',
        ],
      );
    });
  });
}
