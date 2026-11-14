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
import 'package:mitlio/debug/handlers/statistics.dart';
import 'package:mitlio/features/statistics/ui/statistics_view.dart';

/// Statistics slice (P7-T05) on the Linux desktop device with an in-memory
/// Drift database: the `household_2p` seed is read through DebugDrive and
/// asserted in the UI. The period "all" keeps the numbers independent of
/// today's date.
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
      ...statisticsDriveHandlers(container),
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('household_2p: DebugDrive numbers match the screen', (
    tester,
  ) async {
    await start(tester);
    final seeded = await drive['seed']!({'scenario': 'household_2p'});
    expect(seeded['error'], isNull);
    final groupId = seeded['groupId']! as String;

    final got = await drive['statistics.get']!({
      'groupId': groupId,
      'period': 'all',
    });
    expect(got['error'], isNull);
    final total = got['totalCents']! as int;
    expect(total, greaterThan(0));
    final members = (got['members']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(members.map((m) => m['name']), ['Mia', 'Noah']);
    // Every cent is paid by someone and consumed by someone.
    expect(members.fold<int>(0, (a, m) => a + (m['paidCents']! as int)), total);
    expect(
      members.fold<int>(0, (a, m) => a + (m['shareCents']! as int)),
      total,
    );
    expect(got['months'], hasLength(6));

    // The same command as the chip: the screen follows the handler.
    await drive['navigate']!({'route': '/groups/$groupId/statistics'});
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsView), findsOneWidget);
    await drive['statistics.period']!({'groupId': groupId, 'period': 'all'});
    await tester.pumpAndSettle();
    expect(find.text('Insgesamt'), findsOneWidget);
    expect(find.text('Nach Kategorie'), findsOneWidget);
    expect(find.text('Ohne Kategorie'), findsOneWidget);
    expect(find.text('Pro Person'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Noah'), findsOneWidget);

    final state = await drive['state']!({'screen': 'statistics'});
    final snap = state['state']! as Map<String, Object?>;
    expect(snap['status'], 'data');
    expect(snap['period'], 'all');
    expect(snap['totalCents'], total);

    // And through the UI: the picker.
    await tester.tap(find.text('Monat'));
    await tester.pumpAndSettle();
    expect(
      ((await drive['state']!({'screen': 'statistics'}))['state']!
          as Map<String, Object?>)['period'],
      'month',
    );
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });
}
