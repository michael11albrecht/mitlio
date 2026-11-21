import 'dart:collection';

import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/services/push_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// One `device_tokens` row of the fake server.
class FakeDeviceToken {
  FakeDeviceToken({
    required this.userId,
    required this.token,
    required this.platform,
    required this.locale,
    required this.appVersion,
  });

  String userId;
  final String token;
  String platform;
  String locale;
  String? appVersion;

  /// Counts the registrations of this token (`last_seen_at` refreshes).
  int seen = 1;
}

/// In-memory server for tests and DebugDrive; mirrors migration 0015:
/// registering an already known token moves it to the caller, per account the
/// newest 20 tokens are kept, prefs need membership. Failures are scripted
/// with [failNext], [offline] and [fail].
class FakePushRemote implements PushRemote {
  FakePushRemote({this.userId = 'fake-user-1', Set<String>? groups})
    : groups = groups ?? {};

  /// The signed-in account of this view of the server.
  String userId;

  /// Groups the account belongs to (prefs can be written only for these).
  final Set<String> groups;

  /// All tokens of all accounts, oldest first.
  final tokens = <FakeDeviceToken>[];

  /// `userId|groupId` -> row.
  final prefs = <String, NotificationPrefs>{};

  /// When the last [savePrefs] said it was written.
  DateTime? lastUpdatedAt;

  /// While true every call fails with [Offline].
  bool offline = false;

  /// While set, every call fails with this.
  RemoteError? fail;

  final Queue<RemoteError> _scripted = Queue();

  /// Calls attempted, including failed ones.
  int calls = 0;

  /// Makes the next [times] calls fail with [error], then behaves normally.
  void failNext(RemoteError error, {int times = 1}) {
    for (var i = 0; i < times; i++) {
      _scripted.add(error);
    }
  }

  RemoteError? _gate() {
    calls++;
    if (offline) return const Offline();
    if (_scripted.isNotEmpty) return _scripted.removeFirst();
    return fail;
  }

  /// The tokens of [user], oldest first.
  List<String> tokensOf(String user) => [
    for (final t in tokens)
      if (t.userId == user) t.token,
  ];

  @override
  Future<Result<void, RemoteError>> registerToken({
    required String token,
    required String platform,
    required String locale,
    String? appVersion,
  }) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    final known = tokens.where((t) => t.token == token).firstOrNull;
    if (known != null) {
      known
        ..userId = userId
        ..platform = platform
        ..locale = locale
        ..appVersion = appVersion
        ..seen += 1;
      tokens
        ..remove(known)
        ..add(known);
    } else {
      tokens.add(
        FakeDeviceToken(
          userId: userId,
          token: token,
          platform: platform,
          locale: locale,
          appVersion: appVersion,
        ),
      );
    }
    final mine = tokens.where((t) => t.userId == userId).toList();
    mine.take(mine.length > 20 ? mine.length - 20 : 0).forEach(tokens.remove);
    return const Ok(null);
  }

  @override
  Future<Result<void, RemoteError>> unregisterToken(String token) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    tokens.removeWhere((t) => t.token == token && t.userId == userId);
    return const Ok(null);
  }

  @override
  Future<Result<NotificationPrefs, RemoteError>> loadPrefs(
    String groupId,
  ) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    return Ok(prefs['$userId|$groupId'] ?? const NotificationPrefs());
  }

  @override
  Future<Result<void, RemoteError>> savePrefs(
    String groupId,
    NotificationPrefs value, {
    required DateTime updatedAt,
  }) async {
    final gate = _gate();
    if (gate != null) return Err(gate);
    if (!groups.contains(groupId)) return const Err(NotMember());
    prefs['$userId|$groupId'] = value;
    lastUpdatedAt = updatedAt;
    return const Ok(null);
  }
}
