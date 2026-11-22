// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_mapper.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// One row of `app_config` (migration 0012): the oldest app version that may
/// still sync and where to get a newer one. [version] is the raw server text;
/// the gate parses it, so a malformed value reaches the gate and fails open
/// there (documented in `VersionGate`).
class MinVersionConfig {
  const MinVersionConfig({required this.version, this.storeUrl});

  final String version;
  final String? storeUrl;

  @override
  bool operator ==(Object other) =>
      other is MinVersionConfig &&
      other.version == version &&
      other.storeUrl == storeUrl;

  @override
  int get hashCode => Object.hash(MinVersionConfig, version, storeUrl);

  @override
  String toString() => 'MinVersionConfig($version, $storeUrl)';
}

/// Reads the server-side minimum app version (P6-T16, ADR-27 §2.3). Public
/// read: it works before any sign-in. Every failure is a [RemoteError];
/// nothing throws. `SupabaseAppConfigRemote` and `FakeAppConfigRemote` run the
/// same contract suite.
abstract interface class AppConfigRemote {
  /// The row of [platform] (`ios` or `android`); `Ok(null)` when the server
  /// has no row for it.
  Future<Result<MinVersionConfig?, RemoteError>> minSupportedVersion(
    String platform,
  );

  /// The remote flag `support_tips_enabled` (migration 0020, P7-T09) of
  /// [platform]; `Ok(false)` when the server has no row for it.
  Future<Result<bool, RemoteError>> supportTipsEnabled(String platform);
}

/// [AppConfigRemote] on Supabase: `select` on `app_config` with the anon key.
class SupabaseAppConfigRemote implements AppConfigRemote {
  const SupabaseAppConfigRemote(this._backend);

  final RemoteBackend _backend;

  /// Table of migration 0012.
  static const table = 'app_config';

  @override
  Future<Result<MinVersionConfig?, RemoteError>> minSupportedVersion(
    String platform,
  ) async {
    final client = switch (_backend.client()) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (client == null) return const Err(Rejected('backend_unavailable'));
    try {
      final rows = await client
          .from(table)
          .select('min_supported_version, store_url')
          .eq('platform', platform)
          .limit(1);
      if (rows.isEmpty) return const Ok(null);
      final version = rows.first['min_supported_version'];
      final url = rows.first['store_url'];
      if (version is! String || (url != null && url is! String)) {
        return const Err(Rejected('malformed_app_config'));
      }
      return Ok(MinVersionConfig(version: version, storeUrl: url as String?));
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }

  @override
  Future<Result<bool, RemoteError>> supportTipsEnabled(String platform) async {
    final client = switch (_backend.client()) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (client == null) return const Err(Rejected('backend_unavailable'));
    try {
      final rows = await client
          .from(table)
          .select('support_tips_enabled')
          .eq('platform', platform)
          .limit(1);
      if (rows.isEmpty) return const Ok(false);
      final enabled = rows.first['support_tips_enabled'];
      if (enabled is! bool) return const Err(Rejected('malformed_app_config'));
      return Ok(enabled);
    } on Object catch (e) {
      return Err(fromException(e));
    }
  }
}
