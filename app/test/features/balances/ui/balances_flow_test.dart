import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/balances/ui/balances_view.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../balances_support.dart';

/// The balances screen on the real app, router and in-memory repositories
/// (German, the default locale).
void main() {
  late FakeApp app;
  late Scenario s;

  setUp(() async {
    app = FakeApp();
    s = await Scenario.create(app, ['Anna', 'Ben', 'Chiara']);
  });

  testWidgets('group detail leads to the balances screen', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${s.group.id}');
    await tester.tap(find.byTooltip('Wer bekommt was'));
    await tester.pumpAndSettle();
    expect(find.byType(BalancesView), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(BalancesView), findsNothing);
  });

  testWidgets('no entries yet: calm empty state', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${s.group.id}/balances');
    expect(find.text('Noch nichts zu verrechnen'), findsOneWidget);
    expect(find.text('Wer zahlt wem'), findsNothing);
  });

  testWidgets('result first: who gets, who owes, who pays whom', (
    tester,
  ) async {
    await s.expense(
      {'Anna': 3000},
      {'Anna': 1000, 'Ben': 1000, 'Chiara': 1000},
    );
    await s.expense({'Ben': 600}, {'Anna': 300, 'Ben': 300});
    await pumpMitlio(tester, app, location: '/groups/${s.group.id}/balances');

    expect(find.text('Anna bekommt'), findsOneWidget);
    expect(find.textContaining('17,00'), findsOneWidget);
    expect(find.text('Ben schuldet'), findsOneWidget);
    expect(find.text('Chiara schuldet'), findsOneWidget);
    // Gets before owes.
    expect(
      tester.getTopLeft(find.text('Anna bekommt')).dy,
      lessThan(tester.getTopLeft(find.text('Ben schuldet')).dy),
    );
    expect(find.text('Chiara zahlt Anna'), findsOneWidget);
    expect(find.text('Ben zahlt Anna'), findsOneWidget);
    expect(find.text('Alles ausgeglichen'), findsNothing);
  });

  testWidgets('the switch shows the direct debts', (tester) async {
    await s.expense({'Chiara': 2000}, {'Anna': 1000, 'Ben': 1000});
    await s.expense({'Anna': 600}, {'Ben': 600});
    await pumpMitlio(tester, app, location: '/groups/${s.group.id}/balances');
    expect(find.text('Ben zahlt Chiara'), findsOneWidget);
    expect(find.text('Ben zahlt Anna'), findsNothing);

    await tester.tap(find.text('Direkt'));
    await tester.pumpAndSettle();
    expect(find.text('Ben zahlt Anna'), findsOneWidget);
    expect(find.text('Anna zahlt Chiara'), findsOneWidget);

    await tester.tap(find.text('Einfach'));
    await tester.pumpAndSettle();
    expect(find.text('Ben zahlt Anna'), findsNothing);
  });

  testWidgets('paying back everything shows the calm all-square state', (
    tester,
  ) async {
    await s.expense({'Anna': 1000}, {'Ben': 1000});
    final container = await pumpMitlio(
      tester,
      app,
      location: '/groups/${s.group.id}/balances',
    );
    expect(container, isNotNull);
    expect(find.text('Ben zahlt Anna'), findsOneWidget);
    await s.settle('Ben', 'Anna', 1000);
    await tester.pumpAndSettle();
    expect(find.text('Alles ausgeglichen'), findsOneWidget);
    expect(find.text('Ben ist ausgeglichen'), findsOneWidget);
    expect(find.text('Wer zahlt wem'), findsNothing);
  });

  testWidgets('English copy', (tester) async {
    await s.expense({'Anna': 1000}, {'Ben': 1000});
    await pumpMitlio(
      tester,
      app,
      location: '/groups/${s.group.id}/balances',
      locale: const Locale('en'),
    );
    expect(find.text('Anna gets'), findsOneWidget);
    expect(find.text('Ben owes'), findsOneWidget);
    expect(find.text('Ben pays Anna'), findsOneWidget);
  });

  testWidgets('a failing repository offers a retry', (tester) async {
    app.members.watchError = StateError('boom');
    await pumpMitlio(tester, app, location: '/groups/${s.group.id}/balances');
    expect(find.text('Nochmal versuchen'), findsOneWidget);
    app.members.watchError = null;
    await tester.tap(find.text('Nochmal versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Nochmal versuchen'), findsNothing);
  });
}
