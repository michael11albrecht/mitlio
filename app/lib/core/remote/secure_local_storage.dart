import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mitlio/core/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Key/value store for the session. Seam over `flutter_secure_storage` so the
/// storage logic is testable without a platform channel.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecretStore] on the platform keychain / Keystore.
class FlutterSecretStore implements SecretStore {
  const FlutterSecretStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// The keychain refused to forget the stored session.
class SessionStorageException implements Exception {
  const SessionStorageException(this.cause);

  final Object cause;

  @override
  String toString() => 'SessionStorageException: $cause';
}

/// Supabase session persistence in the secure store: the refresh token never
/// lands in plain preferences (P6-T07a). An unavailable key store degrades to
/// "not signed in" and is logged, never thrown into auth start-up. Deleting
/// the session is the exception: that failure propagates.
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage(this._store, this._logger);

  static const sessionKey = 'mitlio.supabase.session';

  final SecretStore _store;
  final Logger _logger;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _store.read(sessionKey);
    } on Object catch (e, st) {
      _logger.warn('session read failed', e, st);
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _store.write(sessionKey, persistSessionString);
    } on Object catch (e, st) {
      _logger.warn('session write failed', e, st);
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _store.delete(sessionKey);
    } on Object catch (e, st) {
      _logger.warn('session delete failed', e, st);
      // Not swallowed: a session that survives "Meine Daten löschen" must
      // reach the user (#181).
      throw SessionStorageException(e);
    }
  }
}

/// GoTrue's small key/value store (PKCE verifier) on the same secure store,
/// so no `shared_preferences` plugin is needed. Failures are logged, not
/// thrown.
class SecureAsyncStorage extends GotrueAsyncStorage {
  const SecureAsyncStorage(this._store, this._logger);

  static const _prefix = 'mitlio.supabase.pkce.';

  final SecretStore _store;
  final Logger _logger;

  @override
  Future<String?> getItem({required String key}) async {
    try {
      return await _store.read('$_prefix$key');
    } on Object catch (e, st) {
      _logger.warn('auth storage read failed', e, st);
      return null;
    }
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    try {
      await _store.write('$_prefix$key', value);
    } on Object catch (e, st) {
      _logger.warn('auth storage write failed', e, st);
    }
  }

  @override
  Future<void> removeItem({required String key}) async {
    try {
      await _store.delete('$_prefix$key');
    } on Object catch (e, st) {
      _logger.warn('auth storage delete failed', e, st);
    }
  }
}
