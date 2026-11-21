import 'dart:async';

import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/logging.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/push_state_store.dart';
import 'package:mitlio/features/push/data/services/push_remote.dart';
import 'package:mitlio/features/push/data/services/push_service.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Permission flow, device token and per-group prefs (P6b-T06, T08).
///
/// - The permission is asked contextually (after the first share or join),
///   once, and only when the user accepts the offer ([enable]).
/// - The token goes to `device_tokens` on [enable], on rotation, and on every
///   start while registered; [unregister] removes it (sign-out, delete my
///   data). Nothing here touches the network while nothing was registered.
/// - Every failure is a [PushError] the caller shows; the background upkeep of
///   [start] reports through `onError` (error sink), never silently.
class PushRepository {
  PushRepository({
    required this._service,
    required this._remote,
    required this._auth,
    required this._store,
    required this._clock,
    required this._logger,
    required this._localeTag,
    required this._appVersion,
    required this._onError,
  });

  final PushService _service;
  final PushRemote _remote;
  final AuthRepository _auth;
  final PushStateStore _store;
  final Clock _clock;
  final Logger _logger;
  final String Function() _localeTag;
  final String? Function() _appVersion;
  final void Function(Object error, StackTrace stack) _onError;

  StreamSubscription<String>? _refreshes;

  /// Whether this build can receive pushes at all.
  bool get isAvailable => _service.isAvailable;

  /// The OS permission, without asking.
  Future<Result<PushPermission, PushError>> permission() =>
      _service.permission();

  /// True when the contextual offer should be made now: pushes are possible,
  /// the user was never asked, and the OS has not decided yet.
  Future<bool> shouldOffer() async {
    if (!_service.isAvailable) return false;
    try {
      if (await _store.asked()) return false;
    } on Object catch (e, st) {
      _logger.warn('push: cannot read the asked flag, not offering', e, st);
      return false;
    }
    return switch (await _service.permission()) {
      Ok(value: PushPermission.undetermined) => true,
      Ok() => false,
      Err(:final error) => _logFalse('push: permission unreadable', error),
    };
  }

  bool _logFalse(String what, Object error) {
    _logger.warn('$what: $error');
    return false;
  }

  /// "Nicht jetzt": the offer is not made again (Settings still has it).
  Future<void> markAsked() async {
    try {
      await _store.setAsked();
    } on Object catch (e, st) {
      // Worst case the offer shows once more; nothing the user must act on.
      _logger.warn('push: cannot save the asked flag', e, st);
    }
  }

  /// The user accepted: ask the OS, and when it says yes register the device.
  /// The answer is the OS answer (granted or denied).
  Future<Result<PushPermission, PushError>> enable() async {
    await markAsked();
    final asked = await _service.requestPermission();
    if (asked case Ok(value: PushPermission.granted)) {
      return switch (await register()) {
        Ok() => asked,
        Err(:final error) => Err(error),
      };
    }
    return asked;
  }

  /// Registers this device's token. `Ok(false)` when the permission is not
  /// granted (nothing to register); `Ok(true)` when the server has the token.
  Future<Result<bool, PushError>> register() async {
    final platform = _service.platform;
    if (!_service.isAvailable || platform == null) {
      return const Err(PushUnavailable());
    }
    final permission = await _service.permission();
    if (permission case Err(:final error)) return Err(error);
    if (permission case Ok(value: != PushPermission.granted)) {
      return const Ok(false);
    }
    return switch (await _service.token()) {
      Err(:final error) => Err(error),
      Ok(value: null) => const Err(PushPlatformError('no_token')),
      Ok(:final value?) => await _send(value, platform),
    };
  }

