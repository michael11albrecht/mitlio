import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_mapper.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/services/push_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Names of migration 0015 (PR #246). Replace by `DbTables` / `Db*Cols` of
// `db_contract.g.dart` once that PR is merged and the contract regenerated.
const _prefsTable = 'notification_prefs';
const _userId = 'user_id';
const _groupId = 'group_id';
const _level = 'level';
const _quietHours = 'quiet_hours';
const _hideAmounts = 'hide_amounts';
const _updatedAt = 'updated_at';

/// [PushRemote] on the RPCs `register_device_token` /
/// `unregister_device_token` and the caller's `notification_prefs` rows (RLS:
/// own rows). Failures go through the `core/remote` mapper. The token is sent
/// but never logged or put into an error.
class SupabasePushRemote implements PushRemote {
  const SupabasePushRemote(this._backend);

  final RemoteBackend _backend;

  static const _unavailable = Rejected('backend_unavailable');

  SupabaseClient? get _client => switch (_backend.client()) {
    Ok(:final value) => value,
    Err() => null,
  };

  @override
  Future<Result<void, RemoteError>> registerToken({
    required String token,
    required String platform,
    required String locale,
    String? appVersion,
  }) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      await client.rpc<Object?>(
        'register_device_token',
        params: {
          'p_token': token,
          'p_platform': platform,
          'p_locale': locale,
          'p_app_version': appVersion,
        },
      );
      return const Ok(null);
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<void, RemoteError>> unregisterToken(String token) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      await client.rpc<Object?>(
        'unregister_device_token',
        params: {'p_token': token},
      );
      return const Ok(null);
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<NotificationPrefs, RemoteError>> loadPrefs(
    String groupId,
  ) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final rows = await client
          .from(_prefsTable)
          .select('$_level, $_quietHours, $_hideAmounts')
          .eq(_groupId, groupId);
      if (rows.isEmpty) return const Ok(NotificationPrefs());
      final r = rows.first;
      return Ok(
        NotificationPrefs(
          level: NotificationLevel.parse(r[_level]),
          quietHours: QuietHours.fromJson(r[_quietHours]),
          hideAmounts: r[_hideAmounts] == true,
        ),
      );
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<void, RemoteError>> savePrefs(
    String groupId,
    NotificationPrefs prefs, {
    required DateTime updatedAt,
  }) async {
    final client = _client;
    if (client == null) return const Err(_unavailable);
    try {
      final uid = client.auth.currentUser?.id;
      if (uid == null) return const Err(Rejected('not_authenticated'));
      await client.from(_prefsTable).upsert({
        _userId: uid,
        _groupId: groupId,
        _level: prefs.level.name,
        _quietHours: prefs.quietHours?.toJson(),
        _hideAmounts: prefs.hideAmounts,
        _updatedAt: updatedAt.toUtc().toIso8601String(),
      }, onConflict: '$_userId,$_groupId');
      return const Ok(null);
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }
}
