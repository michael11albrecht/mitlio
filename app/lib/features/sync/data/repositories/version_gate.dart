// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:async';

import 'package:mitlio/core/clock.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/settle/data/services/payment_link_service.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// How long a fetched `min_supported_version` is trusted (P6-T16).
const versionGateCacheTtl = Duration(hours: 12);

/// `local_settings` keys of the cached answer.
const versionGateCheckedAtKey = 'version_gate.checked_at';
const versionGateMinKey = 'version_gate.min';
const versionGateStoreUrlKey = 'version_gate.store_url';

/// Where "Aktualisieren" goes when the server row has no (usable) `store_url`.
/// Android: the prod application id (`app/android/app_identity.properties`).
/// iOS: a store search, because the App Store id exists only once the app is
/// published; the owner sets the real link in `app_config.store_url`.
const fallbackStoreUrls = <String, String>{
  'android': 'https://play.google.com/store/apps/details?id=app.mitlio',
  'ios': 'https://apps.apple.com/search?term=mitlio',
};

/// What the gate knows: [current] app version, the server's [min] (null when
/// unknown or unusable), whether sync is [blocked], and the [storeUrl] to
/// send the user to.
class VersionGateState {
  const VersionGateState({
    required this.current,
    required this.min,
    required this.blocked,
    required this.storeUrl,
  });

  /// Nothing to compare (no platform, unreadable own version, no config).
  const VersionGateState.open({this.current, this.storeUrl})
    : min = null,
      blocked = false;

  final String? current;
  final String? min;
  final bool blocked;
  final String? storeUrl;

  @override
  bool operator ==(Object other) =>
      other is VersionGateState &&
      other.current == current &&
      other.min == min &&
      other.blocked == blocked &&
      other.storeUrl == storeUrl;

  @override
  int get hashCode => Object.hash(current, min, blocked, storeUrl);

  @override
  String toString() =>
      'VersionGateState(current: $current, min: $min, blocked: $blocked)';
}

/// Decides whether this app version may still sync (P6-T16, ADR-27 §2.3).
///
/// The gate blocks **sync only**: local use is never touched. It asks the
/// server for `min_supported_version` of this platform, caches the answer in
/// `local_settings` for [versionGateCacheTtl] and compares it with the app's
/// own version on every [check] (so a fresh update unblocks at once, without
/// waiting for the cache to expire).
///
/// Fail open: when the answer is unavailable (offline, server error, no row,
/// malformed version text) the app is **not** blocked. Nothing failed for the
/// user, so nothing is shown. A cached answer outlives a failed refresh: a
/// minimum only ever rises, so an older answer is never more permissive than
/// the truth for long, and an app that was blocked stays blocked while
/// offline.
///
/// Called by `SyncService` before every push and pull of a shared group, so
/// the gate only ever runs when the user has shared groups and a backend is
/// configured; a local-only user causes no network call at start.
class VersionGate {
  VersionGate({
    required this._db,
    required this._remote,
    required this._clock,
    required this._launcher,
    required this.currentVersion,
    required this.platform,
  });

  final AppDatabase _db;
  final AppConfigRemote _remote;
  final Clock _clock;
  final LinkLauncher _launcher;

  /// The app's own version (`PackageInfo.version`); null when unreadable.
  final String? currentVersion;

  /// `ios` or `android`; null on any other platform (Linux test harness),
  /// where nothing is gated.
  final String? platform;

  Future<_Cached?>? _fetching;

  /// The state now. Uses the cache while it is fresh; [force] refetches.
  Future<VersionGateState> check({bool force = false}) async {
    final p = platform;
    final raw = currentVersion;
    final current = raw == null ? null : _parse(raw);
    if (p == null || raw == null || current == null) {
      return VersionGateState.open(current: raw);
    }
    var cached = await _readCache();
    if (force || cached == null || !_fresh(cached.checkedAt)) {
      // One request for concurrent callers (several groups sync at once).
      final fetched = await (_fetching ??= _fetch(p).whenComplete(
        () => _fetching = null,
      ));
      cached = fetched ?? cached;
    }
    return _evaluate(raw, current, cached);
  }

  /// Opens the store page where the user updates mitlio ("Aktualisieren").
  /// False when there is no link or nothing on the phone can open it; the
  /// caller says so.
  Future<bool> openStore() async {
    final url = (await check()).storeUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    return uri != null && await _launcher.launchExternal(uri);
  }

  bool _fresh(DateTime checkedAt) {
    final age = _clock.now().difference(checkedAt);
    // A clock set back makes the stamp lie in the future: refetch.
    return !age.isNegative && age < versionGateCacheTtl;
  }

  Future<_Cached?> _fetch(String p) async {
    final result = await _remote.minSupportedVersion(p);
    switch (result) {
      case Err():
        // Fail open (see class comment): keep whatever is cached.
        return null;
      case Ok(:final value):
        final now = _clock.now();
        final cached = _Cached(
          checkedAt: now,
          min: value?.version ?? '',
          storeUrl: value?.storeUrl,
        );
        final dao = _db.syncStateDao;
        await dao.putSetting(versionGateMinKey, cached.min);
        await dao.putSetting(versionGateStoreUrlKey, cached.storeUrl ?? '');
        await dao.putSetting(
          versionGateCheckedAtKey,
          now.toUtc().toIso8601String(),
        );
        return cached;
    }
  }

  Future<_Cached?> _readCache() async {
    final dao = _db.syncStateDao;
    final at = await dao.setting(versionGateCheckedAtKey);
    final min = await dao.setting(versionGateMinKey);
    final parsed = at == null ? null : DateTime.tryParse(at);
    if (parsed == null || min == null) return null;
    final url = await dao.setting(versionGateStoreUrlKey);
    return _Cached(
      checkedAt: parsed,
      min: min,
      storeUrl: url == null || url.isEmpty ? null : url,
    );
  }

  VersionGateState _evaluate(String raw, SemVer current, _Cached? cached) {
    final url = _storeUrl(cached?.storeUrl);
    final minText = cached?.min;
    final min = minText == null ? null : _parse(minText);
    // No answer, no row, or a malformed version: open.
    if (min == null) return VersionGateState.open(current: raw, storeUrl: url);
    return VersionGateState(
      current: raw,
      min: minText,
      blocked: current < min,
      storeUrl: url,
    );
  }

  /// The server's link when it is a usable https URL; else the per-platform
  /// fallback. Never a link the app would not open (no `javascript:` etc.).
  String? _storeUrl(String? fromServer) {
    final uri = fromServer == null ? null : Uri.tryParse(fromServer);
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
      return fromServer;
    }
    return fallbackStoreUrls[platform];
  }

  static SemVer? _parse(String text) => switch (SemVer.parse(text)) {
    Ok(:final value) => value,
    Err() => null,
  };
}

class _Cached {
  const _Cached({
    required this.checkedAt,
    required this.min,
    required this.storeUrl,
  });

  final DateTime checkedAt;
  final String min;
  final String? storeUrl;
}
