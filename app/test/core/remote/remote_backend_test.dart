import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app_config.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/capturing_logger.dart';

class _MemoryStore implements SecretStore {
  final values = <String, String>{};
  Exception? failWith;

  @override
  Future<String?> read(String key) async {
    if (failWith != null) throw failWith!;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWith != null) throw failWith!;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failWith != null) throw failWith!;
    values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('without a backend (empty config)', () {
    test('initialize returns none and never creates a client', () async {
      final backend = await RemoteBackend.initialize(
        const AppConfig(),
        store: _MemoryStore(),
        logger: CapturingLogger(),
      );
      expect(backend.isAvailable, isFalse);
      expect(
        backend.client(),
        const Err<SupabaseClient, BackendUnavailable>(
          BackendUnavailable(),
        ),
      );
    });

    test('only a url is not enough', () async {
      final backend = await RemoteBackend.initialize(
        const AppConfig(supabaseUrl: 'https://x.supabase.co'),
        store: _MemoryStore(),
        logger: CapturingLogger(),
      );
      expect(backend.isAvailable, isFalse);
    });

    test('BackendUnavailable prints', () {
      expect(const BackendUnavailable().toString(), 'BackendUnavailable()');
    });
  });

  group('with a backend', () {
    test('creates the client without any network call', () async {
      final store = _MemoryStore();
      final backend = await RemoteBackend.initialize(
        const AppConfig(
          supabaseUrl: 'http://localhost:54321',
          supabaseAnonKey: 'anon-test-key',
        ),
        store: store,
        logger: CapturingLogger(),
      );
      expect(backend.isAvailable, isTrue);
      expect(backend.client(), isA<Ok<SupabaseClient, BackendUnavailable>>());
      expect(store.values, isEmpty, reason: 'no session without sign-in');
    });
  });

  group('SecureAsyncStorage', () {
    test('get, set, remove and failures are logged', () async {
      final store = _MemoryStore();
      final logger = CapturingLogger();
      final storage = SecureAsyncStorage(store, logger);
      expect(await storage.getItem(key: 'k'), isNull);
      await storage.setItem(key: 'k', value: 'v');
      expect(await storage.getItem(key: 'k'), 'v');
      await storage.removeItem(key: 'k');
      expect(await storage.getItem(key: 'k'), isNull);

      store.failWith = Exception('no keystore');
      expect(await storage.getItem(key: 'k'), isNull);
      await storage.setItem(key: 'k', value: 'secret');
      await storage.removeItem(key: 'k');
      expect(logger.output, contains('auth storage read failed'));
      expect(logger.output, contains('auth storage write failed'));
      expect(logger.output, contains('auth storage delete failed'));
      expect(logger.output, isNot(contains('secret')));
    });
  });

  group('SecureLocalStorage', () {
    late _MemoryStore store;
    late CapturingLogger logger;
    late SecureLocalStorage storage;

    setUp(() {
      store = _MemoryStore();
      logger = CapturingLogger();
      storage = SecureLocalStorage(store, logger);
    });

    test('persist, read, remove', () async {
      await storage.initialize();
      expect(await storage.hasAccessToken(), isFalse);
      await storage.persistSession('{"refresh_token":"r"}');
      expect(store.values[SecureLocalStorage.sessionKey], isNotNull);
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), '{"refresh_token":"r"}');
      await storage.removePersistedSession();
      expect(await storage.accessToken(), isNull);
    });

    test('an unavailable key store means signed out and is logged, '
        'without the session value', () async {
      store.failWith = Exception('no keystore');
      expect(await storage.hasAccessToken(), isFalse);
      await storage.persistSession('secret-refresh-token');
      await storage.removePersistedSession();
      expect(logger.output, contains('session read failed'));
      expect(logger.output, contains('session write failed'));
      expect(logger.output, contains('session delete failed'));
      expect(logger.output, isNot(contains('secret-refresh-token')));
    });
  });
}
