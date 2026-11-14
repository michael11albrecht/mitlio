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
import 'package:mitlio/debug/handlers/settle.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';

/// Settle slice (P4-T03..T05) on the Linux desktop device with an in-memory
/// Drift database and the seeded `trip_4p` scenario: every open transfer is
/// marked as paid once through the UI and once through DebugDrive, and all
/// balances end at zero.
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
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // The CI desktop has no keyring: the key store is covered by unit
        // tests.
        ibanCipherProvider.overrideWithValue(const PlaintextIbanCipher()),
      ],
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
      ...settleDriveHandlers(container),
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Seeds `trip_4p`; returns the group id and member id to name.
  Future<(String, Map<String, String>)> seed() async {
    final seeded = await drive['seed']!({'scenario': 'trip_4p'});
    expect(seeded['error'], isNull);
    return (
      seeded['groupId']! as String,
      {
        for (final e in (seeded['members']! as Map<String, Object?>).entries)
          e.value! as String: e.key,
      },
    );
  }

  List<Map<String, Object?>> transfersOf(Map<String, Object?> r) =>
      (r['transfers']! as List<Object?>).cast<Map<String, Object?>>();

  Future<void> expectAllSquare(String groupId) async {
    final got = await drive['balances.get']!({'groupId': groupId});
    expect(
      (got['balances']! as Map<String, Object?>).values,
      everyElement(0),
    );
    expect(transfersOf(got), isEmpty);
  }

  testWidgets('mark every transfer paid in the UI: all balances are zero', (
    tester,
  ) async {
    await start(tester);
    final (groupId, nameOf) = await seed();
    final open = transfersOf(
      await drive['settle.list']!({'groupId': groupId}),
    );
    expect(open, isNotEmpty);

    await drive['navigate']!({'route': '/groups/$groupId/settle'});
    await tester.pumpAndSettle();
    for (final t in open) {
      final label = '${nameOf[t['from']]} → ${nameOf[t['to']]}';
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.text('Als bezahlt markieren'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    }
    expect(find.text('Alles ausgeglichen'), findsOneWidget);

    final state = await drive['state']!({'screen': 'settle'});
    final snap = state['state']! as Map<String, Object?>;
    expect(snap['status'], 'settled');
    expect(snap['history'], hasLength(open.length));
    await expectAllSquare(groupId);
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });

  testWidgets('mark paid via DebugDrive, the open screen follows', (
    tester,
  ) async {
    await start(tester);
    final (groupId, nameOf) = await seed();
    await drive['navigate']!({'route': '/groups/$groupId/settle'});
    await tester.pumpAndSettle();
    final open = transfersOf(
      await drive['settle.list']!({'groupId': groupId}),
    );
    final first = open.first;
    final label = '${nameOf[first['from']]} → ${nameOf[first['to']]}';
    expect(find.text(label), findsOneWidget);

    final paid = await drive['settle.markPaid']!({
      'fromId': '${first['from']}',
      'toId': '${first['to']}',
      'amountCents': '${first['amount']}',
    });
    expect(paid['error'], isNull);
    await tester.pumpAndSettle();
    // The transfer left the open list and sits in the history.
    expect(find.text(label), findsOneWidget);
    expect(find.text('Noch nichts bezahlt.'), findsNothing);

    for (final t in open.skip(1)) {
      await drive['settle.markPaid']!({
        'fromId': '${t['from']}',
        'toId': '${t['to']}',
        'amountCents': '${t['amount']}',
      });
    }
    await tester.pumpAndSettle();
    expect(find.text('Alles ausgeglichen'), findsOneWidget);
    await expectAllSquare(groupId);

    final list = await drive['settle.list']!({'groupId': groupId});
    expect(list['history'], hasLength(open.length));
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });
}
