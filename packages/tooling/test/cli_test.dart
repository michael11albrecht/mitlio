import 'dart:io';

import 'package:mitlio_tooling/mitlio_tooling.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _config = '''
exclude: ["**/*.g.dart"]
thresholds:
  - {glob: "**", min: 80}
  - {glob: "packages/domain/lib/**", min: 90}
''';

void main() {
  late Directory dir;
  late StringBuffer out;
  late StringBuffer err;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('gate_test');
    out = StringBuffer();
    err = StringBuffer();
    File(p.join(dir.path, 'cfg.yaml')).writeAsStringSync(_config);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  String path(String name) => p.join(dir.path, name);
  String write(String name, String content) {
    File(path(name)).writeAsStringSync(content);
    return path(name);
  }

  Future<int> run(List<String> args) => runCoverageGate(
    ['--config', path('cfg.yaml'), '--root', dir.path, ...args],
    out: out,
    err: err,
  );

  test('passes and normalises paths via --lcov pairs', () async {
    final a = write('a.info', 'SF:lib/a.dart\nDA:1,1\nend_of_record\n');
    final code = await run(['--lcov', '$a=packages/domain']);
    expect(code, 0);
    expect(out.toString(), contains('packages/domain/lib/**'));
    expect(out.toString(), contains('1/1'));
  });

  test('positional args work and multiple files merge', () async {
    final a = write('a.info', 'SF:lib/a.dart\nDA:1,1\nend_of_record\n');
    final b = write('b.info', 'SF:lib/b.dart\nDA:1,0\nend_of_record\n');
    final code = await run(['$a=packages/domain', '--lcov', '$b=app']);
    expect(code, 1);
    expect(out.toString(), contains('1/2'));
    expect(out.toString(), contains('Coverage gate: FAIL'));
  });

  test('absolute paths under --root are made repo-relative', () async {
    final a = write(
      'a.info',
      'SF:${path('packages/domain/lib/a.dart')}\nDA:1,1\nend_of_record\n',
    );
    final code = await run([a]);
    expect(code, 0);
    expect(out.toString(), contains('packages/domain/lib/**'));
  });

  test('write-summary then baseline ratchet', () async {
    final good = write(
      'good.info',
      'SF:lib/a.dart\nDA:1,1\nDA:2,1\nend_of_record\n',
    );
    final summary = path('out/summary.json');
    expect(await run(['--write-summary', summary, '$good=app']), 0);
    expect(File(summary).existsSync(), isTrue);

    final worse = write(
      'worse.info',
      'SF:lib/a.dart\nDA:1,1\nDA:2,1\nDA:3,1\nDA:4,1\nDA:5,1\n'
          'DA:6,1\nDA:7,1\nDA:8,1\nDA:9,1\nDA:10,0\nend_of_record\n',
    );
    out.clear();
    final code = await run(['--baseline', summary, '$worse=app']);
    expect(code, 1);
    expect(out.toString(), contains('RATCHET FAIL'));
  });

  test('usage errors return 64', () async {
    expect(await run([]), 64);
    expect(err.toString(), contains('No lcov files'));
    err.clear();
    expect(await run(['--bogus']), 64);
    expect(err.toString(), isNotEmpty);
  });

  test('--help returns 0', () async {
    final code = await runCoverageGate(['-h'], out: out, err: err);
    expect(code, 0);
    expect(out.toString(), contains('usage: coverage_gate'));
  });

  test('missing files return 66', () async {
    expect(await run([path('nope.info')]), 66);
    expect(err.toString(), contains('lcov file not found'));

    final a = write('a.info', 'SF:x\nDA:1,1\n');
    err.clear();
    expect(await run(['--baseline', path('nope.json'), a]), 66);
    expect(err.toString(), contains('Baseline not found'));

    err.clear();
    final code = await runCoverageGate(
      ['--config', path('nope.yaml'), a],
      out: out,
      err: err,
    );
    expect(code, 66);
    expect(err.toString(), contains('Config not found'));
  });

  test('invalid content returns 65', () async {
    final bad = write('bad.info', 'DA:1,1\n');
    expect(await run([bad]), 65);
    expect(err.toString(), contains('Invalid input'));
  });
}
