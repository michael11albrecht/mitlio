import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/widgets/amount_field.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../helpers/a11y.dart';
import '../../helpers/themed_app.dart';

void main() {
  forEachMode(
    'AmountField meets a11y guidelines',
    () => AmountField(
      currency: Currency.eur,
      label: 'Betrag',
      cents: 1234,
      onChanged: (_) {},
    ),
    (tester, _, _) => expectAccessible(tester),
  );

  testWidgets('emits int cents for comma and dot input', (tester) async {
    final emitted = <int?>[];
    await tester.pumpWidget(
      themedApp(
        AmountField(
          currency: Currency.eur,
          label: 'Betrag',
          onChanged: emitted.add,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '12,34');
    await tester.enterText(find.byType(TextField), '12.3');
    await tester.enterText(find.byType(TextField), '');
    expect(emitted, [1234, 1230, null]);
  });

  testWidgets('filters letters and signs', (tester) async {
    await tester.pumpWidget(
      themedApp(
        AmountField(
          currency: Currency.eur,
          label: 'Betrag',
          onChanged: (_) {},
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '-1a2,5€');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '12,5',
    );
  });

  testWidgets('shows localised error for invalid input, clears when fixed', (
    tester,
  ) async {
    final emitted = <int?>[];
    await tester.pumpWidget(
      themedApp(
        AmountField(
          currency: Currency.eur,
          label: 'Betrag',
          onChanged: emitted.add,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '1,234');
    await tester.pump();
    expect(find.text('Das ist kein gültiger Betrag'), findsOneWidget);
    expect(emitted.last, isNull);
    await tester.enterText(find.byType(TextField), '1,23');
    await tester.pump();
    expect(find.text('Das ist kein gültiger Betrag'), findsNothing);
    expect(emitted.last, 123);
  });

  testWidgets('shows initial value and adopts external changes', (
    tester,
  ) async {
    Widget build(int? cents) => themedApp(
      AmountField(
        currency: Currency.eur,
        label: 'Betrag',
        cents: cents,
        onChanged: (_) {},
      ),
    );
    await tester.pumpWidget(build(1234));
    String text() =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;
    expect(text(), '12,34');
    await tester.pumpWidget(build(500));
    expect(text(), '5,00');
    await tester.pumpWidget(build(null));
    expect(text(), '');
  });

  testWidgets('typing does not get overwritten by the parent echo', (
    tester,
  ) async {
    int? value;
    await tester.pumpWidget(
      themedApp(
        StatefulBuilder(
          builder: (context, setState) => AmountField(
            currency: Currency.eur,
            label: 'Betrag',
            cents: value,
            onChanged: (c) => setState(() => value = c),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '12.3');
    expect(value, 1230);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '12.3',
    );
  });

  testWidgets('uses english separator and currency symbol per locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedApp(
        AmountField(
          currency: Currency.usd,
          label: 'Amount',
          cents: 1234,
          onChanged: (_) {},
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '12.34',
    );
    expect(find.text(r'$'), findsOneWidget);
  });
}
