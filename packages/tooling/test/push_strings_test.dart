import 'dart:convert';
import 'dart:io';

import 'package:mitlio_tooling/mitlio_tooling.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// An ARB source with every server loc-key; [text] renders one body.
String _arb({
  String Function(String key, List<String> args)? text,
  Set<String> without = const {},
  Map<String, Object?> extra = const {},
}) {
  const args = <String, List<String>>{
    'pushLocExpenseAdded': ['actor', 'title', 'amount'],
    'pushLocExpenseChanged': ['actor', 'title', 'amount'],
    'pushLocExpenseDeleted': ['actor', 'title'],
    'pushLocSettlementAdded': ['actor', 'amount'],
    'pushLocMemberJoined': ['name', 'group'],
    'pushLocExpensesAdded': ['actor', 'count', 'group'],
    'pushLocGroupUpdates': ['count', 'group'],
    'pushLocGeneric': ['group'],
  };
  final json = <String, Object?>{'@@locale': 'x', 'unrelated': 'Hallo'};
  for (final e in args.entries) {
    if (without.contains(e.key)) continue;
    json[e.key] =
        text?.call(e.key, e.value) ??
        '${e.key}: ${e.value.map((a) => '{$a}').join(' ')}';
    json['@${e.key}'] = {
      'placeholders': {
        for (final a in e.value) a: {'type': 'String'},
      },
    };
  }
  return jsonEncode({...json, ...extra});
}

