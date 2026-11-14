import 'dart:math';

import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

/// Zero-sum balances over members m0..m(n-1) (n in 1..8): n-1 random ints in
/// ±100000 (about 30% zeros) and the last the negated sum. Non-shrinking to
/// keep mutation runs fast.
final class Case {
  Case(this.balances, this.seed);
  final Map<String, int> balances;
  final int seed;
}

extension SettleAny on Any {
  Generator<Case> get settleCase => simple(
    generate: (random, size) {
      final n = random.nextIntInRange(1, 9);
      final values = <int>[];
      for (var i = 0; i < n - 1; i++) {
        values.add(
          random.nextIntInRange(0, 10) < 3
              ? 0
              : random.nextIntInRange(-100000, 100001),
        );
      }
      values.add(-values.fold(0, (a, b) => a + b));
      return Case({
        for (var i = 0; i < n; i++) 'm$i': values[i],
      }, random.nextInt(1 << 30));
    },
    shrink: (_) => const [],
  );
}

List<Member> membersFor(Map<String, int> b) => [
  for (var i = 0; i < b.length; i++) Member(id: 'm$i', position: i),
];

Map<String, int> apply(Map<String, int> b, List<Transfer> ts) {
  final r = {...b};
  for (final t in ts) {
    r[t.fromId] = r[t.fromId]! + t.amountCents;
    r[t.toId] = r[t.toId]! - t.amountCents;
  }
  return r;
}

