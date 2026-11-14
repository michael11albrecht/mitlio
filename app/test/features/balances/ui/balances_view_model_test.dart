import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';
import '../balances_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;

  BalancesViewModel vm(String id) =>
      container.read(balancesViewModelProvider(id).notifier);
  BalancesState state(String id) =>
      container.read(balancesViewModelProvider(id));
  BalancesLoaded loaded(String id) => state(id) as BalancesLoaded;

  Future<void> open(String id) async {
    container.listen(balancesViewModelProvider(id), (_, _) {});
    await pumpEventQueue();
  }

  Map<String, int> byLabel(Scenario s, BalancesLoaded b) => {
    for (final x in b.balances) s.label(x.member.id): x.cents,
  };

  List<Map<String, Object>> transfers(Scenario s, Iterable<Transfer> list) => [
    for (final t in list)
      {
        'from': s.label(t.fromId),
        'to': s.label(t.toId),
        'amount': t.amountCents,
      },
  ];

  setUp(() {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  group('state', () {
    test('loading, then loaded', () async {
      final s = await Scenario.create(app, ['A', 'B']);
      container.listen(balancesViewModelProvider(s.group.id), (_, _) {});
      expect(state(s.group.id), isA<BalancesLoading>());
      await pumpEventQueue();
      expect(state(s.group.id), isA<BalancesLoaded>());
    });

    test('a group without entries is empty, everyone at zero', () async {
      final s = await Scenario.create(app, ['A', 'B']);
      await open(s.group.id);
      final b = loaded(s.group.id);
      expect(b.hasEntries, isFalse);
      expect(b.isSettled, isFalse);
      expect(byLabel(s, b), {'A': 0, 'B': 0});
      expect(b.transfers, isEmpty);
      expect(vm(s.group.id).debugSnapshot()['status'], 'empty');
    });

    test('a group without members is empty too', () async {
      final s = await Scenario.create(app, []);
      await open(s.group.id);
      expect(loaded(s.group.id).balances, isEmpty);
    });

    test('all settled once the debt is paid back', () async {
      final s = await Scenario.create(app, ['A', 'B']);
      await s.expense({'A': 1000}, {'A': 500, 'B': 500});
      await open(s.group.id);
      expect(loaded(s.group.id).isSettled, isFalse);
      await s.settle('B', 'A', 500);
      await pumpEventQueue();
      final b = loaded(s.group.id);
      expect(b.isSettled, isTrue);
      expect(byLabel(s, b), {'A': 0, 'B': 0});
      expect(b.simplified, isEmpty);
      expect(b.pairwise, isEmpty);
      expect(vm(s.group.id).debugSnapshot()['status'], 'settled');
    });

    test('an unknown or archived group is NotFound', () async {
      await open('nope');
      expect(
        (state('nope') as BalancesFailure).error,
        const NotFound('group', 'nope'),
      );
      final s = await Scenario.create(app, ['A']);
      await open(s.group.id);
      ok(await app.groups.softDelete(s.group.id));
      await pumpEventQueue();
      expect(state(s.group.id), isA<BalancesFailure>());
    });

    test('nameOf resolves members, unknown ids get a placeholder', () async {
      final s = await Scenario.create(app, ['A']);
      await open(s.group.id);
      expect(loaded(s.group.id).nameOf(s.ids['A']!), 'A');
      expect(loaded(s.group.id).nameOf('gone'), '?');
    });
  });

  group('docs/domain-rules.md examples', () {
    test('examples:balances through the repositories', () async {
      for (final row in domainRulesRows('balances')) {
        final fresh = FakeApp();
        final c = fresh.container();
        addTearDown(c.dispose);
        final labels = (row['members'] as List).cast<String>();
        final s = await Scenario.create(fresh, labels);
        for (final e
            in (row['expenses'] as List).cast<Map<String, dynamic>>()) {
          await s.expense(
            (e['payers'] as Map).cast<String, int>(),
            (e['shares'] as Map).cast<String, int>(),
          );
        }
        for (final x
            in (row['settlements'] as List).cast<Map<String, dynamic>>()) {
          await s.settle(
            x['from'] as String,
            x['to'] as String,
            x['amount'] as int,
          );
        }
        c.listen(balancesViewModelProvider(s.group.id), (_, _) {});
        await pumpEventQueue();
        final b =
            c.read(balancesViewModelProvider(s.group.id)) as BalancesLoaded;
        expect(byLabel(s, b), (row['balances'] as Map).cast<String, int>());
      }
    });

    test('examples:simplify transfers match the fixture', () async {
      for (final row in domainRulesRows('simplify')) {
        final fresh = FakeApp();
        final c = fresh.container();
        addTearDown(c.dispose);
        final balances = (row['balances'] as Map).cast<String, int>();
        final s = await Scenario.create(fresh, balances.keys.toList());
        await s.seedBalances(balances);
        c.listen(balancesViewModelProvider(s.group.id), (_, _) {});
        await pumpEventQueue();
        final b =
            c.read(balancesViewModelProvider(s.group.id)) as BalancesLoaded;
        expect(byLabel(s, b), balances);
        expect(transfers(s, b.simplified), [
          for (final t
              in (row['transfers'] as List).cast<Map<String, dynamic>>())
            {'from': t['from'], 'to': t['to'], 'amount': t['amount']},
        ]);
      }
    });
  });

  group('live', () {
    test('new expenses and settlements update the state', () async {
      final s = await Scenario.create(app, ['Anna', 'Ben']);
      await open(s.group.id);
      await s.expense({'Anna': 2340}, {'Anna': 0, 'Ben': 2340});
      await pumpEventQueue();
      expect(byLabel(s, loaded(s.group.id)), {'Anna': 2340, 'Ben': -2340});
      await s.settle('Ben', 'Anna', 340);
      await pumpEventQueue();
      expect(byLabel(s, loaded(s.group.id)), {'Anna': 2000, 'Ben': -2000});
    });

    test('a deleted expense disappears from the balances', () async {
      final s = await Scenario.create(app, ['A', 'B']);
      final e = await s.expense({'A': 1000}, {'B': 1000});
      await open(s.group.id);
      expect(loaded(s.group.id).isSettled, isFalse);
      ok(await app.expenses.softDelete(e.expense.id));
      await pumpEventQueue();
      expect(loaded(s.group.id).hasEntries, isFalse);
    });
  });

  group('modes', () {
    test('simplified by default; pairwise keeps direct debts', () async {
      // C pays for A and B; A pays for B. Direct: A->C, B->A, B->C.
      // Simplified: the greedy rule, B and A both pay C.
      final s = await Scenario.create(app, ['A', 'B', 'C']);
      await s.expense({'C': 2000}, {'A': 1000, 'B': 1000});
      await s.expense({'A': 600}, {'B': 600});
      await open(s.group.id);
      final b = loaded(s.group.id);
      expect(b.mode, BalancesMode.simplified);
      expect(transfers(s, b.pairwise), [
        {'from': 'A', 'to': 'C', 'amount': 1000},
        {'from': 'B', 'to': 'A', 'amount': 600},
        {'from': 'B', 'to': 'C', 'amount': 1000},
      ]);
      expect(byLabel(s, b), {'A': -400, 'B': -1600, 'C': 2000});
      expect(transfers(s, b.simplified), [
        {'from': 'B', 'to': 'C', 'amount': 1600},
        {'from': 'A', 'to': 'C', 'amount': 400},
      ]);
      expect(b.transfers, b.simplified);

      vm(s.group.id).setMode(BalancesMode.pairwise);
      expect(loaded(s.group.id).transfers, b.pairwise);
      // The choice survives live updates.
      await s.expense({'A': 100}, {'B': 100});
      await pumpEventQueue();
      expect(loaded(s.group.id).mode, BalancesMode.pairwise);
      expect(vm(s.group.id).debugSnapshot()['mode'], 'pairwise');
    });

    test('settlements reduce the direct debt they pay', () async {
      final s = await Scenario.create(app, ['A', 'B']);
      await s.expense({'A': 1000}, {'B': 1000});
      await s.settle('B', 'A', 400);
      await open(s.group.id);
      expect(transfers(s, loaded(s.group.id).pairwise), [
        {'from': 'B', 'to': 'A', 'amount': 600},
      ]);
    });
  });

  group('failures', () {
    test('a failing stream shows the error; retry recovers', () async {
      final s = await Scenario.create(app, ['A']);
      app.members.watchError = StateError('boom');
      await open(s.group.id);
      expect(state(s.group.id), isA<BalancesFailure>());
      expect(vm(s.group.id).debugSnapshot()['status'], 'error');

      app.members.watchError = null;
      vm(s.group.id).retry();
      expect(state(s.group.id), isA<BalancesLoading>());
      await pumpEventQueue();
      expect(state(s.group.id), isA<BalancesLoaded>());
    });

    test('a repository error on the stream is kept as is', () async {
      final s = await Scenario.create(app, ['A']);
      app.members.watchError = const Conflict('x');
      await open(s.group.id);
      expect((state(s.group.id) as BalancesFailure).error, const Conflict('x'));
    });

    test('data the domain refuses becomes InvalidData', () async {
      final s = await Scenario.create(app, ['A', 'B']);
      await s.expense({'A': 1000}, {'B': 1000});
      // A member vanishes while an expense still refers to them.
      ok(await app.members.softDelete(s.ids['B']!));
      await open(s.group.id);
      expect(
        (state(s.group.id) as BalancesFailure).error,
        isA<InvalidData>(),
      );
    });
  });

  group('load (DebugDrive)', () {
    test('returns the balances as of now', () async {
      final s = await Scenario.create(app, ['A', 'B']);
      await s.expense({'A': 1000}, {'A': 500, 'B': 500});
      final r = ok(await vm(s.group.id).load());
      expect(byLabel(s, r), {'A': 500, 'B': -500});
    });

    test('unknown group is NotFound', () async {
      expect(err(await vm('nope').load()), const NotFound('group', 'nope'));
    });

    test('a failing repository is an Err', () async {
      final s = await Scenario.create(app, ['A']);
      app.members.watchError = StateError('boom');
      expect(err(await vm(s.group.id).load()), isA<Storage>());
      app.members.watchError = const Conflict('x');
      expect(err(await vm(s.group.id).load()), const Conflict('x'));
    });

    test('data the domain refuses is an Err', () async {
      final s = await Scenario.create(app, ['A', 'B']);
      await s.expense({'A': 1000}, {'B': 1000});
      ok(await app.members.softDelete(s.ids['B']!));
      expect(err(await vm(s.group.id).load()), isA<InvalidData>());
    });
  });

  test('snapshot of a loading and a data state', () async {
    final s = await Scenario.create(app, ['A', 'B']);
    expect(vm(s.group.id).debugSnapshot(), {
      'status': 'loading',
      'groupId': s.group.id,
    });
    await s.expense({'A': 1000}, {'B': 1000});
    await open(s.group.id);
    expect(vm(s.group.id).debugSnapshot(), {
      'status': 'data',
      'groupId': s.group.id,
      'currency': 'EUR',
      'mode': 'simplified',
      'balances': {s.ids['A']!: 1000, s.ids['B']!: -1000},
      'transfers': [
        {'from': s.ids['B'], 'to': s.ids['A'], 'amount': 1000},
      ],
    });
  });
}
