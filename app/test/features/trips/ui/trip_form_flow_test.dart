import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/debug/debug_snapshots.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import '../../repo_test_support.dart';

/// UI flows of the trip slice on the real app, router and in-memory
/// repositories (German, the default locale).
void main() {
  late FakeApp app;
  late Group group;
  late List<GroupMember> people;

  /// A tall screen: the whole form is built, nothing waits behind a scroll.
  void tripTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      tester.view
        ..physicalSize = const Size(800, 2600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await body(tester);
    });
  }

  setUp(() async {
    app = FakeApp();
    group = ok(
      await app.groups.create(
        name: 'Pendeln',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Anna', 'Ben', 'Chiara'])
        ok(await app.members.add(group.id, name: n)),
    ];
  });

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  // `Stream.first` waits for the cancel future, which never completes under
  // the widget tests' fake clock; take the first event by hand.
  Future<List<ExpenseEntry>> stored() {
    final first = Completer<List<ExpenseEntry>>();
    late final StreamSubscription<List<ExpenseEntry>> sub;
    sub = app.expenses.watchExpenses(group.id).listen((entries) {
      first.complete(entries);
      unawaited(sub.cancel());
    });
    return first.future;
  }

  tripTest('from the group: 2 taps and 3 numbers log a trip', (
    tester,
  ) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}');
    final taps = TapCounter(tester);
    await taps.tap(find.byTooltip('Fahrt hinzufügen'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Trag Strecke, Verbrauch und Preis ein'),
      findsOne,
    );

    await taps.enterText(field('Strecke (einfach)'), '250');
    await taps.enterText(field('Verbrauch'), '6,5');
    await taps.enterText(field('Preis pro Liter'), '1,799');
    await tester.pumpAndSettle();
    expect(find.text('Jede Person zahlt rund'), findsOneWidget);
    expect(find.textContaining('9,75'), findsOneWidget);
    expect(find.textContaining('Anna bekommt 19,48'), findsOneWidget);

    await taps.tap(find.text('Fahrt speichern'));
    await tester.pumpAndSettle();
    taps.expectWithinBudget('log_commute_ride');

    expect(find.text('Fahrt gespeichert'), findsOneWidget);
    expect(find.text('Pendeln'), findsOneWidget);
    final entries = await stored();
    expect(entries.single.expense.amountCents, 2923);
    expect(entries.single.expense.title, 'Fahrt');
    expect(entries.single.tripMeta, isNotNull);
  });

  tripTest('undo takes the saved trip back', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}/trip');
    await type(tester, 'Strecke (einfach)', '100');
    await type(tester, 'Verbrauch', '5');
    await type(tester, 'Preis pro Liter', '2');
    await tester.tap(find.text('Fahrt speichern'));
    await tester.pumpAndSettle();
    expect(await stored(), hasLength(1));

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(await stored(), isEmpty);
  });

  tripTest('the breakdown folds open and lists every part', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}/trip');
    await type(tester, 'Strecke (einfach)', '250');
    await type(tester, 'Verbrauch', '6,5');
    await type(tester, 'Preis pro Liter', '1.799');
    await type(tester, 'Verschleiß (optional)', '0,05');
    await tester.ensureVisible(field('Maut (optional)'));
    await type(tester, 'Maut (optional)', '11,50');
    expect(find.text('Gesamt'), findsNothing);

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    for (final label in [
      'Sprit',
      'Verschleiß',
      'Maut',
      'Gesamt',
      'Pro Person',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.textContaining('53,23'), findsOneWidget);
    expect(find.text('Fähre'), findsNothing);
  });

  tripTest('equal shares read "Jede Person zahlt"', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}/trip');
    await tester.tap(find.text('Fahrer zahlt mit'));
    await tester.pump();
    await tester.tap(find.text('Kilometerpauschale'));
    await tester.pumpAndSettle();
    await type(tester, 'Strecke (einfach)', '250');
    await type(tester, 'Pauschale pro km', '0,30');
    expect(find.text('Jede Person zahlt'), findsOneWidget);
    expect(find.textContaining('37,50'), findsOneWidget);
    expect(find.textContaining('Anna bekommt 75,00'), findsOneWidget);
    expect(find.textContaining('Verbrauch'), findsNothing);
  });

  tripTest('wrong numbers are flagged, not guessed', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}/trip');
    await type(tester, 'Strecke (einfach)', '2,5,0');
    expect(find.text('Das ist keine gültige Zahl'), findsOneWidget);
    await tester.tap(find.text('Fahrt speichern'), warnIfMissed: false);
    await tester.pump();
    expect(await stored(), isEmpty);
  });

  tripTest('driver and passengers are chips; nobody left is explained', (
    tester,
  ) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}/trip');
    await type(tester, 'Strecke (einfach)', '100');
    await type(tester, 'Verbrauch', '5');
    await type(tester, 'Preis pro Liter', '2');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Ben'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Ben'))
          .selected,
      isTrue,
    );
    expect(find.widgetWithText(FilterChip, 'Ben'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Anna'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Anna'));
    await tester.tap(find.widgetWithText(FilterChip, 'Chiara'));
    await tester.tap(find.text('Fahrer zahlt mit'));
    await tester.pump();
    expect(find.text('Wähle mindestens eine Person, die mitfährt.'), findsOne);
  });

  tripTest('electric vehicles are asked in kWh', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}/trip');
    await tester.tap(find.text('Strom'));
    await tester.pumpAndSettle();
    expect(field('Preis pro kWh'), findsOneWidget);
    expect(find.text('kWh/100 km'), findsOneWidget);
  });

  tripTest('the next trip starts from the last one', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}/trip');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ben'));
    await tester.pump();
    await type(tester, 'Strecke (einfach)', '100');
    await type(tester, 'Verbrauch', '5,5');
    await type(tester, 'Preis pro Liter', '1,899');
    await tester.tap(find.text('Fahrt speichern'));
    await tester.pumpAndSettle();

    final container = await pumpMitlio(
      tester,
      app,
      location: '/groups/${group.id}/trip',
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Ben'))
          .selected,
      isTrue,
    );
    expect(
      tester.widget<TextField>(field('Verbrauch')).controller!.text,
      '5,5',
    );
    expect(
      tester.widget<TextField>(field('Preis pro Liter')).controller!.text,
      '1,899',
    );
    expect(
      tester.widget<TextField>(field('Strecke (einfach)')).controller!.text,
      isEmpty,
    );
    final snap = buildSnapshotRegistry(container).snapshot('trip')!;
    expect(snap['status'], 'incomplete');
    expect((snap['inputs']! as Map)['driverId'], people[1].id);
  });

  tripTest('a failing save keeps the form and says so', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${group.id}/trip');
    await type(tester, 'Strecke (einfach)', '100');
    await type(tester, 'Verbrauch', '5');
    await type(tester, 'Preis pro Liter', '2');
    ok(await app.groups.softDelete(group.id));
    await tester.tap(find.text('Fahrt speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Das hat nicht geklappt'), findsOneWidget);
    expect(find.text('Fahrt speichern'), findsOneWidget);
  });

  tripTest('a group without people asks for them first', (tester) async {
    final empty = ok(
      await app.groups.create(
        name: 'Leer',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    await pumpMitlio(tester, app, location: '/groups/${empty.id}/trip');
    expect(find.text('Noch niemand dabei'), findsOneWidget);
    expect(find.text('Fahrt speichern'), findsNothing);
  });

  tripTest('an unknown group shows the error state', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/nope/trip');
    expect(find.text('Das hat nicht geklappt'), findsOneWidget);
    await tester.tap(find.text('Nochmal versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Das hat nicht geklappt'), findsOneWidget);
  });

  tripTest('English strings and decimal point', (tester) async {
    await pumpMitlio(
      tester,
      app,
      location: '/groups/${group.id}/trip',
      locale: const Locale('en'),
    );
    await type(tester, 'Distance (one way)', '250');
    await type(tester, 'Consumption', '6.5');
    await type(tester, 'Price per litre', '1.799');
    expect(find.text('Everyone pays about'), findsOneWidget);
    expect(find.text('€9.75'), findsOneWidget);
    expect(find.text('Anna gets €19.48'), findsOneWidget);
  });
}
