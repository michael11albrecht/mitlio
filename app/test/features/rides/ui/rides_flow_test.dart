import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/ride_calendar.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../support/tap_counter.dart';
import 'rides_fixtures.dart';

const _nbsp = ' ';

void main() {
  late RidesApp app;

  String ridesTab() => '/groups/${app.group.id}?tab=rides';

  Future<List<Ride>> stored() async => [
    for (final e in await app.entriesIn(
      Custom(DateTime.utc(2000), DateTime.utc(2100)),
    ))
      e.ride,
  ];

  setUp(() => app = RidesApp());

  void rideTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) {
        app.tester = tester;
        return body(tester);
      });

  group('quick log', () {
    rideTest('one template: one tap saves, the result is in the snackbar', (
      tester,
    ) async {
      await app.seedCommute();
      await pumpRides(tester, app, location: ridesTab());
      expect(find.text('Heute gefahren'), findsWidgets);
      expect(find.text('Arbeit · 2 × 20 km'), findsOneWidget);
      // Everything is pre-set, and the card says what it will do.
      expect(find.text('Ben zahlt 2,27$_nbsp€'), findsOneWidget);
      expect(find.text('Kraftstoff 1,75$_nbsp€ je l'), findsOneWidget);

      final taps = TapCounter(tester);
      await taps.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      taps.expectWithinBudget('log_commute_ride');
      expect(taps.taps, 1);

      expect(
        find.text('Gespeichert · Ben zahlt 2,27$_nbsp€'),
        findsOneWidget,
      );
      final rides = await stored();
      expect(rides, hasLength(1));
      expect(rides.single.driverId, app.people[0].id);
      expect(rides.single.passengerIds, {app.people[1].id});
      // The card turns into the calm done state.
      expect(find.text('Ann ist gefahren'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Speichern'), findsNothing);
    });

    rideTest('undo takes the ride back and reopens the card', (
      tester,
    ) async {
      await app.seedCommute();
      await pumpRides(tester, app, location: ridesTab());
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(await stored(), isEmpty);
      expect(find.widgetWithText(FilledButton, 'Speichern'), findsOneWidget);
    });

    rideTest('another driver is one more tap, still within budget', (
      tester,
    ) async {
      await app.seedCommute();
      await pumpRides(tester, app, location: ridesTab());
      final taps = TapCounter(tester);
      await taps.tap(find.widgetWithText(ChoiceChip, 'Ben'));
      await tester.pump();
      // The carpool follows: Ann pays now.
      expect(find.text('Ann zahlt 2,28$_nbsp€'), findsOneWidget);
      await taps.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      taps.expectWithinBudget('log_commute_ride');
      expect((await stored()).single.driverId, app.people[1].id);
    });

    rideTest('several routes: pick, then save (two taps)', (tester) async {
      await app.seedCommute();
      await app.addRoute('Training', driver: 1);
      await pumpRides(tester, app, location: ridesTab());
      expect(find.text('Wähle deine Strecke.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Speichern'),
            )
            .onPressed,
        isNull,
      );

      final taps = TapCounter(tester);
      await taps.tap(find.widgetWithText(ChoiceChip, 'Arbeit'));
      await tester.pump();
      await taps.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      taps.expectWithinBudget('log_commute_ride');
      expect(taps.taps, 2);
      expect((await stored()).single.distanceMeters, 20000);
    });

    rideTest('passengers toggle and the price edits inline', (
      tester,
    ) async {
      await app.seedCommute();
      await pumpRides(tester, app, location: ridesTab());
      await tester.tap(find.widgetWithText(FilterChip, 'Cy'));
      await tester.pump();
      expect(
        find.text('Ben zahlt 1,52$_nbsp€, Cy zahlt 1,51$_nbsp€'),
        findsOneWidget,
      );
      await tester.tap(find.text('Kraftstoff 1,75$_nbsp€ je l'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Preis je l'),
        '1,999',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      final ride = (await stored()).single;
      expect(ride.pricePerUnitMilli, 1999);
      expect(ride.passengerIds, {app.people[1].id, app.people[2].id});
    });

    rideTest('a failing save says so and keeps the card', (tester) async {
      await app.seedCommute();
      await pumpRides(tester, app, location: ridesTab());
      app.rides.failWith = const Storage('disk');
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Das hat nicht geklappt'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Speichern'), findsOneWidget);
    });

    rideTest("after today's ride the card offers another one", (
      tester,
    ) async {
      await app.seedCommute();
      await app.ride(date: app.today, driver: 0, passengers: [1]);
      await pumpRides(tester, app, location: ridesTab());
      expect(find.text('Ann ist gefahren'), findsOneWidget);
      await tester.tap(find.text('Weitere Fahrt'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Speichern'), findsOneWidget);
    });
  });

  group('first run', () {
    rideTest('car, then route, then the first ride', (tester) async {
      await app.seedGroup();
      await pumpRides(tester, app, location: ridesTab());
      expect(find.text('Noch keine Strecke'), findsOneWidget);
      expect(
        find.text(
          'Leg dein Auto und deine Strecke an — dann reichen 2 Taps pro Fahrt.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Auto und Strecke anlegen'));
      await tester.pumpAndSettle();

      expect(find.text('Neues Fahrzeug'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Golf');
      await tester.enterText(
        find.widgetWithText(TextField, 'Verbrauch (l/100 km)'),
        '6,5',
      );
      await tester.pump();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // The car form hands over to the route form.
      expect(find.text('Neue Strecke'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Arbeit');
      await tester.enterText(
        find.widgetWithText(TextField, 'Entfernung einfach (km)'),
        '20',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ann'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Ben'));
      await tester.pump();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Back on the tab, ready to log.
      expect(find.text('Heute gefahren'), findsWidgets);
      expect(find.text('Arbeit · 2 × 20 km'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect((await stored()).single.driverId, app.people[0].id);
    });

    rideTest('a car exists: straight to the route form', (tester) async {
      await app.seedVehicle();
      await pumpRides(tester, app, location: ridesTab());
      expect(find.text('Strecke anlegen'), findsOneWidget);
      await tester.tap(find.text('Strecke anlegen'));
      await tester.pumpAndSettle();
      expect(find.text('Neue Strecke'), findsOneWidget);
    });

    rideTest('forms explain what is missing', (tester) async {
      await app.seedVehicle();
      await pumpRides(
        tester,
        app,
        location: '/groups/${app.group.id}/rides/templates/new',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pump();
      expect(find.text('Gib einen Namen ein'), findsOneWidget);
      expect(find.text('Gib die Entfernung ein'), findsOneWidget);

      await pumpRides(
        tester,
        app,
        location: '/groups/${app.group.id}/rides/vehicles/new',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pump();
      expect(find.text('Gib den Verbrauch ein'), findsOneWidget);
    });

    rideTest('a group without people asks for them first', (tester) async {
      await app.seedMemberless();
      await pumpRides(tester, app, location: ridesTab());
      expect(
        find.text('Füge zuerst die Leute hinzu, die mitfahren.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Mitglieder hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Leute'), findsNothing);
    });
  });

  group('calendar and list', () {
    Future<void> seedMonth() async {
      await app.seedCommute();
      await app.ride(date: '2026-03-02', driver: 0, passengers: [1]);
      await app.ride(date: '2026-03-03', driver: 1, passengers: [0]);
      await app.ride(date: '2026-02-27', driver: 0, passengers: [1]);
    }

    rideTest('shows the month, its rides and who drove', (tester) async {
      await seedMonth();
      await pumpRides(tester, app, location: ridesTab());
      expect(find.text('März 2026'), findsOneWidget);
      expect(find.byType(RideCalendar), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^1\. März 2026: ?$|Ann$')),
        findsWidgets,
      );
      // Two rides in March, newest first; February's is not listed.
      expect(find.text('Ann fuhr · 2 × 20 km'), findsOneWidget);
      expect(find.text('Ben fuhr · 2 × 20 km'), findsOneWidget);
      expect(find.text('mit Ben'), findsNothing);
      expect(find.textContaining('mit Ben'), findsOneWidget);
    });

    rideTest('moves between months', (tester) async {
      await seedMonth();
      await pumpRides(tester, app, location: ridesTab());
      await tester.tap(find.byTooltip('Vorheriger Monat'));
      await tester.pumpAndSettle();
      expect(find.text('Februar 2026'), findsOneWidget);
      expect(find.textContaining('Ann fuhr'), findsOneWidget);
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      expect(find.text('In diesem Monat noch keine Fahrt'), findsOneWidget);
    });

    rideTest('swipe deletes a ride, undo brings it back', (tester) async {
      await seedMonth();
      await pumpRides(tester, app, location: ridesTab());
      await tester.drag(
        find.text('Ben fuhr · 2 × 20 km'),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ben fuhr · 2 × 20 km'), findsNothing);
      expect(find.text('Fahrt gelöscht'), findsOneWidget);
      expect(await stored(), hasLength(2));
      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('Ben fuhr · 2 × 20 km'), findsOneWidget);
      expect(await stored(), hasLength(3));
    });

    rideTest('a day opens its rides, a ride can go from there', (
      tester,
    ) async {
      await seedMonth();
      await pumpRides(tester, app, location: ridesTab());
      await tester.tap(
        find.descendant(
          of: find.byType(RideCalendar),
          matching: find.text('3'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dienstag, 3. März 2026'), findsOneWidget);
      await tester.drag(
        find.text('Ben fuhr · 2 × 20 km').last,
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(await stored(), hasLength(2));
      expect(find.text('Fahrt gelöscht'), findsOneWidget);
    });

    rideTest('an empty day offers to log a ride for it', (tester) async {
      await seedMonth();
      await pumpRides(tester, app, location: ridesTab());
      await tester.tap(
        find.descendant(
          of: find.byType(RideCalendar),
          matching: find.text('10'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Keine Fahrt an diesem Tag'), findsOneWidget);
      await tester.tap(find.text('Fahrt für diesen Tag erfassen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gefahren am'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(
        (await stored()).map((r) => r.date),
        contains(DateTime.utc(2026, 3, 10)),
      );
      // Today stays open for today's ride.
      expect(find.text('Heute gefahren'), findsWidgets);
    });

    rideTest('rides of a settled period are locked', (tester) async {
      await seedMonth();
      final entry = (await app.entriesIn(const Month(2026, 3))).first;
      await app.settle([entry.ride.id]);
      await pumpRides(tester, app, location: ridesTab());
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      expect(find.bySemanticsLabel('Abgerechnet, gesperrt'), findsWidgets);
      await tester.drag(
        find.text('Ann fuhr · 2 × 20 km'),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ann fuhr · 2 × 20 km'), findsOneWidget);
      expect(await stored(), hasLength(3));
    });
  });

  group('settings', () {
    rideTest('lists cars and routes, edits and deletes with undo', (
      tester,
    ) async {
      await app.seedCommute();
      await pumpRides(tester, app, location: ridesTab());
      await tester.tap(find.byTooltip('Fahrzeuge und Strecken'));
      await tester.pumpAndSettle();
      expect(find.text('Golf'), findsOneWidget);
      expect(find.text('Benzin · 6,5 l/100 km'), findsOneWidget);
      expect(find.text('2 × 20 km · Golf'), findsOneWidget);

      // The car is still in use.
      await tester.tap(find.byTooltip('Löschen').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Das Fahrzeug wird noch von einer Strecke genutzt.'),
        findsOneWidget,
      );

      // The route goes with undo.
      await tester.tap(find.byTooltip('Löschen').last);
      await tester.pumpAndSettle();
      expect(find.text('„Arbeit“ gelöscht'), findsOneWidget);
      expect(find.text('Noch keine Strecke'), findsOneWidget);
      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('2 × 20 km · Golf'), findsOneWidget);

      await tester.tap(find.text('Arbeit'));
      await tester.pumpAndSettle();
      expect(find.text('Strecke bearbeiten'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Büro');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Büro'), findsOneWidget);

      await tester.tap(find.text('Golf'));
      await tester.pumpAndSettle();
      expect(find.text('Fahrzeug bearbeiten'), findsOneWidget);
    });

    rideTest('add buttons open the forms', (tester) async {
      await app.seedCommute();
      await pumpRides(
        tester,
        app,
        location: '/groups/${app.group.id}/rides/settings',
      );
      await tester.tap(find.text('Fahrzeug hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.text('Neues Fahrzeug'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Strecke hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.text('Neue Strecke'), findsOneWidget);
    });
  });

  group('home shortcut', () {
    rideTest('groups without a route do not have it', (tester) async {
      await app.seedVehicle();
      await pumpRides(tester, app, location: '/');
      expect(find.text('Pendler'), findsOneWidget);
      expect(find.text('Heute gefahren'), findsNothing);
    });

    rideTest('it opens the quick log of the group', (tester) async {
      await app.seedCommute();
      await pumpRides(tester, app, location: '/');
      await tester.tap(find.widgetWithText(FilledButton, 'Heute gefahren'));
      await tester.pumpAndSettle();
      // The Fahrten tab is open, ready to save.
      expect(find.widgetWithText(FilledButton, 'Speichern'), findsOneWidget);
    });
  });
}
