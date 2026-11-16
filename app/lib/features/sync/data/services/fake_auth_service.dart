import 'dart:async';

import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio/features/sync/data/services/auth_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [AuthService] for tests and DebugDrive. Failures are scripted;
/// an optional [SecretStore] plays the secure storage so a "restart" is a new
/// instance built with [FakeAuthService.restore].
class FakeAuthService implements AuthService {
  FakeAuthService({this._store, this._userId});

  /// A new instance that finds the session [store] kept (an app restart).
  static Future<FakeAuthService> restore(SecretStore store) async =>
      FakeAuthService(store: store, userId: await store.read(sessionKey));

  /// Key of the fake session in the store.
  static const sessionKey = 'fake.auth.user';

  final SecretStore? _store;
  final _changes = StreamController<String?>.broadcast();
  String? _userId;
  var _issued = 0;

  /// Makes [ensureSignedIn] fail with this while set.
  RemoteError? failWith;

  /// Makes [clearLocalSession] throw this while set (session stays).
  Exception? clearFailWith;

  /// How often [ensureSignedIn] had to sign in (hit the "server").
  int signInCalls = 0;

  /// How often [clearLocalSession] ran.
  int clearCalls = 0;

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get userChanges => _changes.stream;

  @override
  Future<Result<String, RemoteError>> ensureSignedIn() async {
    final existing = _userId;
    if (existing != null) return Ok(existing);
    signInCalls++;
    final error = failWith;
    if (error != null) return Err(error);
    final id = 'fake-user-${++_issued}';
    _userId = id;
    await _store?.write(sessionKey, id);
    _changes.add(id);
    return Ok(id);
  }

  @override
  Future<void> clearLocalSession() async {
    clearCalls++;
    final error = clearFailWith;
    if (error != null) throw error;
    _userId = null;
    await _store?.delete(sessionKey);
    _changes.add(null);
  }
}
