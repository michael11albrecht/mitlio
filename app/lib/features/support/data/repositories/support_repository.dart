import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/support/data/services/tip_store_service.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// How long a fetched `support_tips_enabled` is trusted.
const supportFlagCacheTtl = Duration(hours: 12);

/// `local_settings` keys. Local only; none of it is synced or analysed.
const supportFlagSetting = 'support.tips_enabled';
const supportFlagCheckedAtSetting = 'support.tips_checked_at';
const supportSettledSinceShownSetting = 'support.settled_since_shown';
const supportLastShownSetting = 'support.last_shown';
const supportDismissedSetting = 'support.dismissed';

/// The tip jar's data (ADR-28, P7-T09): the remote flag, the success-screen
/// line's local state and the store purchase. Tips are a side channel: nothing
/// here touches settlements, balances or payment links.
abstract interface class SupportRepository {
  /// The remote flag `support_tips_enabled`. Off until the owner switches it
  /// on. Never throws and never reports a failure: a tip is optional, so when
  /// the flag cannot be read (offline, no row, malformed) the answer is "off"
  /// and the app shows nothing, rather than a message about something the
  /// user did not ask for.
  Future<bool> tipsEnabled();

  Future<RepoResult<SupportPromptState>> promptState();

  Future<RepoResult<void>> savePromptState(SupportPromptState state);

  Future<Result<List<TipProduct>, TipFailure>> tipProducts();

  Future<TipOutcome> buyTip(TipSize size);
}

/// [SupportRepository] on `local_settings`, the `app_config` flag and the
/// store.
class DriftSupportRepository implements SupportRepository {
  DriftSupportRepository({
    required this.db,
    required this.remote,
    required this.store,
    required this.clock,
    required this.platform,
  });

  final AppDatabase db;
  final AppConfigRemote remote;
  final TipStoreService store;
  final Clock clock;

  /// `ios` or `android`; null elsewhere (Linux harness): never on.
  final String? platform;

  @override
  Future<bool> tipsEnabled() async {
    final p = platform;
    if (p == null) return false;
    try {
      final dao = db.syncStateDao;
      final cached = await dao.setting(supportFlagSetting);
      final at = DateTime.tryParse(
        await dao.setting(supportFlagCheckedAtSetting) ?? '',
      );
      if (cached != null && at != null) {
        final age = clock.now().difference(at);
        // A clock set back makes the stamp lie in the future: refetch.
        if (!age.isNegative && age < supportFlagCacheTtl) return cached == '1';
      }
      return switch (await remote.supportTipsEnabled(p)) {
        Ok(:final value) => await _remember(value),
        // Keep the older answer when the refresh fails.
        Err() => cached == '1',
      };
    } on Object {
      return false;
    }
  }

  Future<bool> _remember(bool enabled) async {
    final dao = db.syncStateDao;
    await dao.putSetting(supportFlagSetting, enabled ? '1' : '0');
    await dao.putSetting(
      supportFlagCheckedAtSetting,
      clock.now().toUtc().toIso8601String(),
    );
    return enabled;
  }

  @override
  Future<RepoResult<SupportPromptState>> promptState() =>
      guardStorage(() async {
        final dao = db.syncStateDao;
        return Ok(
          SupportPromptState(
            settledSinceShown:
                int.tryParse(
                  await dao.setting(supportSettledSinceShownSetting) ?? '',
                ) ??
                0,
            lastShown: DateTime.tryParse(
              await dao.setting(supportLastShownSetting) ?? '',
            ),
            dismissed: await dao.setting(supportDismissedSetting) == '1',
          ),
        );
      });

  @override
  Future<RepoResult<void>> savePromptState(SupportPromptState state) =>
      guardStorage(() async {
        final dao = db.syncStateDao;
        await dao.putSetting(
          supportSettledSinceShownSetting,
          '${state.settledSinceShown}',
        );
        await dao.putSetting(
          supportLastShownSetting,
          state.lastShown?.toUtc().toIso8601String() ?? '',
        );
        await dao.putSetting(
          supportDismissedSetting,
          state.dismissed ? '1' : '0',
        );
        return const Ok(null);
      });

  @override
  Future<Result<List<TipProduct>, TipFailure>> tipProducts() =>
      store.products();

  @override
  Future<TipOutcome> buyTip(TipSize size) => store.buy(size);
}
