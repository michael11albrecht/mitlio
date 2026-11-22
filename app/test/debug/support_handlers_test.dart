import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app_version.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/support.dart';
import 'package:mitlio/features/support/data/repositories/support_repository.dart';
import 'package:mitlio/features/support/data/services/fake_tip_store_service.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio/features/support/data/support_providers.dart';
import 'package:mitlio/features/sync/data/services/fake_app_config_remote.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart';

/// `ext.mitlio.support.*` (P7-T09): the same ViewModel and repository calls
/// the screens and the tests use, on a real in-memory database.
void main() {
  late FakeTipStoreService store;
  late FixedClock clock;
  late ProviderContainer c;
  late Map<String, DriveHandler> h;

  setUp(() async {
    final r = await driftRepos();
    store = FakeTipStoreService();
    clock = FixedClock(DateTime.utc(2026, 12));
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(r.db!),
        clockProvider.overrideWithValue(clock),
        tipStoreServiceProvider.overrideWithValue(store),
        appConfigRemoteProvider.overrideWithValue(FakeAppConfigRemote()),
        storePlatformProvider.overrideWithValue('ios'),
      ],
    );
    addTearDown(c.dispose);
    h = supportDriveHandlers(c);
  });

  test('the flag is off until it is set', () async {
    expect((await h['support.state']!({}))['enabled'], isFalse);
    expect(await h['support.setFlag']!({'enabled': 'true'}), {'enabled': true});
    expect((await h['support.state']!({}))['enabled'], isTrue);
    await h['support.setFlag']!({'enabled': 'false'});
    expect((await h['support.state']!({}))['enabled'], isFalse);
  });

  test('setFlag validates its param', () async {
    expect((await h['support.setFlag']!({}))['error'], 'invalid_params');
    expect(
      (await h['support.setFlag']!({'enabled': 'maybe'}))['error'],
      'invalid_params',
    );
  });

  test('the line follows the rate limit', () async {
    await h['support.setFlag']!({'enabled': 'true'});
    for (var i = 1; i <= 4; i++) {
      expect(await h['support.reached']!({}), {'visible': false});
    }
    expect(await h['support.reached']!({}), {'visible': true});
    final s = await h['support.state']!({});
    expect(s['settledSinceShown'], 0);
    expect(s['lastShown'], '2026-12-01T00:00:00.000Z');
  });

  test('flag off: reached shows nothing', () async {
    expect(await h['support.reached']!({}), {'visible': false});
  });

  test('setPrompt scripts the local state', () async {
    await h['support.setPrompt']!({
      'settled': '4',
      'lastShownDaysAgo': '40',
      'dismissed': 'false',
    });
    final s = await h['support.state']!({});
    expect(s['settledSinceShown'], 4);
    expect(s['lastShown'], '2026-10-22T00:00:00.000Z');
    expect(s['dismissed'], isFalse);
  });

  test('setPrompt rejects a malformed number', () async {
    expect(
      (await h['support.setPrompt']!({'settled': 'x'}))['error'],
      'invalid_params',
    );
  });

  test('dismiss is permanent', () async {
    await h['support.setFlag']!({'enabled': 'true'});
    expect(await h['support.dismiss']!({}), {'dismissed': true});
    expect((await h['support.state']!({}))['dismissed'], isTrue);
  });

  test('tips lists the sizes, tip buys one', () async {
    final tips = await h['support.tips']!({});
    expect(tips['state'], 'ready');
    expect((tips['products']! as List).length, 3);
    final bought = await h['support.tip']!({'size': 'medium'});
    expect(bought['state'], 'thanks');
    expect(store.bought, [TipSize.medium]);
  });

  test('a failed purchase is reported, not swallowed', () async {
    store.outcome = const TipFailed(TipFailure.purchaseFailed);
    final r = await h['support.tip']!({'size': 'small'});
    expect(r['state'], 'ready');
    expect(r['error'], 'purchaseFailed');
  });

  test('a cancelled purchase is no error', () async {
    store.outcome = const TipCancelled();
    final r = await h['support.tip']!({'size': 'small'});
    expect(r['state'], 'ready');
    expect(r['error'], isNull);
  });

  test('no store is reported with its reason', () async {
    store.catalog = const Err(TipFailure.storeUnavailable);
    expect(await h['support.tips']!({}), {
      'state': 'unavailable',
      'error': 'storeUnavailable',
    });
  });

  test('tip validates the size', () async {
    expect((await h['support.tip']!({}))['error'], 'invalid_params');
    expect(
      (await h['support.tip']!({'size': 'huge'}))['error'],
      'invalid_params',
    );
  });

  test('constants match the repository keys', () {
    expect(supportFlagSetting, 'support.tips_enabled');
  });
}
