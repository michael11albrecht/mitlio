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

import '../test/support/tap_counter.dart';

/// Groups slice (P3-T06) on the Linux desktop device with an in-memory Drift
/// database: once driven through the UI and asserted through DebugDrive, once
/// driven through DebugDrive and asserted in the UI. The handlers are called
/// directly, exactly as the VM service extensions call them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late Map<String, DriveHandler> drive;

  Future<void> start(WidgetTester tester) async {
    // German strings: the CI device language is not guaranteed.
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
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
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addMember(WidgetTester tester, String name) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Name hinzufügen'),
      name,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('create a group with 4 members in the UI, assert via state', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Noch keine Gruppe'), findsOneWidget);

    final taps = TapCounter(tester);
    await taps.tap(find.text('Gruppe anlegen'));
    await tester.pumpAndSettle();
    await taps.enterText(find.byType(TextField), 'Skiwochenende');
    await taps.tap(find.text('Gruppe anlegen'));
    await tester.pumpAndSettle();
    for (final name in ['Anna', 'Ben', 'Chiara', 'Dino']) {
      await addMember(tester, name);
    }
    taps.expectWithinBudget('create_group_with_members');

    final state = await drive['state']!({'screen': 'group'});
    final group = state['state']! as Map<String, Object?>;
    expect(group['name'], 'Skiwochenende');
    expect(group['currency'], 'EUR');
    final members = group['members']! as List<Object?>;
    expect(
      [for (final m in members) (m! as Map)['name']],
      [
        'Anna',
        'Ben',
        'Chiara',
        'Dino',
      ],
    );
    expect([for (final m in members) (m! as Map)['position']], [0, 1, 2, 3]);

    final list = await drive['groups.list']!({});
    expect(list['groups']! as List<Object?>, hasLength(1));
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });

  testWidgets('create a group via DebugDrive, assert in the UI', (
    tester,
  ) async {
    await start(tester);
    final created = await drive['groups.create']!({
      'name': 'WG',
      'currency': 'CHF',
      'members': '["Eva","Felix"]',
    });
    final id = created['id']! as String;
    await tester.pumpAndSettle();
    expect(find.text('WG'), findsOneWidget);
    expect(find.text('Franken'), findsOneWidget);

    await drive['navigate']!({'route': '/groups/$id'});
    await tester.pumpAndSettle();
    expect(find.text('Eva'), findsOneWidget);
    expect(find.text('Felix'), findsOneWidget);

    await drive['members.add']!({'groupId': id, 'name': 'Greta'});
    await tester.pumpAndSettle();
    expect(find.text('Greta'), findsOneWidget);

    await drive['reset']!({});
    await drive['navigate']!({'route': '/'});
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Gruppe'), findsOneWidget);
  });

  testWidgets('seed groups fills the list', (tester) async {
    await start(tester);
    final seeded = await drive['seed']!({'scenario': 'groups'});
    expect(seeded['ids'], hasLength(5));
    await tester.pumpAndSettle();
    expect(find.text('Wochenende'), findsOneWidget);
  });
}
