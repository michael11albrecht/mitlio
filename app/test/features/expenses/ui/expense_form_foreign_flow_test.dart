import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'expenses_fixtures.dart';

/// P7-T01 on the real app: a dollar expense in a euro group, entered in the
/// form, listed with both amounts, and reopened for editing.
void main() {
  late ExpensesApp app;

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.ensureVisible(field(label));
    await tester.tap(field(label));
    await tester.pump();
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  Future<void> pickCurrency(WidgetTester tester, String code) async {
    await tester.tap(find.byType(DropdownButtonFormField<Currency>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(code).last);
    await tester.pumpAndSettle();
  }

  Future<void> openForm(WidgetTester tester) async {
    await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
    await tester.tap(find.text('Ausgaben'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausgabe hinzufügen').last);
    await tester.pumpAndSettle();
  }

  setUp(() async {
    app = ExpensesApp();
    await app.seedTrip();
  });

  testWidgets('enter a dollar amount and a rate, see the result, save', (
    tester,
  ) async {
    await openForm(tester);
    expect(find.text('Kurs'), findsNothing);

    await pickCurrency(tester, 'USD');
    expect(find.text('Kurs'), findsOneWidget);
    expect(find.text('1 USD = '), findsOneWidget);

    await type(tester, 'Betrag', '10');
    await type(tester, 'Wofür?', 'Taxi');
    // Without a rate there is no result yet; saving explains why, calmly.
    expect(find.textContaining('Gruppenwährung'), findsNothing);
    await tester.ensureVisible(find.text('Speichern'));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Gib den Kurs ein'), findsOneWidget);
    expect(find.text('Neue Ausgabe'), findsOneWidget);

    await type(tester, 'Kurs', 'abc');
    expect(
      find.text('Das ist kein gültiger Kurs'),
      findsNothing,
      reason: 'letters are filtered out',
    );
    await type(tester, 'Kurs', '0,92');
    expect(find.text('= 9,20 € (Gruppenwährung)'), findsOneWidget);
    expect(find.text('Gib den Kurs ein'), findsNothing);

    await tester.ensureVisible(find.text('Speichern'));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final entries = (await tester.runAsync(
      () => app.expenses.watchExpenses(app.trip.id).first,
    ))!;
    final e = entries.single;
    expect(e.expense.amountCents, 920);
    expect(
      e.foreign,
      const ForeignAmount(
        currency: Currency.usd,
        amountCents: 1000,
        ratePpm: 920000,
      ),
    );
    // The list shows what was paid and what it is worth in the group.
    expect(find.text(r'10,00 $'), findsOneWidget);
    expect(find.textContaining('9,20 € · '), findsOneWidget);
  });

  testWidgets('a rate with a wrong separator is flagged inline', (
    tester,
  ) async {
    await openForm(tester);
    await pickCurrency(tester, 'USD');
    await type(tester, 'Kurs', '1,2,3');
    expect(find.text('Das ist kein gültiger Kurs'), findsOneWidget);
    await type(tester, 'Kurs', '1,2');
    expect(find.text('Das ist kein gültiger Kurs'), findsNothing);
  });

  testWidgets('the form reopens a stored dollar expense with its rate', (
    tester,
  ) async {
    await app.expenses.create(
      app.trip.id,
      ExpenseDraft(
        title: 'Taxi NYC',
        amountCents: 1104,
        currency: Currency.eur,
        date: DateTime.utc(2026, 2),
        payers: {app.people[0].id: 1104},
        split: EqualSplit({for (final p in app.people) p.id}),
        foreign: const ForeignAmount(
          currency: Currency.usd,
          amountCents: 1200,
          ratePpm: 920000,
        ),
      ),
    );
    await pumpExpenses(tester, app, location: '/groups/${app.trip.id}');
    await tester.tap(find.text('Ausgaben'));
    await tester.pumpAndSettle();
    expect(find.text(r'12,00 $'), findsOneWidget);
    expect(find.textContaining('11,04 € · '), findsOneWidget);

    await tester.tap(find.text('Taxi NYC'));
    await tester.pumpAndSettle();
    expect(find.text('Ausgabe bearbeiten'), findsOneWidget);
    expect(find.text('0,92'), findsOneWidget);
    expect(find.text('12,00'), findsOneWidget);
    expect(find.text('= 11,04 € (Gruppenwährung)'), findsOneWidget);
  });
}
