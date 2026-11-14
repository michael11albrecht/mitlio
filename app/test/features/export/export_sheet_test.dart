import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/export/ui/export_sheet.dart';
import 'package:mitlio/l10n/app_localizations.dart';

import '../../helpers/fake_app.dart';
import '../balances/balances_support.dart';
import 'export_support.dart';

void main() {
  testWidgets('menu: Exportieren opens the sheet; CSV shares a file', (
    tester,
  ) async {
    final app = FakeApp();
    final actions = FakeExportActions();
    final s = await Scenario.create(app, ['Anna', 'Ben']);
    await s.expense({'Anna': 3000}, {'Anna': 1500, 'Ben': 1500});
    final container = ProviderContainer(
      overrides: [...app.overrides, ...exportOverrides(actions)],
    );
    addTearDown(container.dispose);
    tester.platformDispatcher.localesTestValue = [const Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    container.read(routerProvider).go('/groups/${s.group.id}');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10nOf('de').groupMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportieren'));
    await tester.pumpAndSettle();
    expect(find.text('Tabelle (CSV)'), findsOneWidget);
    expect(find.text('Abrechnung (PDF)'), findsOneWidget);

    // `BalancesViewModel.load` uses `Stream.first`, which needs real time.
    await tester.runAsync(() async {
      await tester.tap(find.text('Abrechnung (PDF)'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text(l10nOf('de').exportFailed), findsNothing);
    expect(actions.shared.single.name, 'trip.pdf');
    // The sheet closes after a successful export.
    expect(find.text('Tabelle (CSV)'), findsNothing);
  });

  testWidgets('a failed export says so and keeps the sheet', (tester) async {
    final app = FakeApp();
    final actions = FakeExportActions();
    final s = await Scenario.create(app, ['Anna', 'Ben']);
    app.members.watchError = Exception('disk');
    final container = ProviderContainer(
      overrides: [...app.overrides, ...exportOverrides(actions)],
    );
    addTearDown(container.dispose);
    // The group detail itself cannot load while members fail, so open the
    // sheet on its own.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    unawaited(showExportSheet(context, s.group.id)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spreadsheet (CSV)'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.text('That did not work. Please try again.'), findsOneWidget);
    expect(find.text('Spreadsheet (CSV)'), findsOneWidget);
    expect(actions.shared, isEmpty);
  });
}
