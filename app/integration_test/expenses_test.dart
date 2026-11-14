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
import 'package:mitlio/debug/handlers/expenses.dart';
import 'package:mitlio/debug/handlers/groups.dart';

import '../test/support/tap_counter.dart';

/// Expenses slice (P3-T07, P3-T08) on the Linux desktop device with an
/// in-memory Drift database: one expense per split mode entered in the UI
/// and asserted through DebugDrive, then one entered through DebugDrive and
/// asserted in the UI. The handlers are called directly, exactly as the VM
/// service extensions call them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late Map<String, DriveHandler> drive;

  Future<void> start(WidgetTester tester) async {
    // German strings: the CI device language is not guaranteed.
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // Tall enough that the whole form is built (lists build lazily).
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
      ...expensesDriveHandlers(container),
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<String> newGroup() async {
    final created = await drive['groups.create']!({
      'name': 'Berge',
      'members': '["Anna","Ben","Chiara"]',
    });
    return created['id']! as String;
  }

  Future<List<Map<String, Object?>>> expenses(String groupId) async {
    final r = await drive['expenses.list']!({'groupId': groupId});
    return [
      for (final e in r['expenses']! as List<Object?>)
        e! as Map<String, Object?>,
    ];
  }

  Future<void> addInUi(
    WidgetTester tester, {
    required String title,
    required String amount,
    String? mode,
    TapCounter? taps,
  }) async {
    await (taps?.tap ?? tester.tap)(find.text('Ausgabe hinzufügen'));
    await tester.pumpAndSettle();
    await (taps?.enterText ?? tester.enterText)(
      find.widgetWithText(TextField, 'Betrag'),
      amount,
    );
    await (taps?.enterText ?? tester.enterText)(
      find.widgetWithText(TextField, 'Wofür?'),
      title,
    );
    await tester.pump();
    if (mode != null) {
      await tester.tap(find.widgetWithText(ChoiceChip, mode));
      await tester.pump();
    }
    if (mode == 'Anteile') {
      await tester.tap(find.byTooltip('Mehr Anteile für Anna'));
      await tester.pump();
    }
    await (taps?.tap ?? tester.tap)(find.text('Speichern'));
    await tester.pumpAndSettle();
  }

  testWidgets('add one expense per split mode in the UI, delete one, assert '
      'via DebugDrive', (tester) async {
    await start(tester);
    final groupId = await newGroup();
    await drive['navigate']!({'route': '/groups/$groupId'});
    await tester.pumpAndSettle();

    final taps = TapCounter(tester);
    await taps.tap(find.text('Ausgaben'));
    await tester.pumpAndSettle();
    await addInUi(tester, title: 'Pizza', amount: '12,40', taps: taps);
    taps.expectWithinBudget('add_equal_split_expense');

    await addInUi(tester, title: 'Hütte', amount: '30', mode: 'Anteile');
    await addInUi(tester, title: 'Taxi', amount: '10', mode: 'Prozent');
    await addInUi(tester, title: 'Eis', amount: '9', mode: 'Genau');

    final stored = await expenses(groupId);
    expect(
      {for (final e in stored) e['title']: e['splitMode']},
      {
        'Pizza': 'equal',
        'Hütte': 'shares',
        'Taxi': 'percent',
        'Eis': 'exact',
      },
    );
    final pizza = stored.firstWhere((e) => e['title'] == 'Pizza');
    expect(pizza['amountCents'], 1240);
    expect((pizza['shares']! as Map).values, [414, 413, 413]);
    final hut = stored.firstWhere((e) => e['title'] == 'Hütte');
    expect((hut['shares']! as Map).values, [1500, 750, 750]);
    for (final title in ['Pizza', 'Hütte', 'Taxi', 'Eis']) {
      expect(find.text(title), findsOneWidget);
    }

    // The screen state matches the list.
    final state = await drive['state']!({'screen': 'expenses'});
    final screen = state['state']! as Map<String, Object?>;
    expect(screen['status'], 'data');
    expect(screen['visible'], 4);

    await tester.drag(find.text('Eis'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Eis'), findsNothing);
    expect(find.text('„Eis“ gelöscht'), findsOneWidget);
    expect(
      [for (final e in await expenses(groupId)) e['title']],
      isNot(contains('Eis')),
    );
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });

  testWidgets('add and delete via DebugDrive, assert in the UI', (
    tester,
  ) async {
    await start(tester);
    final groupId = await newGroup();
    expect(
      (await drive['state']!({}))['screens'],
      containsAll(['expenses', 'expense_form']),
    );
    await drive['navigate']!({'route': '/groups/$groupId'});
    await tester.pumpAndSettle();
    final group =
        (await drive['state']!({'screen': 'group'}))['state']!
            as Map<String, Object?>;
    final ids = [
      for (final m in group['members']! as List<Object?>)
        (m! as Map)['id']! as String,
    ];

    final added = await drive['expenses.add']!({
      'groupId': groupId,
      'title': 'Fondue',
      'amountCents': '4500',
      'payers': jsonEncode({ids[1]: 4500}),
      'category': 'food',
    });
    expect(added['error'], isNull);

    await tester.tap(find.text('Ausgaben'));
    await tester.pumpAndSettle();
    expect(find.text('Fondue'), findsOneWidget);
    expect(find.text('45,00\u00a0€'), findsOneWidget);
    expect(find.text('Ben hat bezahlt · Essen & Trinken'), findsOneWidget);

    final bad = await drive['expenses.add']!({
      'groupId': groupId,
      'title': 'Falsch',
      'amountCents': '4500',
      'payers': jsonEncode({ids[1]: 100}),
    });
    expect(bad['error'], 'invalid_params');

    // The open form is reachable through DebugDrive state.
    await tester.tap(find.text('Fondue'));
    await tester.pumpAndSettle();
    final form = await drive['state']!({'screen': 'expense_form'});
    expect((form['state']! as Map)['title'], 'Fondue');

    await drive['navigate']!({'route': '/groups/$groupId'});
    await tester.pumpAndSettle();
    await drive['expenses.delete']!({'id': added['id']! as String});
    await tester.pumpAndSettle();
    expect(find.text('Fondue'), findsNothing);
    expect(find.text('Noch keine Ausgabe'), findsOneWidget);
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });
}
