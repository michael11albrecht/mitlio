import 'dart:io';

import 'package:mitlio_tooling/mitlio_tooling.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _policy = '''
denylist:
  - category: ads
    reason: No ads.
    packages: [google_mobile_ads]
  - category: analytics
    reason: No tracking.
    packages: [firebase_analytics, mixpanel-browser, "@segment/analytics-next"]
  - category: review-prompt
    reason: No prompts.
    packages: [in_app_review]
allowlist: []
''';

String _pubLock(List<String> names) {
  final entries = [
    for (final n in names)
      '  $n:\n    dependency: transitive\n    version: "1"',
  ];
  return 'packages:\n${entries.join('\n')}\nsdks:\n  dart: ">=3.0.0 <4.0.0"\n';
}

const _npmLock = '''
{"lockfileVersion": 3, "packages": {
  "": {"name": "web"},
  "node_modules/astro": {"version": "5.0.0"},
  "node_modules/foo/node_modules/mixpanel-browser": {"version": "2.0.0"},
  "node_modules/@segment/analytics-next": {"version": "1.0.0"}
}}
''';

void main() {
  late Directory dir;
  late StringBuffer out;
  late StringBuffer err;

  void write(String rel, String content) {
    final f = File(p.join(dir.path, rel));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('deps_policy_test');
    out = StringBuffer();
    err = StringBuffer();
    write('tool/deps_policy.yaml', _policy);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<int> run() => runDepsPolicy(
    [
      '--root',
      dir.path,
      '--policy',
      p.join(dir.path, 'tool/deps_policy.yaml'),
    ],
    out: out,
    err: err,
  );

  group('parsing', () {
    test('pubspec.lock names include transitive packages', () {
      expect(parsePubspecLock(_pubLock(['a', 'b'])), {'a', 'b'});
    });

    test('package-lock names handle nested and scoped packages', () {
      expect(parsePackageLock(_npmLock), {
        'astro',
        'mixpanel-browser',
        '@segment/analytics-next',
      });
    });

    test('malformed lockfiles throw FormatException', () {
      expect(() => parsePubspecLock('foo: 1'), throwsFormatException);
      expect(() => parsePackageLock('{}'), throwsFormatException);
    });

    test('allowlist entry without reason is rejected', () {
      final source = _policy.replaceFirst(
        'allowlist: []',
        'allowlist:\n  - package: in_app_review',
      );
      expect(() => DepsPolicy.parse(source), throwsFormatException);
    });

    test('policy without denylist is rejected', () {
      expect(() => DepsPolicy.parse('allowlist: []'), throwsFormatException);
    });
  });

  group('runDepsPolicy', () {
    test('passes on clean lockfiles', () async {
      write('pubspec.lock', _pubLock(['collection']));
      write(
        'web/package-lock.json',
        '{"packages": {"node_modules/astro": {}}}',
      );
      expect(await run(), 0);
      expect(out.toString(), contains('OK (2 lockfiles)'));
    });

    test('fails on a denied pubspec.lock package with category', () async {
      write('pubspec.lock', _pubLock(['collection', 'google_mobile_ads']));
      expect(await run(), 1);
      expect(out.toString(), contains('pubspec.lock'));
      expect(out.toString(), contains('"google_mobile_ads"'));
      expect(out.toString(), contains('[ads]'));
    });

    test('fails on denied npm packages, nested and scoped', () async {
      write('web/package-lock.json', _npmLock);
      expect(await run(), 1);
      expect(out.toString(), contains('"mixpanel-browser"'));
      expect(out.toString(), contains('"@segment/analytics-next"'));
    });

    test('allowlist with reason permits a denied package', () async {
      write('pubspec.lock', _pubLock(['in_app_review']));
      expect(await run(), 1);
      write(
        'tool/deps_policy.yaml',
        _policy.replaceFirst(
          'allowlist: []',
          'allowlist:\n  - package: in_app_review\n    reason: after 5th trip',
        ),
      );
      expect(await run(), 0);
    });

    test('ignores lockfiles in node_modules and .dart_tool', () async {
      write('node_modules/x/pubspec.lock', _pubLock(['google_mobile_ads']));
      write('.dart_tool/pubspec.lock', _pubLock(['google_mobile_ads']));
      expect(await run(), 0);
    });

    test('missing policy file is exit 66', () async {
      File(p.join(dir.path, 'tool/deps_policy.yaml')).deleteSync();
      expect(await run(), 66);
      expect(err.toString(), contains('Policy file not found'));
    });

    test('invalid lockfile is exit 66', () async {
      write('pubspec.lock', 'nope: 1');
      expect(await run(), 66);
    });

    test('unknown option is usage error 64, --help is 0', () async {
      expect(await runDepsPolicy(['--bogus'], out: out, err: err), 64);
      expect(await runDepsPolicy(['-h'], out: out, err: err), 0);
    });
  });

  test('the real repo policy passes on the real lockfiles', () async {
    var root = Directory.current;
    while (!File(p.join(root.path, 'tool/deps_policy.yaml')).existsSync()) {
      root = root.parent;
    }
    final code = await runDepsPolicy(
      [
        '--root',
        root.path,
        '--policy',
        p.join(root.path, 'tool/deps_policy.yaml'),
      ],
      out: out,
      err: err,
    );
    expect(code, 0, reason: out.toString());
  });
}
