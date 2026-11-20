import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_repository.dart';
import 'package:mitlio/features/settings/ui/author_credit_view_model.dart';

import '../../../helpers/fake_platform.dart';

class _Throwing extends FakeLinkLauncher {
  @override
  Future<bool> launchExternal(Uri uri) => throw PlatformException(code: 'x');
}

void main() {
  test('opens the GitHub profile in the external browser', () async {
    final launcher = FakeLinkLauncher();
    final vm = AuthorCreditViewModel(
      LegalLinksRepository(launcher: launcher, siteUrl: 'https://example.test'),
    );
    expect(await vm.openProfile(), isTrue);
    expect(launcher.launched.single.toString(), authorProfileUrl);
    expect(authorProfileUrl, 'https://github.com/michael11albrecht');
  });

  test(
    'a link that cannot open is copied and reported as not opened',
    () async {
      final launcher = FakeLinkLauncher(canLaunch: false);
      final vm = AuthorCreditViewModel(
        LegalLinksRepository(
          launcher: launcher,
          siteUrl: 'https://example.test',
        ),
      );
      expect(await vm.openProfile(), isFalse);
      expect(launcher.copied.single, authorProfileUrl);
    },
  );

  test('a failing launcher is reported as not opened', () async {
    final vm = AuthorCreditViewModel(
      LegalLinksRepository(
        launcher: _Throwing(),
        siteUrl: 'https://example.test',
      ),
    );
    expect(await vm.openProfile(), isFalse);
  });
}
