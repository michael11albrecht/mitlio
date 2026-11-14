import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../balances/balances_support.dart';
import '../../repo_test_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Scenario s;

  SettleViewModel vm() =>
      container.read(settleViewModelProvider(s.group.id).notifier);
  SettleState state() => container.read(settleViewModelProvider(s.group.id));
  SettleLoaded loaded() => state() as SettleLoaded;

  Future<void> open() async {
    container.listen(settleViewModelProvider(s.group.id), (_, _) {});
    await pumpEventQueue();
  }

  /// Anna paid 30,00 for Anna, Ben and Chiara: Ben and Chiara owe 10,00.
  setUp(() async {
    app = FakeApp();
    container = ProviderContainer(
      overrides: [...app.overrides, clockProvider.overrideWithValue(app.clock)],
    );
    addTearDown(container.dispose);
    s = await Scenario.create(app, ['Anna', 'Ben', 'Chiara']);
    await s.expense(
      {'Anna': 3000},
      {'Anna': 1000, 'Ben': 1000, 'Chiara': 1000},
    );
  });

  String id(String label) => s.ids[label]!;

  group('state', () {
    test('loading, then the simplified transfers', () async {
      container.listen(settleViewModelProvider(s.group.id), (_, _) {});
      expect(state(), isA<SettleLoading>());
      await pumpEventQueue();
      final l = loaded();
      expect(
        [
          for (final t in l.transfers)
            (s.label(t.fromId), s.label(t.toId), t.amountCents),
        ],
        [('Ben', 'Anna', 1000), ('Chiara', 'Anna', 1000)],
      );
      expect(l.history, isEmpty);
      expect(l.isSettled, isFalse);
      expect(l.nameOf(id('Ben')), 'Ben');
      expect(l.nameOf('unknown'), '?');
      expect(l.currency, Currency.eur);
    });

    test('a failing balances stream is a failure, retry recovers', () async {
      app.members.watchError = StateError('boom');
      await open();
      expect(state(), isA<SettleFailure>());
      expect(vm().debugSnapshot()['status'], 'error');
      app.members.watchError = null;
      vm().retry();
      expect(state(), isA<SettleLoading>());
      await pumpEventQueue();
      expect(state(), isA<SettleLoaded>());
    });

    test('a failing settlements stream is a failure', () async {
      app.settlements.watchError = StateError('boom');
      await open();
      expect((state() as SettleFailure).error, isA<Storage>());
    });

    test('a repository error on the stream keeps its type', () async {
      app.settlements.watchError = const InvalidData('bad row');
      await open();
      expect((state() as SettleFailure).error, const InvalidData('bad row'));
    });

    test('an unknown group is a failure', () async {
      container.listen(settleViewModelProvider('nope'), (_, _) {});
      await pumpEventQueue();
      expect(
        container.read(settleViewModelProvider('nope')),
        isA<SettleFailure>(),
      );
    });
  });

  group('markPaid', () {
    test('in full: the transfer is gone, the history has the entry', () async {
      await open();
      final r = ok(
        await vm().markPaid(
          fromId: id('Ben'),
          toId: id('Anna'),
          amountCents: 1000,
          method: SettlementMethod.paypal,
        ),
      );
      await pumpEventQueue();
      expect(r.entry.method, SettlementMethod.paypal);
      expect(r.entry.settlement.date, DateTime.utc(2026, 3));
      final l = loaded();
      expect(l.transfers.map((t) => s.label(t.fromId)), ['Chiara']);
      expect(l.history.single.fromName, 'Ben');
      expect(l.history.single.toName, 'Anna');
      expect(l.history.single.amountCents, 1000);
    });

    test('everything paid: settled, all balances zero', () async {
      await open();
      for (final from in ['Ben', 'Chiara']) {
        ok(
          await vm().markPaid(
            fromId: id(from),
            toId: id('Anna'),
            amountCents: 1000,
          ),
        );
      }
      await pumpEventQueue();
      expect(loaded().isSettled, isTrue);
      expect(vm().debugSnapshot()['status'], 'settled');
    });

    test('partly: the rest of the transfer stays open', () async {
      await open();
      ok(
        await vm().markPaid(
          fromId: id('Ben'),
          toId: id('Anna'),
          amountCents: 400,
        ),
      );
      await pumpEventQueue();
      final ben = loaded().transfers.firstWhere(
        (t) => t.fromId == id('Ben'),
      );
      expect(ben.amountCents, 600);
    });

    test('the default method is "other"', () async {
      await open();
      final r = ok(
        await vm().markPaid(
          fromId: id('Ben'),
          toId: id('Anna'),
          amountCents: 100,
        ),
      );
      expect(r.entry.method, SettlementMethod.other);
    });

    test('undo takes the payment back', () async {
      await open();
      final r = ok(
        await vm().markPaid(
          fromId: id('Ben'),
          toId: id('Anna'),
          amountCents: 1000,
        ),
      );
      await pumpEventQueue();
      expect(loaded().transfers, hasLength(1));
      ok(await r.undo());
      await pumpEventQueue();
      expect(loaded().transfers, hasLength(2));
      expect(loaded().history, isEmpty);
    });

    test('invalid amounts and members are InvalidData', () async {
      await open();
      for (final cents in [0, -5]) {
        expect(
          await vm().markPaid(
            fromId: id('Ben'),
            toId: id('Anna'),
            amountCents: cents,
          ),
          isA<Err<PaidTransfer, RepositoryError>>(),
        );
      }
      final self = await vm().markPaid(
        fromId: id('Ben'),
        toId: id('Ben'),
        amountCents: 100,
      );
      expect(err(self), isA<InvalidData>());
      final unknown = await vm().markPaid(
        fromId: 'x',
        toId: id('Ben'),
        amountCents: 100,
      );
      expect(err(unknown), isA<InvalidData>());
      expect(loaded().history, isEmpty);
    });

    test('a failing repository is an Err and writes nothing', () async {
      await open();
      app.settlements.failWith = const Storage('disk');
      final r = await vm().markPaid(
        fromId: id('Ben'),
        toId: id('Anna'),
        amountCents: 1000,
      );
      expect(err(r), const Storage('disk'));
      app.settlements.failWith = null;
      await pumpEventQueue();
      expect(loaded().history, isEmpty);
    });

    test('an unknown group is NotFound', () async {
      final other = container.read(
        settleViewModelProvider('nope').notifier,
      );
      final r = await other.markPaid(
        fromId: id('Ben'),
        toId: id('Anna'),
        amountCents: 100,
      );
      expect(err(r), isA<NotFound>());
    });
  });

  group('history', () {
    test('newest first', () async {
      await s.settle('Ben', 'Anna', 300); // 2026-02-02
      await open();
      ok(
        await vm().markPaid(
          fromId: id('Chiara'),
          toId: id('Anna'),
          amountCents: 200,
        ),
      ); // 2026-03-01
      await pumpEventQueue();
      expect(loaded().history.map((h) => h.fromName), ['Chiara', 'Ben']);
    });

    test('delete is a soft delete with undo', () async {
      final entry = await s.settle('Ben', 'Anna', 300);
      await open();
      final undo = ok(await vm().deleteSettlement(entry.settlement.id));
      await pumpEventQueue();
      expect(loaded().history, isEmpty);
      expect(loaded().transfers.first.amountCents, 1000);
      ok(await undo());
      await pumpEventQueue();
      expect(loaded().history, hasLength(1));
    });

    test('deleting an unknown settlement is NotFound', () async {
      await open();
      expect(err(await vm().deleteSettlement('nope')), isA<NotFound>());
    });

    test('a failing repository keeps the entry', () async {
      final entry = await s.settle('Ben', 'Anna', 300);
      await open();
      app.settlements.failWith = const Storage('disk');
      expect(
        err(await vm().deleteSettlement(entry.settlement.id)),
        const Storage('disk'),
      );
      app.settlements.failWith = null;
      expect(loaded().history, hasLength(1));
    });
  });

  group('share', () {
    String format(int cents) => '${cents ~/ 100},${cents % 100} €';

    test('summary lists every open transfer', () async {
      await open();
      expect(
        vm().summary(format),
        'Trip: Ben → Anna 10,0 €, Chiara → Anna 10,0 €',
      );
    });

    test('share hands the text to the share sheet', () async {
      await open();
      ok((await vm().share(format))!);
      expect(app.share.shared, [
        'Trip: Ben → Anna 10,0 €, Chiara → Anna 10,0 €',
      ]);
    });

    test('a failing share sheet is an Err', () async {
      await open();
      app.share.failWith = Exception('no share');
      expect(err((await vm().share(format))!), isA<Storage>());
    });

    test('nothing open: nothing to share', () async {
      await s.settle('Ben', 'Anna', 1000);
      await s.settle('Chiara', 'Anna', 1000);
      await open();
      expect(vm().summary(format), isNull);
      expect(await vm().share(format), isNull);
      expect(app.share.shared, isEmpty);
    });

    test('not loaded yet: nothing to share', () async {
      expect(vm().summary(format), isNull);
    });
  });

  group('list (DebugDrive)', () {
    test('transfers and history as of now', () async {
      final entry = await s.settle('Ben', 'Anna', 300);
      final r = ok(await vm().list());
      expect(r['transfers'], [
        {'from': id('Chiara'), 'to': id('Anna'), 'amount': 1000},
        {'from': id('Ben'), 'to': id('Anna'), 'amount': 700},
      ]);
      final history = (r['history']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(history.single['id'], entry.settlement.id);
      expect(history.single['method'], 'cash');
      expect(history.single['amount'], 300);
    });

    test('an unknown group is NotFound', () async {
      final other = container.read(settleViewModelProvider('nope').notifier);
      expect(err(await other.list()), isA<NotFound>());
    });

    test('a failing stream is an Err', () async {
      app.settlements.watchError = StateError('boom');
      expect(err(await vm().list()), isA<Storage>());
    });
  });

  test('the snapshot never contains payment details', () async {
    ok(
      await app.payments.save(
        id('Anna'),
        paypalMe: 'anna',
        iban: 'DE89370400440532013000',
      ),
    );
    await open();
    final snap = vm().debugSnapshot();
    expect(snap['status'], 'data');
    expect(snap['groupId'], s.group.id);
    final text = jsonEncode(snap);
    expect(text, isNot(contains('0532')));
    expect(text, isNot(contains('anna"')));
  });

  test('loading and error snapshots', () async {
    expect(vm().debugSnapshot()['status'], 'loading');
  });
}
