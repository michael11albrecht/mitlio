import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A server holding `app_config` and a way to put a row on it.
class AppConfigFixture {
  const AppConfigFixture({
    required this.remote,
    required this.seed,
    required this.seedSupportTips,
  });

  final AppConfigRemote remote;
  final Future<void> Function(String platform, String version, String? url)
  seed;

  /// Sets the tip jar flag (migration 0017) of the row of `platform`.
  final Future<void> Function(String platform, {required bool enabled})
  seedSupportTips;
}

MinVersionConfig? _config(Result<MinVersionConfig?, RemoteError> r) =>
    switch (r) {
      Ok(:final value) => value,
      Err(:final error) => fail('unexpected $error'),
    };

/// What every [AppConfigRemote] must do (anon read of `app_config`, 0012).
void runAppConfigRemoteContract(
  String name,
  Future<AppConfigFixture> Function() create,
) {
  group('AppConfigRemote contract: $name', () {
    late AppConfigFixture f;
    setUp(() async => f = await create());

    test('returns the row of the platform with its store link', () async {
      await f.seed('ios', '1.4.0', 'https://apps.apple.com/app/id1');
      await f.seed('android', '2.0.1', null);
      expect(
        _config(await f.remote.minSupportedVersion('ios')),
        const MinVersionConfig(
          version: '1.4.0',
          storeUrl: 'https://apps.apple.com/app/id1',
        ),
      );
      expect(
        _config(await f.remote.minSupportedVersion('android')),
        const MinVersionConfig(version: '2.0.1'),
      );
    });

    test('a platform without a row is Ok(null), not an error', () async {
      await f.seed('ios', '1.0.0', null);
      expect(_config(await f.remote.minSupportedVersion('android')), isNull);
    });

    test('the seeded 0.0.0 blocks nobody and is returned as is', () async {
      await f.seed('ios', '0.0.0', null);
      expect(
        _config(await f.remote.minSupportedVersion('ios'))?.version,
        '0.0.0',
      );
    });

    test('the tip jar flag is read per platform', () async {
      await f.seed('ios', '1.0.0', null);
      await f.seed('android', '1.0.0', null);
      await f.seedSupportTips('ios', enabled: true);
      expect(
        await f.remote.supportTipsEnabled('ios'),
        const Ok<bool, RemoteError>(true),
      );
      expect(
        await f.remote.supportTipsEnabled('android'),
        const Ok<bool, RemoteError>(false),
      );
    });

    test('a platform without a row has the tip jar off', () async {
      expect(
        await f.remote.supportTipsEnabled('ios'),
        const Ok<bool, RemoteError>(false),
      );
    });
  });
}
