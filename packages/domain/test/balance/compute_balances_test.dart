import 'dart:math';

import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

final _date = DateTime.utc(2026, 1, 2);

List<Member> _abc() => [
  for (var i = 0; i < 3; i++) Member(id: 'ABC'[i], position: i),
];

Expense _expense({
  required List<Member> members,
  required int amount,
  required Map<String, int> payers,
  required SplitSpec split,
  Currency currency = Currency.eur,
  String id = 'e',
}) => (Expense.create(
  id: id,
  title: 't',
  amountCents: amount,
  currency: currency,
  date: _date,
  payers: payers,
  split: split,
  members: members,
) as Ok<Expense, ExpenseError>).value;

Settlement _settlement(
  List<Member> members,
  String from,
  String to,
  int amount, {
  Currency currency = Currency.eur,
  String id = 's',
}) => (Settlement.create(
  id: id,
  fromId: from,
  toId: to,
  amountCents: amount,
  currency: currency,
  date: _date,
  members: members,
) as Ok<Settlement, SettlementError>).value;

List<Map<String, dynamic>> _rows(Object? raw) =>
    (raw! as List).cast<Map<String, dynamic>>();

Map<String, int> _ints(Object? raw) => (raw! as Map).cast<String, int>();

/// Expenses from the doc's rows: explicit shares, amount = sum of payments.
List<Expense> _docExpensesOf(Object? raw, List<Member> m) => [
  for (final (n, x) in _rows(raw).indexed)
    _expense(
      members: m,
      id: 'e$n',
      amount: _ints(x['payers']).values.fold(0, (a, b) => a + b),
      payers: _ints(x['payers']),
      split: ExactSplit(_ints(x['shares'])),
    ),
];

/// Expenses of the first examples:balances row (members A, B, C).
List<Expense> _docExpenses(List<Member> m) =>
    _docExpensesOf(domainRulesRows('balances').first['expenses'], m);

final class Group {
  Group(this.members, this.expenses, this.settlements);
  final List<Member> members;
  final List<Expense> expenses;
  final List<Settlement> settlements;
}

extension _Gens on Any {
  /// 2..5 members, 0..5 equal-split expenses (one or two payers) and 0..3
  /// settlements, all EUR. No shrinking so mutation runs stay fast.
  Generator<Group> get group => simple(
    generate: (random, size) {
      final n = random.nextIntInRange(2, 6);
      final members = [
        for (var i = 0; i < n; i++) Member(id: 'm$i', position: i),
      ];
      final ids = [for (final m in members) m.id];
      final expenses = <Expense>[];
      final count = random.nextIntInRange(0, 6);
      for (var i = 0; i < count; i++) {
        final amount = random.nextIntInRange(1, 1000000);
        final participants = (ids.toList()..shuffle(random))
            .take(random.nextIntInRange(1, n + 1))
            .toSet();
        final p1 = ids[random.nextInt(n)];
        final p2 = ids[random.nextInt(n)];
        final payers = p1 == p2 || amount < 2
            ? {p1: amount}
            : {p1: amount ~/ 2, p2: amount - amount ~/ 2};
        expenses.add(
          _expense(
            members: members,
            amount: amount,
            payers: payers,
            split: EqualSplit(participants),
            id: 'e$i',
          ),
        );
      }
      final settlements = <Settlement>[];
      final sc = random.nextIntInRange(0, 4);
      for (var i = 0; i < sc; i++) {
        final from = random.nextInt(n);
        final to = (from + random.nextIntInRange(1, n)) % n;
        settlements.add(
          _settlement(
            members,
            ids[from],
            ids[to],
            random.nextIntInRange(1, 100000),
            id: 's$i',
          ),
        );
      }
      return Group(members, expenses, settlements);
    },
    shrink: (_) => const [],
  );
}

Map<String, int> _balances(Group g) => computeBalances(
  members: g.members,
  expenses: g.expenses,
  settlements: g.settlements,
);

