import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/balances/ui/balances_view.dart';
import 'package:mitlio/features/settle/ui/settle_view.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import '../../balances/balances_support.dart';
import '../../repo_test_support.dart';

const _iban = 'DE89370400440532013000';

/// A phone-sized screen: the sheet with a QR code is taller than the default
/// 800x600 test surface.
void phoneTest(String name, Future<void> Function(WidgetTester tester) body) =>
    testWidgets(name, (tester) async {
      tester.view
        ..physicalSize = const Size(400, 1000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await body(tester);
    });

/// The settle screen and the transfer sheet on the real app, router and
/// in-memory repositories (German, the default locale).
void main() {
  late FakeApp app;
  late Scenario s;

  String route() => '/groups/${s.group.id}/settle';

  /// Anna paid 30,00 for everyone: Ben and Chiara owe her 10,00 each.
  setUp(() async {
    app = FakeApp();
    s = await Scenario.create(app, ['Anna', 'Ben', 'Chiara']);
    await s.expense(
      {'Anna': 3000},
      {'Anna': 1000, 'Ben': 1000, 'Chiara': 1000},
    );
  });

  Future<void> annaPays({bool paypal = true, bool iban = true}) async {
    ok(
      await app.payments.save(
        s.ids['Anna']!,
        paypalMe: paypal ? 'anna' : null,
        iban: iban ? _iban : null,
        accountName: iban ? 'Anna Muster' : null,
      ),
    );
  }

  Finder amountField() => find.widgetWithText(TextField, 'Betrag');

  phoneTest('balances lead to the settle screen', (tester) async {
    await pumpMitlio(tester, app, location: '/groups/${s.group.id}/balances');
    await tester.tap(find.text('Ausgleichen'));
    await tester.pumpAndSettle();
    expect(find.byType(SettleView), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(BalancesView), findsOneWidget);
  });

  phoneTest('result first: who pays whom, then the history', (tester) async {
    await pumpMitlio(tester, app, location: route());
    expect(find.text('Noch zu zahlen'), findsOneWidget);
    expect(find.text('Ben → Anna'), findsOneWidget);
    expect(find.text('Chiara → Anna'), findsOneWidget);
    expect(find.textContaining('10,00'), findsNWidgets(2));
    expect(find.text('Ausgleiche'), findsOneWidget);
    expect(
      find.text('Noch nichts bezahlt. Sobald jemand zahlt, siehst du es hier.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Zusammenfassung teilen'), findsOneWidget);
  });

  phoneTest('a transfer opens a sheet, never a dialog', (tester) async {
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Als bezahlt markieren'), findsOneWidget);
    expect(amountField(), findsOneWidget);
  });

  phoneTest('mark as paid takes 2 taps and offers undo', (tester) async {
    await pumpMitlio(tester, app, location: route());
    final taps = TapCounter(tester);
    await taps.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    await taps.tap(find.text('Als bezahlt markieren'));
    await tester.pumpAndSettle();
    taps.expectWithinBudget('mark_transfer_paid');
    expect(taps.taps, 2);

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Ben → Anna als bezahlt markiert'), findsOneWidget);
    // The transfer left the open list and sits in the history.
    expect(find.text('Chiara → Anna'), findsOneWidget);
    expect(find.text('Ben → Anna'), findsOneWidget);
    expect(
      find.text('Noch nichts bezahlt.', skipOffstage: false),
      findsNothing,
    );

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(find.text('Ben → Anna'), findsOneWidget);
    expect(find.text('Chiara → Anna'), findsOneWidget);
    expect(
      find.textContaining('Noch nichts bezahlt.'),
      findsOneWidget,
    );
  });

  phoneTest('paying everything shows the calm settled state', (tester) async {
    await pumpMitlio(tester, app, location: route());
    for (final from in ['Ben', 'Chiara']) {
      await tester.tap(find.text('$from → Anna'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Als bezahlt markieren'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Alles ausgeglichen'), findsOneWidget);
    expect(find.text('Noch zu zahlen'), findsNothing);
    expect(find.byTooltip('Zusammenfassung teilen'), findsNothing);
    expect(find.text('Ben → Anna'), findsOneWidget);
    expect(find.text('Chiara → Anna'), findsOneWidget);
  });

  phoneTest('no payment details: a calm hint, marking still works', (
    tester,
  ) async {
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Anna hat noch keine Zahlungsdaten — trotzdem als bezahlt markieren?',
      ),
      findsOneWidget,
    );
    expect(find.text('Mit PayPal zahlen'), findsNothing);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Als bezahlt markieren'));
    await tester.pumpAndSettle();
    expect(find.text('Ben → Anna als bezahlt markiert'), findsOneWidget);
  });

  phoneTest('with details: PayPal, QR and copy IBAN', (tester) async {
    await annaPays();
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    expect(find.text('Mit PayPal zahlen'), findsOneWidget);
    expect(find.text('Überweisung'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      tester.widget<QrImageView>(find.byType(QrImageView)).errorCorrectionLevel,
      QrErrorCorrectLevel.M,
    );
    expect(find.textContaining('IBAN kopieren'), findsOneWidget);
    expect(find.textContaining('DE89 •••• 3000'), findsOneWidget);
    // The IBAN itself is never shown.
    expect(find.textContaining('0532'), findsNothing);

    await tester.tap(find.text('Mit PayPal zahlen'));
    await tester.pumpAndSettle();
    expect(app.launcher.launched.single.host, 'paypal.me');
    expect(find.text('Link kopiert'), findsNothing);

    await tester.tap(find.textContaining('IBAN kopieren'));
    await tester.pumpAndSettle();
    expect(app.launcher.copied, [_iban]);
    expect(find.text('IBAN kopiert'), findsOneWidget);
  });

  phoneTest('PayPal without an app copies the link and says so', (
    tester,
  ) async {
    await annaPays(iban: false);
    app.launcher.canLaunch = false;
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    await tester.tap(find.text('Mit PayPal zahlen'));
    await tester.pumpAndSettle();
    expect(find.text('Link kopiert'), findsOneWidget);
    expect(app.launcher.copied.single, startsWith('https://paypal.me/anna/'));
  });

  phoneTest('a partial payment leaves the rest open', (tester) async {
    await annaPays();
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    expect(find.text('Teilzahlung: Der Rest bleibt offen.'), findsNothing);
    await tester.enterText(amountField(), '4');
    await tester.pumpAndSettle();
    expect(find.text('Teilzahlung: Der Rest bleibt offen.'), findsOneWidget);
    await tester.tap(find.text('Als bezahlt markieren'));
    await tester.pumpAndSettle();
    // 6,00 still open for Ben, 4,00 in the history.
    expect(find.textContaining('6,00'), findsOneWidget);
    expect(find.textContaining('4,00'), findsOneWidget);
    expect(find.text('Ben → Anna'), findsNWidgets(2));
  });

  phoneTest('more than the open amount cannot be marked', (tester) async {
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    await tester.enterText(amountField(), '10,01');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Das ist mehr als die offenen 10,00'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Als bezahlt markieren'),
    );
    expect(button.onPressed, isNull);
  });

  phoneTest('a failing repository keeps the sheet open', (tester) async {
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    app.settlements.failWith = const Storage('disk');
    await tester.tap(find.text('Als bezahlt markieren'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.text('Das hat nicht geklappt. Versuch es nochmal.'),
      findsOneWidget,
    );
  });

  phoneTest('swipe deletes a settlement, undo brings it back', (
    tester,
  ) async {
    await s.settle('Ben', 'Anna', 400);
    await pumpMitlio(tester, app, location: route());
    expect(find.textContaining('4,00'), findsOneWidget);
    await tester.drag(
      find.byType(Dismissible),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ausgleich gelöscht'), findsOneWidget);
    expect(find.textContaining('4,00'), findsNothing);
    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(find.textContaining('4,00'), findsOneWidget);
  });

  phoneTest('the delete button works like the swipe', (tester) async {
    await s.settle('Ben', 'Anna', 400);
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.byTooltip('Ausgleich löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Ausgleich gelöscht'), findsOneWidget);
  });

  phoneTest('a failing delete shows an error and keeps the entry', (
    tester,
  ) async {
    await s.settle('Ben', 'Anna', 400);
    await pumpMitlio(tester, app, location: route());
    app.settlements.failWith = const Storage('disk');
    await tester.tap(find.byTooltip('Ausgleich löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Das hat nicht geklappt'), findsOneWidget);
    expect(find.textContaining('4,00'), findsOneWidget);
  });

  phoneTest('share hands the summary to the share sheet', (tester) async {
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.byTooltip('Zusammenfassung teilen'));
    await tester.pumpAndSettle();
    expect(app.share.shared, [
      'Trip: Ben → Anna 10,00\u00a0€, Chiara → Anna 10,00\u00a0€',
    ]);
  });

  phoneTest('a failing share sheet shows an error', (tester) async {
    app.share.failWith = Exception('nope');
    await pumpMitlio(tester, app, location: route());
    await tester.tap(find.byTooltip('Zusammenfassung teilen'));
    await tester.pumpAndSettle();
    expect(find.text('Das hat nicht geklappt'), findsOneWidget);
  });

  phoneTest('English copy', (tester) async {
    await pumpMitlio(
      tester,
      app,
      location: route(),
      locale: const Locale('en'),
    );
    expect(find.text('Still to pay'), findsOneWidget);
    expect(find.text('Ben → Anna'), findsOneWidget);
    await tester.tap(find.text('Ben → Anna'));
    await tester.pumpAndSettle();
    expect(
      find.text('Anna has no payment details yet — mark as paid anyway?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Mark as paid'));
    await tester.pumpAndSettle();
    expect(find.text('Ben → Anna marked as paid'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  phoneTest('a failing repository offers a retry', (tester) async {
    app.members.watchError = StateError('boom');
    await pumpMitlio(tester, app, location: route());
    expect(find.text('Nochmal versuchen'), findsOneWidget);
    expect(find.byTooltip('Zusammenfassung teilen'), findsNothing);
    app.members.watchError = null;
    await tester.tap(find.text('Nochmal versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Ben → Anna'), findsOneWidget);
  });
}
