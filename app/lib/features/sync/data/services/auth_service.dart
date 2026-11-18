import 'dart:async';

import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_mapper.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The anonymous account of this install (ADR-08, ADR-27 §2.2). It is created
/// silently the first time someone shares or joins, and lives in secure
/// storage across restarts. There is no sign-out in v1.
abstract interface class AuthService {
  /// The signed-in user, or null (never signed in, or no backend).
  String? get currentUserId;

  /// The current user, signing in anonymously first when there is none. Every
  /// failure is a [RemoteError] with a user-facing text.
  Future<Result<String, RemoteError>> ensureSignedIn();

  /// Emits the user id on every change, null when the session ends.
  Stream<String?> get userChanges;

  /// Drops the session on this device (after "Meine Daten löschen"). Throws
  /// when the session is still there afterwards.
  Future<void> clearLocalSession();
}

/// [AuthService] on Supabase anonymous auth. Errors go through the
/// `core/remote` mapper; nothing else looks at Supabase exceptions.
class SupabaseAuthService implements AuthService {
  const SupabaseAuthService(this._backend);

  final RemoteBackend _backend;

  GoTrueClient? get _auth => switch (_backend.client()) {
    Ok(:final value) => value.auth,
    Err() => null,
  };

  @override
  String? get currentUserId => _auth?.currentUser?.id;

  @override
  Future<Result<String, RemoteError>> ensureSignedIn() async {
    final auth = _auth;
    // Callers hide share/join without a backend; this is the safety net.
    if (auth == null) return const Err(Rejected('backend_unavailable'));
    final existing = auth.currentUser?.id;
    if (existing != null) return Ok(existing);
    try {
      final id = (await auth.signInAnonymously()).user?.id;
      return id == null ? const Err(Rejected('no_user')) : Ok(id);
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Stream<String?> get userChanges =>
      _auth?.onAuthStateChange.map((s) => s.session?.user.id).distinct() ??
      const Stream.empty();

  @override
  Future<void> clearLocalSession() async {
    final auth = _auth;
    if (auth == null) return;
    try {
      await auth.signOut();
    } on Object catch (e) {
      if (e is SessionStorageException) rethrow;
      // The server revoke may fail (offline, user already deleted); only a
      // session that is still here counts as a failure.
      if (auth.currentUser != null) rethrow;
    }
    if (auth.currentUser != null) {
      throw StateError('local session still present after sign out');
    }
    // supabase_flutter only logs a failed keychain delete; do it again here
    // so the failure reaches the user. Harmless when already gone.
    await _backend.sessionStorage?.removePersistedSession();
  }
}
