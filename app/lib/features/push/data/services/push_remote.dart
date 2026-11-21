import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The server side of push for the signed-in account: the two token RPCs and
/// the caller's own `notification_prefs` rows (migration 0015, P6b-T02).
/// Every failure is a [RemoteError]; nothing throws. `SupabasePushRemote` is
/// the real one, `FakePushRemote` the in-memory one; both run the contract
/// suite.
abstract interface class PushRemote {
  /// `register_device_token`: upserts by token (a token that belonged to
  /// another account on a shared phone moves to the caller). Repeating it only
  /// refreshes `last_seen_at`.
  Future<Result<void, RemoteError>> registerToken({
    required String token,
    required String platform,
    required String locale,
    String? appVersion,
  });

  /// `unregister_device_token`: removes the caller's row of [token]; an
  /// unknown token is a no-op.
  Future<Result<void, RemoteError>> unregisterToken(String token);

  /// The caller's prefs of [groupId]; the defaults (`all`, no quiet hours,
  /// amounts shown) when there is no row.
  Future<Result<NotificationPrefs, RemoteError>> loadPrefs(String groupId);

  /// Writes the caller's prefs of [groupId] (insert or update). [NotMember]
  /// when the caller is not in the group.
  Future<Result<void, RemoteError>> savePrefs(
    String groupId,
    NotificationPrefs prefs, {
    required DateTime updatedAt,
  });
}