void main() {
  group('PushStrings', () {
    test('every loc-key in every locale: no problems', () {
      final s = PushStrings.parse({'de': _arb(), 'en': _arb()});
      expect(s.problems(), isEmpty);
      expect(s.byLocale['de']!.keys.toSet(), pushLocKeys.keys.toSet());
    });

    test('reports a loc-key missing in one locale', () {
      final s = PushStrings.parse({
        'de': _arb(),
        'en': _arb(without: {'pushLocGeneric'}),
      });
      expect(s.problems(), ['en: missing loc-key push_generic']);
    });

    test('reports wrong argument counts, unused arguments, empty text', () {
      final s = PushStrings.parse({
        'de': _arb(
          text: (key, args) => switch (key) {
            'pushLocGeneric' => 'Neues',
            'pushLocMemberJoined' => ' ',
            _ => args.map((a) => '{$a}').join(' '),
          },
        ),
      });
      expect(
        s.problems(),
        containsAll([
          'de: push_generic never uses {group}',
          'de: push_member_joined is empty',
        ]),
      );
      final fewer = PushStrings.parse({
        'de': _arb(
          extra: {
            '@pushLocGeneric': {'placeholders': <String, Object?>{}},
          },
        ),
      });
      expect(
        fewer.problems(),
        contains('de: push_generic has 0 arguments, the server sends 1'),
      );
    });

    test(
      'reports a loc-key the server does not send and a missing default',
      () {
        final s = PushStrings.parse({
          'en': _arb(extra: {'pushLocSurprise': 'x'}),
        });
        expect(
          s.problems(),
          containsAll([
            'no app_de.arb (the default locale)',
            'en: push_surprise is not a loc-key the server sends',
          ]),
        );
      },
    );

    test('rejects an ARB that is not an object', () {
      expect(() => PushStrings.parse({'de': '[]'}), throwsFormatException);
    });

    test('generates Android (default = German) and iOS files', () {
      final s = PushStrings.parse({
        'de': _arb(
          text: (key, args) => key == 'pushLocGeneric'
              ? "Neues in \"{group}\" & <mehr> ''ok'' 100%"
              : args.map((a) => '{$a}').join(' · '),
        ),
        'en': _arb(),
      });
      final files = s.generate();
      expect(files.keys, [
        'app/android/app/src/main/res/values/push_strings.xml',
        'app/ios/Runner/de.lproj/Localizable.strings',
        'app/android/app/src/main/res/values-en/push_strings.xml',
        'app/ios/Runner/en.lproj/Localizable.strings',
      ]);
      final androidDe =
          files['app/android/app/src/main/res/values/push_strings.xml']!;
      expect(
        androidDe,
        allOf(
          contains(
            r'<string name="push_expense_added">%1$s · %2$s · %3$s</string>',
          ),
          contains(
            r'<string name="push_generic">Neues in \"%1$s\" &amp; &lt;mehr&gt; '
            r"\'ok\' 100%</string>",
          ),
        ),
      );
      final iosDe = files['app/ios/Runner/de.lproj/Localizable.strings']!;
      expect(
        iosDe,
        allOf(
          contains(r'"push_expense_added" = "%1$@ · %2$@ · %3$@";'),
          contains(
            r'"push_generic" = "Neues in \"%1$@\" & <mehr> '
            "'ok' 100%\";",
          ),
        ),
      );
    });

    test('a text starting with @ or ? is escaped for Android', () {
      final s = PushStrings.parse({
        'de': _arb(text: (key, args) => '@${args.map((a) => '{$a}').join()}'),
      });
      expect(
        s.generate()['app/android/app/src/main/res/values/push_strings.xml'],
        contains(r'>\@%1$s</string>'),
      );
    });
  });

  group('CLI', () {
    late Directory root;
    late StringBuffer out;
    late StringBuffer err;

    void writeArbs(Map<String, String> arbs) {
      for (final e in arbs.entries) {
        File(p.join(root.path, 'app/lib/l10n/app_${e.key}.arb'))
          ..createSync(recursive: true)
          ..writeAsStringSync(e.value);
      }
    }

    setUp(() {
      root = Directory.systemTemp.createTempSync('push_strings_test');
      writeArbs({'de': _arb(), 'en': _arb()});
      out = StringBuffer();
      err = StringBuffer();
    });
    tearDown(() => root.deleteSync(recursive: true));

    Future<int> run(List<String> args) =>
        runGenPushStrings([...args, '--root', root.path], out: out, err: err);

    test(
      '--check fails before generation, passes after, fails on edit',
      () async {
        expect(await run(['--check']), 1);
        expect(err.toString(), contains('values/push_strings.xml'));
        expect(await run([]), 0);
        expect(await run(['--check']), 0);
        File(
          p.join(root.path, 'app/ios/Runner/en.lproj/Localizable.strings'),
        ).writeAsStringSync('stale');
        err.clear();
        expect(await run(['--check']), 1);
        expect(err.toString(), contains('en.lproj'));
      },
    );

    test('a missing loc-key fails and writes nothing', () async {
      writeArbs({
        'en': _arb(without: {'pushLocGeneric'}),
      });
      expect(await run([]), 1);
      expect(err.toString(), contains('en: missing loc-key push_generic'));
      expect(
        File(
          p.join(root.path, 'app/ios/Runner/de.lproj/Localizable.strings'),
        ).existsSync(),
        isFalse,
      );
    });

    test('usage, unreadable and malformed input exit non-zero', () async {
      expect(await runGenPushStrings(['--nope'], out: out, err: err), 64);
      writeArbs({'de': '[]'});
      expect(await run([]), 1);
      root
        ..deleteSync(recursive: true)
        ..createSync();
      expect(await run([]), 1);
    });
  });

  group('the repository', () {
    final repo = p.normalize(p.join(Directory.current.path, '../..'));

    test('every loc-key exists in all locales, files are generated', () {
      final strings = readPushStrings(repo);
      expect(strings.byLocale.keys, containsAll(['de', 'en']));
      expect(strings.problems(), isEmpty);
      expect(
        pushStringsDrift(repo, strings),
        isEmpty,
        reason: 'run `make push-strings`',
      );
    });

    test('pushLocKeys matches LOC_KEYS of notify.ts when present', () {
      // notify.ts comes with P6b-T04; the check starts to bite once it is on
      // this branch.
      final file = File(
        p.join(repo, 'supabase/functions/_shared/notify.ts'),
      );
      if (!file.existsSync()) return;
      final block = RegExp(
        r'LOC_KEYS = \[([^\]]*)\]',
      ).firstMatch(file.readAsStringSync());
      expect(block, isNotNull);
      final keys = RegExp(
        r'"(\w+)"',
      ).allMatches(block![1]!).map((m) => m[1]).toSet();
      expect(pushLocKeys.keys.toSet(), keys);
    });
  });
}
