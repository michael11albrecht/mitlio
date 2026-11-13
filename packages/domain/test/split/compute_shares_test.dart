import 'dart:convert';

import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

// Verbatim from docs/domain-rules.md (examples:split).
const _examplesJson = '''
[
  {"amount": 1000, "spec": {"equal": ["A", "B", "C"]},                   "shares": {"A": 334, "B": 333, "C": 333}},
  {"amount": 1000, "spec": {"equal": ["A", "C"]},                        "shares": {"A": 500, "B": 0, "C": 500}},
  {"amount": 1000, "spec": {"shares": {"A": 2, "B": 1, "C": 1}},         "shares": {"A": 500, "B": 250, "C": 250}},
  {"amount": 1000, "spec": {"shares": {"A": 1, "B": 0, "C": 1}},         "shares": {"A": 500, "B": 0, "C": 500}},
  {"amount": 1000, "spec": {"percent": {"A": 5000, "B": 2500, "C": 2500}}, "shares": {"A": 500, "B": 250, "C": 250}},
  {"amount": 1001, "spec": {"percent": {"A": 3333, "B": 3333, "C": 3334}}, "shares": {"A": 334, "B": 333, "C": 334}},
  {"amount": 1000, "spec": {"exact": {"A": 600, "B": 400}},              "shares": {"A": 600, "B": 400, "C": 0}},
  {"amount": 1000, "spec": {"exact": {"A": 600, "B": 300}},              "error": "ExactMismatch"},
  {"amount": 1000, "spec": {"percent": {"A": 5000, "B": 4000}},          "error": "PercentNotFull"},
  {"amount": 1000, "spec": {"equal": []},                                "error": "NoParticipants"},
  {"amount": 1000, "spec": {"equal": ["A", "X"]},                        "error": "UnknownMember"},
  {"amount": 0,    "spec": {"equal": ["A", "B"]},                        "error": "AmountNotPositive"}
]
''';

const _maxCents = 999999999999999;

const _abc = [
  Member(id: 'A', position: 0),
  Member(id: 'B', position: 1),
  Member(id: 'C', position: 2),
];

SplitSpec _parseSpec(Map<String, dynamic> json) {
  final kind = json.keys.single;
  final value = json[kind];
  return switch (kind) {
    'equal' => EqualSplit((value as List).cast<String>().toSet()),
    'shares' => SharesSplit((value as Map).cast<String, int>()),
    'percent' => PercentSplit((value as Map).cast<String, int>()),
    'exact' => ExactSplit((value as Map).cast<String, int>()),
    _ => throw ArgumentError(kind),
  };
}

Map<String, int> _ok(Result<Map<String, int>, SplitError> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('unexpected $error'),
};

SplitError _err(Result<Map<String, int>, SplitError> r) => switch (r) {
  Err(:final error) => error,
  Ok(:final value) => throw StateError('unexpected $value'),
};

Result<Map<String, int>, SplitError> _run(
  int amount,
  SplitSpec spec, [
  List<Member> members = _abc,
]) => computeShares(amountCents: amount, spec: spec, members: members);

int _sum(Iterable<int> xs) => xs.fold(0, (a, b) => a + b);

// A valid scenario: members m0..mN-1 and weights with sum > 0.
class _Scenario {
  _Scenario(this.amount, this.weights);

  final int amount;
  final List<int> weights;

  List<Member> get members => [
    for (var i = 0; i < weights.length; i++) Member(id: 'm$i', position: i % 3),
  ];

  Map<String, int> get weightMap => {
    for (var i = 0; i < weights.length; i++) 'm$i': weights[i],
  };

  Set<String> get participants => {
    for (var i = 0; i < weights.length; i++)
      if (weights[i] > 0) 'm$i',
  };

  List<SplitSpec> get specs {
    final bp = allocate(10000, weights);
    final exact = allocate(amount, weights);
    return [
      EqualSplit(participants),
      SharesSplit(weightMap),
      PercentSplit({for (var i = 0; i < bp.length; i++) 'm$i': bp[i]}),
      ExactSplit({for (var i = 0; i < exact.length; i++) 'm$i': exact[i]}),
    ];
  }

