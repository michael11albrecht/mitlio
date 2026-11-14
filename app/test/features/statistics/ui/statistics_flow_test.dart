import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/statistics/ui/statistics_view.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import '../../rides/ui/rides_fixtures.dart';

/// The statistics screen on the real app, router and in-memory repositories
/// (German, the default locale). The fake clock says 2026-03-01.
void main() {
  late RidesApp app;

  setUp(() => app = RidesApp());

  Future<void> spend(
    WidgetTester tester,
    int cents,
    String date, {
    String? category,
  }) async {
    await tester.runAsync(
      () async => ok(
        await app.expenses.create(
          app.group.id,
          ExpenseDraft(
            title: 'Ausgabe',
            amountCents: cents,
            currency: app.group.currency,
            date: DateTime.parse('${date}T00:00:00Z'),
            payers: {app.people[0].id: cents},
            split: EqualSplit({app.people[0].id, app.people[1].id}),
            category: category,
          ),
        ),
      ),
    );
  }

  String route() => '/groups/${app.group.id}/statistics';

  testWidgets('the group menu leads to the statistics', (tester) async {
    app.tester = tester;
    await app.seedGroup();
    await pumpRides(tester, app, location: '/groups/${app.group.id}');
    await tester.tap(find.byTooltip('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Statistik'));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsView), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsView), findsNothing);
  });

  testWidgets('nothing yet: calm empty state, the picker stays', (
    tester,
  ) async {
    app.tester = tester;
    await app.seedGroup();
    await pumpRides(tester, app, location: route());
    expect(find.text('Nichts in diesem Zeitraum'), findsOneWidget);
    expect(find.text('Monat'), findsOneWidget);
    expect(find.text('Nach Kategorie'), findsNothing);
  });

  testWidgets('result first: total and top category, then the lists', (
    tester,
  ) async {
    app.tester = tester;
    await app.seedGroup();
    await spend(tester, 3800, '2026-03-01', category: 'transport');
    await spend(tester, 1200, '2026-03-01', category: 'food');
    await pumpRides(tester, app, location: route());

    expect(find.text('Diesen Monat'), findsOneWidget);
    expect(find.textContaining('50,00'), findsWidgets);
    expect(find.text('2 Ausgaben · meist Verkehr (76 %)'), findsOneWidget);
    for (final title in [
      'Nach Kategorie',
      'Pro Person',
      'Letzte 6 Monate',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    // No rides logged: no rides section.
    expect(find.text('Fahrten'), findsNothing);
    // Result before the lists.
    expect(
      tester.getTopLeft(find.text('Diesen Monat')).dy,
      lessThan(tester.getTopLeft(find.text('Nach Kategorie')).dy),
    );
  });

  testWidgets('the period picker changes the numbers', (tester) async {
    app.tester = tester;
    await app.seedGroup();
    await spend(tester, 1000, '2026-03-01');
    await spend(tester, 2000, '2026-01-10');
    await spend(tester, 4000, '2025-05-10');
    await pumpRides(tester, app, location: route());
    expect(find.text('1 Ausgabe'), findsOneWidget);

    await tester.tap(find.text('3 Monate'));
    await tester.pumpAndSettle();
    expect(find.text('Letzte 3 Monate'), findsOneWidget);
    expect(find.text('2 Ausgaben'), findsOneWidget);

    await tester.tap(find.text('Jahr'));
    await tester.pumpAndSettle();
    expect(find.text('Dieses Jahr'), findsOneWidget);

    await tester.tap(find.text('Alles'));
    await tester.pumpAndSettle();
    expect(find.text('Insgesamt'), findsOneWidget);
    expect(find.text('3 Ausgaben'), findsOneWidget);
  });

  testWidgets('every bar is read out with its numbers', (tester) async {
    final semantics = tester.ensureSemantics();
    app.tester = tester;
    await app.seedGroup();
    await spend(tester, 3800, '2026-03-01', category: 'transport');
    await spend(tester, 1200, '2026-03-01', category: 'food');
    await pumpRides(tester, app, location: route());

    expect(
      find.bySemanticsLabel('Verkehr: 38 Euro, 76 Prozent'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Essen & Trinken: 12 Euro, 24 Prozent'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Ann: bezahlt 50 Euro, verbraucht 25 Euro'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('März 2026: 50 Euro'), findsOneWidget);
    expect(find.bySemanticsLabel('Oktober 2025: 0 Euro'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('rides show km and cost per month', (tester) async {
    final semantics = tester.ensureSemantics();
    app.tester = tester;
    await app.seedCommute();
    await app.ride(date: '2026-03-01', driver: 0);
    await pumpRides(tester, app, location: route());
    expect(find.text('Fahrten'), findsOneWidget);
    expect(find.textContaining('40 km'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^März 2026: 40 Kilometer, .* Euro')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
