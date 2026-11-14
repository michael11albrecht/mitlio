import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/balances/ui/balances_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../helpers/fake_app.dart';
import 'balances_support.dart';

void main() {
  test('200 expenses compute in under 16 ms', () async {
    final labels = [for (var i = 0; i < 6; i++) 'M$i'];
    final s = await Scenario.create(FakeApp(), labels);
    final members = [
      for (var i = 0; i < labels.length; i++)
        Member(id: s.ids[labels[i]]!, position: i),
    ];
    final expenses = <Expense>[];
    for (var i = 0; i < 200; i++) {
      final payer = labels[i % labels.length];
      final others = labels.where((l) => l != payer).toList();
      final entry = await s.expense(
        {payer: 1000 + i},
        {
          for (final o in others) o: (1000 + i) ~/ others.length,
          payer: (1000 + i) - ((1000 + i) ~/ others.length) * others.length,
        },
      );
      expenses.add(entry.expense);
    }
    // Warm up the JIT, then take the best of a few runs: the bound is about
    // the algorithm, not about a noisy CI core.
    BalancesResult run() => computeBalancesResult(
      members: members,
      expenses: expenses,
      settlements: const [],
    );
    run();
    final times = <int>[];
    late BalancesResult result;
    for (var i = 0; i < 5; i++) {
      final watch = Stopwatch()..start();
      result = run();
      times.add(watch.elapsedMicroseconds);
    }
    times.sort();
    expect(times.first, lessThan(16000), reason: 'best of 5: $times us');
    expect(result.balances.values.fold<int>(0, (a, b) => a + b), 0);
    expect(result.simplified.length, lessThan(members.length));
  });

  test('settlements that overpay flip the direct debt', () async {
    final s = await Scenario.create(FakeApp(), ['A', 'B']);
    final e = await s.expense({'A': 1000}, {'B': 1000});
    final paid = await s.settle('B', 'A', 1500);
    final members = [
      Member(id: s.ids['A']!, position: 0),
      Member(id: s.ids['B']!, position: 1),
    ];
    final pairwise = pairwiseDebts(
      members: members,
      expenses: [e.expense],
      settlements: [paid.settlement],
    );
    expect(pairwise, [
      Transfer(fromId: s.ids['A']!, toId: s.ids['B']!, amountCents: 500),
    ]);
  });

  test('a multi-payer expense settles every share', () async {
    final s = await Scenario.create(FakeApp(), ['A', 'B', 'C']);
    final e = await s.expense(
      {'A': 600, 'B': 400},
      {'A': 0, 'B': 0, 'C': 1000},
    );
    final members = [
      for (final (i, l) in ['A', 'B', 'C'].indexed)
        Member(id: s.ids[l]!, position: i),
    ];
    final result = computeBalancesResult(
      members: members,
      expenses: [e.expense],
      settlements: const [],
    );
    expect(result.pairwise, [
      Transfer(fromId: s.ids['C']!, toId: s.ids['A']!, amountCents: 600),
      Transfer(fromId: s.ids['C']!, toId: s.ids['B']!, amountCents: 400),
    ]);
  });
}
