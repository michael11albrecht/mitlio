import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';

import 'rides_fixtures.dart';

const _nbsp = '\u00a0';

void main() {
  late RidesApp app;

  Future<List<ExpenseEntry>> expenses() async => (await app.tester!.runAsync(
    () => app.expenses.watchExpenses(app.group.id).first,
  ))!;

  setUp(() => app = RidesApp());

  testWidgets('settle March from the card, then undo', (tester) async {
    app.tester = tester;
    await app.seedCommute();
    // The fixture of examples:rides, in March; today is in April.
    await app.ride(
      date: '2026-03-05',
      driver: 0,
      passengers: [1],
      priceMilli: 1799,
    );
    await app.ride(
      date: '2026-03-06',
      driver: 1,
      passengers: [0, 2],
      priceMilli: 1759,
    );
    await app.ride(
      date: '2026-03-07',
      driver: 0,
      passengers: [1, 2],
      priceMilli: 1799,
    );
    app.base.clock.value = DateTime.utc(2026, 4, 2, 9);
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}?tab=rides',
    );
    // Nothing to settle in April, so no card yet.
    expect(find.textContaining('abrechnen'), findsNothing);
    await tester.tap(find.byTooltip('Vorheriger Monat'));
    await tester.pumpAndSettle();

    expect(find.text('März abrechnen · 3 Fahrten'), findsOneWidget);
    expect(find.text('Fairness'), findsOneWidget);
    expect(find.textContaining('Als Nächstes dran'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Ansehen'));
    await tester.pumpAndSettle();
    // Look 1: the rides of the month; look 2: who gets what.
    expect(find.text('Das war im März los'), findsOneWidget);
    expect(find.text('Schritt 1 von 2'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Wer bekommt was?'), findsOneWidget);
    expect(
      find.text('Ann bekommt 5,46$_nbsp€ für 2 Fahrten'),
      findsOneWidget,
    );
    expect(find.text('Ben bekommt 3,05$_nbsp€ für 1 Fahrt'), findsOneWidget);
    expect(find.text('Ben zahlt 3,90$_nbsp€'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    // Confirm: nothing is settled before this button.
    expect(find.text('März abrechnen'), findsOneWidget);
    expect(find.text('3 Fahrten werden gesperrt'), findsOneWidget);
    expect(find.text('Daraus werden 2 Ausgaben'), findsOneWidget);
    expect(await expenses(), isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Abrechnen'));
    await tester.pumpAndSettle();
    expect(find.text('März abgerechnet'), findsOneWidget);
    final made = await expenses();
    expect(made.map((e) => e.expense.title).toSet(), {
      'Fahrten März 2026 · Ann',
      'Fahrten März 2026 · Ben',
    });
    // The card is gone, the rides are locked.
    expect(find.text('März abrechnen · 3 Fahrten'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(await expenses(), isEmpty);
    expect(find.text('März abrechnen · 3 Fahrten'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('the month menu settles any time', (tester) async {
    app.tester = tester;
    await app.seedCommute();
    await app.ride(date: '2026-03-01', driver: 0, passengers: [1]);
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}?tab=rides',
    );
    // March is not over: no card, but the menu offers it.
    expect(find.textContaining('abrechnen ·'), findsNothing);
    await tester.tap(find.byTooltip('Monatsmenü'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monat abrechnen'));
    await tester.pumpAndSettle();
    expect(find.text('Das war im März los'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Ann bekommt 2,27$_nbsp€ für 1 Fahrt'), findsOneWidget);
  });

  testWidgets('the menu entry is disabled without rides to settle', (
    tester,
  ) async {
    app.tester = tester;
    await app.seedCommute();
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}?tab=rides',
    );
    await tester.tap(find.byTooltip('Monatsmenü'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monat abrechnen'));
    await tester.pumpAndSettle();
    expect(find.text('Das war im März los'), findsNothing);
  });

  testWidgets('a failing store keeps the review and says so', (tester) async {
    app.tester = tester;
    await app.seedCommute();
    await app.ride(date: '2026-03-01', driver: 0, passengers: [1]);
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}/rides/settle',
    );
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    app.rides.failWith = const Storage('down');
    await tester.tap(find.widgetWithText(FilledButton, 'Abrechnen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Prüf den freien Speicher'), findsOneWidget);
    expect(find.text('März abrechnen'), findsOneWidget);
    expect(await expenses(), isEmpty);
  });

  testWidgets('a month with nothing to settle says so', (tester) async {
    app.tester = tester;
    await app.seedCommute();
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}/rides/settle',
    );
    expect(
      find.text('Dieser Monat ist schon abgerechnet oder hat keine Fahrten.'),
      findsOneWidget,
    );
    expect(find.text('Weiter'), findsNothing);
  });
}