  Future<Result<bool, PushError>> _send(String token, String platform) async {
    final signedIn = await _auth.ensureSignedIn();
    if (signedIn case Err(:final error)) return Err(PushRemoteError(error));
    final sent = await _remote.registerToken(
      token: token,
      platform: platform,
      locale: _localeTag(),
      appVersion: _appVersion(),
    );
    if (sent case Err(:final error)) return Err(PushRemoteError(error));
    try {
      await _store.setRegisteredToken(token);
    } on Object catch (e, st) {
      // The server has it; only the rotation check on the next start is lost.
      _logger.warn('push: cannot remember the registered token', e, st);
    }
    return const Ok(true);
  }

  /// Removes this device's token from the server and the device (sign-out,
  /// delete my data). Without a registered token nothing is called.
  Future<Result<void, PushError>> unregister() async {
    String? token;
    try {
      token = await _store.registeredToken();
    } on Object catch (e, st) {
      _logger.warn('push: cannot read the registered token', e, st);
    }
    if (token != null && _auth.isSignedIn) {
      final removed = await _remote.unregisterToken(token);
      if (removed case Err(:final error)) return Err(PushRemoteError(error));
    }
    try {
      await _store.setRegisteredToken(null);
    } on Object catch (e) {
      return Err(PushPlatformError('state: $e'));
    }
    if (!_service.isAvailable) return const Ok(null);
    return _service.deleteToken();
  }

  /// Keeps the server's token current: registers a rotated token, and the
  /// current one once per start (refreshes `last_seen_at`). Only while a token
  /// was registered before. Failures go to the error sink.
  Future<void> start() async {
    if (_refreshes != null || !_service.isAvailable) return;
    _refreshes = _service.tokenRefreshes.listen(
      (token) => unawaited(_onRefresh(token)),
    );
    String? known;
    try {
      known = await _store.registeredToken();
    } on Object catch (e, st) {
      _onError(e, st);
    }
    if (known != null) await _refresh();
  }

  Future<void> _onRefresh(String token) async {
    try {
      final known = await _store.registeredToken();
      final platform = _service.platform;
      if (known == null || platform == null) return;
      final sent = await _send(token, platform);
      if (sent case Err(:final error)) {
        _onError(error, StackTrace.current);
      }
    } on Object catch (e, st) {
      _onError(e, st);
    }
  }

  Future<void> _refresh() async {
    final r = await register();
    if (r case Err(:final error)) _onError(error, StackTrace.current);
  }

  Future<void> dispose() async {
    await _refreshes?.cancel();
    _refreshes = null;
  }

  // ---- per-group prefs (P6b-T08) -------------------------------------

  Future<Result<NotificationPrefs, PushError>> loadPrefs(
    String groupId,
  ) async {
    final signedIn = await _auth.ensureSignedIn();
    if (signedIn case Err(:final error)) return Err(PushRemoteError(error));
    return switch (await _remote.loadPrefs(groupId)) {
      Ok(:final value) => Ok(value),
      Err(:final error) => Err(PushRemoteError(error)),
    };
  }

  /// Saves [prefs]; quiet hours are stamped with this phone's current UTC
  /// offset, which the server needs to compare in UTC.
  Future<Result<void, PushError>> savePrefs(
    String groupId,
    NotificationPrefs prefs,
  ) async {
    final signedIn = await _auth.ensureSignedIn();
    if (signedIn case Err(:final error)) return Err(PushRemoteError(error));
    final now = _clock.now();
    final quiet = prefs.quietHours;
    final stamped = quiet == null
        ? prefs
        : NotificationPrefs(
            level: prefs.level,
            quietHours: QuietHours(
              startMinutes: quiet.startMinutes,
              endMinutes: quiet.endMinutes,
              utcOffsetMinutes: now.timeZoneOffset.inMinutes,
            ),
            hideAmounts: prefs.hideAmounts,
          );
    return switch (await _remote.savePrefs(
      groupId,
      stamped,
      updatedAt: now,
    )) {
      Ok() => const Ok(null),
      Err(:final error) => Err(PushRemoteError(error)),
    };
  }
}
