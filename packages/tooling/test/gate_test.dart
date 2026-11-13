import 'package:mitlio_tooling/mitlio_tooling.dart';
import 'package:test/test.dart';

/// Builds lcov with [hit] hit lines and [miss] missed lines for [path].
String _file(String path, int hit, int miss) {
  final b = StringBuffer('SF:$path\n');
  for (var i = 0; i < hit; i++) {
    b.writeln('DA:${i + 1},1');
  }
  for (var i = 0; i < miss; i++) {
    b.writeln('DA:${hit + i + 1},0');
  }
  b.writeln('end_of_record');
  return b.toString();
}

const _config = '''
exclude:
  - "**/*.g.dart"
  - "**/*.freezed.dart"
  - "**/*.drift.dart"
  - "**/lib/l10n/**"
thresholds:
  - glob: "**"
    min: 80
  - glob: "packages/domain/lib/**"
    min: 90
  - glob: "app/lib/**/data/**"
    min: 90
  - glob: "app/lib/**/ui/*_view_model.dart"
    min: 90
  - glob: "app/lib/features/sync/**"
    min: 90
''';

GlobResult _r(GateReport r, String glob) =>
    r.results.firstWhere((e) => e.glob == glob);

void main() {
  final config = GateConfig.parse(_config);

  group('GateConfig.parse', () {
    test('parses exclude and thresholds', () {
      expect(config.exclude, hasLength(4));
      expect(config.thresholds, hasLength(5));
      expect(config.thresholds.first.glob, '**');
      expect(config.thresholds.first.min, 80);
    });

    test('exclude is optional', () {
      final c = GateConfig.parse('thresholds:\n  - {glob: "**", min: 50.5}\n');
      expect(c.exclude, isEmpty);
      expect(c.thresholds.single.min, 50.5);
    });

    test('rejects invalid configs', () {
      expect(() => GateConfig.parse('- a'), throwsFormatException);
      expect(
        () => GateConfig.parse('exclude: x\nthresholds: [1]'),
        throwsFormatException,
      );
      expect(() => GateConfig.parse('exclude: []'), throwsFormatException);
      expect(() => GateConfig.parse('thresholds: []'), throwsFormatException);
      expect(
        () => GateConfig.parse('thresholds:\n  - {glob: x}\n'),
        throwsFormatException,
      );
      expect(
        () => GateConfig.parse('thresholds:\n  - nope\n'),
        throwsFormatException,
      );
    });
  });

  group('exclusion', () {
    test('generated files and l10n are removed', () {
      final files = parseLcov(
        [
          _file('app/lib/a.dart', 1, 0),
          _file('app/lib/a.g.dart', 0, 9),
          _file('app/lib/x/a.freezed.dart', 0, 9),
          _file('app/lib/db/a.drift.dart', 0, 9),
          _file('g.g.dart', 0, 9),
          _file('app/lib/l10n/app_en.dart', 0, 9),
          _file('app/lib/l10n/sub/x.dart', 0, 9),
        ].join(),
      );
      final kept = applyExcludes(files, config.exclude);
      expect(kept.keys, ['app/lib/a.dart']);
    });

    test('excluded files do not count towards any threshold', () {
      final files = parseLcov(
        _file('packages/domain/lib/a.dart', 10, 0) +
            _file('packages/domain/lib/a.g.dart', 0, 100),
      );
      final report = evaluate(files, config);
      expect(_r(report, '**').found, 10);
      expect(report.passed, isTrue);
    });
  });

  group('thresholds', () {
    test('everything above thresholds passes', () {
      final files = parseLcov(
        [
          _file('packages/domain/lib/a.dart', 95, 5),
          _file('app/lib/features/trip/data/repo.dart', 90, 10),
          _file('app/lib/features/trip/ui/trip_view_model.dart', 9, 1),
          _file('app/lib/features/sync/s.dart', 10, 0),
          _file('app/lib/features/trip/ui/trip_view.dart', 8, 2),
        ].join(),
      );
      final report = evaluate(files, config);
      expect(report.passed, isTrue);
      expect(report.results.every((r) => r.status == GateStatus.pass), isTrue);
      expect(_r(report, 'app/lib/**/data/**').found, 100);
      expect(_r(report, 'app/lib/**/ui/*_view_model.dart').hit, 9);
    });

    test('glob ** matches zero intermediate directories', () {
      final files = parseLcov(
        _file('app/lib/data/x.dart', 1, 0) +
            _file('app/lib/ui/y_view_model.dart', 1, 0),
      );
      final report = evaluate(files, config);
      expect(_r(report, 'app/lib/**/data/**').found, 1);
      expect(_r(report, 'app/lib/**/ui/*_view_model.dart').found, 1);
    });

    test('view_model glob does not match nested or other files', () {
      final files = parseLcov(
        _file('app/lib/f/ui/a_view.dart', 1, 0) +
            _file('app/lib/f/ui/sub/a_view_model.dart', 1, 0),
      );
      final report = evaluate(files, config);
      expect(_r(report, 'app/lib/**/ui/*_view_model.dart').found, 0);
    });

    test('a failing glob fails the gate', () {
      final files = parseLcov(
        [
          _file('packages/domain/lib/a.dart', 89, 11),
          _file('app/lib/main.dart', 100, 0),
        ].join(),
      );
      final report = evaluate(files, config);
      expect(report.passed, isFalse);
      expect(_r(report, '**').status, GateStatus.pass);
      expect(_r(report, 'packages/domain/lib/**').status, GateStatus.fail);
    });

    test('exact threshold passes', () {
      final files = parseLcov(_file('app/lib/x.dart', 80, 20));
      expect(_r(evaluate(files, config), '**').status, GateStatus.pass);
    });

    test('overall below 80 fails', () {
      final files = parseLcov(_file('app/lib/x.dart', 79, 21));
      final report = evaluate(files, config);
      expect(_r(report, '**').status, GateStatus.fail);
      expect(report.passed, isFalse);
    });

    test('globs with zero lines are skipped, not failed', () {
      final files = parseLcov(_file('app/lib/x.dart', 10, 0));
      final report = evaluate(files, config);
      final skipped = _r(report, 'packages/domain/lib/**');
      expect(skipped.status, GateStatus.skip);
      expect(skipped.percent, isNull);
      expect(report.passed, isTrue);
    });

    test('no coverage at all skips everything and passes', () {
      final report = evaluate({}, config);
      expect(report.passed, isTrue);
      expect(report.results.every((r) => r.status == GateStatus.skip), isTrue);
    });
  });

  group('baseline ratchet', () {
    final files = parseLcov(_file('packages/domain/lib/a.dart', 95, 5));

    String baselineWith(double pct) =>
        '''
{"globs": {"packages/domain/lib/**": {"hit": 1, "found": 1, "percent": $pct}}}
''';

    test('summary round-trips into a baseline', () {
      final report = evaluate(files, config);
      final baseline = parseBaseline(report.toSummaryJson());
      expect(baseline['packages/domain/lib/**'], 95);
      expect(baseline['**'], 95);
      expect(baseline.containsKey('app/lib/features/sync/**'), isFalse);
    });

    test('drop of more than 0.5 pp fails', () {
      final report = evaluate(
        files,
        config,
        baseline: parseBaseline(baselineWith(95.6)),
      );
      expect(report.passed, isFalse);
      expect(report.ratchetFailures.single.glob, 'packages/domain/lib/**');
      expect(report.ratchetFailures.single.drop, closeTo(0.6, 1e-9));
    });

    test('drop of exactly 0.5 pp passes', () {
      final report = evaluate(
        files,
        config,
        baseline: parseBaseline(baselineWith(95.5)),
      );
      expect(report.passed, isTrue);
    });

    test('improvement passes', () {
      final report = evaluate(
        files,
        config,
        baseline: parseBaseline(baselineWith(50)),
      );
      expect(report.passed, isTrue);
    });

    test('globs missing from baseline or current are ignored', () {
      final report = evaluate(
        files,
        config,
        baseline: {'app/lib/features/sync/**': 100, 'unknown/**': 100},
      );
      expect(report.passed, isTrue);
    });

    test('custom maxDrop', () {
      final report = evaluate(
        files,
        config,
        baseline: {'**': 97},
        maxDrop: 2.5,
      );
      expect(report.passed, isTrue);
    });

    test('invalid baseline JSON shapes throw', () {
      expect(() => parseBaseline('[]'), throwsFormatException);
      expect(() => parseBaseline('{}'), throwsFormatException);
      expect(() => parseBaseline('{"globs": 1}'), throwsFormatException);
      expect(() => parseBaseline('nope'), throwsFormatException);
    });

    test('entries without a percent are skipped', () {
      final b = parseBaseline(
        '{"globs": {"a": {"hit": 0, "found": 0, "percent": null}, "b": 1}}',
      );
      expect(b, isEmpty);
    });
  });

  group('renderReport', () {
    test('contains table, statuses and verdict', () {
      final files = parseLcov(
        _file('packages/domain/lib/a.dart', 50, 50) +
            _file('app/lib/x.dart', 300, 0),
      );
      final text = renderReport(evaluate(files, config));
      expect(text, contains('GLOB'));
      expect(text, contains('HIT/FOUND'));
      expect(text, contains('350/400'));
      expect(text, contains('87.50%'));
      expect(text, contains('>= 90.0%'));
      expect(text, contains('FAIL'));
      expect(text, contains('PASS'));
      expect(text, contains('SKIP (no lines)'));
      expect(text, contains('Coverage gate: FAIL'));
    });

    test('shows ratchet failures', () {
      final files = parseLcov(_file('app/lib/x.dart', 90, 10));
      final report = evaluate(files, config, baseline: {'**': 95});
      final text = renderReport(report);
      expect(text, contains('RATCHET FAIL: ** dropped 5.00 pp'));
      expect(text, contains('Coverage gate: FAIL'));
    });

    test('passing report says PASS', () {
      final files = parseLcov(_file('app/lib/x.dart', 10, 0));
      expect(renderReport(evaluate(files, config)), contains('gate: PASS'));
    });
  });
}
