import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart';
import 'seed_support.dart';

/// Plan §2.6: balances plus `simplifyDebts` for 200 expenses in < 16 ms
/// (median of 20 runs). Runs by default; very slow CI runners can opt out
/// with `MITLIO_SKIP_PERF=1`.
void main() {
  const budget = Duration(milliseconds: 16);
  final skip = Platform.environment['MITLIO_SKIP_PERF'] == '1'
      ? 'MITLIO_SKIP_PERF=1 (perf budget disabled on this runner)'
      : null;

  test(
    'balances + simplifyDebts for large_200_expenses < 16 ms (median of 20)',
    () async {
      final r = await fakeRepos();
      final seeded = await seederFor(r).load('large_200_expenses');
      final groupId = seeded['groupId']! as String;
      final members = [
        for (final m in ok(await r.members.list(groupId))) m.toDomain(),
      ];
      final expenses = [
        for (final e in await r.expenses.watchExpenses(groupId).first)
          e.expense,
      ];
      expect(expenses, hasLength(200));

      List<Transfer> run() => simplifyDebts(
        computeBalances(
          members: members,
          expenses: expenses,
          settlements: const [],
        ),
        members,
      );
      for (var i = 0; i < 5; i++) {
        run(); // warm-up so JIT compilation is not measured
      }
      final micros = <int>[];
      final watch = Stopwatch();
      for (var i = 0; i < 20; i++) {
        watch
          ..reset()
          ..start();
        run();
        watch.stop();
        micros.add(watch.elapsedMicroseconds);
      }
      micros.sort();
      final median = Duration(microseconds: (micros[9] + micros[10]) ~/ 2);
      // The number goes into the PR body.
      // ignore: avoid_print, perf figure for the PR description
      print('perf: median of 20 = ${median.inMicroseconds} us');
      expect(median, lessThan(budget));
    },
    skip: skip, // env opt-out for slow runners, see #59
  );
}
