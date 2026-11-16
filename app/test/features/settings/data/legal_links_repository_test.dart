import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_repository.dart';

import '../../../helpers/fake_platform.dart';

void main() {
  const site = 'https://example.test';

  test('maps pages and language to the website paths', () {
    final repo = LegalLinksRepository(
      launcher: FakeLinkLauncher(),
      siteUrl: site,
    );
    expect(
      repo.uriFor(LegalPage.privacy, 'de').toString(),
      '$site/datenschutz/',
    );
    expect(repo.uriFor(LegalPage.imprint, 'de').toString(), '$site/impressum/');
    expect(
      repo.uriFor(LegalPage.privacy, 'en').toString(),
      '$site/en/privacy/',
    );
    expect(
      repo.uriFor(LegalPage.imprint, 'fr').toString(),
      '$site/en/imprint/',
    );
  });

  test('opens the page externally', () async {
    final launcher = FakeLinkLauncher();
    final repo = LegalLinksRepository(launcher: launcher, siteUrl: site);
    expect(await repo.open(LegalPage.privacy, 'de'), isTrue);
    expect(launcher.launched.single.toString(), '$site/datenschutz/');
    expect(launcher.copied, isEmpty);
  });

  test('copies the link when nothing can open it', () async {
    final launcher = FakeLinkLauncher(canLaunch: false);
    final repo = LegalLinksRepository(launcher: launcher, siteUrl: site);
    expect(await repo.open(LegalPage.imprint, 'en'), isFalse);
    expect(launcher.copied.single, '$site/en/imprint/');
  });
}
