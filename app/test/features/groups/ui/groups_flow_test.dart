import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import '../../repo_test_support.dart';

/// UI flows of the groups slice on the real app, router and in-memory
/// repositories (German, the default locale).
void main() {
  late FakeApp app;
  late Group trip;
  late List<GroupMember> people;

  Future<void> seed() async {
    trip = ok(
      await app.groups.create(
        name: 'Trip',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Anna', 'Ben', 'Chiara'])
        ok(await app.members.add(trip.id, name: n)),
    ];
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  Future<void> addMember(
    WidgetTester tester,
    String name, [
    TapCounter? taps,
  ]) async {
    await (taps?.enterText ?? tester.enterText)(
      find.widgetWithText(TextField, 'Name hinzufügen'),
      name,
    );
    await submit(tester);
  }

  setUp(() => app = FakeApp());

  group('home', () {
    testWidgets('empty: the first-run screen leads to the form', (
      tester,
    ) async {
      await pumpMitlio(tester, app);
      expect(find.text('Willkommen bei mitlio'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('Gruppe für Ausgaben anlegen'));
      await tester.pumpAndSettle();
      expect(find.text('Neue Gruppe'), findsOneWidget);
    });

    testWidgets('lists groups; the floating button starts a new one', (
      tester,
    ) async {
      await seed();
      await pumpMitlio(tester, app);
      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('Euro'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.text('Neue Gruppe'));
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);

      await back(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trip'));
      await tester.pumpAndSettle();
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('a failing store shows the error state; retry recovers', (
      tester,
    ) async {
      app.groups.watchError = const Storage('down');
      await pumpMitlio(tester, app);
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);

      app.groups.watchError = null;
      await tester.tap(find.text('Nochmal versuchen'));
      await tester.pumpAndSettle();
      expect(find.text('Willkommen bei mitlio'), findsOneWidget);
    });
  });

  group('create', () {
    testWidgets('name, create, then add people one after another', (
      tester,
    ) async {
      await pumpMitlio(tester, app);
      final taps = TapCounter(tester);
      await taps.tap(find.text('Gruppe für Ausgaben anlegen'));
      await tester.pumpAndSettle();

      await taps.enterText(find.byType(TextField), 'Skiwochenende');
      await taps.tap(find.text('Gruppe anlegen'));
      await tester.pumpAndSettle();

      expect(find.text('Skiwochenende'), findsOneWidget);
      expect(find.text('Noch niemand dabei'), findsOneWidget);
      for (final name in ['Anna', 'Ben', 'Chiara', 'Dino']) {
        await addMember(tester, name, taps);
      }
      taps.expectWithinBudget('create_group_with_members');
      expect(find.text('Noch niemand dabei'), findsNothing);
      for (final name in ['Anna', 'Ben', 'Chiara', 'Dino']) {
        expect(find.text(name), findsOneWidget);
      }
      final group = ok(await app.groups.get('id-1'));
      expect(group.name, 'Skiwochenende');
      expect(group.currency, Currency.eur);

      await back(tester);
      await tester.pumpAndSettle();
      expect(find.text('Skiwochenende'), findsOneWidget);
    });

    testWidgets('the currency can be picked', (tester) async {
      await pumpMitlio(tester, app, location: '/groups/new');
      await tester.enterText(find.byType(TextField), 'Berge');
      await tester.tap(find.byType(DropdownButtonFormField<Currency>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHF · Franken').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gruppe anlegen'));
      await tester.pumpAndSettle();
      expect(ok(await app.groups.get('id-1')).currency, Currency.chf);
    });

    testWidgets('a blank name is explained, then the hint goes away', (
      tester,
    ) async {
      await pumpMitlio(tester, app, location: '/groups/new');
      await tester.tap(find.text('Gruppe anlegen'));
      await tester.pumpAndSettle();
      expect(find.text('Gib der Gruppe einen Namen'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'T');
      await tester.pump();
      expect(find.text('Gib der Gruppe einen Namen'), findsNothing);
    });

    testWidgets('a failing store is reported without leaving the form', (
      tester,
    ) async {
      await pumpMitlio(tester, app, location: '/groups/new');
      app.groups.failWith = const Storage('x');
      await tester.enterText(find.byType(TextField), 'Trip');
      await submit(tester);
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);
      expect(find.text('Neue Gruppe'), findsOneWidget);
    });
  });

  group('members', () {
    testWidgets('tap a name to rename it; an empty name keeps the old one', (
      tester,
    ) async {
      await seed();
      await pumpMitlio(tester, app, location: '/groups/${trip.id}');

      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Benno');
      await submit(tester);
      expect(find.text('Benno'), findsOneWidget);
      expect(find.text('Ben'), findsNothing);

      await tester.tap(find.text('Benno'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), '  ');
      await submit(tester);
      expect(find.text('Benno'), findsOneWidget);
    });

    testWidgets('removing offers undo instead of asking', (tester) async {
      await seed();
      await pumpMitlio(tester, app, location: '/groups/${trip.id}');

      await tester.tap(find.byTooltip('Ben entfernen'));
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsNothing);
      expect(find.text('„Ben“ entfernt'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget);
    });

    testWidgets('a member with expenses stays; a calm note says why', (
      tester,
    ) async {
      await seed();
      ok(
        await app.expenses.create(
          trip.id,
          ExpenseDraft(
            title: 'Taxi',
            amountCents: 900,
            currency: Currency.eur,
            date: DateTime.utc(2026, 2),
            payers: {people[0].id: 900},
            split: EqualSplit({for (final p in people) p.id}),
          ),
        ),
      );
      await pumpMitlio(tester, app, location: '/groups/${trip.id}');

      await tester.tap(find.byTooltip('Anna entfernen'));
      await tester.pumpAndSettle();
      expect(find.text('Anna'), findsOneWidget);
      expect(
        find.text(
          'Anna hat Ausgaben oder Zahlungen und bleibt deshalb in der Gruppe.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byTooltip('Schließen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('bleibt deshalb'), findsNothing);
    });

    testWidgets('dragging a handle reorders the members', (tester) async {
      await seed();
      await pumpMitlio(tester, app, location: '/groups/${trip.id}');

      await tester.drag(
        find.byIcon(Icons.drag_indicator).first,
        const Offset(0, 130),
      );
      await tester.pumpAndSettle();
      final stored = ok(await app.members.list(trip.id));
      expect([for (final m in stored) m.name], ['Ben', 'Anna', 'Chiara']);
      final y = {
        for (final n in ['Anna', 'Ben', 'Chiara'])
          n: tester.getTopLeft(find.text(n)).dy,
      };
      expect(y['Ben'], lessThan(y['Anna']!));
    });

    testWidgets('a blank name adds nobody and keeps the field', (tester) async {
      await seed();
      await pumpMitlio(tester, app, location: '/groups/${trip.id}');
      await tester.tap(find.byTooltip('Hinzufügen'));
      await tester.pumpAndSettle();
      expect(ok(await app.members.list(trip.id)), hasLength(3));
    });
  });

  group('edit and archive', () {
    testWidgets('edit shows the stored values and saves a new name', (
      tester,
    ) async {
      await seed();
      await pumpMitlio(tester, app, location: '/groups/${trip.id}');
      await tester.tap(find.byTooltip('Mehr'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gruppe bearbeiten'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
      expect(find.text('Trip'), findsWidgets);
      await tester.enterText(find.byType(TextField), 'Skitrip');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Skitrip'), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('the currency is locked once expenses exist', (tester) async {
      await seed();
      ok(
        await app.expenses.create(
          trip.id,
          ExpenseDraft(
            title: 'Taxi',
            amountCents: 900,
            currency: Currency.eur,
            date: DateTime.utc(2026, 2),
            payers: {people[0].id: 900},
            split: EqualSplit({for (final p in people) p.id}),
          ),
        ),
      );
      await pumpMitlio(tester, app, location: '/groups/${trip.id}/edit');
      expect(
        find.text(
          'Die Währung lässt sich nicht mehr ändern, sobald es Ausgaben gibt.',
        ),
        findsOneWidget,
      );
      final dropdown = tester.widget<DropdownButtonFormField<Currency>>(
        find.byType(DropdownButtonFormField<Currency>),
      );
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('archiving returns home with an undo', (tester) async {
      await seed();
      await pumpMitlio(tester, app, location: '/groups/${trip.id}');
      await tester.tap(find.byTooltip('Mehr'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gruppe archivieren'));
      await tester.pumpAndSettle();

      expect(find.text('Willkommen bei mitlio'), findsOneWidget);
      expect(find.text('„Trip“ archiviert'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('Trip'), findsOneWidget);
    });

    testWidgets('an archived group shows the error state, not a crash', (
      tester,
    ) async {
      await pumpMitlio(tester, app, location: '/groups/nope');
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);
    });
  });

  testWidgets('English strings', (tester) async {
    await pumpMitlio(tester, app, locale: const Locale('en'));
    expect(find.text('Welcome to mitlio'), findsOneWidget);
    expect(find.text('Start a carpool'), findsOneWidget);
  });
}
