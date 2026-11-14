import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

const _members = [
  Member(id: 'A', position: 0),
  Member(id: 'B', position: 1),
  Member(id: 'C', position: 2),
];
final _date = DateTime.utc(2026, 1, 2);

Result<Expense, ExpenseError> _create({
  String title = 'Dinner',
  int amount = 1000,
  Map<String, int> payers = const {'A': 1000},
  SplitSpec? split,
  List<Member> members = _members,
}) => Expense.create(
  id: 'e1',
  title: title,
  amountCents: amount,
  currency: Currency.eur,
  date: _date,
  payers: payers,
  split: split ?? EqualSplit({'A', 'B', 'C'}),
  members: members,
);

ExpenseError _err(Result<Expense, ExpenseError> r) =>
    (r as Err<Expense, ExpenseError>).error;
Expense _ok(Result<Expense, ExpenseError> r) =>
    (r as Ok<Expense, ExpenseError>).value;

/// No shrinking, so mutation runs stay fast.
extension _Gens on Any {
  Generator<int> get amount => simple(
    generate: (random, size) => random.nextIntInRange(1, 1000000),
    shrink: (_) => const [],
  );

  /// Seed for deriving a payer split of the amount.
  Generator<int> get seed => simple(
    generate: (random, size) => random.nextIntInRange(0, 1 << 30),
    shrink: (_) => const [],
  );
}

