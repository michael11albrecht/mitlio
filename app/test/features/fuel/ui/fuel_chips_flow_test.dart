import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/fuel/data/fuel_price.dart' show FuelFailure;
import 'package:mitlio/features/fuel/data/services/location_service.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../repo_test_support.dart';
import '../../rides/ui/rides_fixtures.dart';

const _nbsp = '\u00a0';

/// The fuel price chips in the trip form and the ride card, on the real app
/// with the fake price backend (German).
void main() {
  group('trip form', () {
    late FakeApp app;
    late Group group;

    setUp(() async {
      app = FakeApp();
      group = ok(
        await app.groups.create(
          name: 'Pendeln',
          currency: Currency.eur,
          createdBy: 'dev',
        ),
      );
      for (final n in ['Anna', 'Ben']) {
        ok(await app.members.add(group.id, name: n));
      }
    });

    void tripTest(String name, Future<void> Function(WidgetTester) body) =>
        testWidgets(name, (tester) async {
          tester.view
            ..physicalSize = const Size(800, 2600)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await body(tester);
        });

    Future<void> open(WidgetTester tester, {bool fuel = true}) async {
      await pumpMitlio(
        tester,
        app,
        location: '/groups/${group.id}',
        extra: fuel ? app.fuelOverrides : const [],
      );
      await tester.tap(find.byTooltip('Fahrt hinzufügen'));
      await tester.pumpAndSettle();
    }

    String priceField(WidgetTester tester) => tester
        .widget<TextField>(find.widgetWithText(TextField, 'Preis pro Liter'))
        .controller!
        .text;

    tripTest('no backend: no chips, no request', (tester) async {
      await open(tester, fuel: false);
      expect(find.text('Spritpreis übernehmen'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'E5'), findsNothing);
      expect(app.fuel.calls, isEmpty);
    });

    tripTest('the empty price field is filled with the national E5 average', (
      tester,
    ) async {
      await open(tester);
      expect(priceField(tester), '1,799');
      expect(
        find.text(
          '1,799$_nbsp€/l · Ø Deutschland · vor 12 min · '
          'Daten: MTS-K via Tankerkönig (CC BY 4.0)',
        ),
        findsOneWidget,
      );
      expect(app.fuel.calls.single.area, isNull);
      expect(app.location.asked, 0);
    });

    tripTest('tapping Diesel fills its price', (tester) async {
      await open(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Diesel'));
      await tester.pumpAndSettle();
      expect(priceField(tester), '1,659');
    });

    tripTest('offline with nothing known: a calm hint, field stays free', (
      tester,
    ) async {
      app.fuel.failWith = FuelFailure.offline;
      await open(tester);
      expect(find.textContaining('Gerade kein aktueller Preis'), findsOne);
      expect(priceField(tester), isEmpty);
    });

    tripTest('"in meiner Nähe" is hidden without a location plugin', (
      tester,
    ) async {
      await pumpMitlio(
        tester,
        app,
        location: '/groups/${group.id}',
        extra: [
          ...app.fuelOverrides.take(2),
        ],
      );
      await tester.tap(find.byTooltip('Fahrt hinzufügen'));
      await tester.pumpAndSettle();
      // The fake location service is not installed in this run.
      expect(find.text('In meiner Nähe'), findsNothing);
      expect(find.text('PLZ eingeben'), findsOneWidget);
    });

    tripTest('"in meiner Nähe" asks for the position only on tap', (
      tester,
    ) async {
      await open(tester);
      expect(app.location.asked, 0);
      await tester.tap(find.text('In meiner Nähe'));
      await tester.pumpAndSettle();
      expect(app.location.asked, 1);
      expect(find.textContaining('Ø in deiner Nähe'), findsOneWidget);
    });

    tripTest('denied location keeps the national average and says so', (
      tester,
    ) async {
      app.location.result = const LocationDenied();
      await open(tester);
      await tester.tap(find.text('In meiner Nähe'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Standort nicht freigegeben'), findsOne);
      expect(find.textContaining('Ø Deutschland'), findsOneWidget);
    });

    tripTest('a postcode: five digits required', (tester) async {
      await open(tester);
      await tester.tap(find.text('PLZ eingeben'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Postleitzahl'),
        '10',
      );
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();
      expect(find.text('Bitte fünf Ziffern'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Postleitzahl'),
        '10115',
      );
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ø PLZ 10115'), findsOneWidget);
    });

    tripTest('electric: no fuel chips', (tester) async {
      await open(tester);
      await tester.tap(find.text('Strom'));
      await tester.pumpAndSettle();
      expect(find.text('Spritpreis übernehmen'), findsNothing);
    });
  });

  group('ride card', () {
    late RidesApp app;

    setUp(() => app = RidesApp());

    testWidgets('chips appear after tapping the price; a chip sets it', (
      tester,
    ) async {
      app.tester = tester;
      await app.seedCommute();
      await pumpRides(
        tester,
        app,
        location: '/groups/${app.group.id}?tab=rides',
        extra: app.base.fuelBackendOverrides,
      );
      expect(find.text('Spritpreis übernehmen'), findsNothing);
      await tester.tap(find.text('Kraftstoff 1,75$_nbsp€ je l'));
      await tester.pumpAndSettle();
      // Pre-selected from the vehicle (petrol), but the frozen price stays
      // until the user taps a chip.
      expect(find.widgetWithText(TextField, 'Preis je l'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'E10'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Preis je l'),
      );
      expect(field.controller!.text, '1,739');
    });

    testWidgets('no backend: the card is unchanged', (tester) async {
      app.tester = tester;
      await app.seedCommute();
      await pumpRides(
        tester,
        app,
        location: '/groups/${app.group.id}?tab=rides',
      );
      await tester.tap(find.text('Kraftstoff 1,75$_nbsp€ je l'));
      await tester.pumpAndSettle();
      expect(find.text('Spritpreis übernehmen'), findsNothing);
    });
  });
}
