import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory `app_config` for tests and DebugDrive. Set [rows] to script the
/// server; [offline] and [fail] script failures.
class FakeAppConfigRemote implements AppConfigRemote {
  FakeAppConfigRemote({Map<String, MinVersionConfig>? rows})
    : rows = rows ?? {};

  /// Rows by platform (`ios`, `android`).
  final Map<String, MinVersionConfig> rows;

  /// Platforms whose tip jar flag (0017) is on.
  final Set<String> supportTips = {};

  /// While true every call fails with [Offline].
  bool offline = false;

  /// While set, every call fails with this.
  RemoteError? fail;

  /// Calls attempted, including failed ones.
  int calls = 0;

  @override
  Future<Result<MinVersionConfig?, RemoteError>> minSupportedVersion(
    String platform,
  ) async {
    calls++;
    if (offline) return const Err(Offline());
    final failure = fail;
    if (failure != null) return Err(failure);
    return Ok(rows[platform]);
  }

  @override
  Future<Result<bool, RemoteError>> supportTipsEnabled(String platform) async {
    calls++;
    if (offline) return const Err(Offline());
    final failure = fail;
    if (failure != null) return Err(failure);
    return Ok(supportTips.contains(platform));
  }
}
