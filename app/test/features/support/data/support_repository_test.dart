import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/support/data/repositories/support_repository.dart';
import 'package:mitlio/features/support/data/services/fake_tip_store_service.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio/features/sync/data/services/fake_app_config_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

void main() {
  late Repos r;
  late FixedClock clock;
  late FakeAppConfigRemote config;
  late FakeTipStoreService store;

  setUp(() async {
    r = await driftRepos();
    clock = FixedClock(DateTime.utc(2026, 12));
    config = FakeAppConfigRemote();
    store = FakeTipStoreService();
  });

  DriftSupportRepository repo({String? platform = 'ios'}) =>
      DriftSupportRepository(
        db: r.db!,
        remote: config,
        store: store,
        clock: clock,
        platform: platform,
      );

  group('flag', () {
    test('is off by default', () async {
      expect(await repo().tipsEnabled(), isFalse);
    });

    test('is on when the server says so', () async {
      config.supportTips.add('ios');
      expect(await repo().tipsEnabled(), isTrue);
    });

    test('is never on without a store platform', () async {
      config.supportTips.add('ios');
      expect(await repo(platform: null).tipsEnabled(), isFalse);
      expect(config.calls, 0);
    });

    test('the answer is cached for 12 hours, then asked again', () async {
      config.supportTips.add('ios');
      final sut = repo();
      expect(await sut.tipsEnabled(), isTrue);
      config.supportTips.clear();
      clock.advance(const Duration(hours: 11));
      expect(await sut.tipsEnabled(), isTrue);
      expect(config.calls, 1);
      clock.advance(const Duration(hours: 2));
      expect(await sut.tipsEnabled(), isFalse);
      expect(config.calls, 2);
    });

    test('a failed refresh keeps the older answer', () async {
      config.supportTips.add('ios');
      final sut = repo();
      await sut.tipsEnabled();
      clock.advance(const Duration(days: 1));
      config.fail = const ServerDown();
      expect(await sut.tipsEnabled(), isTrue);
    });

    test('a failure without any older answer is off', () async {
      config.offline = true;
      expect(await repo().tipsEnabled(), isFalse);
    });

    test('a clock set back refetches', () async {
      config.supportTips.add('ios');
      final sut = repo();
      await sut.tipsEnabled();
      clock.advance(const Duration(days: -2));
      config.supportTips.clear();
      expect(await sut.tipsEnabled(), isFalse);
    });

    test('a broken database is off, not a crash', () async {
      config.supportTips.add('ios');
      final sut = repo();
      await r.db!.customStatement('DROP TABLE local_settings');
      expect(await sut.tipsEnabled(), isFalse);
    });
  });

  group('prompt state', () {
    test('starts empty', () async {
      expect(
        await repo().promptState(),
        const Ok<SupportPromptState, Object>(SupportPromptState()),
      );
    });

    test('is stored and read back', () async {
      final saved = SupportPromptState(
        settledSinceShown: 3,
        lastShown: DateTime.utc(2026, 11, 5, 8),
        dismissed: true,
      );
      final sut = repo();
      await sut.savePromptState(saved);
      final read = await sut.promptState();
      expect((read as Ok<SupportPromptState, Object>).value, saved);
    });

    test('a state without a last-shown time reads back as none', () async {
      final sut = repo();
      await sut.savePromptState(const SupportPromptState(settledSinceShown: 2));
      final read = await sut.promptState() as Ok<SupportPromptState, Object>;
      expect(read.value.lastShown, isNull);
      expect(read.value.dismissed, isFalse);
    });

    test('a broken database is a storage error', () async {
      final sut = repo();
      await r.db!.customStatement('DROP TABLE local_settings');
      expect(await sut.promptState(), isA<Err<SupportPromptState, Object>>());
      expect(
        await sut.savePromptState(const SupportPromptState()),
        isA<Err<void, Object>>(),
      );
    });
  });

  test('products and purchases go to the store', () async {
    final sut = repo();
    expect(await sut.tipProducts(), store.catalog);
    expect(await sut.buyTip(TipSize.large), const TipThanks());
    expect(store.bought, [TipSize.large]);
  });
}
