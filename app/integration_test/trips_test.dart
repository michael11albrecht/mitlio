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
import 'package:mitlio/debug/handlers/trips.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';

import '../test/support/tap_counter.dart';
import '../test/support/trip_examples.dart';

/// Trip slice (P3-T09) on the Linux desktop device with an in-memory Drift
/// database: once driven through the UI, once through DebugDrive. Both are
/// checked against the `examples:trip` rows of docs/domain-rules.md.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late Map<String, DriveHandler> drive;
  late String groupId;
  late List<String> memberIds;

  Future<void> start(WidgetTester tester) async {
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
      ...tripsDriveHandlers(container),
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();

    final created = await drive['groups.create']!({
      'name': 'Pendeln',
      'members': '["Anna","Ben","Chiara"]',
    });
    groupId = created['id']! as String;
    await drive['navigate']!({'route': '/groups/$groupId'});
    await tester.pumpAndSettle();
    final snap = await drive['state']!({'screen': 'group'});
    memberIds = [
      for (final m in (snap['state']! as Map)['members']! as List<Object?>)
        (m! as Map)['id']! as String,
    ];
  }

  Map<String, int> sharesOf(Object? raw) => {
    for (final e in (raw! as Map).entries) e.key as String: e.value as int,
  };

  testWidgets('the documented example, entered in the UI', (tester) async {
    await start(tester);
    final ex = tripExamples().first;

    final taps = TapCounter(tester);
    await taps.tap(find.byTooltip('Fahrt hinzufügen'));
    await tester.pumpAndSettle();
    for (final (label, text) in [
      ('Strecke (einfach)', '250'),
      ('Verbrauch', '6,5'),
      ('Preis pro Liter', '1,799'),
    ]) {
      final field = find.widgetWithText(TextField, label);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await taps.enterText(field, text);
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('Jede Person zahlt'), findsOneWidget);

    final live = await drive['state']!({'screen': 'trip'});
    final result = (live['state']! as Map)['result']! as Map;
    expect(result['totalCents'], ex.total);

    await taps.tap(find.text('Fahrt speichern'));
    await tester.pumpAndSettle();
    taps.expectWithinBudget('log_commute_ride');

    // The expense the UI saved has the documented shares.
    final saved = await container
        .read(expensesRepositoryProvider)
        .watchExpenses(groupId)
        .first;
    expect(saved.single.expense.amountCents, ex.total);
    expect(saved.single.expense.shares, {
      memberIds[0]: ex.shares['A'],
      memberIds[1]: ex.shares['B'],
      memberIds[2]: ex.shares['C'],
    });
    expect(saved.single.tripMeta, isNotNull);
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });

  testWidgets('every documented example via DebugDrive, then in the UI', (
    tester,
  ) async {
    await start(tester);
    final letters = {'A': memberIds[0], 'B': memberIds[1], 'C': memberIds[2]};
    for (final ex in tripExamples()) {
      final i = ex.inputs(letters).toJson();
      final r = await drive['trips.add']!({
        'groupId': groupId,
        'driverId': i['driverId']! as String,
        'passengerIds': jsonEncode(i['passengerIds']),
        'distance': i['distance']! as String,
        'roundTrip': '${i['roundTrip']}',
        'driverCounts': '${i['driverCounts']}',
        if (i['useKmRate']! as bool)
          'kmRate': i['kmRate']! as String
        else ...{
          'consumption': i['consumption']! as String,
          'price': i['price']! as String,
          if ((i['wear']! as String).isNotEmpty) 'wear': i['wear']! as String,
        },
        'tolls': i['tolls']! as String,
        'title': ex.name,
      });
      expect(r['totalCents'], ex.total, reason: ex.name);
      expect(sharesOf(r['shares']), {
        for (final e in letters.entries) e.value: ex.shares[e.key] ?? 0,
      }, reason: ex.name);
    }

    // The next trip form starts from the last example (km rate, driver free).
    await drive['navigate']!({'route': '/groups/$groupId/trip'});
    await tester.pumpAndSettle();
    final snap = await drive['state']!({'screen': 'trip'});
    final inputs = (snap['state']! as Map)['inputs']! as Map;
    expect(inputs['driverId'], memberIds[0]);
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });
}
