import 'dart:async';

import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/services/push_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [PushService] for tests and DebugDrive: the permission answer,
/// the token and failures are scripted, messages are injected with the
/// `emit*` methods.
class FakePushService implements PushService {
  FakePushService({
    this.available = true,
    this.permissionState = PushPermission.undetermined,
    this.currentToken = 'fake-token-1',
    this.platform = 'android',
  });

  /// What [isAvailable] says.
  bool available;

  /// What the OS currently says; [requestPermission] moves it to
  /// [permissionAnswer].
  PushPermission permissionState;

  /// The user's answer to the next [requestPermission].
  PushPermission permissionAnswer = PushPermission.granted;

  /// The token [token] returns; null: none yet.
  String? currentToken;

  @override
  String? platform;

  /// While set, every call fails with this.
  PushError? failWith;

  /// How often [requestPermission] was called.
  int permissionRequests = 0;

  /// How often [deleteToken] ran.
  int deleteTokenCalls = 0;

  final _refreshes = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _background = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  /// The message that started the app, returned once by [initialMessage].
  PushMessage? launchMessage;

  @override
  bool get isAvailable => available;

  Result<T, PushError> _answer<T>(T value) {
    if (!available) return const Err(PushUnavailable());
    final e = failWith;
    return e == null ? Ok(value) : Err(e);
  }

  @override
  Future<Result<PushPermission, PushError>> permission() async =>
      _answer(permissionState);

  @override
  Future<Result<PushPermission, PushError>> requestPermission() async {
    permissionRequests++;
    final r = _answer(permissionAnswer);
    if (r is Ok) permissionState = permissionAnswer;
    return r;
  }

  @override
  Future<Result<String?, PushError>> token() async => _answer(currentToken);

  @override
  Future<Result<void, PushError>> deleteToken() async {
    deleteTokenCalls++;
    final r = _answer<void>(null);
    if (r is Ok) currentToken = null;
    return r;
  }

  @override
  Stream<String> get tokenRefreshes => _refreshes.stream;

  @override
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  @override
  Stream<PushMessage> get backgroundMessages => _background.stream;

  @override
  Stream<PushMessage> get openedMessages => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async {
    final m = launchMessage;
    launchMessage = null;
    return m;
  }

  /// The platform rotates the token.
  void emitTokenRefresh(String token) {
    currentToken = token;
    _refreshes.add(token);
  }

  void emitForeground(PushMessage m) => _foreground.add(m);

  void emitBackground(PushMessage m) => _background.add(m);

  void emitOpened(PushMessage m) => _opened.add(m);

  Future<void> dispose() => Future.wait([
    _refreshes.close(),
    _foreground.close(),
    _background.close(),
    _opened.close(),
  ]);
}
