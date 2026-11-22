import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import '../../balances/balances_support.dart';

/// The tip jar on the real app, router and in-memory repositories (German).
void main() {
  late FakeApp app;
  late Scenario s;

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(400, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Anna paid 30,00 for everyone: Ben and Chiara owe her 10,00 each.
  setUp(() async {
    app = FakeApp();
    s = await Scenario.create(app, ['Anna', 'Ben', 'Chiara']);
    await s.expense(
      {'Anna': 3000},
      {'Anna': 1000, 'Ben': 1000, 'Chiara': 1000},
    );
  });

  /// Pays both transfers and ends on the settled screen. Each transfer takes
  /// the same two taps as without the tip jar (docs/ux-budgets.md).
  Future<void> payAll(WidgetTester tester) async {
    await pumpMitlio(tester, app, location: '/groups/${s.group.id}/settle');
    for (final from in ['Ben', 'Chiara']) {
      final taps = TapCounter(tester);
      await taps.tap(find.text('$from → Anna'));
      await tester.pumpAndSettle();
      // Never a tip surface in the payment step.
      expect(find.text('Unterstützen'), findsNothing);
      expect(find.textContaining('Trinkgeld'), findsNothing);
      await taps.tap(find.text('Als bezahlt markieren'));
      await tester.pumpAndSettle();
      taps.expectWithinBudget('mark_transfer_paid');
      expect(taps.taps, 2);
    }
  }

  group('settings row', () {
    testWidgets('flag off: no row', (tester) async {
      await pumpMitlio(tester, app, location: '/settings');
      expect(find.text('mitlio unterstützen'), findsNothing);
    });

    testWidgets('flag on: the row opens the tip jar', (tester) async {
      phone(tester);
      app.support.enabled = true;
      await pumpMitlio(tester, app, location: '/settings');
      await tester.tap(find.text('mitlio unterstützen'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Kleines Trinkgeld'), findsOneWidget);
      expect(find.text('Mittleres Trinkgeld'), findsOneWidget);
      expect(find.text('Großes Trinkgeld'), findsOneWidget);
      expect(find.text('2,99 €'), findsOneWidget);
    });
  });

  group('success-screen line', () {
    testWidgets('flag off: nothing, however many settlements', (tester) async {
      phone(tester);
      app.support.state = const SupportPromptState(settledSinceShown: 40);
      await payAll(tester);
      expect(find.text('Alles ausgeglichen'), findsOneWidget);
      expect(find.text('Unterstützen'), findsNothing);
      expect(app.support.state.settledSinceShown, 40);
    });

    testWidgets('flag on, not yet the fifth settlement: nothing', (
      tester,
    ) async {
      phone(tester);
      app
        ..support.enabled = true
        ..support.state = const SupportPromptState(settledSinceShown: 1);
      await payAll(tester);
      expect(find.text('Alles ausgeglichen'), findsOneWidget);
      expect(find.text('Unterstützen'), findsNothing);
    });

    testWidgets('the fifth: one quiet line after the result, no dialog', (
      tester,
    ) async {
      phone(tester);
      app
        ..support.enabled = true
        ..support.state = const SupportPromptState(settledSinceShown: 4);
      await payAll(tester);
      expect(find.text('Alles ausgeglichen'), findsOneWidget);
      expect(find.textContaining('freiwillig unterstützen'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('"Nicht mehr zeigen" removes it for good', (tester) async {
      phone(tester);
      app
        ..support.enabled = true
        ..support.state = const SupportPromptState(settledSinceShown: 4);
      await payAll(tester);
      await tester.tap(find.text('Nicht mehr zeigen'));
      await tester.pumpAndSettle();
      expect(find.text('Unterstützen'), findsNothing);
      expect(app.support.state.dismissed, isTrue);
    });

    testWidgets('a dismissal that cannot be saved says so', (tester) async {
      phone(tester);
      app
        ..support.enabled = true
        ..support.state = const SupportPromptState(settledSinceShown: 4);
      await payAll(tester);
      app.support.failStorage = true;
      await tester.tap(find.text('Nicht mehr zeigen'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Unterstützen'), findsOneWidget);
    });

    testWidgets('"Unterstützen" opens the tip jar, a tip says thanks', (
      tester,
    ) async {
      phone(tester);
      app
        ..support.enabled = true
        ..support.state = const SupportPromptState(settledSinceShown: 4);
      await payAll(tester);
      await tester.tap(find.text('Unterstützen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Großes Trinkgeld'));
      await tester.pumpAndSettle();
      expect(app.tipStore.bought, [TipSize.large]);
      expect(find.text('Danke dir!'), findsOneWidget);
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('tip jar sheet', () {
    Future<void> open(WidgetTester tester) async {
      phone(tester);
      app.support.enabled = true;
      await pumpMitlio(tester, app, location: '/settings');
      await tester.tap(find.text('mitlio unterstützen'));
      await tester.pumpAndSettle();
    }

    testWidgets('cancel returns to the sizes without a message', (
      tester,
    ) async {
      app.tipStore.outcome = const TipCancelled();
      await open(tester);
      await tester.tap(find.text('Kleines Trinkgeld'));
      await tester.pumpAndSettle();
      expect(find.text('Kleines Trinkgeld'), findsOneWidget);
      expect(find.textContaining('ging nicht durch'), findsNothing);
      expect(find.text('Danke dir!'), findsNothing);
    });

    testWidgets('a failed purchase says what happened and what to do', (
      tester,
    ) async {
      app.tipStore.outcome = const TipFailed(TipFailure.purchaseFailed);
      await open(tester);
      await tester.tap(find.text('Mittleres Trinkgeld'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Das Trinkgeld ging nicht durch.'),
        findsOneWidget,
      );
      expect(find.textContaining('in ein paar Minuten'), findsOneWidget);
      expect(find.text('Mittleres Trinkgeld'), findsOneWidget);
    });

    testWidgets('no store: a message and a retry that works', (tester) async {
      app.tipStore.catalog = const Err(TipFailure.storeUnavailable);
      await open(tester);
      expect(
        find.textContaining('Der Store ist gerade nicht erreichbar'),
        findsOneWidget,
      );
      app.tipStore.catalog = const Ok([
        TipProduct(size: TipSize.small, price: '0,99 €'),
      ]);
      await tester.tap(find.text('Nochmal versuchen'));
      await tester.pumpAndSettle();
      expect(find.text('Kleines Trinkgeld'), findsOneWidget);
    });
  });
}
