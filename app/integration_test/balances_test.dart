import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/balances.dart';
import 'package:mitlio/debug/handlers/groups.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Balances slice (P3-T10) on the Linux desktop device with an in-memory
/// Drift database. The scenario is seeded through the repositories (the
/// expense UI belongs to another slice), then read through DebugDrive and
/// asserted in the UI: both show the transfers of `examples:simplify`.
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

  /// `examples:simplify` row 2: A +500, B +500, C -600, D -400.
  Future<(String, Map<String, String>)> seedScenario() async {
    final created = await drive['groups.create']!({
      'name': 'Ski',
      'members': '["Anna","Ben","Chiara","Dino"]',
    });
    final groupId = created['id']! as String;
    final members = switch (await container
        .read(membersRepositoryProvider)
        .list(groupId)) {
      Ok(:final value) => value,
      Err(:final error) => fail('$error'),
    };
    final id = {for (final m in members) m.name: m.id};
    final result = await container
        .read(expensesRepositoryProvider)
        .create(
          groupId,
          ExpenseDraft(
            title: 'Hütte',
            amountCents: 1000,
            currency: Currency.eur,
            date: DateTime.utc(2026, 2),
            payers: {id['Anna']!: 500, id['Ben']!: 500},
            split: ExactSplit({id['Chiara']!: 600, id['Dino']!: 400}),
          ),
        );
    expect(result, isA<Ok<ExpenseEntry, RepositoryError>>());
    return (groupId, id);
  }

  testWidgets('seeded scenario: DebugDrive and UI show the fixture transfers', (
    tester,
  ) async {
    await start(tester);
    final (groupId, _) = await seedScenario();

    final got = await drive['balances.get']!({'groupId': groupId});
    final transfers = (got['transfers']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final members = await drive['groups.list']!({});
    expect(members['groups'], hasLength(1));
    // Fixture: C->A 500, D->B 400, C->B 100 (names map to ids in order).
    expect(
      [for (final t in transfers) t['amount']],
      [500, 400, 100],
    );
    final balances = (got['balances']! as Map<String, Object?>).values;
    expect(balances.toList(), [500, 500, -600, -400]);

    await drive['navigate']!({'route': '/groups/$groupId/balances'});
    await tester.pumpAndSettle();
    expect(find.text('Anna bekommt'), findsOneWidget);
    expect(find.text('Chiara schuldet'), findsOneWidget);
    expect(find.text('Chiara zahlt Anna'), findsOneWidget);
    expect(find.text('Dino zahlt Ben'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Chiara zahlt Ben'), 100);
    expect(find.text('Chiara zahlt Ben'), findsOneWidget);

    final state = await drive['state']!({'screen': 'balances'});
    final snap = state['state']! as Map<String, Object?>;
    expect(snap['status'], 'data');
    expect(snap['transfers'], hasLength(3));

    await tester.tap(find.text('Direkt'));
    await tester.pumpAndSettle();
    expect(find.text('Wer zahlt wem'), findsOneWidget);
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });

  testWidgets('a new expense updates the open screen live', (tester) async {
    await start(tester);
    final (groupId, id) = await seedScenario();
    await drive['navigate']!({'route': '/groups/$groupId/balances'});
    await tester.pumpAndSettle();
    expect(find.text('Chiara schuldet'), findsOneWidget);

    // Chiara pays 600 for Anna and Ben: she is square afterwards.
    await container
        .read(expensesRepositoryProvider)
        .create(
          groupId,
          ExpenseDraft(
            title: 'Pizza',
            amountCents: 600,
            currency: Currency.eur,
            date: DateTime.utc(2026, 2, 2),
            payers: {id['Chiara']!: 600},
            split: ExactSplit({id['Anna']!: 300, id['Ben']!: 300}),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Chiara ist ausgeglichen'), findsOneWidget);
    expect(find.text('Dino schuldet'), findsOneWidget);
  });
}
