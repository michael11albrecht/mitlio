import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:test/test.dart';

String describe(Result<int, String> r) => switch (r) {
  Ok(:final value) => 'ok $value',
  Err(:final error) => 'err $error',
};

void main() {
  group('Result', () {
    test('exhaustive switch', () {
      expect(describe(const Ok(1)), 'ok 1');
      expect(describe(const Err('x')), 'err x');
    });

    test('value equality and hashCode', () {
      expect(const Ok<int, String>(1), const Ok<int, String>(1));
      expect(
        const Ok<int, String>(1).hashCode,
        const Ok<int, String>(1).hashCode,
      );
      expect(const Ok<int, String>(1) == const Ok<int, String>(2), isFalse);
      expect(const Err<int, String>('a'), const Err<int, String>('a'));
      expect(
        const Err<int, String>('a').hashCode,
        const Err<int, String>('a').hashCode,
      );
      expect(
        const Err<int, String>('a') == const Err<int, String>('b'),
        isFalse,
      );
      const Object err = Err<int, int>(1);
      expect(const Ok<int, int>(1) == err, isFalse);
      const Object ok = Ok<int, int>(1);
      expect(const Err<int, int>(1) == ok, isFalse);
    });

    test('toString', () {
      expect(const Ok<int, String>(1).toString(), 'Ok(1)');
      expect(const Err<int, String>('e').toString(), 'Err(e)');
    });
  });
}
