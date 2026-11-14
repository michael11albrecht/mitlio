import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/fx/data/repositories/fx_providers.dart';
import 'package:mitlio/features/fx/data/services/fake_fx_rate_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'expenses_fixtures.dart';

/// P7-T02 on the real app: the ECB rate shows up under the rate field, fills
/// it, and can be overridden and taken back.
void main() {
  late ExpensesApp app;
  late FakeFxRateService fx;

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.ensureVisible(field(label));
    await tester.tap(field(label));
    await tester.pump();
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  Future<void> openForm(WidgetTester tester, {bool backend = true}) async {
    await pumpExpenses(
      tester,
      app,
      location: '/groups/${app.trip.id}',
      extra: [if (backend) fxRateServiceProvider.overrideWithValue(fx)],
    );
    await tester.tap(find.text('Ausgaben'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausgabe hinzufügen').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Currency>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
  }

  setUp(() async {
    app = ExpensesApp();
    fx = FakeFxRateService();
    await app.seedTrip();
  });

  testWidgets('the suggestion fills the rate and is shown with its day', (
    tester,
  ) async {
    await openForm(tester);
    expect(find.text('1 USD = 0,9200 € · EZB, 13.11.'), findsOneWidget);
    expect(find.text('Übernehmen'), findsNothing, reason: 'already applied');
    await type(tester, 'Betrag', '10');
    expect(find.text('= 9,20\u00A0€ (Gruppenwährung)'), findsOneWidget);
  });

  testWidgets('typing another rate offers the ECB rate again', (tester) async {
    await openForm(tester);
    await type(tester, 'Betrag', '10');
    await type(tester, 'Kurs', '0,9');
    expect(find.text('= 9,00\u00A0€ (Gruppenwährung)'), findsOneWidget);
    expect(find.text('Übernehmen'), findsOneWidget);
    await tester.ensureVisible(find.text('Übernehmen'));
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();
    expect(find.text('= 9,20\u00A0€ (Gruppenwährung)'), findsOneWidget);
    expect(find.text('Übernehmen'), findsNothing);
  });

  testWidgets('without a backend the form works as before', (tester) async {
    await openForm(tester, backend: false);
    expect(find.textContaining('EZB'), findsNothing);
    expect(find.text('Kurs'), findsOneWidget);
    expect(fx.calls, isEmpty);
  });
}
