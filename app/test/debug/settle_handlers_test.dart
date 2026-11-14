import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/settle.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';

import '../features/balances/balances_support.dart';
import '../features/repo_test_support.dart' show ok;
import '../helpers/fake_app.dart';

const _iban = 'DE89370400440532013000';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;
  late Scenario s;

  setUp(() async {
    app = FakeApp();
    container = ProviderContainer(
      overrides: [...app.overrides, clockProvider.overrideWithValue(app.clock)],
    );
    addTearDown(container.dispose);
    h = settleDriveHandlers(container);
    s = await Scenario.create(app, ['Ann', 'Ben']);
    await s.expense({'Ann': 2000}, {'Ann': 1000, 'Ben': 1000});
  });

  Map<String, String> pay(int cents) => {
    'fromId': s.ids['Ben']!,
    'toId': s.ids['Ann']!,
    'amountCents': '$cents',
  };

  group('settle.markPaid', () {
    test('books the settlement and answers with its id', () async {
      final r = await h['settle.markPaid']!(pay(1000));
      expect(r['groupId'], s.group.id);
      expect(r['amount'], 1000);
      final id = r['id']! as String;
      expect(ok(await app.settlements.get(id)).settlement.amountCents, 1000);
    });

    test('balances are zero afterwards', () async {
      await h['settle.markPaid']!(pay(1000));
      final list = await h['settle.list']!({'groupId': s.group.id});
      expect(list['transfers'], isEmpty);
    });

    test('a partial payment leaves the rest', () async {
      await h['settle.markPaid']!(pay(300));
      final list = await h['settle.list']!({'groupId': s.group.id});
      expect(list['transfers'], [
        {'from': s.ids['Ben'], 'to': s.ids['Ann'], 'amount': 700},
      ]);
    });

    test('invalid params', () async {
      for (final p in [
        <String, String>{},
        {...pay(100), 'amountCents': 'x'},
        pay(0),
        pay(-1),
        {'toId': s.ids['Ann']!, 'amountCents': '5'},
      ]) {
        expect((await h['settle.markPaid']!(p))['error'], 'invalid_params');
      }
    });

    test('unknown members are not_found', () async {
      final r = await h['settle.markPaid']!({
        'fromId': 'x',
        'toId': 'y',
        'amountCents': '5',
      });
      expect(r['error'], 'not_found');
    });

    test('a self payment is invalid_params', () async {
      final r = await h['settle.markPaid']!({
        'fromId': s.ids['Ben']!,
        'toId': s.ids['Ben']!,
        'amountCents': '5',
      });
      expect(r['error'], 'invalid_params');
    });
  });

  group('settle.list', () {
    test('open transfers and history', () async {
      final r = await h['settle.markPaid']!(pay(400));
      final list = await h['settle.list']!({'groupId': s.group.id});
      expect(list['groupId'], s.group.id);
      expect(list['transfers'], hasLength(1));
      final history = (list['history']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(history.single['id'], r['id']);
      expect(history.single['amount'], 400);
    });

    test('needs a groupId, unknown group is not_found', () async {
      expect((await h['settle.list']!({}))['error'], 'invalid_params');
      expect(
        (await h['settle.list']!({'groupId': 'nope'}))['error'],
        'not_found',
      );
    });

    test('never contains payment details', () async {
      ok(await app.payments.save(s.ids['Ann']!, paypalMe: 'ann', iban: _iban));
      await h['settle.markPaid']!(pay(400));
      final list = await h['settle.list']!({'groupId': s.group.id});
      final text = jsonEncode(list);
      expect(text, isNot(contains('0532')));
      expect(text, isNot(contains('"ann"')));
    });
  });

  test('the same command as the screen: state shows the booking', () async {
    container.listen(settleViewModelProvider(s.group.id), (_, _) {});
    await pumpEventQueue();
    await h['settle.markPaid']!(pay(400));
    await pumpEventQueue();
    final state =
        container.read(settleViewModelProvider(s.group.id)) as SettleLoaded;
    expect(state.history.single.amountCents, 400);
  });
}
