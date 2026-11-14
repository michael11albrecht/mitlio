import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';

import '../../helpers/a11y.dart';
import '../../helpers/themed_app.dart';

void main() {
  group('EmptyState', () {
    forEachMode(
      'meets a11y guidelines',
      () => EmptyState(
        icon: Icons.directions_car_outlined,
        title: 'Noch keine Fahrten',
        message: 'Trag deine erste Fahrt ein, den Rest rechnen wir.',
        action: FilledButton(onPressed: () {}, child: const Text('Fahrt')),
      ),
      (tester, _, _) => expectAccessible(tester),
    );

    testWidgets('renders only what it is given', (tester) async {
      await tester.pumpWidget(
        themedApp(const EmptyState(icon: Icons.inbox, title: 'Leer')),
      );
      expect(find.text('Leer'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('title is a header for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        themedApp(const EmptyState(icon: Icons.inbox, title: 'Leer')),
      );
      expect(
        tester.getSemantics(find.text('Leer')),
        matchesSemantics(label: 'Leer', isHeader: true),
      );
      handle.dispose();
    });
  });

  group('ErrorState', () {
    forEachMode(
      'meets a11y guidelines',
      () => ErrorState(onRetry: () {}),
      (tester, _, _) => expectAccessible(tester),
    );

    testWidgets('retry callback fires, default copy per locale', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(themedApp(ErrorState(onRetry: () => retries++)));
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);
      await tester.tap(find.text('Nochmal versuchen'));
      expect(retries, 1);

      await tester.pumpWidget(
        themedApp(ErrorState(onRetry: () {}), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('custom message replaces the default', (tester) async {
      await tester.pumpWidget(
        themedApp(ErrorState(onRetry: () {}, message: 'Kein Netz')),
      );
      expect(find.text('Kein Netz'), findsOneWidget);
      expect(find.text('Versuch es gleich noch einmal.'), findsNothing);
    });
  });
}
