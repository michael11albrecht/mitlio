import 'dart:async';

import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/services/auth_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The anonymous account for the share and join commands. Never signs in on
/// its own: app start has no network call (first launch may be offline); the
/// account is created by the first [ensureSignedIn] a user action triggers.
class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

  Future<Result<String, RemoteError>>? _signingIn;

  String? get currentUserId => _service.currentUserId;

  bool get isSignedIn => currentUserId != null;

  Stream<String?> get userChanges => _service.userChanges;

  /// The user id; signs in only when there is no session yet, so a second
  /// call (or one made while the first still runs) does not hit the service
  /// again. On failure the next call tries again.
  Future<Result<String, RemoteError>> ensureSignedIn() {
    final existing = _service.currentUserId;
    if (existing != null) return Future.value(Ok(existing));
    return _signingIn ??= _service.ensureSignedIn().whenComplete(
      () => _signingIn = null,
    );
  }

  /// Drops the local session; throws when that did not work.
  Future<void> clearLocalSession() => _service.clearLocalSession();
}
