import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../support/tap_counter.dart';
import '../../repo_test_support.dart';
import 'expenses_fixtures.dart';

/// UI flows of the expenses slice on the real app, router and in-memory
/// repositories (German, the default locale).
void main() {
  late ExpensesApp app;

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  Future<void> openTab(WidgetTester tester) async {
    await tester.tap(find.text('Ausgaben'));
    await settle(tester);
  }

  Future<void> openForm(WidgetTester tester) async {
    await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
    await openTab(tester);
    await tester.tap(find.text('Ausgabe hinzufügen').last);
    await settle(tester);
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> fill(
    WidgetTester tester, {
    String? amount,
    String? title,
  }) async {
    // Focus first and let the input connection attach, as a user's tap does.
    if (amount != null) {
      await tester.tap(field('Betrag'));
      await tester.pump();
      await tester.enterText(field('Betrag'), amount);
    }
    if (title != null) {
      await tester.tap(field('Wofür?'));
      await tester.pump();
      await tester.enterText(field('Wofür?'), title);
    }
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Speichern'));
    await tester.tap(find.text('Speichern'));
    await settle(tester);
  }

  Future<List<ExpenseEntry>> stored(WidgetTester tester) async =>
      (await tester.runAsync(
        () => app.expenses.watchExpenses(app.trip.id).first,
      ))!;

  setUp(() async {
    app = ExpensesApp();
    await app.seedTrip();
  });

  group('list', () {
    testWidgets('empty: one calm action leads to the form', (tester) async {
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      await openTab(tester);
      expect(find.text('Noch keine Ausgabe'), findsOneWidget);
      expect(find.text('Trag die erste ein.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('Ausgabe hinzufügen'));
      await settle(tester);
      expect(find.text('Neue Ausgabe'), findsOneWidget);
    });

    testWidgets('without members it points to the members tab', (
      tester,
    ) async {
      final empty = ExpensesApp();
      final group = ok(
        await empty.base.groups.create(
          name: 'Leer',
          currency: Currency.eur,
          createdBy: 'dev',
        ),
      );
      await pumpExpenses(tester, empty, location: '/groups/${group.id}');
      await openTab(tester);
      expect(find.text('Ausgabe hinzufügen'), findsNothing);
      await tester.tap(find.text('Mitglieder hinzufügen'));
      await settle(tester);
      expect(find.text('Name hinzufügen'), findsOneWidget);
    });

    testWidgets('groups rows by day with who paid and the amount', (
      tester,
    ) async {
      await app.add(
        title: 'Pizza',
        cents: 4860,
        date: DateTime.utc(2026, 3),
        payers: {app.people[1].id: 4860},
        category: 'food',
      );
      await app.add(cents: 2350, date: DateTime.utc(2026, 3));
      await app.add(
        title: 'Hütte',
        cents: 26000,
        date: DateTime.utc(2026, 2, 28),
        payers: {app.people[1].id: 20000, app.people[2].id: 6000},
      );
      await app.add(title: 'Früher', date: DateTime.utc(2026, 2, 20));
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      await openTab(tester);

      expect(find.text('Heute'), findsOneWidget);
      expect(find.text('Gestern'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Ben hat bezahlt · Essen & Trinken'), findsOneWidget);
      expect(find.text('48,60\u00a0€'), findsOneWidget);
      expect(find.text('Ann hat bezahlt'), findsWidgets);
      expect(find.text('Ben +1 haben bezahlt'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      // Older days show a date, not "Heute".
      expect(find.text('Heute'), findsOneWidget);
      expect(find.textContaining('Feb'), findsWidgets);
    });

    testWidgets('filters by person and by category, then resets', (
      tester,
    ) async {
      await app.add(
        split: EqualSplit({app.people[0].id}),
        category: 'transport',
      );
      await app.add(
        title: 'Pizza',
        payers: {app.people[1].id: 900},
        category: 'food',
      );
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      await openTab(tester);
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);

      await tester.tap(find.text('Person'));
      await settle(tester);
      await tester.tap(find.text('Ben').last);
      await settle(tester);
      expect(find.text('Taxi'), findsNothing);
      expect(find.text('Pizza'), findsOneWidget);

      await tester.tap(find.text('Kategorie'));
      await settle(tester);
      await tester.tap(find.text('Verkehr').last);
      await settle(tester);
      expect(find.text('Nichts gefunden'), findsOneWidget);

      await tester.tap(find.text('Filter zurücksetzen'));
      await settle(tester);
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);

      // "Alle" clears a single filter.
      await tester.tap(find.text('Kategorie'));
      await settle(tester);
      await tester.tap(find.text('Essen & Trinken').last);
      await settle(tester);
      expect(find.text('Taxi'), findsNothing);
      await tester.tap(find.text('Essen & Trinken').first);
      await settle(tester);
      await tester.tap(find.text('Alle').last);
      await settle(tester);
      expect(find.text('Taxi'), findsOneWidget);
    });

    testWidgets('swipe deletes with an undo, never a dialog', (tester) async {
      await app.add();
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      await openTab(tester);

      await tester.drag(find.text('Taxi'), const Offset(-600, 0));
      await settle(tester);
      expect(find.text('Taxi'), findsNothing);
      expect(find.text('„Taxi“ gelöscht'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(await stored(tester), isEmpty);

      await tester.tap(find.text('Rückgängig'));
      await settle(tester);
      expect(find.text('Taxi'), findsOneWidget);
      expect(await stored(tester), hasLength(1));
    });

    testWidgets('a failing delete keeps the row and says so', (tester) async {
      await app.add();
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      await openTab(tester);
      app.expenses.failWith = const Storage('x');

      await tester.drag(find.text('Taxi'), const Offset(-600, 0));
      await settle(tester);
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);
    });

    testWidgets('the semantic delete action does the same', (tester) async {
      await app.add();
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      await openTab(tester);
      final row = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.customSemanticsActions?.keys.any(
                  (a) => a.label == 'Löschen',
                ) ??
                false),
      );
      expect(row, findsOneWidget);
      tester
          .widget<Semantics>(row)
          .properties
          .customSemanticsActions!
          .values
          .single();
      await settle(tester);
      expect(find.text('Taxi'), findsNothing);
      expect(find.text('„Taxi“ gelöscht'), findsOneWidget);
    });

    testWidgets('a failing store shows the error state; retry recovers', (
      tester,
    ) async {
      app.expenses.watchError = const Storage('down');
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      // The group page reads the expenses too, so it fails as a whole.
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);

      app.expenses.watchError = null;
      await tester.tap(find.text('Nochmal versuchen'));
      await settle(tester);
      await openTab(tester);
      expect(find.text('Noch keine Ausgabe'), findsOneWidget);
    });
  });

  group('form: equal split', () {
    testWidgets('amount, title, save: within the tap budget', (tester) async {
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      final taps = TapCounter(tester);
      await taps.tap(find.text('Ausgaben'));
      await settle(tester);
      await taps.tap(find.text('Ausgabe hinzufügen'));
      await settle(tester);

      // The amount is focused; the result is visible before saving.
      await taps.enterText(field('Betrag'), '12,40');
      await taps.enterText(field('Wofür?'), 'Pizza');
      await tester.pump();
      expect(find.text('4,14\u00a0€'), findsOneWidget);
      expect(find.text('4,13\u00a0€'), findsNWidgets(2));

      await taps.tap(find.text('Speichern'));
      await settle(tester);
      taps.expectWithinBudget('add_equal_split_expense');

      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('12,40\u00a0€'), findsOneWidget);
      final entry = (await stored(tester)).single;
      expect(entry.expense.payers, {app.people[0].id: 1240});
      expect(entry.expense.date, DateTime.utc(2026, 3));
      expect(entry.split, isA<EqualSplit>());
    });

    testWidgets('amount typed with a comma or a dot, via keyboard action', (
      tester,
    ) async {
      await openForm(tester);
      await fill(tester, amount: '3.5', title: 'Kaffee');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      await save(tester);
      expect((await stored(tester)).single.expense.amountCents, 350);
    });

    testWidgets('unticking a person excludes them from the split', (
      tester,
    ) async {
      await openForm(tester);
      await fill(tester, amount: '10', title: 'Eis');
      await tester.tap(find.text('Ben').last);
      await tester.pump();
      expect(find.text('Nicht dabei'), findsOneWidget);
      expect(find.text('5,00\u00a0€'), findsNWidgets(2));

      await save(tester);
      final entry = (await stored(tester)).single;
      expect(entry.expense.shares[app.people[1].id], 0);
      expect(entry.split, EqualSplit({app.people[0].id, app.people[2].id}));
    });

    testWidgets('excluding everybody is explained', (tester) async {
      await openForm(tester);
      await fill(tester, amount: '10', title: 'Eis');
      for (final n in ['Ann', 'Ben', 'Cy']) {
        await tester.tap(find.text(n).last);
        await tester.pump();
      }
      expect(find.text('Wähle mindestens eine Person'), findsOneWidget);
    });

    testWidgets('the payer defaults to the last one and can be changed', (
      tester,
    ) async {
      await app.add(payers: {app.people[2].id: 900});
      await openForm(tester);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Cy'))
            .selected,
        isTrue,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ben'));
      await tester.pump();
      await fill(tester, amount: '9', title: 'Bus');
      await save(tester);
      expect((await stored(tester)).first.expense.payers, {
        app.people[1].id: 900,
      });
    });

    testWidgets('a date and a category can be chosen', (tester) async {
      await openForm(tester);
      await fill(tester, amount: '9', title: 'Bus');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Verkehr'));
      await tester.pump();
      await tester.tap(find.text('Heute'));
      await settle(tester);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await settle(tester);
      await save(tester);
      final entry = (await stored(tester)).single;
      expect(entry.category, 'transport');
      expect(entry.expense.date, DateTime.utc(2026, 3, 15));
    });

    testWidgets('a chosen category can be unchosen', (tester) async {
      await openForm(tester);
      await fill(tester, amount: '9', title: 'Bus');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Verkehr'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Verkehr'));
      await tester.pump();
      await save(tester);
      expect((await stored(tester)).single.category, isNull);
    });
  });

  group('form: other split modes', () {
    testWidgets('shares: plus and minus weigh the preview', (tester) async {
      await openForm(tester);
      await fill(tester, amount: '12', title: 'Essen');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Anteile'));
      await tester.pump();
      await tester.tap(find.byTooltip('Mehr Anteile für Ann'));
      await tester.pump();
      expect(find.text('6,00\u00a0€'), findsOneWidget);
      expect(find.text('3,00\u00a0€'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Weniger Anteile für Cy'));
      await tester.pump();
      expect(find.text('Nicht dabei'), findsOneWidget);
      await save(tester);
      final entry = (await stored(tester)).single;
      expect(entry.split, isA<SharesSplit>());
      expect(entry.expense.shares[app.people[0].id], 800);
    });

    testWidgets('percent: a sum below 100 % is explained, 100 % saves', (
      tester,
    ) async {
      await openForm(tester);
      await fill(tester, amount: '10', title: 'Essen');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Prozent'));
      await tester.pump();
      final fields = find.widgetWithText(TextField, 'Prozent');
      expect(fields, findsNWidgets(3));

      await tester.enterText(fields.at(0), '50');
      await tester.enterText(fields.at(1), '25');
      await tester.enterText(fields.at(2), '20');
      await tester.pump();
      expect(
        find.text('Zusammen 95,00 % – es müssen 100 % sein'),
        findsOneWidget,
      );

      await tester.enterText(fields.at(2), '25');
      await tester.pump();
      expect(find.textContaining('Zusammen'), findsNothing);
      expect(find.text('5,00\u00a0€'), findsOneWidget);
      await save(tester);
      final entry = (await stored(tester)).single;
      expect(entry.split, isA<PercentSplit>());
      expect(entry.expense.shares[app.people[0].id], 500);
    });

    testWidgets('exact: a difference is calm and inline, then it saves', (
      tester,
    ) async {
      await openForm(tester);
      await fill(tester, amount: '10', title: 'Essen');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Genau'));
      await tester.pump();
      final fields = find.widgetWithText(TextField, 'Betrag');
      // The amount field above plus one per person.
      expect(fields, findsNWidgets(4));

      await tester.enterText(fields.at(1), '5');
      await tester.pump();
      expect(find.text('3,34\u00a0€ zu viel'), findsNothing);
      expect(find.textContaining('zu viel'), findsOneWidget);

      await tester.enterText(fields.at(1), '4');
      await tester.enterText(fields.at(2), '3');
      await tester.enterText(fields.at(3), '2');
      await tester.pump();
      expect(find.text('Noch 1,00\u00a0€ offen'), findsOneWidget);

      await tester.enterText(fields.at(3), '3');
      await tester.pump();
      expect(find.textContaining('offen'), findsNothing);
      await save(tester);
      final entry = (await stored(tester)).single;
      expect(entry.split, isA<ExactSplit>());
      expect(entry.expense.shares, {
        app.people[0].id: 400,
        app.people[1].id: 300,
        app.people[2].id: 300,
      });
    });

    testWidgets('exact with a mismatch does not save', (tester) async {
      await openForm(tester);
      await fill(tester, amount: '10', title: 'Essen');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Genau'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Betrag').at(1),
        '1',
      );
      await tester.pump();
      await save(tester);
      expect(find.text('Neue Ausgabe'), findsOneWidget);
      expect(await stored(tester), isEmpty);
    });
  });

  group('form: payers', () {
    testWidgets('several payers must add up to the amount', (tester) async {
      await openForm(tester);
      await fill(tester, amount: '9', title: 'Hotel');
      await tester.tap(find.text('Mehrere haben bezahlt'));
      await tester.pump();
      expect(find.text('Nur eine Person hat bezahlt'), findsOneWidget);

      final fields = find.widgetWithText(TextField, 'Ann');
      await tester.enterText(fields, '6');
      await tester.pump();
      expect(find.text('Noch 3,00\u00a0€ offen'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Ben'), '3');
      await tester.pump();
      expect(find.textContaining('offen'), findsNothing);
      await save(tester);
      expect((await stored(tester)).single.expense.payers, {
        app.people[0].id: 600,
        app.people[1].id: 300,
      });
    });

    testWidgets('going back to one payer', (tester) async {
      await openForm(tester);
      await fill(tester, amount: '9', title: 'Hotel');
      await tester.tap(find.text('Mehrere haben bezahlt'));
      await tester.pump();
      await tester.tap(find.text('Nur eine Person hat bezahlt'));
      await tester.pump();
      expect(find.text('Mehrere haben bezahlt'), findsOneWidget);
    });
  });

  group('form: validation and failures', () {
    testWidgets('a blank form explains itself and stays', (tester) async {
      await openForm(tester);
      expect(find.text('Gib einen Betrag ein'), findsNothing);
      await save(tester);
      expect(find.text('Gib einen Betrag ein'), findsOneWidget);
      expect(find.text('Gib der Ausgabe einen Titel'), findsOneWidget);
      expect(find.text('Neue Ausgabe'), findsOneWidget);
      expect(await stored(tester), isEmpty);

      await fill(tester, amount: '5', title: 'x');
      await save(tester);
      expect(await stored(tester), hasLength(1));
      expect(find.text('Neue Ausgabe'), findsNothing);
    });

    testWidgets('a failing store keeps the form and says so', (tester) async {
      await openForm(tester);
      await fill(tester, amount: '5', title: 'Eis');
      app.expenses.failWith = const Storage('x');
      await save(tester);
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);
      expect(find.text('Neue Ausgabe'), findsOneWidget);
    });

    testWidgets('an unknown expense shows the error state', (tester) async {
      await pumpExpenses(
        tester,
        app,
        location: '/groups/${app.trip.id}/expenses/nope',
      );
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);
      app.expenses.watchError = null;
      await tester.tap(find.text('Nochmal versuchen'));
      await settle(tester);
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);
    });
  });

  group('edit', () {
    testWidgets('a tap opens the stored expense; saving updates the row', (
      tester,
    ) async {
      await app.add(
        cents: 1200,
        category: 'transport',
        split: SharesSplit({app.people[0].id: 2, app.people[1].id: 1}),
      );
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      await openTab(tester);
      await tester.tap(find.text('Taxi'));
      await settle(tester);

      expect(find.text('Ausgabe bearbeiten'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Betrag'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Wofür?'))
            .controller!
            .text,
        'Taxi',
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Anteile'))
            .selected,
        isTrue,
      );
      expect(find.text('8,00\u00a0€'), findsOneWidget);

      await tester.enterText(field('Wofür?'), 'Taxi heim');
      await save(tester);
      expect(find.text('Taxi heim'), findsOneWidget);
      expect(find.text('Taxi'), findsNothing);
      final entry = (await stored(tester)).single;
      expect(entry.expense.title, 'Taxi heim');
      expect(entry.split, isA<SharesSplit>());
    });
  });

  testWidgets('English strings', (tester) async {
    await pumpExpenses(
      tester,
      app,
      location: '/groups/${app.trip.id}',
      locale: const Locale('en'),
    );
    await tester.tap(find.text('Expenses'));
    await settle(tester);
    expect(find.text('No expenses yet'), findsOneWidget);
    await tester.tap(find.text('Add expense'));
    await settle(tester);
    expect(find.text('New expense'), findsOneWidget);
    expect(find.text('Who paid?'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    await tester.enterText(field('Amount'), '10');
    await tester.pump();
    expect(find.text('€3.34'), findsOneWidget);
  });
}
