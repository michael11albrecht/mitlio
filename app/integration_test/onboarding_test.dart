import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/groups.dart';
import 'package:mitlio/debug/handlers/rides.dart';

/// First run (P7-T06) on the Linux desktop device with an in-memory Drift
/// database: the onboarding screen shows while no group exists, the commute
/// path creates the group in one tap, and once car and route exist (set up
/// through DebugDrive, the vehicle and route forms have their own test) the
/// quick log is on the rides tab.
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

  testWidgets('first run: commute path to the quick log', (tester) async {
    await start(tester);
    expect(find.text('Willkommen bei mitlio'), findsOneWidget);
    expect(find.text('Nur eine Fahrt berechnen'), findsOneWidget);

    await tester.tap(find.text('Fahrgemeinschaft starten'));
    await tester.pumpAndSettle();

    // One tap made the group; the rides tab asks for the people first.
    final listed = await drive['groups.list']!({});
    final groups = listed['groups']! as List<Object?>;
    expect(groups, hasLength(1));
    final group = groups.single! as Map<String, Object?>;
    final groupId = group['id']! as String;
    expect(group['name'], 'Fahrgemeinschaft');
    expect(find.text('Noch niemand dabei'), findsOneWidget);

    final people = <String>[];
    for (final name in ['Anna', 'Ben']) {
      final added = await drive['members.add']!({
        'groupId': groupId,
        'name': name,
      });
      people.add(added['id']! as String);
    }
    await tester.pumpAndSettle();
    expect(find.text('Auto und Strecke anlegen'), findsOneWidget);

    final golf = await drive['vehicles.create']!({
      'groupId': groupId,
      'name': 'Golf',
      'consumptionMilliPer100km': '6500',
    });
    await drive['templates.create']!({
      'groupId': groupId,
      'name': 'Arbeit',
      'distanceMeters': '20000',
      'roundTrip': 'true',
      'vehicleId': golf['id']! as String,
      'defaultDriverId': people[0],
      'defaultPassengerIds': jsonEncode([people[1]]),
    });
    await tester.pumpAndSettle();

    // The quick log is there: everything pre-set, one tap saves.
    expect(find.text('Heute gefahren'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Speichern'), findsOneWidget);

    // Back home the screen is a list now, not the first run.
    await drive['navigate']!({'route': '/'});
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei mitlio'), findsNothing);
    expect(find.text('Fahrgemeinschaft'), findsOneWidget);
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });

  testWidgets('first run: the welcome route is reachable via DebugDrive', (
    tester,
  ) async {
    await start(tester);
    await drive['navigate']!({'route': '/welcome'});
    await tester.pumpAndSettle();
    expect(find.text('Willkommen bei mitlio'), findsOneWidget);
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });
}
