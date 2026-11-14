import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import '../../repo_test_support.dart';
import '../../rides/ui/rides_fixtures.dart';

/// First run on the real app, router and in-memory repositories (German).
void main() {
  late FakeApp app;

  setUp(() => app = FakeApp());

  Finder field(String label) => find.widgetWithText(TextField, label);

  testWidgets('shows one calm screen while no group exists', (tester) async {
    await pumpMitlio(tester, app);
    expect(find.text('Willkommen bei mitlio'), findsOneWidget);
    expect(
      find.text(
        'Fahrtkosten und Ausgaben fair teilen — ohne Anmeldung, ohne Werbung.',
      ),
      findsOneWidget,
    );
    expect(find.text('Fahrgemeinschaft starten'), findsOneWidget);
    expect(find.text('Gruppe für Ausgaben anlegen'), findsOneWidget);
    expect(find.text('Nur eine Fahrt berechnen'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('the screen is gone once a group exists', (tester) async {
    ok(
      await app.groups.create(
        name: 'Trip',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    await pumpMitlio(tester, app);
    expect(find.text('Willkommen bei mitlio'), findsNothing);
    expect(find.text('Trip'), findsOneWidget);
  });

  testWidgets('it is also a route of its own', (tester) async {
    await pumpMitlio(tester, app, location: '/welcome');
    expect(find.text('Willkommen bei mitlio'), findsOneWidget);
  });

  testWidgets('commute path: one tap creates the group, then car and route', (
    tester,
  ) async {
    final rides = RidesApp();
    await pumpRides(tester, rides);
    final taps = TapCounter(tester);
    await taps.tap(find.text('Fahrgemeinschaft starten'));
    await tester.pumpAndSettle();

    final groups = (await tester.runAsync(
      () => rides.base.groups.watchGroups().first,
    ))!;
    expect(groups.single.name, 'Fahrgemeinschaft');
    expect(groups.single.currency, Currency.eur);
    // Rides tab: the people come first, then car and route.
    expect(find.text('Noch niemand dabei'), findsOneWidget);
    expect(taps.taps, 1);

    await tester.runAsync(() async {
      for (final name in ['Ann', 'Ben']) {
        ok(await rides.base.members.add(groups.single.id, name: name));
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Auto und Strecke anlegen'), findsOneWidget);
    await tester.tap(find.text('Auto und Strecke anlegen'));
    await tester.pumpAndSettle();
    expect(find.text('Neues Fahrzeug'), findsOneWidget);
  });

  testWidgets('commute path: a failing store keeps the screen and says so', (
    tester,
  ) async {
    app.groups.failWith = const Storage('down');
    await pumpMitlio(tester, app);
    await tester.tap(find.text('Fahrgemeinschaft starten'));
    await tester.pumpAndSettle();
    expect(find.text('Das hat nicht geklappt'), findsOneWidget);
    expect(find.text('Willkommen bei mitlio'), findsOneWidget);
    expect(
      await tester.runAsync(() => app.groups.watchGroups().first),
      isEmpty,
    );
  });

  testWidgets('expense path opens the regular group form', (tester) async {
    await pumpMitlio(tester, app);
    await tester.tap(find.text('Gruppe für Ausgaben anlegen'));
    await tester.pumpAndSettle();
    expect(find.text('Neue Gruppe'), findsOneWidget);
    expect(
      await tester.runAsync(() => app.groups.watchGroups().first),
      isEmpty,
    );
  });

  testWidgets('trip only: result without a group, shared, nothing stored', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpMitlio(tester, app);
    await tester.tap(find.text('Nur eine Fahrt berechnen'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Fahrt'), findsOneWidget);
    expect(find.text('Person 1'), findsWidgets);
    expect(find.text('Fahrt speichern'), findsNothing);
    final share = find.widgetWithText(FilledButton, 'Ergebnis teilen');
    expect(tester.widget<FilledButton>(share).onPressed, isNull);

    await tester.enterText(field('Strecke (einfach)'), '250');
    await tester.enterText(field('Verbrauch'), '6,5');
    await tester.enterText(field('Preis pro Liter'), '1,799');
    await tester.pumpAndSettle();
    expect(find.text('Jede Person zahlt rund'), findsOneWidget);
    expect(find.textContaining('14,62'), findsWidgets);

    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(app.share.shared, hasLength(1));
    expect(app.share.shared.single, contains('14,62'));
    expect(
      await tester.runAsync(() => app.groups.watchGroups().first),
      isEmpty,
    );
  });
}
