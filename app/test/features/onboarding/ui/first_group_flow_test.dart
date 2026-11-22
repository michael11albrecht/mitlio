import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import '../../repo_test_support.dart';

final _de = AppLocalizationsDe();

/// The first group in three steps on the real app, router and in-memory
/// repositories (PU-T12).
void main() {
  late FakeApp app;

  setUp(() => app = FakeApp());

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpMitlio(tester, app, location: '/welcome/group');
  }

  Finder text(String t) => find.text(t);
  Finder field(String label) => find.widgetWithText(TextField, label);

  testWidgets('every step answered stays within the first_group budget', (
    tester,
  ) async {
    ok(await app.profile.save(displayName: 'Mia'));
    await open(tester);
    final taps = TapCounter(tester);

    expect(text(_de.firstGroupNameTitle), findsOneWidget);
    await taps.enterText(field(_de.groupNameLabel), 'Rom');
    await taps.tap(text(_de.setupNext));
    await tester.pumpAndSettle();

    expect(text(_de.firstGroupPeopleTitle), findsOneWidget);
    expect(text('Schritt 2 von 3'), findsOneWidget);
    // Typing a name and "Weiter" is enough; the name need not be added first.
    await taps.enterText(field(_de.firstGroupPeopleLabel), 'Ann');
    await taps.tap(text(_de.setupNext));
    await tester.pumpAndSettle();

    expect(text(_de.firstGroupCurrencyTitle), findsOneWidget);
    await taps.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();

    expect(text(_de.firstGroupFinishTitle('Rom')), findsOneWidget);
    expect(text(_de.firstGroupSummaryPeople('Ann')), findsOneWidget);
    await taps.tap(text(_de.firstGroupCreate));
    await tester.pumpAndSettle();

    taps.expectWithinBudget('first_group');
    final groups = (await tester.runAsync(
      () => app.groups.watchGroups().first,
    ))!;
    expect(groups.single.name, 'Rom');
    expect(groups.single.currency, Currency.eur);
    final members = (await tester.runAsync(
      () => app.members.list(groups.single.id),
    ))!;
    expect([for (final m in ok(members)) m.name], ['Mia', 'Ann']);
    // The new group is open.
    expect(find.widgetWithText(AppBar, 'Rom'), findsOneWidget);
  });

  testWidgets('a blank name stays with a plain hint', (tester) async {
    await open(tester);
    await tester.tap(text(_de.setupNext));
    await tester.pumpAndSettle();
    expect(text(_de.groupNameRequired), findsOneWidget);
    expect(text(_de.firstGroupNameTitle), findsOneWidget);
  });

  testWidgets('people can be added one by one and removed again', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(field(_de.groupNameLabel), 'Rom');
    await tester.tap(text(_de.setupNext));
    await tester.pumpAndSettle();
    await tester.enterText(field(_de.firstGroupPeopleLabel), 'Ann');
    await tester.tap(find.byTooltip(_de.firstGroupPeopleAdd));
    await tester.pump();
    await tester.enterText(field(_de.firstGroupPeopleLabel), 'Ben');
    await tester.tap(find.byTooltip(_de.firstGroupPeopleAdd));
    await tester.pump();
    expect(find.byType(InputChip), findsNWidgets(2));
    await tester.tap(find.byTooltip(_de.firstGroupPeopleRemove('Ann')));
    await tester.pump();
    expect(find.byType(InputChip), findsOneWidget);
    await tester.tap(text(_de.setupNext));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    expect(text(_de.firstGroupSummaryPeople('Ben')), findsOneWidget);
  });

  testWidgets('nobody added: "Weiter" is "just me"', (tester) async {
    await open(tester);
    await tester.enterText(field(_de.groupNameLabel), 'Rom');
    await tester.tap(text(_de.setupNext));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupNext));
    await tester.pumpAndSettle();
    expect(text(_de.firstGroupCurrencyTitle), findsOneWidget);
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    expect(text(_de.firstGroupSummaryAlone), findsOneWidget);
  });

  testWidgets('a failing store says so and keeps the answers', (tester) async {
    await open(tester);
    await tester.enterText(field(_de.groupNameLabel), 'Rom');
    await tester.tap(text(_de.setupNext));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    app.groups.failWith = const Storage('down');
    await tester.tap(text(_de.firstGroupCreate));
    await tester.pumpAndSettle();
    expect(find.textContaining('Prüf den freien Speicher'), findsOneWidget);
    expect(text(_de.firstGroupFinishTitle('Rom')), findsOneWidget);
    app.groups.failWith = null;
    await tester.tap(text(_de.firstGroupCreate));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Rom'), findsOneWidget);
  });

  testWidgets('back from the finish screen returns to the last step', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(field(_de.groupNameLabel), 'Rom');
    await tester.tap(text(_de.setupNext));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupSkip));
    await tester.pumpAndSettle();
    await tester.tap(text(_de.setupBack));
    await tester.pumpAndSettle();
    expect(text(_de.firstGroupCurrencyTitle), findsOneWidget);
  });
}
