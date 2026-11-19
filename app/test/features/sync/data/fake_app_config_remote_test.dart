import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';
import 'package:mitlio/features/sync/data/services/fake_app_config_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/app_config_remote_contract.dart';

void main() {
  runAppConfigRemoteContract('FakeAppConfigRemote', () async {
    final fake = FakeAppConfigRemote();
    return AppConfigFixture(
      remote: fake,
      seed: (platform, version, url) async => fake.rows[platform] =
          MinVersionConfig(version: version, storeUrl: url),
    );
  });

  group('scripting', () {
    test('offline and fail script the failure and count calls', () async {
      final fake = FakeAppConfigRemote()..offline = true;
      expect(
        await fake.minSupportedVersion('ios'),
        const Err<MinVersionConfig?, RemoteError>(Offline()),
      );
      fake
        ..offline = false
        ..fail = const ServerDown();
      expect(
        await fake.minSupportedVersion('ios'),
        const Err<MinVersionConfig?, RemoteError>(ServerDown()),
      );
      expect(fake.calls, 2);
    });
  });

  test('MinVersionConfig has value equality and a readable form', () {
    const a = MinVersionConfig(version: '1.0.0', storeUrl: 'https://x.y');
    const same = MinVersionConfig(version: '1.0.0', storeUrl: 'https://x.y');
    expect(a, same);
    expect(a.hashCode, same.hashCode);
    expect(
      a,
      isNot(const MinVersionConfig(version: '1.0.1', storeUrl: 'https://x.y')),
    );
    expect(a, isNot(const MinVersionConfig(version: '1.0.0')));
    expect(a.toString(), 'MinVersionConfig(1.0.0, https://x.y)');
  });
}
