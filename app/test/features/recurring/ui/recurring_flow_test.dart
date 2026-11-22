import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/recurring/data/repositories/recurring_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../support/tap_counter.dart';
import '../../expenses/ui/expenses_fixtures.dart';
import '../../repo_test_support.dart';
import 'recurring_view_model_test.dart' show rule;

/// UI flows of recurring expenses on the real app, router and in-memory
/// repositories (German, the default locale). Today is 1 March 2026.
void main() {
  late ExpensesApp app;

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<List<ExpenseEntry>> expenses(WidgetTester tester) async =>
      (await tester.runAsync(
        () => app.expenses.watchExpenses(app.trip.id).first,
      ))!;

  Future<List<RecurringExpense>> rules(WidgetTester tester) async =>
      ok((await tester.runAsync(app.base.recurring.all))!);

  Future<RecurringExpense> addRule({
    String title = 'Miete',
    int cents = 90000,
    DateTime? start,
    DateTime? lastGenerated,
  }) async => ok(
    await app.base.recurring.create(
      app.trip.id,
      RecurringDraft(
        title: title,
        amountCents: cents,
        payers: {app.people[0].id: cents},
        split: EqualSplit({for (final p in app.people) p.id}),
        rule: rule(start ?? DateTime.utc(2026, 3, 15)),
        lastGenerated: lastGenerated,
      ),
    ),
  );

  setUp(() async {
    app = ExpensesApp();
    await app.seedTrip();
  });

  group('add form', () {
    testWidgets('one quiet chip; one tap makes it monthly; within budget', (
      tester,
    ) async {
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      final taps = TapCounter(tester);
      await taps.tap(find.text('Ausgaben'));
      await settle(tester);
      await taps.tap(find.text('Ausgabe hinzufügen'));
      await settle(tester);

      // Nothing but the chip is visible until it is wanted.
      expect(find.text('Wiederkehrend'), findsOneWidget);
      expect(find.text('Monatlich'), findsNothing);

      await taps.enterText(field('Betrag'), '900');
      await taps.enterText(field('Wofür?'), 'Miete');
      await tester.pump();
      await taps.tap(find.text('Wiederkehrend'));
      await tester.pump();
      expect(find.text('Wöchentlich'), findsOneWidget);
      expect(find.text('Monatlich'), findsOneWidget);
      expect(find.text('Jährlich'), findsOneWidget);
      expect(
        find.textContaining('Ab '),
        findsOneWidget,
        reason: 'says when it starts and that it is automatic',
      );

      await tester.ensureVisible(find.text('Speichern'));
      await taps.tap(find.text('Speichern'));
      await settle(tester);
      taps.expectWithinBudget('add_recurring_expense');

      expect((await expenses(tester)).single.expense.title, 'Miete');
      final stored = (await rules(tester)).single;
      expect(stored.rule.frequency, RecurrenceFrequency.monthly);
      expect(stored.amountCents, 90000);
    });

    testWidgets('weekly can be picked, and the chip toggles off again', (
      tester,
    ) async {
      await pumpExpenses(
        tester,
        app,
        location: '/groups/${app.trip.id}/expenses/new',
      );
      await tester.tap(find.text('Wiederkehrend'));
      await tester.pump();
      await tester.tap(find.text('Wöchentlich'));
      await tester.pump();
      await tester.tap(find.text('Wiederkehrend'));
      await tester.pump();
      expect(find.text('Wöchentlich'), findsNothing);

      await tester.tap(find.text('Wiederkehrend'));
      await tester.pump();
      await tester.tap(find.text('Wöchentlich'));
      await tester.pump();
      await tester.enterText(field('Betrag'), '5');
      await tester.enterText(field('Wofür?'), 'Zeitung');
      await tester.ensureVisible(find.text('Speichern'));
      await tester.tap(find.text('Speichern'));
      await settle(tester);
      expect(
        (await rules(tester)).single.rule.frequency,
        RecurrenceFrequency.weekly,
      );
    });

    testWidgets('a failing rule store says why and keeps the form', (
      tester,
    ) async {
      await pumpExpenses(
        tester,
        app,
        location: '/groups/${app.trip.id}/expenses/new',
      );
      await tester.enterText(field('Betrag'), '5');
      await tester.enterText(field('Wofür?'), 'Zeitung');
      await tester.tap(find.text('Wiederkehrend'));
      await tester.pump();
      app.base.recurring.failWith = const Storage('disk');
      await tester.ensureVisible(find.text('Speichern'));
      await tester.tap(find.text('Speichern'));
      await settle(tester);
      expect(find.textContaining('Das hat nicht geklappt'), findsOneWidget);
      expect(find.text('Neue Ausgabe'), findsOneWidget);
      expect(await expenses(tester), isEmpty);
    });

    testWidgets('English labels', (tester) async {
      await pumpExpenses(
        tester,
        app,
        location: '/groups/${app.trip.id}/expenses/new',
        locale: const Locale('en'),
      );
      await tester.tap(find.text('Recurring'));
      await tester.pump();
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.textContaining('automatically'), findsOneWidget);
    });
  });

  group('list', () {
    Future<void> openList(WidgetTester tester) async {
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      await tester.tap(find.byTooltip('Mehr'));
      await settle(tester);
      await tester.tap(find.text('Wiederkehrende Ausgaben'));
      await settle(tester);
    }

    testWidgets('empty: says how to start', (tester) async {
      await openList(tester);
      expect(
        find.textContaining('Noch nichts Wiederkehrendes'),
        findsOneWidget,
      );
    });

    testWidgets('shows what repeats and when it is next due', (tester) async {
      await addRule();
      await openList(tester);
      expect(find.textContaining('Miete'), findsOneWidget);
      expect(find.textContaining('900,00'), findsOneWidget);
      expect(find.textContaining('Monatlich'), findsOneWidget);
      expect(find.textContaining('Nächste:'), findsOneWidget);
    });

    testWidgets('pause and resume with undo, one tap each', (tester) async {
      await addRule();
      await openList(tester);
      await tester.tap(find.byType(Switch));
      await settle(tester);
      expect(find.text('„Miete“ pausiert'), findsOneWidget);
      expect(find.textContaining('Pausiert'), findsOneWidget);
      expect((await rules(tester)).single.paused, isTrue);

      await tester.tap(find.text('Rückgängig'));
      await settle(tester);
      expect((await rules(tester)).single.paused, isFalse);
    });

    testWidgets('delete with undo, no dialog', (tester) async {
      await addRule();
      await openList(tester);
      await tester.tap(find.byTooltip('Löschen'));
      await settle(tester);
      expect(find.textContaining('„Miete“ gelöscht'), findsOneWidget);
      expect(await rules(tester), isEmpty);

      await tester.tap(find.text('Rückgängig'));
      await settle(tester);
      expect((await rules(tester)).single.title, 'Miete');
    });

    testWidgets('a failing delete says why', (tester) async {
      await addRule();
      await openList(tester);
      app.base.recurring.failWith = const Storage('disk');
      await tester.tap(find.byTooltip('Löschen'));
      await settle(tester);
      expect(find.textContaining('Das hat nicht geklappt'), findsOneWidget);
    });
  });

  group('on app start', () {
    testWidgets('makes what is due and tells so', (tester) async {
      await addRule(start: DateTime.utc(2026, 1, 31));
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      expect(find.text('2 wiederkehrende Ausgaben angelegt.'), findsOneWidget);
      final days = [
        for (final e in await expenses(tester))
          e.expense.date.toIso8601String().substring(0, 10),
      ]..sort();
      expect(days, ['2026-01-31', '2026-02-28']);
    });

    testWidgets('says when older dates were skipped', (tester) async {
      await addRule(start: DateTime.utc(2025, 1, 15));
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      expect(
        find.textContaining('12 wiederkehrende Ausgaben angelegt.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('2 ältere Termine wurden übersprungen.'),
        findsOneWidget,
      );
    });

    testWidgets('a failure names the rule and says what to do', (
      tester,
    ) async {
      await addRule(start: DateTime.utc(2026, 1, 31));
      app.expenses.failWith = const Storage('disk');
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      expect(
        find.textContaining('„Miete“ konnte nicht angelegt werden.'),
        findsOneWidget,
      );
      expect(find.textContaining('Prüf den freien Speicher'), findsOneWidget);
    });

    testWidgets('nothing due: no noise', (tester) async {
      await addRule();
      await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
