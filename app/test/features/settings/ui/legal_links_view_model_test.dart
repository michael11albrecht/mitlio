import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_repository.dart';
import 'package:mitlio/features/settings/ui/legal_links_view_model.dart';

import '../../../helpers/fake_platform.dart';

class _Throwing extends FakeLinkLauncher {
  @override
  Future<bool> launchExternal(Uri uri) => throw PlatformException(code: 'x');
}

void main() {
  const site = 'https://example.test';

  test('opens the privacy policy and the imprint in the language', () async {
    final launcher = FakeLinkLauncher();
    final vm = LegalLinksViewModel(
      LegalLinksRepository(launcher: launcher, siteUrl: site),
    );
    expect(await vm.openPrivacy('de'), isTrue);
    expect(await vm.openImprint('en'), isTrue);
    expect(launcher.launched.map((u) => u.toString()), [
      '$site/datenschutz/',
      '$site/en/imprint/',
    ]);
  });

  test(
    'a link that cannot open is copied and reported as not opened',
    () async {
      final launcher = FakeLinkLauncher(canLaunch: false);
      final vm = LegalLinksViewModel(
        LegalLinksRepository(launcher: launcher, siteUrl: site),
      );
      expect(await vm.openPrivacy('en'), isFalse);
      expect(launcher.copied.single, '$site/en/privacy/');
    },
  );

  test('a failing launcher is reported as not opened', () async {
    final vm = LegalLinksViewModel(
      LegalLinksRepository(launcher: _Throwing(), siteUrl: site),
    );
    expect(await vm.openImprint('de'), isFalse);
  });
}
