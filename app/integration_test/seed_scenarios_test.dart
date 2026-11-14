import 'dart:convert';
import 'dart:io';

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
import 'package:mitlio/debug/handlers/balances.dart';
import 'package:mitlio/debug/handlers/groups.dart';

/// Seed scenarios (P3-T11) on the Linux desktop device: every scenario loads
/// through `ext.mitlio.seed` (bundled asset, real repositories, in-memory
/// Drift) and its balances equal the values committed in the scenario file.
/// Also measures scrolling the expense list of `large_200_expenses`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
      ...balancesDriveHandlers(container),
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  // `commute_3p` is settled per ride period, which the balances screen does
  // not show; the handler test covers its expected values.
  const withBalances = [
    'trip_4p',
    'household_2p',
    'rounding_edge',
    'large_200_expenses',
  ];

  for (final name in ['empty', ...withBalances, 'commute_3p']) {
    testWidgets('seed $name loads and matches the committed values', (
      tester,
    ) async {
      await start(tester);
      final seeded = await drive['seed']!({'scenario': name});
      expect(seeded['error'], isNull);
      final groupId = seeded['groupId']! as String;
      expect(
        (await drive['groups.list']!({}))['groups'],
        hasLength(1),
      );
      if (!withBalances.contains(name)) return;

      final nameOf = {
        for (final e in (seeded['members']! as Map<String, Object?>).entries)
          e.value! as String: e.key,
      };
      final file = File('../tool/fixtures/scenarios/$name.json');
      final expected =
          (jsonDecode(file.readAsStringSync())
                  as Map<String, dynamic>)['expected']
              as Map<String, dynamic>;
      final got = await drive['balances.get']!({'groupId': groupId});
      expect(
        {
          for (final e in (got['balances']! as Map<String, Object?>).entries)
            nameOf[e.key]!: e.value,
        },
        expected['balances'],
      );
      expect(
        [
          for (final t
              in (got['transfers']! as List<Object?>)
                  .cast<Map<String, Object?>>())
            {
              'from': nameOf[t['from']],
              'to': nameOf[t['to']],
              'amountCents': t['amount'],
            },
        ],
        expected['transfers'],
      );
    });
  }

  testWidgets('scroll the expense list of large_200_expenses (report only)', (
    tester,
  ) async {
    await start(tester);
    final seeded = await drive['seed']!({'scenario': 'large_200_expenses'});
    await drive['navigate']!({'route': '/groups/${seeded['groupId']}'});
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausgaben'));
    await tester.pumpAndSettle();

    final list = find.byType(Scrollable).first;
    Future<void> scroll() async {
      for (var i = 0; i < 12; i++) {
        await tester.fling(list, const Offset(0, -600), 3000);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 12; i++) {
        await tester.fling(list, const Offset(0, 600), 3000);
        await tester.pumpAndSettle();
      }
    }

    await binding.traceAction(
      () => binding.watchPerformance(scroll, reportKey: 'expense_list_scroll'),
      reportKey: 'expense_list_scroll_timeline',
    );
    final summary =
        binding.reportData!['expense_list_scroll']! as Map<String, dynamic>;
    // No hard gate yet (plan §2.6); the numbers go into the PR.
    // ignore: avoid_print, perf figures for the PR description
    print(
      'perf: expense list scroll build p90 = '
      '${summary['90th_percentile_frame_build_time_millis']} ms, '
      'raster p90 = '
      '${summary['90th_percentile_frame_rasterizer_time_millis']} ms, '
      'worst build = ${summary['worst_frame_build_time_millis']} ms',
    );
    expect(summary, isNotEmpty);
  });
}
