import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio/features/settle/ui/transfer_sheet_view_model.dart';

import '../../../helpers/fake_app.dart';
import '../../balances/balances_support.dart';
import '../../repo_test_support.dart';

const _iban = 'DE89370400440532013000';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Scenario s;
  late TransferKey key;

  TransferSheetViewModel vm() =>
      container.read(transferSheetViewModelProvider(key).notifier);
  TransferSheetState state() =>
      container.read(transferSheetViewModelProvider(key));
  TransferSheetLoaded loaded() => state() as TransferSheetLoaded;

  /// Opens the sheet the way the screen does: the settle state is loaded.
  Future<void> open() async {
    container.listen(settleViewModelProvider(s.group.id), (_, _) {});
    await pumpEventQueue();
    container.listen(transferSheetViewModelProvider(key), (_, _) {});
    await pumpEventQueue();
  }

  Future<void> annPays({bool paypal = true, bool iban = true}) async {
    ok(
      await app.payments.save(
        s.ids['Anna']!,
        paypalMe: paypal ? 'anna' : null,
        iban: iban ? _iban : null,
        accountName: iban ? 'Anna Muster' : null,
      ),
    );
  }

  /// Ben owes Anna 12,40.
  setUp(() async {
    app = FakeApp();
    container = ProviderContainer(
      overrides: [...app.overrides, clockProvider.overrideWithValue(app.clock)],
    );
    addTearDown(container.dispose);
    s = await Scenario.create(app, ['Anna', 'Ben']);
    await s.expense({'Anna': 1240}, {'Ben': 1240});
    key = (
      groupId: s.group.id,
      fromId: s.ids['Ben']!,
      toId: s.ids['Anna']!,
      amountCents: 1240,
    );
  });

  group('loading', () {
    test('loading, then the full amount with all options', () async {
      await annPays();
      container.listen(settleViewModelProvider(s.group.id), (_, _) {});
      await pumpEventQueue();
      container.listen(transferSheetViewModelProvider(key), (_, _) {});
      expect(state(), isA<TransferSheetLoading>());
      await pumpEventQueue();
      final l = loaded();
      expect(l.fromName, 'Ben');
      expect(l.toName, 'Anna');
      expect(l.amountCents, 1240);
      expect(l.isFull, isTrue);
      expect(l.problem, isNull);
      expect(l.canMarkPaid, isTrue);
      expect(l.options.hasPaypal, isTrue);
      expect(l.options.hasIban, isTrue);
      expect(l.options.ibanHint, 'DE89 •••• 3000');
      expect(l.hasNoPaymentDetails, isFalse);
      expect(l.method, SettlementMethod.other);
      expect(
        l.epcPayload,
        'BCD\n002\n1\nSCT\n\nAnna Muster\n$_iban\nEUR12.40\n\n\nmitlio: Trip',
      );
    });

    test('without payment details nothing but marking is offered', () async {
      await open();
      final l = loaded();
      expect(l.hasNoPaymentDetails, isTrue);
      expect(l.epcPayload, isNull);
      expect(l.canMarkPaid, isTrue);
    });

    test('only PayPal: no QR', () async {
      await annPays(iban: false);
      await open();
      expect(loaded().options.hasPaypal, isTrue);
      expect(loaded().epcPayload, isNull);
    });

    test('a group that is not loaded is a failure, retry recovers', () async {
      container.listen(transferSheetViewModelProvider(key), (_, _) {});
      await pumpEventQueue();
      expect((state() as TransferSheetFailure).error, isA<NotFound>());
      expect(vm().debugSnapshot()['status'], 'error');
      container.listen(settleViewModelProvider(s.group.id), (_, _) {});
      await pumpEventQueue();
      vm().retry();
      expect(state(), isA<TransferSheetLoading>());
      await pumpEventQueue();
      expect(state(), isA<TransferSheetLoaded>());
    });

    test('an unknown receiver is a failure', () async {
      key = (
        groupId: s.group.id,
        fromId: s.ids['Ben']!,
        toId: 'nobody',
        amountCents: 100,
      );
      await open();
      expect((state() as TransferSheetFailure).error, isA<NotFound>());
    });

    test('loading snapshot', () async {
      expect(vm().debugSnapshot(), {'status': 'loading'});
    });
  });

  group('amount', () {
    test('a partial amount is valid and moves the QR amount', () async {
      await annPays();
      await open();
      vm().setAmount(500);
      await pumpEventQueue();
      final l = loaded();
      expect(l.amountCents, 500);
      expect(l.isFull, isFalse);
      expect(l.problem, isNull);
      expect(l.epcPayload, contains('EUR5.00'));
    });

    test('more than the transfer is rejected, the QR disappears', () async {
      await annPays();
      await open();
      vm().setAmount(1241);
      await pumpEventQueue();
      expect(loaded().problem, AmountProblem.tooHigh);
      expect(loaded().canMarkPaid, isFalse);
      expect(loaded().epcPayload, isNull);
    });

    test('empty or zero is invalid', () async {
      await annPays();
      await open();
      vm().setAmount(null);
      await pumpEventQueue();
      expect(loaded().amountCents, isNull);
      expect(loaded().problem, AmountProblem.invalid);
      expect(loaded().epcPayload, isNull);
      vm().setAmount(0);
      await pumpEventQueue();
      expect(loaded().problem, AmountProblem.invalid);
      vm().setAmount(1240);
      await pumpEventQueue();
      expect(loaded().problem, isNull);
      expect(loaded().epcPayload, contains('EUR12.40'));
    });

    test('commands before the details are loaded do nothing', () async {
      container.listen(settleViewModelProvider(s.group.id), (_, _) {});
      await pumpEventQueue();
      container.listen(transferSheetViewModelProvider(key), (_, _) {});
      // No awaits in between: the details have not arrived yet.
      final commands = [vm().openPayPal(), vm().copyIban()];
      vm()
        ..setAmount(5)
        ..setAmount(null);
      final marked = vm().markPaid();
      expect(state(), isA<TransferSheetLoading>());
      expect(err(await marked), const InvalidData('amount not valid'));
      await Future.wait(commands);
      expect(app.launcher.launched, isEmpty);
      expect(app.launcher.copied, isEmpty);
    });
  });

  group('PayPal', () {
    test('opens the link for the current amount', () async {
      await annPays();
      await open();
      vm().setAmount(700);
      await pumpEventQueue();
      await vm().openPayPal();
      expect(
        app.launcher.launched.single.toString(),
        contains('paypal.me/anna/7'),
      );
      expect(loaded().method, SettlementMethod.paypal);
      expect(loaded().notice, isNull);
    });

    test(
      'no app can open it: the link is copied and the notice says so',
      () async {
        await annPays();
        await open();
        app.launcher.canLaunch = false;
        await vm().openPayPal();
        expect(app.launcher.copied.single, contains('paypal.me/anna/12.4'));
        expect(loaded().notice, SheetNotice.linkCopied);
        expect(loaded().method, SettlementMethod.paypal);
      },
    );

    test('an invalid amount opens nothing', () async {
      await annPays();
      await open();
      vm().setAmount(99999);
      await pumpEventQueue();
      await vm().openPayPal();
      expect(app.launcher.launched, isEmpty);
    });

    test('without a handle nothing happens', () async {
      await annPays(paypal: false);
      await open();
      await vm().openPayPal();
      expect(app.launcher.launched, isEmpty);
      expect(loaded().notice, isNull);
    });

    test('a failing details repository shows a calm failure', () async {
      await annPays();
      await open();
      app.payments.failWith = const Storage('disk');
      await vm().openPayPal();
      expect(loaded().notice, SheetNotice.actionFailed);
    });
  });

  group('copy IBAN', () {
    test('puts the IBAN on the clipboard, method becomes sepa', () async {
      await annPays();
      await open();
      await vm().copyIban();
      expect(app.launcher.copied, [_iban]);
      expect(loaded().notice, SheetNotice.ibanCopied);
      expect(loaded().method, SettlementMethod.sepa);
    });

    test('without an IBAN nothing is copied', () async {
      await annPays(iban: false);
      await open();
      await vm().copyIban();
      expect(app.launcher.copied, isEmpty);
    });

    test('a failing details repository shows a calm failure', () async {
      await annPays();
      await open();
      app.payments.failWith = const Storage('disk');
      await vm().copyIban();
      expect(loaded().notice, SheetNotice.actionFailed);
    });
  });

  group('markPaid', () {
    test('books the full amount with the used method', () async {
      await annPays();
      await open();
      await vm().copyIban();
      final r = ok(await vm().markPaid());
      expect(r.entry.settlement.amountCents, 1240);
      expect(r.entry.method, SettlementMethod.sepa);
      await pumpEventQueue();
      expect(
        (container.read(
          settleViewModelProvider(s.group.id),
        ) as SettleLoaded).isSettled,
        isTrue,
      );
    });

    test('books a partial amount, the rest stays open', () async {
      await open();
      vm().setAmount(400);
      ok(await vm().markPaid());
      await pumpEventQueue();
      final settle =
          container.read(settleViewModelProvider(s.group.id)) as SettleLoaded;
      expect(settle.transfers.single.amountCents, 840);
    });

    test('undo takes it back', () async {
      await open();
      final r = ok(await vm().markPaid());
      await pumpEventQueue();
      ok(await r.undo());
      await pumpEventQueue();
      final settle =
          container.read(settleViewModelProvider(s.group.id)) as SettleLoaded;
      expect(settle.transfers, hasLength(1));
    });

    test('an invalid amount books nothing', () async {
      await open();
      vm().setAmount(5000);
      expect(
        err(await vm().markPaid()),
        const InvalidData('amount not valid'),
      );
      vm().setAmount(null);
      expect(err(await vm().markPaid()), isA<InvalidData>());
      expect(
        (container.read(
          settleViewModelProvider(s.group.id),
        ) as SettleLoaded).history,
        isEmpty,
      );
    });

    test('a failing repository keeps the sheet open with a notice', () async {
      await open();
      app.settlements.failWith = const Storage('disk');
      expect(err(await vm().markPaid()), const Storage('disk'));
      expect(loaded().notice, SheetNotice.actionFailed);
      expect(loaded().busy, isFalse);
      expect(loaded().canMarkPaid, isTrue);
    });
  });

  test('the snapshot never contains the IBAN or the QR payload', () async {
    await annPays();
    await open();
    final snap = vm().debugSnapshot();
    expect(snap, {
      'status': 'data',
      'from': s.ids['Ben'],
      'to': s.ids['Anna'],
      'fullCents': 1240,
      'amountCents': 1240,
      'problem': null,
      'hasPaypal': true,
      'hasIban': true,
      'hasQr': true,
      'method': 'other',
      'notice': null,
    });
    final text = jsonEncode(snap);
    expect(text, isNot(contains('0532')));
    expect(text, isNot(contains('BCD')));
  });
}