void main() {
  group('Expense examples', () {
    test('valid single payer', () {
      final e = _ok(_create());
      expect(e.id, 'e1');
      expect(e.title, 'Dinner');
      expect(e.amountCents, 1000);
      expect(e.currency, Currency.eur);
      expect(e.date, _date);
      expect(e.payers, {'A': 1000});
      expect(e.shares, {'A': 334, 'B': 333, 'C': 333});
    });

    test('multi payer', () {
      final e = _ok(_create(payers: {'A': 600, 'C': 400}));
      expect(e.payers, {'A': 600, 'C': 400});
      expect(e.shares.values.fold<int>(0, (a, b) => a + b), 1000);
    });

    test('title is trimmed', () {
      expect(_ok(_create(title: '  Pizza \n')).title, 'Pizza');
    });

    test('shares cover every member', () {
      final e = _ok(_create(split: EqualSplit({'A', 'C'})));
      expect(e.shares, {'A': 500, 'B': 0, 'C': 500});
    });

    test('toString names the expense', () {
      expect(_ok(_create()).toString(), 'Expense(e1, Dinner, 1000 EUR)');
    });
  });

  group('Expense errors', () {
    test('EmptyTitle', () {
      expect(_err(_create(title: '')), const EmptyTitle());
      expect(_err(_create(title: ' \t\n ')), const EmptyTitle());
    });

    test('InvalidSplit wraps the split error', () {
      expect(_err(_create(amount: 0)), const InvalidSplit(AmountNotPositive()));
      expect(
        _err(_create(split: EqualSplit({'A', 'X'}))),
        const InvalidSplit(UnknownMember('X')),
      );
      expect(
        _err(_create(split: ExactSplit({'A': 600, 'B': 300}))),
        const InvalidSplit(ExactMismatch(900, 1000)),
      );
    });

    test('NoPayer', () {
      expect(_err(_create(payers: {})), const NoPayer());
    });

    test('PayerNotMember', () {
      expect(
        _err(_create(payers: {'X': 1000})),
        const PayerNotMember('X'),
      );
    });

    test('NonPositivePayment', () {
      expect(
        _err(_create(payers: {'A': 1000, 'B': 0})),
        const NonPositivePayment('B'),
      );
      expect(
        _err(_create(payers: {'A': 1100, 'B': -100})),
        const NonPositivePayment('B'),
      );
    });

    test('PayersMismatch', () {
      expect(
        _err(_create(payers: {'A': 600, 'B': 300})),
        const PayersMismatch(900, 1000),
      );
      expect(
        _err(_create(payers: {'A': 1001})),
        const PayersMismatch(1001, 1000),
      );
      final e = _err(_create(payers: {'A': 600, 'B': 300})) as PayersMismatch;
      expect(e.sum, 900);
      expect(e.expected, 1000);
    });
  });

  group('Expense check order', () {
    test('title before split', () {
      expect(
        _err(_create(title: ' ', amount: 0, payers: {})),
        const EmptyTitle(),
      );
    });

    test('split before payers', () {
      expect(
        _err(_create(amount: -5, payers: {})),
        const InvalidSplit(AmountNotPositive()),
      );
    });

    test('NoPayer before everything in payers', () {
      expect(_err(_create(payers: {})), const NoPayer());
    });

    test('PayerNotMember before NonPositivePayment', () {
      expect(
        _err(_create(payers: {'A': 0, 'X': 1000})),
        const PayerNotMember('X'),
      );
    });

    test('NonPositivePayment before PayersMismatch', () {
      expect(
        _err(_create(payers: {'A': 5, 'B': 0})),
        const NonPositivePayment('B'),
      );
    });

    test('smallest unknown payer id wins', () {
      expect(
        _err(_create(payers: {'Z': 1, 'X': 1, 'Y': 1})),
        const PayerNotMember('X'),
      );
    });

    test('non-positive payer first in tieOrder wins, not by id', () {
      final members = [
        const Member(id: 'a', position: 2),
        const Member(id: 'z', position: 0),
      ];
      expect(
        _err(
          _create(
            members: members,
            split: EqualSplit({'a', 'z'}),
            payers: {'a': 0, 'z': -1},
          ),
        ),
        const NonPositivePayment('z'),
      );
    });
  });

  group('Expense value semantics', () {
    test('equality and hashCode', () {
      final a = _ok(_create(payers: {'A': 600, 'B': 400}));
      final b = _ok(_create(payers: {'B': 400, 'A': 600}));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality per field', () {
      final base = _ok(_create());
      expect(base == _ok(_create(title: 'Other')), isFalse);
      expect(base == _ok(_create(payers: {'B': 1000})), isFalse);
      expect(
        base == _ok(_create(split: EqualSplit({'A', 'B'}))),
        isFalse,
      );
      expect(
        base ==
            _ok(
              Expense.create(
                id: 'e2',
                title: 'Dinner',
                amountCents: 1000,
                currency: Currency.eur,
                date: _date,
                payers: {'A': 1000},
                split: EqualSplit({'A', 'B', 'C'}),
                members: _members,
              ),
            ),
        isFalse,
      );
      expect(
        base ==
            _ok(
              Expense.create(
                id: 'e1',
                title: 'Dinner',
                amountCents: 1000,
                currency: Currency.usd,
                date: _date,
                payers: {'A': 1000},
                split: EqualSplit({'A', 'B', 'C'}),
                members: _members,
              ),
            ),
        isFalse,
      );
      expect(
        base ==
            _ok(
              Expense.create(
                id: 'e1',
                title: 'Dinner',
                amountCents: 1000,
                currency: Currency.eur,
                date: DateTime.utc(2027),
                payers: {'A': 1000},
                split: EqualSplit({'A', 'B', 'C'}),
                members: _members,
              ),
            ),
        isFalse,
      );
      // ignore: unrelated_type_equality_checks, intentional comparison with a non-Expense
      expect(base == 5, isFalse);
    });

    test('maps are unmodifiable', () {
      final e = _ok(_create());
      expect(() => e.payers['B'] = 1, throwsUnsupportedError);
      expect(() => e.shares['A'] = 1, throwsUnsupportedError);
    });

    test('mutating the input map afterwards does not affect the expense', () {
      final input = {'A': 1000};
      final e = _ok(_create(payers: input));
      input['A'] = 1;
      input['B'] = 2;
      expect(e.payers, {'A': 1000});
    });
  });

  group('Expense properties', () {
    Glados2(any.amount, any.seed).test(
      'payers sum == shares sum == amount',
      (amount, seed) {
        // Split the amount into up to three positive payments.
        final first = 1 + seed % amount;
        final rest = amount - first;
        final second = rest == 0 ? 0 : 1 + (seed ~/ 7) % rest;
        final third = rest - second;
        final payers = <String, int>{
          'A': first,
          if (second > 0) 'B': second,
          if (third > 0) 'C': third,
        };
        final e = _ok(_create(amount: amount, payers: payers));
        int sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);
        expect(sum(e.payers), amount);
        expect(sum(e.shares), amount);
        expect(e.shares.keys.toSet(), {'A', 'B', 'C'});
        expect(e.payers.values.every((v) => v > 0), isTrue);
      },
    );

    Glados2(any.amount, any.seed).test('maps are immutable', (amount, seed) {
      final e = _ok(_create(amount: amount, payers: {'A': amount}));
      expect(() => e.payers.remove('A'), throwsUnsupportedError);
      expect(e.shares.clear, throwsUnsupportedError);
    });

    Glados2(any.amount, any.seed).test('payer sum off by delta is rejected', (
      amount,
      seed,
    ) {
      final delta = 1 + seed % 100;
      expect(
        _err(_create(amount: amount, payers: {'A': amount + delta})),
        PayersMismatch(amount + delta, amount),
      );
    });
  });
}