  @override
  String toString() => '_Scenario($amount, $weights)';
}

extension _Gens on Any {
  Generator<_Scenario> get scenario => combine2(
    intInRange(1, 1000000),
    nonEmptyList(intInRange(0, 30)),
    (amount, ws) => _Scenario(amount, _sum(ws) == 0 ? [1, ...ws.skip(1)] : ws),
  );
}

void main() {
  group('examples', () {
    final examples = (jsonDecode(_examplesJson) as List)
        .cast<Map<String, dynamic>>();
    for (final e in examples) {
      final amount = e['amount'] as int;
      final spec = _parseSpec(e['spec'] as Map<String, dynamic>);
      test('$amount ${e['spec']}', () {
        final result = _run(amount, spec);
        if (e.containsKey('shares')) {
          expect(_ok(result), (e['shares'] as Map).cast<String, int>());
        } else {
          expect(_err(result).runtimeType.toString(), e['error']);
        }
      });
    }

    test('tie order: position, then id', () {
      const members = [
        Member(id: 'b', position: 1), // X
        Member(id: 'z', position: 0), // Y
        Member(id: 'a', position: 0), // Z
      ];
      final shares = _ok(_run(100, EqualSplit({'a', 'z', 'b'}), members));
      expect(shares, {'a': 34, 'z': 33, 'b': 33});
    });
  });

  group('errors carry details', () {
    test('UnknownMember reports the id', () {
      expect(_err(_run(10, EqualSplit({'X'}))), const UnknownMember('X'));
    });

    test('NegativeValue reports the id', () {
      expect(
        _err(_run(10, SharesSplit({'A': 2, 'B': -1}))),
        const NegativeValue('B'),
      );
      expect(
        _err(_run(10, PercentSplit({'A': 10001, 'C': -1}))),
        const NegativeValue('C'),
      );
      expect(
        _err(_run(10, ExactSplit({'A': 11, 'B': -1}))),
        const NegativeValue('B'),
      );
    });

    test('PercentNotFull reports the sum (10001 and 9999)', () {
      expect(
        _err(_run(10, PercentSplit({'A': 5000, 'B': 5001}))),
        const PercentNotFull(10001),
      );
      expect(
        _err(_run(10, PercentSplit({'A': 9999}))),
        const PercentNotFull(9999),
      );
    });

    test('ExactMismatch reports sum and expected', () {
      expect(
        _err(_run(1000, ExactSplit({'A': 600, 'B': 300}))),
        const ExactMismatch(900, 1000),
      );
      expect(
        _err(_run(1000, ExactSplit({'A': 600, 'B': 500}))),
        const ExactMismatch(1100, 1000),
      );
    });

    test('check order: amount before unknown id', () {
      expect(
        _err(_run(0, EqualSplit({'X'}))),
        const AmountNotPositive(),
      );
      expect(
        _err(_run(-5, EqualSplit({'A'}))),
        const AmountNotPositive(),
      );
    });

    test('check order: unknown id before negative value', () {
      expect(
        _err(_run(10, SharesSplit({'A': -1, 'X': 1}))),
        const UnknownMember('X'),
      );
    });

    test('check order: negative value before sum check', () {
      expect(
        _err(_run(10, PercentSplit({'A': -1, 'B': 5}))),
        const NegativeValue('A'),
      );
    });

    test('check order: sum check before participants', () {
      expect(
        _err(_run(10, ExactSplit({'A': 0}))),
        const ExactMismatch(0, 10),
      );
      expect(
        _err(_run(10, PercentSplit({}))),
        const PercentNotFull(0),
      );
    });

    test('error choice is independent of map order', () {
      expect(
        _err(_run(10, SharesSplit({'Y': 1, 'X': 1}))),
        const UnknownMember('X'),
      );
      expect(
        _err(_run(10, SharesSplit({'C': -1, 'B': -1}))),
        const NegativeValue('B'),
      );
    });

    test('all shares zero is NoParticipants', () {
      expect(
        _err(_run(10, SharesSplit({'A': 0, 'B': 0}))),
        const NoParticipants(),
      );
      expect(_err(_run(10, SharesSplit({}))), const NoParticipants());
    });

    test('no members at all', () {
      expect(
        _err(_run(10, EqualSplit({'A'}), const [])),
        const UnknownMember('A'),
      );
      expect(
        _err(_run(10, EqualSplit({}), const [])),
        const NoParticipants(),
      );
    });
  });

  group('edge cases', () {
    test('1 cent goes to the first participant in tie order', () {
      expect(_ok(_run(1, EqualSplit({'A', 'B', 'C'}))), {
        'A': 1,
        'B': 0,
        'C': 0,
      });
      expect(_ok(_run(1, EqualSplit({'B', 'C'}))), {
        'A': 0,
        'B': 1,
        'C': 0,
      });
    });

    test('single member takes everything', () {
      const one = [Member(id: 'solo', position: 0)];
      expect(_ok(_run(777, EqualSplit({'solo'}), one)), {'solo': 777});
      expect(_ok(_run(777, ExactSplit({'solo': 777}), one)), {
        'solo': 777,
      });
    });

    test('all members excluded', () {
      expect(
        _err(_run(10, SharesSplit({'A': 0, 'B': 0, 'C': 0}))),
        const NoParticipants(),
      );
    });

    test('percent sum 10001 and 9999 rejected', () {
      expect(
        _err(_run(100, PercentSplit({'A': 5000, 'B': 5001}))),
        isA<PercentNotFull>(),
      );
      expect(
        _err(_run(100, PercentSplit({'A': 5000, 'B': 4999}))),
        isA<PercentNotFull>(),
      );
    });

    test('huge amounts stay exact', () {
      final shares = _ok(_run(_maxCents, EqualSplit({'A', 'B', 'C'})));
      expect(shares, {
        'A': 333333333333333,
        'B': 333333333333333,
        'C': 333333333333333,
      });
      final pct = _ok(
        _run(_maxCents, PercentSplit({'A': 3333, 'B': 3333, 'C': 3334})),
      );
      expect(_sum(pct.values), _maxCents);
    });

    test('huge share weights do not overflow', () {
      const w = 4611686018427387904; // 2^62
      final shares = _ok(_run(10, SharesSplit({'A': w, 'B': w, 'C': w})));
      expect(shares, {'A': 4, 'B': 3, 'C': 3});
    });

    test('huge exact values summing past 2^63 are a mismatch, not a wrap', () {
      const big = 9223372036854775807;
      expect(
        _err(_run(10, ExactSplit({'A': big, 'B': big}))),
        isA<ExactMismatch>(),
      );
    });

    test('duplicate member ids are collapsed (first in tie order wins)', () {
      const dup = [
        Member(id: 'A', position: 0),
        Member(id: 'A', position: 1),
        Member(id: 'B', position: 2),
      ];
      expect(_ok(_run(3, EqualSplit({'A', 'B'}), dup)), {
        'A': 2,
        'B': 1,
      });
    });

    test('members not mentioned participate with 0', () {
      expect(_ok(_run(10, SharesSplit({'B': 1}))), {
        'A': 0,
        'B': 10,
        'C': 0,
      });
    });

    test('exact allows explicit zero entries', () {
      expect(_ok(_run(10, ExactSplit({'A': 10, 'B': 0}))), {
        'A': 10,
        'B': 0,
        'C': 0,
      });
    });
  });

  group('immutability', () {
    test('mutating the input collection does not change the spec', () {
      final set = {'A', 'B'};
      final map = {'A': 1, 'B': 1};
      final specs = [
        EqualSplit(set),
        SharesSplit(map),
        PercentSplit(map),
        ExactSplit(map),
      ];
      final hashes = specs.map((s) => s.hashCode).toList();
      set.add('C');
      map['C'] = 5;
      expect(EqualSplit(set), isNot(specs[0]));
      expect(specs[0], EqualSplit({'A', 'B'}));
      expect(specs[1], SharesSplit({'A': 1, 'B': 1}));
      expect(specs[2], PercentSplit({'A': 1, 'B': 1}));
      expect(specs[3], ExactSplit({'A': 1, 'B': 1}));
      expect(specs.map((s) => s.hashCode).toList(), hashes);
    });

    test('exposed collections are unmodifiable', () {
      expect(
        () => EqualSplit({'A'}).participants.add('B'),
        throwsUnsupportedError,
      );
      expect(
        () => SharesSplit({'A': 1}).weights['B'] = 1,
        throwsUnsupportedError,
      );
      expect(
        () => PercentSplit({'A': 1}).basisPoints['B'] = 1,
        throwsUnsupportedError,
      );
      expect(
        () => ExactSplit({'A': 1}).cents['B'] = 1,
        throwsUnsupportedError,
      );
    });
  });

  group('value equality', () {
    test('specs', () {
      expect(EqualSplit({'A', 'B'}), EqualSplit({'B', 'A'}));
      expect(
        EqualSplit({'A', 'B'}).hashCode,
        EqualSplit({'B', 'A'}).hashCode,
      );
      expect(EqualSplit({'A'}), isNot(EqualSplit({'B'})));
      expect(EqualSplit({'A'}), isNot(EqualSplit({'A', 'B'})));
      expect(
        SharesSplit({'A': 1, 'B': 2}),
        SharesSplit({'B': 2, 'A': 1}),
      );
      expect(
        SharesSplit({'A': 1, 'B': 2}).hashCode,
        SharesSplit({'B': 2, 'A': 1}).hashCode,
      );
      expect(SharesSplit({'A': 1}), isNot(SharesSplit({'A': 2})));
      expect(SharesSplit({'A': 1}), isNot(SharesSplit({'B': 1})));
      expect(
        SharesSplit({'A': 1}),
        isNot(SharesSplit({'A': 1, 'B': 1})),
      );
      expect(PercentSplit({'A': 1}), PercentSplit({'A': 1}));
      expect(
        PercentSplit({'A': 1}).hashCode,
        PercentSplit({'A': 1}).hashCode,
      );
      expect(PercentSplit({'A': 1}), isNot(PercentSplit({'A': 2})));
      expect(ExactSplit({'A': 1}), ExactSplit({'A': 1}));
      expect(
        ExactSplit({'A': 1}).hashCode,
        ExactSplit({'A': 1}).hashCode,
      );
      expect(ExactSplit({'A': 1}), isNot(ExactSplit({'A': 2})));
      expect(SharesSplit({'A': 1}), isNot(ExactSplit({'A': 1})));
      expect(SharesSplit({'A': 1}), isNot(PercentSplit({'A': 1})));
      expect(PercentSplit({'A': 1}), isNot(ExactSplit({'A': 1})));
    });

    test('errors', () {
      const errors = <SplitError>[
        AmountNotPositive(),
        NoParticipants(),
        UnknownMember('A'),
        NegativeValue('A'),
        PercentNotFull(1),
        ExactMismatch(1, 2),
      ];
      for (final e in errors) {
        expect(e, same(e));
      }
      expect(const AmountNotPositive(), const AmountNotPositive());
      expect(
        const AmountNotPositive().hashCode,
        const AmountNotPositive().hashCode,
      );
      expect(const NoParticipants(), const NoParticipants());
      expect(const NoParticipants().hashCode, const NoParticipants().hashCode);
      expect(const NoParticipants(), isNot(const AmountNotPositive()));
      expect(const UnknownMember('A'), const UnknownMember('A'));
      expect(
        const UnknownMember('A').hashCode,
        const UnknownMember('A').hashCode,
      );
      expect(const UnknownMember('A'), isNot(const UnknownMember('B')));
      expect(const UnknownMember('A'), isNot(const NegativeValue('A')));
      expect(const NegativeValue('A'), const NegativeValue('A'));
      expect(
        const NegativeValue('A').hashCode,
        const NegativeValue('A').hashCode,
      );
      expect(const NegativeValue('A'), isNot(const NegativeValue('B')));
      expect(const PercentNotFull(1), const PercentNotFull(1));
      expect(
        const PercentNotFull(1).hashCode,
        const PercentNotFull(1).hashCode,
      );
      expect(const PercentNotFull(1), isNot(const PercentNotFull(2)));
      expect(const ExactMismatch(1, 2), const ExactMismatch(1, 2));
      expect(
        const ExactMismatch(1, 2).hashCode,
        const ExactMismatch(1, 2).hashCode,
      );
      expect(const ExactMismatch(1, 2), isNot(const ExactMismatch(2, 2)));
      expect(const ExactMismatch(1, 2), isNot(const ExactMismatch(1, 3)));
    });

    test('toString is informative', () {
      expect(EqualSplit({'A'}).toString(), contains('A'));
      expect(SharesSplit({'A': 1}).toString(), contains('SharesSplit'));
      expect(PercentSplit({'A': 1}).toString(), contains('PercentSplit'));
      expect(ExactSplit({'A': 1}).toString(), contains('ExactSplit'));
      expect(const AmountNotPositive().toString(), 'AmountNotPositive()');
      expect(const NoParticipants().toString(), 'NoParticipants()');
      expect(const UnknownMember('A').toString(), 'UnknownMember(A)');
      expect(const NegativeValue('A').toString(), 'NegativeValue(A)');
      expect(const PercentNotFull(1).toString(), 'PercentNotFull(1)');
      expect(const ExactMismatch(1, 2).toString(), 'ExactMismatch(1, 2)');
    });
  });

  group('properties', () {
    Glados(any.scenario).test('shares sum to the amount, all members keyed', (
      s,
    ) {
      for (final spec in s.specs) {
        final shares = _ok(_run(s.amount, spec, s.members));
        expect(shares.keys.toSet(), s.members.map((m) => m.id).toSet());
        expect(_sum(shares.values), s.amount);
        expect(shares.values.every((v) => v >= 0), isTrue);
      }
    });

    Glados(any.scenario).test('equal split shares differ by at most 1', (s) {
      final shares = _ok(
        _run(s.amount, EqualSplit(s.participants), s.members),
      );
      final inside = [
        for (final id in s.participants) shares[id]!,
      ];
      final spread =
          inside.reduce((a, b) => a > b ? a : b) -
          inside.reduce((a, b) => a < b ? a : b);
      expect(spread, lessThanOrEqualTo(1));
    });

    Glados(any.scenario).test('non-participants get 0', (s) {
      for (final spec in [
        EqualSplit(s.participants),
        SharesSplit(s.weightMap),
      ]) {
        final shares = _ok(_run(s.amount, spec, s.members));
        for (final m in s.members) {
          if (!s.participants.contains(m.id)) {
            expect(shares[m.id], 0);
          }
        }
      }
    });

    Glados(any.scenario).test('deterministic', (s) {
      for (final spec in s.specs) {
        expect(
          _ok(_run(s.amount, spec, s.members)),
          _ok(_run(s.amount, spec, s.members)),
        );
      }
    });

    Glados(any.scenario).test('member list order does not matter', (s) {
      final reversed = s.members.reversed.toList();
      final rotated = [...s.members.skip(1), s.members.first];
      for (final spec in s.specs) {
        final base = _ok(_run(s.amount, spec, s.members));
        expect(_ok(_run(s.amount, spec, reversed)), base);
        expect(_ok(_run(s.amount, spec, rotated)), base);
      }
    });

    Glados(any.scenario).test('exact split is returned as given', (s) {
      final exact = allocate(s.amount, s.weights);
      final spec = ExactSplit({
        for (var i = 0; i < exact.length; i++) 'm$i': exact[i],
      });
      final shares = _ok(_run(s.amount, spec, s.members));
      for (var i = 0; i < exact.length; i++) {
        expect(shares['m$i'], exact[i]);
      }
    });
  });
}
