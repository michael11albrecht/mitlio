import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/router.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/fake_platform.dart';

Future<FakeLinkLauncher> _open(
  WidgetTester tester,
  Locale locale, {
  bool canLaunch = true,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final app = FakeApp();
  final launcher = app.launcher..canLaunch = canLaunch;
  final c = ProviderContainer(overrides: app.overrides);
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const MitlioApp()),
  );
  c.read(routerProvider).go('/settings');
  await tester.pumpAndSettle();
  return launcher;
}

void main() {
  for (final (locale, lead, mid) in [
    (const Locale('de'), 'Mit', 'gemacht von'),
    (const Locale('en'), 'Made with', 'by'),
  ]) {
    testWidgets(
      'shows the credit and opens the profile (${locale.languageCode})',
      (
        tester,
      ) async {
        final launcher = await _open(tester, locale);
        final name = find.text('Michael Albrecht');
        await tester.scrollUntilVisible(name, 200);
        expect(find.text(lead), findsOneWidget);
        expect(find.text(mid), findsOneWidget);
        // The decorative heart is not part of the semantics tree.
        expect(find.bySemanticsLabel('♥'), findsNothing);
        await tester.tap(name);
        await tester.pumpAndSettle();
        expect(
          launcher.launched.single.toString(),
          'https://github.com/michael11albrecht',
        );
      },
    );
  }

  testWidgets('says what to do when the link cannot open', (tester) async {
    final launcher = await _open(tester, const Locale('de'), canLaunch: false);
    final name = find.text('Michael Albrecht');
    await tester.scrollUntilVisible(name, 200);
    await tester.tap(name);
    await tester.pumpAndSettle();
    expect(launcher.copied.single, 'https://github.com/michael11albrecht');
    expect(find.textContaining('kopiert'), findsOneWidget);
  });
}
