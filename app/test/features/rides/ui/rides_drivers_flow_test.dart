import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';

import '../../repo_test_support.dart';
import 'rides_fixtures.dart';

void main() {
  late RidesApp app;

  setUp(() => app = RidesApp());

  Future<void> seedOwnerCase(WidgetTester tester) async {
    app.tester = tester;
    await app.seedCommute();
    await app.ride(
      date: '2026-03-12',
      driver: 0,
      passengers: [1, 2],
      meters: 70000,
    );
    await app.ride(
      date: '2026-03-14',
      driver: 1,
      passengers: [0, 2],
      meters: 70000,
    );
  }

  testWidgets('the fairness card names the next driver and explains', (
    tester,
  ) async {
    await seedOwnerCase(tester);
    app.base.clock.value = DateTime.utc(2026, 3, 20, 9);
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}?tab=rides',
    );
    expect(find.text('Als Nächstes dran: Cy'), findsOneWidget);
    expect(find.textContaining('Nur Mitglieder, die als Fahrer'), findsNothing);
    await tester.tap(find.text('Wie wird das berechnet?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Nur Mitglieder, die als Fahrer'),
      findsOneWidget,
    );
  });

  testWidgets('a non-driver is marked, switching back needs no dialog', (
    tester,
  ) async {
    await seedOwnerCase(tester);
    app.base.clock.value = DateTime.utc(2026, 3, 20, 9);
    await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}?tab=rides',
    );
    expect(find.text('Fährt nicht · wird nicht vorgeschlagen'), findsNothing);

    await tester.tap(find.text('Fahrer ändern'));
    await tester.pumpAndSettle();
    expect(find.text('Wer fährt?'), findsOneWidget);
    expect(
      find.text('Nur Fahrer werden als Nächstes vorgeschlagen.'),
      findsOne,
    );

    await tester.ensureVisible(find.byType(SwitchListTile).last);
    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();
    expect(find.text('Cy wird nicht mehr vorgeschlagen'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).last).value,
      isFalse,
    );

    // Undo puts the switch back.
    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).last).value,
      isTrue,
    );

    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Als Nächstes dran: Ann'), findsOneWidget);
    expect(find.text('Fährt nicht · wird nicht vorgeschlagen'), findsOneWidget);
  });

  testWidgets('a passenger who never drives is asked once', (tester) async {
    app.tester = tester;
    await app.seedCommute();
    for (var day = 1; day <= 4; day++) {
      await app.ride(date: '2026-03-0$day', driver: 0, passengers: [1]);
    }
    app.base.clock.value = DateTime.utc(2026, 3, 10, 9);
    final container = await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}?tab=rides',
    );
    expect(find.textContaining('nicht selbst?'), findsNothing);

    await tester.runAsync(
      () => container
          .read(ridesViewModelProvider(app.group.id).notifier)
          .logRide(
            driverId: app.people[0].id,
            templateId: app.work.id,
            passengerIds: {app.people[1].id},
          ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fährt Ben nicht selbst?'), findsOneWidget);
    expect(find.textContaining('Ben ist bei 5 Fahrten mitgefahren'), findsOne);

    await tester.tap(find.text('Als Nichtfahrer markieren'));
    await tester.pumpAndSettle();
    expect(find.text('Fährt Ben nicht selbst?'), findsNothing);
    expect(find.text('Ben wird nicht mehr vorgeschlagen'), findsOneWidget);
    expect(
      container
          .read(ridesViewModelProvider(app.group.id).notifier)
          .debugSnapshot()['status'],
      'data',
    );

    // Never again: another ride does not bring the sheet back.
    await tester.runAsync(
      () => container
          .read(ridesViewModelProvider(app.group.id).notifier)
          .logRide(driverId: app.people[0].id, templateId: app.work.id),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('nicht selbst?'), findsNothing);
  });

  testWidgets('dismissing the question keeps the member a driver', (
    tester,
  ) async {
    app.tester = tester;
    await app.seedCommute();
    for (var day = 1; day <= 4; day++) {
      await app.ride(date: '2026-03-0$day', driver: 0, passengers: [1]);
    }
    app.base.clock.value = DateTime.utc(2026, 3, 10, 9);
    final container = await pumpRides(
      tester,
      app,
      location: '/groups/${app.group.id}?tab=rides',
    );
    final vm = container.read(ridesViewModelProvider(app.group.id).notifier);
    await tester.runAsync(
      () => vm.logRide(
        driverId: app.people[0].id,
        templateId: app.work.id,
        passengerIds: {app.people[1].id},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fährt Ben nicht selbst?'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Fährt Ben nicht selbst?'), findsNothing);
    final asked = await tester.runAsync(
      () => app.base.members.askedDriverPrompts(),
    );
    expect(ok(asked!), {app.people[1].id});
    expect(find.textContaining('nicht mehr vorgeschlagen'), findsNothing);
  });
}
