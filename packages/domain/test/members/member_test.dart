import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/no_shrink.dart';

extension MemberAny on Any {
  /// Small position and id ranges to provoke ties.
  Generator<Member> get member => any.combine2(
    any.intNoShrink(0, 4),
    any.intNoShrink(0, 6),
    (pos, id) => Member(id: 'm$id', position: pos),
  );
}

void main() {
  group('Member', () {
    test('equality, hashCode, toString', () {
      const a = Member(id: 'a', position: 1);
      expect(a, const Member(id: 'a', position: 1));
      expect(a.hashCode, const Member(id: 'a', position: 1).hashCode);
      expect(a == const Member(id: 'b', position: 1), isFalse);
      expect(a == const Member(id: 'a', position: 2), isFalse);
      // ignore: unrelated_type_equality_checks, intentional comparison with a non-Member
      expect(a == 'a', isFalse);
      expect(a.toString(), 'Member(a, 1)');
    });
  });

  group('tieOrder examples', () {
    test('doc example: position then id', () {
      const x = Member(id: 'b', position: 1);
      const y = Member(id: 'z', position: 0);
      const z = Member(id: 'a', position: 0);
      expect(tieOrder([x, y, z]), [z, y, x]);
    });

    test('empty and single', () {
      expect(tieOrder(const []), isEmpty);
      const a = Member(id: 'a', position: 0);
      expect(tieOrder([a]), [a]);
    });

    test('does not mutate input and accepts any Iterable', () {
      const a = Member(id: 'a', position: 1);
      const b = Member(id: 'b', position: 0);
      final input = [a, b];
      expect(tieOrder(input), [b, a]);
      expect(input, [a, b]);
      expect(tieOrder({a, b}), [b, a]);
    });

    test('negative positions sort first', () {
      const a = Member(id: 'a', position: 0);
      const b = Member(id: 'b', position: -1);
      expect(tieOrder([a, b]), [b, a]);
    });
  });

  group('tieOrder properties', () {
    Glados(any.list(any.member)).test('is a permutation', (ms) {
      final out = tieOrder(ms);
      expect(out.length, ms.length);
      String key(Member m) => '${m.position}/${m.id}';
      expect(
        out.map(key).toList()..sort(),
        equals(ms.map(key).toList()..sort()),
      );
    });

    Glados(any.list(any.member)).test('is sorted by position then id', (ms) {
      final out = tieOrder(ms);
      for (var i = 1; i < out.length; i++) {
        final p = out[i - 1];
        final q = out[i];
        final ok =
            p.position < q.position ||
            (p.position == q.position && p.id.compareTo(q.id) <= 0);
        expect(ok, equals(true));
      }
    });

    Glados(any.list(any.member)).test('deterministic and idempotent', (ms) {
      expect(tieOrder(ms), equals(tieOrder(ms)));
      expect(tieOrder(tieOrder(ms)), equals(tieOrder(ms)));
    });

    Glados(any.list(any.member)).test('independent of input order', (ms) {
      expect(tieOrder(ms.reversed), equals(tieOrder(ms)));
    });
  });
}
