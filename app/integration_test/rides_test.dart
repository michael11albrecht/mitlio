import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/groups.dart';
import 'package:mitlio/debug/handlers/rides.dart';
import 'package:mitlio/features/rides/ui/ride_calendar.dart';

import '../test/support/tap_counter.dart';

/// Rides slice (P3r-T04, P3r-T05) on the Linux desktop device with an
/// in-memory Drift database: ten commute days logged through the UI and
/// asserted through DebugDrive, then ten logged through DebugDrive and
/// asserted in the UI (calendar and list). The handlers are called directly,
/// exactly as the VM service extensions call them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late Map<String, DriveHandler> drive;

  Future<void> start(WidgetTester tester) async {
    // German strings: the CI device language is not guaranteed.
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    drive = {
      ...buildDriveHandlers(
        errors: container.read(errorSinkProvider),
        router: container.read(routerProvider),
        data: container.read(debugDataControlProvider),
        snapshots: buildSnapshotRegistry(container),
      ),
      ...groupsDriveHandlers(container),
      ...ridesDriveHandlers(container),
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A commute group "Pendler" with Anna and Ben, the car and the route
  /// "Arbeit" (2 x 20 km, Anna drives, Ben rides along).
  Future<({String groupId, String templateId, List<String> people})>
  commuteGroup(WidgetTester tester) async {
    final created = await drive['groups.create']!({
      'name': 'Pendler',
      'members': '["Anna","Ben"]',
    });
    final groupId = created['id']! as String;
    // The group screen knows the member ids.
    await drive['navigate']!({'route': '/groups/$groupId'});
    await tester.pumpAndSettle();
    final detail = await drive['state']!({'screen': 'group'});
    final members = [
      for (final m in (detail['state']! as Map)['members']! as List<Object?>)
        (m! as Map)['id']! as String,
    ];
    final golf = await drive['vehicles.create']!({
      'groupId': groupId,
      'name': 'Golf',
      'consumptionMilliPer100km': '6500',
    });
    final work = await drive['templates.create']!({
      'groupId': groupId,
      'name': 'Arbeit',
      'distanceMeters': '20000',
      'roundTrip': 'true',
      'vehicleId': golf['id']! as String,
      'defaultDriverId': members[0],
      'defaultPassengerIds': jsonEncode([members[1]]),
    });
    return (
      groupId: groupId,
      templateId: work['id']! as String,
      people: members,
    );
  }

  Future<List<Map<String, Object?>>> rides(String groupId, String month) async {
    final r = await drive['rides.list']!({'groupId': groupId, 'month': month});
    return [
      for (final e in r['rides']! as List<Object?>) e! as Map<String, Object?>,
    ];
  }

  String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  Finder calendarDay(int day) => find.descendant(
    of: find.byType(RideCalendar),
    matching: find.text('$day'),
  );

  testWidgets('log ten commute days in the UI, assert via DebugDrive', (
    tester,
  ) async {
    await start(tester);
    final group = await commuteGroup(tester);
    final now = container.read(clockProvider).now();
    final previous = DateTime(now.year, now.month - 1);

    await tester.tap(find.text('Fahrten'));
    await tester.pumpAndSettle();
    expect(find.text('Heute gefahren'), findsWidgets);

    // Today's ride: everything is pre-set, one tap saves it.
    final taps = TapCounter(tester);
    await taps.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();
    taps.expectWithinBudget('log_commute_ride');
    expect(find.text('Anna ist gefahren'), findsOneWidget);
    final today = await rides(group.groupId, monthKey(now));
    expect(today.where((r) => r['driverId'] == group.people[0]), hasLength(1));

    // Ten days of last month, through the calendar.
    await tester.tap(find.byTooltip('Vorheriger Monat'));
    await tester.pumpAndSettle();
    for (var day = 1; day <= 10; day++) {
      await tester.tap(calendarDay(day));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fahrt für diesen Tag erfassen'));
      await tester.pumpAndSettle();
      if (day == 1) {
        // Ben takes over once; from then on the fair-driver suggestion
        // alternates by itself.
        await tester.tap(find.widgetWithText(ChoiceChip, 'Ben'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
    }

    final stored = await rides(group.groupId, monthKey(previous));
    expect(stored, hasLength(10));
    expect(
      {for (final r in stored) r['date']},
      {
        for (var d = 1; d <= 10; d++)
          '${monthKey(previous)}-${d.toString().padLeft(2, '0')}',
      },
    );
    // Both of them drove, and the carpool followed each driver.
    final drivers = {for (final r in stored) r['driverId']! as String};
    expect(drivers, group.people.toSet());
    for (final r in stored) {
      expect(r['passengerIds'], [
        group.people.firstWhere((p) => p != r['driverId']),
      ]);
    }

    // The screen shows what is stored.
    expect(find.textContaining(' fuhr · 2 × 20 km'), findsNWidgets(10));
    expect(
      find.descendant(
        of: find.byType(RideCalendar),
        matching: find.byType(MemberAvatar),
      ),
      findsNWidgets(10),
    );
    final snapshot = await drive['state']!({'screen': 'rides'});
    final screen = snapshot['state']! as Map<String, Object?>;
    expect(screen['status'], 'data');
    expect(screen['rides'], hasLength(10));

    // Swipe one away, undo it.
    final before = await rides(group.groupId, monthKey(previous));
    await tester.drag(
      find.textContaining(' fuhr · 2 × 20 km').first,
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(await rides(group.groupId, monthKey(previous)), hasLength(9));
    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(await rides(group.groupId, monthKey(previous)), hasLength(10));
    expect(before, hasLength(10));
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });

  testWidgets('log ten commute days via DebugDrive, assert in the UI', (
    tester,
  ) async {
    await start(tester);
    final group = await commuteGroup(tester);
    expect(
      (await drive['state']!({}))['screens'],
      containsAll(['rides', 'rides_setup', 'vehicle_form', 'template_form']),
    );
    final now = container.read(clockProvider).now();
    final previous = DateTime(now.year, now.month - 1);
    final month = monthKey(previous);

    final alternate = [group.people[0], group.people[1]];
    for (var day = 1; day <= 10; day++) {
      final driver = alternate[(day - 1) % 2];
      final logged = await drive['rides.log']!({
        'groupId': group.groupId,
        'templateId': group.templateId,
        'driverId': driver,
        'date': '$month-${day.toString().padLeft(2, '0')}',
      });
      expect(logged['error'], isNull, reason: '$logged');
      expect(logged['driverId'], driver);
    }
    final stored = await rides(group.groupId, month);
    expect(stored, hasLength(10));

    await tester.tap(find.text('Fahrten'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Vorheriger Monat'));
    await tester.pumpAndSettle();
    expect(find.textContaining(' fuhr · 2 × 20 km'), findsNWidgets(10));
    expect(
      find.descendant(
        of: find.byType(RideCalendar),
        matching: find.byType(MemberAvatar),
      ),
      findsNWidgets(10),
    );
    expect(find.textContaining('Anna fuhr'), findsNWidgets(5));
    expect(find.textContaining('Ben fuhr'), findsNWidgets(5));

    // Deleting through the handler shows in the UI.
    await drive['rides.delete']!({'id': stored.first['id']! as String});
    await tester.pumpAndSettle();
    expect(find.textContaining(' fuhr · 2 × 20 km'), findsNWidgets(9));
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });
}
