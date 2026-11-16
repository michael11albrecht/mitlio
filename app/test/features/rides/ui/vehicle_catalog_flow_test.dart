import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

/// The typeahead of the vehicle form (P9-T09), through the real screen.
void main() {
  late RidesApp app;

  setUp(() => app = RidesApp());

  void formTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        app.tester = tester;
        await app.seedGroup();
        await pumpRides(
          tester,
          app,
          location: '/groups/${app.group.id}/rides/vehicles/new',
        );
        await body(tester);
      });

  Finder nameField() => find.widgetWithText(TextField, 'Name');
  Finder consumptionField() =>
      find.widgetWithText(TextField, 'Verbrauch (l/100 km)');

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(nameField(), text);
    await tester.pumpAndSettle();
  }

  formTest('typing shows up to five cars with data and attribution', (
    tester,
  ) async {
    await type(tester, 'Golf');
    expect(find.text('VW Golf'), findsNWidgets(2));
    expect(find.text('1,5 l, 85 kW, Benzin, 5,6 l/100 km'), findsOneWidget);
    expect(find.text('2 l, 85 kW, Diesel, 4,5 l/100 km'), findsOneWidget);
    expect(find.text('Daten: EEA, CC BY 4.0'), findsOneWidget);
    expect(find.bySemanticsLabel('Fahrzeugvorschläge'), findsOneWidget);
    // Nothing is filled before a pick.
    expect(find.text('Gib den Verbrauch ein'), findsNothing);
  });

  formTest('an electric car shows kWh', (tester) async {
    await type(tester, 'tesla');
    expect(find.text('190 kW, Elektro, 14,9 kWh/100 km'), findsOneWidget);
  });

  formTest('pick fills the form, shows the WLTP note and saves', (
    tester,
  ) async {
    await type(tester, 'Golf');
    await tester.tap(find.text('1,5 l, 85 kW, Benzin, 5,6 l/100 km'));
    await tester.pumpAndSettle();

    final name = tester.widget<TextField>(nameField()).controller!.text;
    expect(name, 'VW Golf');
    expect(
      tester.widget<TextField>(consumptionField()).controller!.text,
      '5,6',
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Benzin'))
          .selected,
      isTrue,
    );
    // The suggestions are gone, the honest line is there.
    expect(find.text('1,5 l, 85 kW, Benzin, 5,6 l/100 km'), findsNothing);
    expect(
      find.text(
        'Herstellerangabe (WLTP). Im Alltag verbrauchst du meist '
        'etwa 20 % mehr.',
      ),
      findsOneWidget,
    );
    expect(find.text('Daten: EEA, CC BY 4.0'), findsOneWidget);
    // Nothing to undo: no typed consumption was replaced.
    expect(find.text('Rückgängig'), findsNothing);

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    final stored = ok(await app.vehicles.get('rd-1'));
    expect(stored.name, 'VW Golf');
    expect(stored.fuelType, FuelType.petrol);
    expect(stored.consumptionMilliPer100km, 5600);
    expect(stored.wearMilliPerKm, 0);
    expect(stored.kmRateMilliPerKm, isNull);
  });

  formTest(
    'one tap takes the realistic value, a manual edit removes the note',
    (
      tester,
    ) async {
      await type(tester, 'Golf');
      await tester.tap(find.text('1,5 l, 85 kW, Benzin, 5,6 l/100 km'));
      await tester.pumpAndSettle();
      Finder button() =>
          find.text('Realistischen Wert übernehmen: 6,72 l/100 km');
      expect(button(), findsOneWidget);
      await tester.tap(button());
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(consumptionField()).controller!.text,
        '6,72',
      );
      expect(button(), findsNothing);
      expect(
        find.text(
          'Geschätzter Alltagswert: Herstellerangabe (WLTP) plus etwa 20 %. '
          'Das ist eine Schätzung, kein offizieller Wert.',
        ),
        findsOneWidget,
      );

      await tester.enterText(consumptionField(), '6,9');
      await tester.pumpAndSettle();
      expect(find.textContaining('Herstellerangabe'), findsNothing);
      expect(find.text('Daten: EEA, CC BY 4.0'), findsNothing);
      expect(find.textContaining('Geschätzter Alltagswert'), findsNothing);
    },
  );

  formTest('an electric pick has the note but no realistic action', (
    tester,
  ) async {
    await type(tester, 'tesla');
    await tester.tap(find.text('190 kW, Elektro, 14,9 kWh/100 km'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Herstellerangabe (WLTP). Im Alltag brauchst du meist etwas mehr.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Realistischen Wert'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.widgetWithText(TextField, 'Verbrauch (kWh/100 km)'),
          )
          .controller!
          .text,
      '14,9',
    );
  });

  formTest('a pick over typed values says so and can be undone', (
    tester,
  ) async {
    await tester.enterText(consumptionField(), '4,8');
    await tester.pump();
    await type(tester, 'Golf');
    await tester.tap(find.text('1,5 l, 85 kW, Benzin, 5,6 l/100 km'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('„VW Golf“ übernommen. Dein Verbrauch wurde ersetzt.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(consumptionField()).controller!.text,
      '5,6',
    );

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(nameField()).controller!.text, 'Golf');
    expect(
      tester.widget<TextField>(consumptionField()).controller!.text,
      '4,8',
    );
    expect(find.textContaining('Herstellerangabe'), findsNothing);
  });

  formTest('no match says what to do instead', (tester) async {
    await type(tester, 'Trabant');
    expect(
      find.text(
        'Nicht dabei? Trag den Verbrauch selbst ein, z. B. aus deinem '
        'Bordcomputer.',
      ),
      findsOneWidget,
    );
    // The form works as before.
    await tester.enterText(consumptionField(), '7');
    await tester.pump();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(ok(await app.vehicles.get('rd-1')).name, 'Trabant');
  });

  formTest('a list that cannot load shows a message, never nothing', (
    tester,
  ) async {
    app.catalog.failure = const Storage('asset missing');
    await type(tester, 'Golf');
    expect(
      find.text(
        'Die Fahrzeugliste konnte nicht geladen werden. Trag den Verbrauch '
        'selbst ein, z. B. aus deinem Bordcomputer.',
      ),
      findsOneWidget,
    );
    expect(find.text('Daten: EEA, CC BY 4.0'), findsNothing);
    // Manual entry is unchanged and saves.
    await tester.enterText(consumptionField(), '6,5');
    await tester.pump();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(ok(await app.vehicles.get('rd-1')).name, 'Golf');
  });

  formTest('clearing the name clears the suggestions', (tester) async {
    await type(tester, 'Golf');
    expect(find.text('VW Golf'), findsNWidgets(2));
    await type(tester, 'G');
    expect(find.text('VW Golf'), findsNothing);
    expect(find.textContaining('Nicht dabei?'), findsNothing);
  });
}
