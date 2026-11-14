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
import 'package:mitlio/debug/handlers/payment.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';

const _iban = 'DE89370400440532013000';

/// Payment details (P4-T01, P4-T02) on the Linux desktop device with an
/// in-memory Drift database: once entered in the UI and asserted through
/// DebugDrive, once set through DebugDrive and asserted in the UI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late AppDatabase db;
  late Map<String, DriveHandler> drive;

  Future<void> start(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // The CI desktop has no keyring: skip the key store here, it is
        // covered by unit tests (fallback to plaintext, logged once).
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
      ...paymentDriveHandlers(container),
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MitlioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<({String groupId, String annId, String benId})> seed(
    WidgetTester tester,
  ) async {
    final g = await drive['groups.create']!({
      'name': 'WG',
      'members': '["Anna","Ben"]',
    });
    final groupId = g['id']! as String;
    await drive['navigate']!({'route': '/groups/$groupId'});
    await tester.pumpAndSettle();
    final members = await db.membersDao.listByGroup(groupId);
    return (groupId: groupId, annId: members[0].id, benId: members[1].id);
  }

  testWidgets('enter payment details in the UI, assert via DebugDrive', (
    tester,
  ) async {
    await start(tester);
    final ids = await seed(tester);

    await tester.tap(find.byTooltip('Zahlungsdaten von Anna'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'PayPal.Me-Name'),
      '@anna',
    );
    await tester.enterText(find.widgetWithText(TextField, 'IBAN'), _iban);
    await tester.enterText(
      find.widgetWithText(TextField, 'Kontoinhaber'),
      'Anna Muster',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);

    // The synced member holds the handle and a masked hint only.
    final member = (await db.membersDao.findById(ids.annId))!;
    expect(member.paypalMe, 'anna');
    expect(member.ibanHint, 'DE89 •••• 3000');
    expect((await db.localMemberBankDao.findByMember(ids.annId))!.iban, _iban);

    final links = await drive['payment.links']!({
      'fromId': ids.benId,
      'toId': ids.annId,
      'amountCents': '1234',
    });
    expect(links['paypalUrl'], 'https://paypal.me/anna/12.34EUR');
    expect(
      links['epcPayload'],
      'BCD\n002\n1\nSCT\n\nAnna Muster\n$_iban\nEUR12.34\n\n\nmitlio: WG',
    );

    // No state snapshot ever contains the IBAN.
    for (final screen in ['groups', 'group']) {
      final state = await drive['state']!({'screen': screen});
      expect(jsonEncode(state), isNot(contains('0532')));
    }
    expect(await drive['errors']!({}), {'errors': <Object?>[]});
  });

  testWidgets('set payment details via DebugDrive, assert in the UI', (
    tester,
  ) async {
    await start(tester);
    final ids = await seed(tester);

    final set = await drive['members.setPayment']!({
      'memberId': ids.benId,
      'paypalMe': 'ben',
      'iban': 'de89 3704 0044 0532 0130 00',
      'bic': 'cobadeffxxx',
    });
    expect(set, {
      'memberId': ids.benId,
      'paypalMe': 'ben',
      'ibanHint': 'DE89 •••• 3000',
      'hasIban': true,
    });
    expect(jsonEncode(set), isNot(contains('0532')));

    await tester.tap(find.byTooltip('Zahlungsdaten von Ben'));
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextField>(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          ),
        )
        .map((f) => f.controller!.text)
        .toList();
    expect(fields, ['ben', _iban, 'COBADEFFXXX', '']);

    final bad = await drive['members.setPayment']!({
      'memberId': ids.benId,
      'iban': 'DE89370400440532013001',
    });
    expect(bad['error'], 'invalid_params');
  });
}