void main() {
  group('computeBalances examples', () {
    for (final (i, e) in domainRulesRows('balances').indexed) {
      test('docs example ${i + 1}', () {
        final m = [
          for (final (p, id) in (e['members'] as List).cast<String>().indexed)
            Member(id: id, position: p),
        ];
        final expenses = _docExpensesOf(e['expenses'], m);
        final settlements = [
          for (final (n, s) in _rows(e['settlements']).indexed)
            _settlement(
              m,
              s['from'] as String,
              s['to'] as String,
              s['amount'] as int,
              id: 's$n',
            ),
        ];
        expect(
          computeBalances(
            members: m,
            expenses: expenses,
            settlements: settlements,
          ),
          (e['balances'] as Map).cast<String, int>(),
        );
      });
    }
  });

  group('computeBalances edge cases', () {
    test('no expenses and no settlements: all zero', () {
      expect(
        computeBalances(
          members: _abc(),
          expenses: const [],
          settlements: const [],
        ),
        {'A': 0, 'B': 0, 'C': 0},
      );
    });

    test('no members: empty map', () {
      expect(
        computeBalances(
          members: const [],
          expenses: const [],
          settlements: const [],
        ),
        isEmpty,
      );
    });

    test('member without activity is 0', () {
      final m = _abc();
      final e = _expense(
        members: m,
        amount: 1000,
        payers: {'A': 1000},
        split: EqualSplit({'A', 'B'}),
      );
      expect(
        computeBalances(members: m, expenses: [e], settlements: const []),
        {'A': 500, 'B': -500, 'C': 0},
      );
    });

    test('result is unmodifiable', () {
      final r = computeBalances(
        members: _abc(),
        expenses: const [],
        settlements: const [],
      );
      expect(() => r['A'] = 1, throwsUnsupportedError);
    });

    test('mixed currencies across expenses throw ArgumentError', () {
      final m = _abc();
      final eur = _expense(
        members: m,
        amount: 100,
        payers: {'A': 100},
        split: EqualSplit({'A', 'B'}),
      );
      final usd = _expense(
        members: m,
        amount: 100,
        payers: {'A': 100},
        split: EqualSplit({'A', 'B'}),
        currency: Currency.usd,
      );
      expect(
        () => computeBalances(
          members: m,
          expenses: [eur, usd],
          settlements: const [],
        ),
        throwsArgumentError,
      );
    });

    test('settlement currency differing from expense throws', () {
      final m = _abc();
      expect(
        () => computeBalances(
          members: m,
          expenses: _docExpenses(m),
          settlements: [_settlement(m, 'C', 'A', 10, currency: Currency.usd)],
        ),
        throwsArgumentError,
      );
    });

    test('a single non-default currency is fine', () {
      final m = _abc();
      final jpy = _expense(
        members: m,
        amount: 100,
        payers: {'A': 100},
        split: EqualSplit({'A', 'B'}),
        currency: Currency.jpy,
      );
      expect(
        computeBalances(
          members: m,
          expenses: [jpy],
          settlements: [_settlement(m, 'B', 'A', 50, currency: Currency.jpy)],
        ),
        {'A': 0, 'B': 0, 'C': 0},
      );
    });

    test('expense member unknown to members throws ArgumentError', () {
      final m = _abc();
      final e = _expense(
        members: m,
        amount: 100,
        payers: {'A': 100},
        split: EqualSplit({'A', 'B'}),
      );
      expect(
        () => computeBalances(
          members: [m[0], m[2]],
          expenses: [e],
          settlements: const [],
        ),
        throwsArgumentError,
      );
    });

    test('unknown payer id throws ArgumentError', () {
      final m = _abc();
      final e = _expense(
        members: m,
        amount: 100,
        payers: {'C': 100},
        split: EqualSplit({'A', 'B'}),
      );
      expect(
        () => computeBalances(
          members: [m[0], m[1]],
          expenses: [e],
          settlements: const [],
        ),
        throwsArgumentError,
      );
    });

    test('unknown settlement id throws ArgumentError', () {
      final m = _abc();
      expect(
        () => computeBalances(
          members: [m[0], m[1]],
          expenses: const [],
          settlements: [_settlement(m, 'A', 'C', 10)],
        ),
        throwsArgumentError,
      );
    });

    test('unknown id error names the id', () {
      final m = _abc();
      final e = _expense(
        members: m,
        amount: 100,
        payers: {'C': 100},
        split: EqualSplit({'A', 'B'}),
      );
      expect(
        () => computeBalances(
          members: [m[0], m[1]],
          expenses: [e],
          settlements: const [],
        ),
        throwsA(
          isA<ArgumentError>()
              .having((x) => x.name, 'name', 'id')
              .having((x) => x.invalidValue, 'invalidValue', 'C')
              .having((x) => x.message, 'message', 'unknown member'),
        ),
      );
    });

    test('balance beyond maxAbsCents throws MoneyOverflow', () {
      final m = _abc();
      const half = 600000000000000;
      final e = [
        for (var i = 0; i < 2; i++)
          _expense(
            members: m,
            amount: half,
            payers: {'A': half},
            split: ExactSplit({'B': half}),
            id: 'e$i',
          ),
      ];
      expect(
        () => computeBalances(members: m, expenses: e, settlements: const []),
        throwsA(isA<MoneyOverflow>()),
      );
    });

    test('balance exactly maxAbsCents is allowed', () {
      final m = _abc();
      const max = Money.maxAbsCents;
      final e = _expense(
        members: m,
        amount: max,
        payers: {'A': max},
        split: ExactSplit({'B': max}),
      );
      expect(
        computeBalances(members: m, expenses: [e], settlements: const []),
        {'A': max, 'B': -max, 'C': 0},
      );
    });

    test('accepts lazy iterables', () {
      final m = _abc();
      expect(
        computeBalances(
          members: m,
          expenses: _docExpenses(m).map((e) => e),
          settlements: const <Settlement>[].map((s) => s),
        ),
        {'A': 1700, 'B': -700, 'C': -1000},
      );
    });
  });

  group('computeBalances properties', () {
    Glados(any.group).test('every member is a key and sum is zero', (g) {
      final b = _balances(g);
      expect(b.keys.toSet(), {for (final m in g.members) m.id});
      expect(b.values.fold(0, (a, c) => a + c), 0);
    });

    Glados(any.group).test('settling a debt reduces both balances', (g) {
      final b = _balances(g);
      final debtors = b.entries.where((e) => e.value < 0).toList();
      final creditors = b.entries.where((e) => e.value > 0).toList();
      if (debtors.isEmpty || creditors.isEmpty) return;
      final d = debtors.first;
      final c = creditors.first;
      final amount = min(-d.value, c.value);
      final after = computeBalances(
        members: g.members,
        expenses: g.expenses,
        settlements: [
          ...g.settlements,
          _settlement(g.members, d.key, c.key, amount, id: 'extra'),
        ],
      );
      expect(after[d.key]!.abs(), d.value.abs() - amount);
      expect(after[c.key]!.abs(), c.value.abs() - amount);
      for (final id in b.keys.where((k) => k != d.key && k != c.key)) {
        expect(after[id], b[id]);
      }
    });

    Glados(any.group).test('settle-up via simplifyDebts zeroes balances', (g) {
      final transfers = simplifyDebts(_balances(g), g.members);
      final settled = computeBalances(
        members: g.members,
        expenses: g.expenses,
        settlements: [
          ...g.settlements,
          for (var i = 0; i < transfers.length; i++)
            _settlement(
              g.members,
              transfers[i].fromId,
              transfers[i].toId,
              transfers[i].amountCents,
              id: 'x$i',
            ),
        ],
      );
      expect(settled.values.every((v) => v == 0), isTrue);
    });

    Glados2(any.group, any.int).test('order of expenses does not matter', (
      g,
      seed,
    ) {
      final shuffled = g.expenses.toList()..shuffle(Random(seed));
      expect(
        computeBalances(
          members: g.members,
          expenses: shuffled,
          settlements: g.settlements.reversed.toList(),
        ),
        _balances(g),
      );
    });
  });
}
