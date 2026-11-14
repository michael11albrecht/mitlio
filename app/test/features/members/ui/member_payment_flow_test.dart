import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../repo_test_support.dart';

/// The payment details sheet on the real app and in-memory repositories
/// (German, the default locale).
void main() {
  late FakeApp app;
  late String groupId;
  late GroupMember anna;

  setUp(() async {
    app = FakeApp();
    groupId = ok(
      await app.groups.create(
        name: 'Trip',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    ).id;
    anna = ok(await app.members.add(groupId, name: 'Anna'));
  });

  Future<void> openSheet(WidgetTester tester) async {
    await pumpMitlio(tester, app, location: '/groups/$groupId');
    await tester.tap(find.byTooltip('Zahlungsdaten von Anna'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  testWidgets('opens as a sheet, not a dialog, with all four fields', (
    tester,
  ) async {
    await openSheet(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Zahlungsdaten'), findsOneWidget);
    expect(find.text('Anna'), findsWidgets);
    for (final label in [
      'PayPal.Me-Name',
      'IBAN',
      'BIC (optional)',
      'Kontoinhaber',
    ]) {
      expect(field(label), findsOneWidget);
    }
    expect(
      find.text('IBAN, BIC und Kontoinhaber bleiben nur auf diesem Gerät.'),
      findsOneWidget,
    );
  });

  testWidgets('saving stores the details and closes the sheet', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(field('PayPal.Me-Name'), '@anna');
    await tester.enterText(field('IBAN'), 'de89 3704 0044 0532 0130 00');
    await tester.enterText(field('Kontoinhaber'), 'Anna Muster');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    final stored = ok(await app.payments.get(anna.id));
    expect(stored.paypalMe, 'anna');
    expect(stored.iban, 'DE89370400440532013000');
    expect(stored.accountName, 'Anna Muster');
    final member = ok(await app.members.list(groupId)).single;
    expect(member.ibanHint, 'DE89 •••• 3000');
  });

  testWidgets('invalid input shows inline errors and keeps the sheet', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(field('PayPal.Me-Name'), 'anna muster');
    await tester.enterText(field('IBAN'), 'DE89370400440532013001');
    await tester.enterText(field('BIC (optional)'), 'x');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Das ist kein gültiger PayPal.Me-Name.'), findsOneWidget);
    expect(
      find.text('Die Prüfziffer der IBAN stimmt nicht. Vertippt?'),
      findsOneWidget,
    );
    expect(find.text('Das ist keine gültige BIC.'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(ok(await app.payments.get(anna.id)).paypalMe, isNull);

    // Fixing the input and saving again works.
    await tester.enterText(field('PayPal.Me-Name'), 'anna');
    await tester.enterText(field('IBAN'), 'DE89370400440532013000');
    await tester.enterText(field('BIC (optional)'), '');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('BIC without an IBAN asks for the IBAN', (tester) async {
    await openSheet(tester);
    await tester.enterText(field('BIC (optional)'), 'COBADEFFXXX');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Dafür brauchen wir zuerst eine IBAN.'), findsOneWidget);
  });

  testWidgets('stored details are prefilled', (tester) async {
    ok(
      await app.payments.save(
        anna.id,
        paypalMe: 'anna',
        iban: 'DE89370400440532013000',
        bic: 'COBADEFFXXX',
        accountName: 'Anna Muster',
      ),
    );
    await openSheet(tester);
    final texts = tester
        .widgetList<TextField>(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          ),
        )
        .map((f) => f.controller!.text)
        .toList();
    expect(texts, [
      'anna',
      'DE89370400440532013000',
      'COBADEFFXXX',
      'Anna Muster',
    ]);
  });

  testWidgets('a refused save is told calmly, the sheet stays', (tester) async {
    await openSheet(tester);
    app.members.failWith = const Storage('down');
    await tester.enterText(field('PayPal.Me-Name'), 'anna');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Versuch es gleich noch einmal.'), findsOneWidget);
    expect(
      find.text('IBAN, BIC und Kontoinhaber bleiben nur auf diesem Gerät.'),
      findsNothing,
    );
  });
}
