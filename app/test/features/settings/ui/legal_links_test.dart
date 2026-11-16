import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/router.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/fake_platform.dart';

Future<FakeLinkLauncher> _open(
  WidgetTester tester, {
  bool canLaunch = true,
}) async {
  tester.platformDispatcher.localesTestValue = [const Locale('de')];
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
  testWidgets('shows the summary and opens the German pages', (tester) async {
    final launcher = await _open(tester);
    expect(
      find.textContaining('Deine Daten bleiben auf diesem Gerät'),
      findsOneWidget,
    );
    await tester.tap(find.text('Datenschutzerklärung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Impressum'));
    await tester.pumpAndSettle();
    expect(launcher.launched.map((u) => u.path), [
      '/datenschutz/',
      '/impressum/',
    ]);
  });

  testWidgets('copies the link and says so when it cannot open', (
    tester,
  ) async {
    final launcher = await _open(tester, canLaunch: false);
    await tester.tap(find.text('Datenschutzerklärung'));
    await tester.pumpAndSettle();
    expect(launcher.copied.single, endsWith('/datenschutz/'));
    expect(find.text('Link kopiert'), findsOneWidget);
  });
}
