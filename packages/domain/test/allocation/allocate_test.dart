import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';
import '../support/no_shrink.dart';

const _maxCents = 999999999999999;

int _sum(List<int> xs) => xs.fold(0, (a, b) => a + b);

/// Makes any non-negative weight list valid (sum > 0).
List<int> _valid(List<int> ws) => _sum(ws) == 0 ? [1, ...ws.skip(1)] : ws;

extension _Gens on Any {
  Generator<List<int>> get weights =>
      nonEmptyList(intNoShrink(0, 50)).map(_valid);
  Generator<int> get total => intNoShrink(0, 100000);
}

void main() {
  group('examples', () {
    for (final e in domainRulesRows('allocate')) {
      final total = e['total'] as int;
      final weights = (e['weights'] as List).cast<int>();
      final expected = (e['result'] as List).cast<int>();
      test('allocate($total, $weights) == $expected', () {
        expect(allocate(total, weights), expected);
      });
    }
  });

  group('edge cases', () {
    test('single weight gets everything', () {
      expect(allocate(12345, [7]), [12345]);
    });

    test('all-but-one zero weights', () {
      expect(allocate(99, [0, 0, 5, 0]), [0, 0, 99, 0]);
    });

    test('huge total with huge weights stays exact', () {
      final r = allocate(_maxCents, [_maxCents, _maxCents, _maxCents]);
      expect(r, [333333333333333, 333333333333333, 333333333333333]);
    });

    test('huge total, uneven huge weights', () {
      final weights = [_maxCents, 1, _maxCents ~/ 2];
      final r = allocate(_maxCents, weights);
      expect(_sum(r), _maxCents);
      expect(r[1], lessThanOrEqualTo(1));
    });

    test('weight sum beyond int64 does not wrap', () {
      expect(allocate(1, List.filled(4, 4611686018427387904)), [1, 0, 0, 0]);
    });

    test('weights near 2^53 stay exact', () {
      const w = 9007199254740991; // 2^53 - 1
      expect(allocate(_maxCents, [w, w, w]), [
        333333333333333,
        333333333333333,
        333333333333333,
      ]);
      expect(allocate(10, [w, w, w, w]), [3, 3, 2, 2]);
    });

    test('tie goes to the lower index', () {
      expect(allocate(2, [1, 1, 1]), [1, 1, 0]);
    });

    test('larger remainder beats lower index', () {
      expect(allocate(5, [3, 3, 1]), [2, 2, 1]);
    });

    test('does not mutate the input', () {
      final w = [1, 1, 1];
      allocate(10, w);
      expect(w, [1, 1, 1]);
    });
  });

  group('preconditions', () {
    test('negative total', () {
      expect(() => allocate(-1, [1]), throwsArgumentError);
    });
    test('negative weight', () {
      expect(() => allocate(10, [1, -1]), throwsArgumentError);
      expect(() => allocate(10, [-1, 2]), throwsArgumentError);
    });
    test('empty weights', () {
      expect(() => allocate(10, []), throwsArgumentError);
    });
    test('zero weight sum', () {
      expect(() => allocate(10, [0, 0]), throwsArgumentError);
    });
  });

  group('properties', () {
    Glados2(any.total, any.weights).test('sum equals total', (t, ws) {
      expect(_sum(allocate(t, ws)), t);
    });

    Glados2(any.total, any.weights).test('deterministic', (t, ws) {
      expect(allocate(t, ws), allocate(t, List.of(ws)));
    });

    Glados2(any.total, any.intNoShrink(1, 30)).test(
      'equal weights differ by at most 1',
      (t, n) {
        final r = allocate(t, List.filled(n, 1));
        final max = r.reduce((a, b) => a > b ? a : b);
        final min = r.reduce((a, b) => a < b ? a : b);
        expect(max - min, lessThanOrEqualTo(1));
      },
    );

    Glados2(any.total, any.weights).test('zero weight gets zero', (t, ws) {
      final r = allocate(t, ws);
      for (var i = 0; i < ws.length; i++) {
        if (ws[i] == 0) expect(r[i], 0);
      }
    });

    Glados2(any.total, any.weights).test(
      'each share is floor or floor+1 of the exact quota',
      (t, ws) {
        final r = allocate(t, ws);
        final w = BigInt.from(_sum(ws));
        for (var i = 0; i < ws.length; i++) {
          final floor = (BigInt.from(t) * BigInt.from(ws[i]) ~/ w).toInt();
          expect(r[i], anyOf(floor, floor + 1));
        }
      },
    );

    Glados2(any.total, any.weights).test('larger weight never gets less', (
      t,
      ws,
    ) {
      final r = allocate(t, ws);
      for (var i = 0; i < ws.length; i++) {
        for (var j = 0; j < ws.length; j++) {
          if (ws[i] > ws[j]) expect(r[i], greaterThanOrEqualTo(r[j]));
        }
      }
    });
  });
}
