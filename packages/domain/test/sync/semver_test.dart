import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/no_shrink.dart';

SemVer _v(String s) => (SemVer.parse(s) as Ok<SemVer, SemVerInvalid>).value;

extension on Any {
  Generator<SemVer> get semver => combine3(
    intNoShrink(0, 30),
    intNoShrink(0, 30),
    intNoShrink(0, 30),
    SemVer.new,
  );
}

void main() {
  group('parse', () {
    test('plain version', () {
      final v = _v('1.22.333');
      expect([v.major, v.minor, v.patch], [1, 22, 333]);
      expect(v.toString(), '1.22.333');
    });

    test('build suffix is ignored', () {
      expect(_v('0.2.0+15'), _v('0.2.0'));
    });

    test('seed value 0.0.0', () {
      expect(_v('0.0.0'), const SemVer(0, 0, 0));
    });

    for (final bad in [
      '',
      '1',
      '1.2',
      '1.2.3.4',
      'a.b.c',
      '1.2.x',
      '-1.2.3',
      '1.2.3-beta',
      '1.2.3+',
      ' 1.2.3',
      '1.2.3 ',
      '1..3',
      '1234567890.0.0',
      '1.2.3\n',
    ]) {
      test('rejects "${bad.replaceAll('\n', r'\n')}"', () {
        expect(SemVer.parse(bad), isA<Err<SemVer, SemVerInvalid>>());
      });
    }

    test('error keeps the input', () {
      final r = SemVer.parse('nope');
      expect(
        (r as Err<SemVer, SemVerInvalid>).error,
        const SemVerInvalid('nope'),
      );
      expect(r.error.toString(), 'SemVerInvalid(nope)');
      expect(r.error.hashCode, const SemVerInvalid('nope').hashCode);
    });
  });

  group('compare', () {
    test('numeric, not textual', () {
      expect(_v('1.10.0') > _v('1.9.9'), isTrue);
      expect(_v('0.2.0') < _v('0.10.0'), isTrue);
      expect(_v('2.0.0') > _v('1.99.99'), isTrue);
      expect(_v('1.0.10') > _v('1.0.9'), isTrue);
    });

    test('equal versions', () {
      expect(_v('1.2.3') >= _v('1.2.3'), isTrue);
      expect(_v('1.2.3') <= _v('1.2.3'), isTrue);
      expect(_v('1.2.3') < _v('1.2.3'), isFalse);
      expect(_v('1.2.3') > _v('1.2.3'), isFalse);
      expect(_v('1.2.3').hashCode, _v('1.2.3').hashCode);
    });

    test('each part decides alone', () {
      expect(_v('1.2.3') < _v('2.0.0'), isTrue);
      expect(_v('1.2.3') < _v('1.3.0'), isTrue);
      expect(_v('1.2.3') < _v('1.2.4'), isTrue);
      expect(_v('1.2.3') > _v('0.9.9'), isTrue);
      expect(_v('1.2.3') > _v('1.1.9'), isTrue);
      expect(_v('1.2.3') > _v('1.2.2'), isTrue);
    });
  });

  group('properties', () {
    Glados(any.semver).test('toString round-trips', (v) {
      expect(_v(v.toString()), v);
    });

    Glados2(any.semver, any.semver).test('antisymmetric', (a, b) {
      expect(a.compareTo(b).sign, -b.compareTo(a).sign);
    });

    Glados3(any.semver, any.semver, any.semver).test('transitive', (a, b, c) {
      if (a <= b && b <= c) expect(a <= c, isTrue);
    });

    Glados2(any.semver, any.semver).test('equal iff same parts', (a, b) {
      final same =
          a.major == b.major && a.minor == b.minor && a.patch == b.patch;
      expect(a == b, same);
      expect(a.compareTo(b) == 0, same);
    });

    Glados(any.semver).test('a patch bump is greater', (v) {
      expect(SemVer(v.major, v.minor, v.patch + 1) > v, isTrue);
    });
  });
}
