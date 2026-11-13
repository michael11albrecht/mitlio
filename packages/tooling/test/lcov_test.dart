import 'package:mitlio_tooling/mitlio_tooling.dart';
import 'package:test/test.dart';

const _lcov = '''
TN:
SF:lib/a.dart
FN:1,foo
DA:1,1
DA:2,0
DA:3,5
LF:3
LH:2
end_of_record
SF:lib/b.dart
DA:1,0
end_of_record
''';

void main() {
  group('parseLcov', () {
    test('parses files, lines and hits', () {
      final files = parseLcov(_lcov);
      expect(files.keys, ['lib/a.dart', 'lib/b.dart']);
      expect(files['lib/a.dart']!.found, 3);
      expect(files['lib/a.dart']!.hit, 2);
      expect(files['lib/b.dart']!.hit, 0);
    });

    test('duplicate DA lines keep the max hits', () {
      final files = parseLcov('SF:x.dart\nDA:1,0\nDA:1,2\nDA:1,1\n');
      expect(files['x.dart']!.lines, {1: 2});
    });

    test('repeated SF blocks for same file are combined', () {
      final files = parseLcov(
        'SF:x.dart\nDA:1,0\nend_of_record\nSF:x.dart\nDA:2,1\nend_of_record\n',
      );
      expect(files['x.dart']!.lines, {1: 0, 2: 1});
    });

    test('handles CRLF and blank lines', () {
      final files = parseLcov('SF:x.dart\r\n\r\nDA:1,1\r\nend_of_record\r\n');
      expect(files['x.dart']!.hit, 1);
    });

    test('ignores checksum field in DA', () {
      final files = parseLcov('SF:x.dart\nDA:1,3,abcd\n');
      expect(files['x.dart']!.hit, 1);
    });

    test('DA outside SF throws', () {
      expect(() => parseLcov('DA:1,1\n'), throwsFormatException);
      expect(
        () => parseLcov('SF:x\nend_of_record\nDA:1,1\n'),
        throwsFormatException,
      );
    });

    test('malformed DA throws', () {
      expect(() => parseLcov('SF:x\nDA:1\n'), throwsFormatException);
      expect(() => parseLcov('SF:x\nDA:a,b\n'), throwsFormatException);
    });

    test('empty input yields no files', () {
      expect(parseLcov(''), isEmpty);
    });
  });

  group('normalizePath', () {
    test('applies package prefix', () {
      expect(
        normalizePath('lib/a.dart', prefix: 'packages/domain'),
        'packages/domain/lib/a.dart',
      );
    });

    test('no prefix leaves relative path', () {
      expect(normalizePath('lib/a.dart'), 'lib/a.dart');
    });

    test('strips ./ and collapses ..', () {
      expect(
        normalizePath('./lib/../lib/a.dart', prefix: 'app'),
        'app/lib/a.dart',
      );
    });

    test('converts backslashes', () {
      expect(
        normalizePath(r'lib\src\a.dart', prefix: r'packages\x'),
        'packages/x/lib/src/a.dart',
      );
    });

    test('absolute path below root becomes relative', () {
      expect(
        normalizePath('/repo/packages/domain/lib/a.dart', root: '/repo'),
        'packages/domain/lib/a.dart',
      );
    });

    test('absolute path ignores prefix', () {
      expect(
        normalizePath('/repo/app/lib/a.dart', prefix: 'zzz', root: '/repo'),
        'app/lib/a.dart',
      );
    });

    test('absolute path outside root stays absolute', () {
      expect(normalizePath('/other/a.dart', root: '/repo'), '/other/a.dart');
      expect(normalizePath('/other/a.dart'), '/other/a.dart');
    });

    test('prefix is applied through parseLcov', () {
      final files = parseLcov(_lcov, prefix: 'app');
      expect(files.keys, ['app/lib/a.dart', 'app/lib/b.dart']);
    });
  });

  group('mergeCoverage', () {
    test('unions files and takes max hits per line', () {
      final a = parseLcov('SF:x\nDA:1,0\nDA:2,1\n');
      final b = parseLcov('SF:x\nDA:1,3\nDA:3,0\nSF:y\nDA:1,1\n');
      final merged = mergeCoverage([a, b]);
      expect(merged['x']!.lines, {1: 3, 2: 1, 3: 0});
      expect(merged['y']!.hit, 1);
    });

    test('empty input', () {
      expect(mergeCoverage([]), isEmpty);
    });
  });
}
