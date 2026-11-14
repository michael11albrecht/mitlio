import 'dart:io';

import 'package:mitlio_tooling/mitlio_tooling.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _yaml = '''
name: mitlio
flavors:
  dev:
    display_name: mitlio dev
    bundle_id: app.mitlio.dev
  prod:
    display_name: mitlio
    bundle_id: app.mitlio
''';

void main() {
  group('AppIdentity', () {
    test('parses flavors and generates android + ios files', () {
      final files = AppIdentity.parse(_yaml).generate();
      expect(files.keys, [
        'app/android/app_identity.properties',
        'app/ios/Flutter/Flavor-dev.xcconfig',
        'app/ios/Flutter/Flavor-prod.xcconfig',
      ]);
      expect(
        files['app/android/app_identity.properties'],
        allOf(
          contains('dev.applicationId=app.mitlio.dev\n'),
          contains('dev.appName=mitlio dev\n'),
          contains('prod.applicationId=app.mitlio\n'),
          contains('prod.appName=mitlio\n'),
        ),
      );
      expect(
        files['app/ios/Flutter/Flavor-dev.xcconfig'],
        allOf(
          contains('PRODUCT_BUNDLE_IDENTIFIER = app.mitlio.dev\n'),
          contains('APP_DISPLAY_NAME = mitlio dev\n'),
        ),
      );
    });

    test('rejects missing or malformed keys', () {
      expect(() => AppIdentity.parse('name: x'), throwsFormatException);
      expect(
        () => AppIdentity.parse('flavors:\n  dev:\n    display_name: a\n'),
        throwsFormatException,
      );
      expect(
        () => AppIdentity.parse('flavors:\n  dev: 1\n'),
        throwsFormatException,
      );
      expect(() => AppIdentity.parse('flavors: {}\n'), throwsFormatException);
    });
  });

  group('CLI', () {
    late Directory root;
    late StringBuffer out;
    late StringBuffer err;

    setUp(() {
      root = Directory.systemTemp.createTempSync('identity_test');
      File(p.join(root.path, 'app/app_identity.yaml'))
        ..createSync(recursive: true)
        ..writeAsStringSync(_yaml);
      out = StringBuffer();
      err = StringBuffer();
    });
    tearDown(() => root.deleteSync(recursive: true));

    Future<int> run(List<String> args) =>
        runGenAppIdentity([...args, '--root', root.path], out: out, err: err);

    test(
      '--check fails before generation, passes after, fails on edit',
      () async {
        expect(await run(['--check']), 1);
        expect(err.toString(), contains('app/android/app_identity.properties'));
        expect(await run([]), 0);
        expect(await run(['--check']), 0);
        File(
          p.join(root.path, 'app/ios/Flutter/Flavor-dev.xcconfig'),
        ).writeAsStringSync('stale');
        err.clear();
        expect(await run(['--check']), 1);
        expect(err.toString(), contains('Flavor-dev.xcconfig'));
      },
    );

    test('usage and unreadable yaml exit non-zero', () async {
      expect(await runGenAppIdentity(['--nope'], out: out, err: err), 64);
      root
        ..deleteSync(recursive: true)
        ..createSync();
      expect(await run([]), 1);
    });
  });

  test('committed identity files match app/app_identity.yaml', () {
    final repo = p.normalize(p.join(Directory.current.path, '../..'));
    final identity = AppIdentity.parse(
      File(p.join(repo, 'app/app_identity.yaml')).readAsStringSync(),
    );
    expect(
      identityDrift(repo, identity),
      isEmpty,
      reason: 'run `make identity`',
    );
  });
}
