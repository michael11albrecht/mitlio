import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../helpers/a11y.dart';
import '../../helpers/themed_app.dart';

void main() {
  forEachMode(
    'MoneyText meets a11y guidelines',
    () => const MoneyText(cents: 1240, currency: Currency.eur),
    (tester, _, _) => expectAccessible(tester),
  );

  testWidgets('formats per locale', (tester) async {
    for (final (locale, expected) in [
      (const Locale('de'), '12,40 €'),
      (const Locale('en'), '€12.40'),
    ]) {
      await tester.pumpWidget(
        themedApp(
          const MoneyText(cents: 1240, currency: Currency.eur),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
    }
  });

  testWidgets('uses tabular figures', (tester) async {
    await tester.pumpWidget(
      themedApp(const MoneyText(cents: 1, currency: Currency.eur)),
    );
    final text = tester.widget<Text>(find.byType(Text).first);
    expect(
      text.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  group('semantics label', () {
    Future<String> label(
      WidgetTester tester,
      int cents,
      Currency c,
      Locale l,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        themedApp(
          MoneyText(cents: cents, currency: c),
          locale: l,
        ),
      );
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.byType(MoneyText));
      final result = node.label;
      handle.dispose();
      return result;
    }

    testWidgets('de reads units and cents', (tester) async {
      expect(
        await label(tester, 1234, Currency.eur, const Locale('de')),
        '12 Euro 34',
      );
    });
    testWidgets('whole amounts omit zero cents', (tester) async {
      expect(
        await label(tester, 1200, Currency.eur, const Locale('de')),
        '12 Euro',
      );
    });
    testWidgets('negative and grouping', (tester) async {
      expect(
        await label(tester, -123456, Currency.eur, const Locale('de')),
        'minus 1.234 Euro 56',
      );
    });
    testWidgets('en and other currencies', (tester) async {
      expect(
        await label(tester, 505, Currency.usd, const Locale('en')),
        '5 US dollars 05',
      );
      expect(
        await label(tester, 300, Currency.sek, const Locale('en')),
        '3 SEK',
      );
    });
  });
}