void main() {
  List<Member> abcd() => [
    for (var i = 0; i < 4; i++) Member(id: 'ABCD'[i], position: i),
  ];

  Transfer t(String f, String to, int a) =>
      Transfer(fromId: f, toId: to, amountCents: a);

  group('simplifyDebts examples', () {
    for (final (i, e) in domainRulesRows('simplify').indexed) {
      test('docs example ${i + 1}', () {
        final balances = (e['balances'] as Map).cast<String, int>();
        final members = [
          for (final (p, id) in balances.keys.indexed)
            Member(id: id, position: p),
        ];
        expect(simplifyDebts(balances, members), [
          for (final x in (e['transfers'] as List).cast<Map<String, dynamic>>())
            t(x['from'] as String, x['to'] as String, x['amount'] as int),
        ]);
      });
    }
  });

  group('simplifyDebts edge cases', () {
    test('empty map', () {
      expect(simplifyDebts({}, abcd()), isEmpty);
      expect(simplifyDebts({}, []), isEmpty);
    });

    test('single debtor many creditors', () {
      expect(
        simplifyDebts({'A': 100, 'B': 300, 'C': 200, 'D': -600}, abcd()),
        [t('D', 'B', 300), t('D', 'C', 200), t('D', 'A', 100)],
      );
    });

    test('single creditor many debtors', () {
      expect(
        simplifyDebts({'A': 600, 'B': -100, 'C': -300, 'D': -200}, abcd()),
        [t('C', 'A', 300), t('D', 'A', 200), t('B', 'A', 100)],
      );
    });

    test('ties go to earlier member in tieOrder, not map order', () {
      // Positions reverse the id order: D first, A last.
      final members = [
        for (var i = 0; i < 4; i++) Member(id: 'ABCD'[i], position: 3 - i),
      ];
      expect(
        simplifyDebts({'A': 100, 'B': 100, 'C': -100, 'D': -100}, members),
        [t('D', 'B', 100), t('C', 'A', 100)],
      );
    });

    test('equal positions fall back to id order', () {
      final members = [
        const Member(id: 'C', position: 0),
        const Member(id: 'B', position: 0),
        const Member(id: 'A', position: 0),
      ];
      expect(simplifyDebts({'A': 5, 'B': 5, 'C': -10}, members), [
        t('C', 'A', 5),
        t('C', 'B', 5),
      ]);
    });

    test('members missing from balances count as zero', () {
      expect(simplifyDebts({'A': 5, 'B': -5}, abcd()), [t('B', 'A', 5)]);
    });

    test('large values do not overflow the sum check', () {
      const big = 999999999999999;
      expect(
        simplifyDebts({'A': big, 'B': big, 'C': -big, 'D': -big}, abcd()),
        [t('C', 'A', big), t('D', 'B', big)],
      );
    });

    test('sum not zero throws', () {
      expect(() => simplifyDebts({'A': 1}, abcd()), throwsArgumentError);
      expect(
        () => simplifyDebts({'A': 1, 'B': -2}, abcd()),
        throwsArgumentError,
      );
    });

    test('argument errors carry name, value and message', () {
      Matcher argError(String name, Object? value, String message) => throwsA(
        isA<ArgumentError>()
            .having((e) => e.name, 'name', name)
            .having((e) => e.invalidValue, 'invalidValue', value)
            .having((e) => e.message, 'message', message),
      );
      expect(
        () => simplifyDebts({'A': 1, 'Z': -1}, abcd()),
        argError('balances', 'Z', 'unknown member'),
      );
      final unbalanced = {'A': 1, 'B': -2};
      expect(
        () => simplifyDebts(unbalanced, abcd()),
        argError('balances', unbalanced, 'must sum to zero'),
      );
    });

    test('unknown key throws even if sum is zero', () {
      expect(
        () => simplifyDebts({'A': 1, 'Z': -1}, abcd()),
        throwsArgumentError,
      );
    });
  });

  group('Transfer', () {
    test('value equality and hashCode', () {
      expect(t('A', 'B', 1), t('A', 'B', 1));
      expect(t('A', 'B', 1).hashCode, t('A', 'B', 1).hashCode);
      expect(t('A', 'B', 1) == t('A', 'B', 2), isFalse);
      expect(t('A', 'B', 1) == t('A', 'C', 1), isFalse);
      expect(t('A', 'B', 1) == t('C', 'B', 1), isFalse);
      // ignore: unrelated_type_equality_checks, intentional comparison with a non-Transfer
      expect(t('A', 'B', 1) == 1, isFalse);
    });

    test('toString', () {
      expect(t('A', 'B', 1).toString(), 'Transfer(A -> B, 1)');
    });

    test('rejects non-positive amounts', () {
      expect(() => t('A', 'B', 0), throwsArgumentError);
      expect(() => t('A', 'B', -1), throwsArgumentError);
      expect(
        () => t('A', 'B', -5),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'amountCents')
              .having((e) => e.invalidValue, 'invalidValue', -5)
              .having((e) => e.message, 'message', 'must be > 0'),
        ),
      );
    });
  });

  group('simplifyDebts properties', () {
    Glados(any.settleCase).test('applying transfers zeroes balances', (c) {
      final ts = simplifyDebts(c.balances, membersFor(c.balances));
      expect(apply(c.balances, ts).values.every((v) => v == 0), isTrue);
    });

    Glados(any.settleCase).test('at most n-1 transfers (n non-zero)', (c) {
      final ts = simplifyDebts(c.balances, membersFor(c.balances));
      final n = c.balances.values.where((v) => v != 0).length;
      expect(ts.length, lessThanOrEqualTo(max(0, n - 1)));
    });

    Glados(any.settleCase).test('no self or zero transfers', (c) {
      final ts = simplifyDebts(c.balances, membersFor(c.balances));
      for (final x in ts) {
        expect(x.fromId, isNot(x.toId));
        expect(x.amountCents, greaterThan(0));
      }
    });

    Glados(any.settleCase).test('deterministic', (c) {
      final m = membersFor(c.balances);
      expect(simplifyDebts(c.balances, m), simplifyDebts(c.balances, m));
    });

    Glados(any.settleCase).test('independent of map insertion order', (c) {
      final m = membersFor(c.balances);
      final keys = c.balances.keys.toList()..shuffle(Random(c.seed));
      final shuffled = {for (final k in keys) k: c.balances[k]!};
      expect(simplifyDebts(shuffled, m), simplifyDebts(c.balances, m));
    });

    Glados(any.settleCase).test('independent of member list order', (c) {
      final m = membersFor(c.balances);
      final shuffled = [...m]..shuffle(Random(c.seed));
      expect(simplifyDebts(c.balances, shuffled), simplifyDebts(c.balances, m));
    });
  });
}
