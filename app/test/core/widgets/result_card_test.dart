import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/widgets/result_card.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../helpers/a11y.dart';
import '../../helpers/themed_app.dart';

void main() {
  forEachMode(
    'ResultCard meets a11y guidelines',
    () => const ResultCard(
      caption: 'Jede Person zahlt',
      cents: 1240,
      currency: Currency.eur,
      detail: '3 Personen, 42 km',
    ),
    (tester, _, _) => expectAccessible(tester),
  );

  testWidgets('shows caption, figure and optional detail', (tester) async {
    await tester.pumpWidget(
      themedApp(
        const ResultCard(
          caption: 'Jede Person zahlt',
          cents: 1240,
          currency: Currency.eur,
        ),
      ),
    );
    expect(find.text('Jede Person zahlt'), findsOneWidget);
    expect(find.text('12,40 €'), findsOneWidget);
    expect(find.byType(Text), findsNWidgets(2));
  });

  testWidgets('screen reader gets one sentence', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      themedApp(
        const ResultCard(
          caption: 'Jede Person zahlt',
          cents: 1240,
          currency: Currency.eur,
          detail: '3 Personen',
        ),
      ),
    );
    final label = tester.getSemantics(find.byType(MergeSemantics)).label;
    expect(label, contains('Jede Person zahlt'));
    expect(label, contains('12 Euro 40'));
    expect(label, contains('3 Personen'));
    handle.dispose();
  });

  testWidgets('figure shrinks instead of overflowing at 2x on small screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      themedApp(
        const ResultCard(
          caption: 'Jede Person zahlt',
          cents: 123456789,
          currency: Currency.eur,
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
