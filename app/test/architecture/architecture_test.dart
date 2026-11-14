import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'rules.dart';
import 'source_scanner.dart';

/// Repo-relative files allowed to call `showDialog` (plan §2.6: undo instead
/// of confirm dialogs). Keep empty unless an issue explicitly asks.
const showDialogAllowlist = <String>[];

void main() {
  final rules = buildRules(showDialogAllowlist: showDialogAllowlist);

  group('real repository obeys architecture rules', () {
    final tree = SourceTree.load(findRepoRoot());

    test('scanner sees the repo', () {
      expect(tree.files.map((f) => f.path), contains('app/lib/main.dart'));
      expect(
        tree.files.map((f) => f.path),
        contains('packages/domain/lib/mitlio_domain.dart'),
      );
    });

    for (final rule in rules) {
      test('${rule.id}: ${rule.description}', () {
        final violations = rule.check(tree);
        expect(violations, isEmpty, reason: violations.join('\n'));
      });
    }
  });

  group('self-tests: every rule fires on a violating fixture', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('mitlio_arch_');
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    List<Violation> run(String ruleId, Map<String, String> files) {
      for (final e in files.entries) {
        File('${tmp.path}/${e.key}')
          ..createSync(recursive: true)
          ..writeAsStringSync(e.value);
      }
      final tree = SourceTree.load(tmp.path);
      final rule = buildRules(
        showDialogAllowlist: const ['app/lib/features/a/ui/allowed_view.dart'],
      ).singleWhere((r) => r.id == ruleId);
      return rule.check(tree);
    }

    // (ruleId, bad fixture, good fixture). Bad must yield >= 1 violation.
    final cases = <(String, Map<String, String>, Map<String, String>)>[
      (
        'domain-purity',
        {
          'packages/domain/lib/a.dart':
              "import 'package:flutter/material.dart';",
        },
        {
          'packages/domain/lib/a.dart':
              "import 'package:collection/collection.dart';",
        },
      ),
      (
        'domain-purity',
        {'packages/domain/lib/a.dart': "import 'package:drift/drift.dart';"},
        {'packages/domain/lib/a.dart': "import 'dart:math';"},
      ),
      (
        'domain-purity',
        {
          'packages/domain/lib/a.dart':
              "export 'package:supabase_flutter/x.dart';",
        },
        {},
      ),
      (
        'domain-purity',
        {
          'packages/domain/lib/a.dart':
              "import 'package:flutter_riverpod/x.dart';",
        },
        {},
      ),
      (
        'domain-purity',
        {
          'packages/domain/lib/a.dart':
              "import 'package:hooks_riverpod/x.dart';",
        },
        {},
      ),
      (
        'domain-purity',
        {
          'packages/domain/lib/a.dart':
              "import 'package:mitlio/core/app.dart';",
        },
        {
          'packages/domain/lib/a.dart':
              "import 'package:mitlio_domain/b.dart';",
        },
      ),
      (
        'services-no-ui',
        {
          'app/lib/features/a/data/services/s.dart':
              "import '../../ui/a_view.dart';",
        },
        {
          'app/lib/features/a/data/services/s.dart':
              "import '../repositories/r.dart';",
        },
      ),
      (
        'services-no-ui',
        {
          'app/lib/features/a/data/services/s.dart':
              "import 'package:mitlio/features/a/ui/a_view_model.dart';",
        },
        {},
      ),
      (
        'repositories-no-ui',
        {
          'app/lib/features/a/data/repositories/r.dart':
              "import '../../ui/a_view_model.dart';",
        },
        {
          'app/lib/features/a/data/repositories/r.dart':
              "import '../services/s.dart';",
        },
      ),
      (
        'repositories-no-ui',
        {
          'app/lib/features/a/data/repositories/r.dart':
              "import 'package:flutter/widgets.dart';",
        },
        {},
      ),
      (
        'repositories-no-ui',
        {
          'app/lib/features/a/data/repositories/r.dart':
              "import 'package:material_ui/material_ui.dart';",
        },
        {},
      ),
      (
        'viewmodel-no-services-or-views',
        {
          'app/lib/features/a/ui/a_view_model.dart':
              "import '../data/services/s.dart';",
        },
        {
          'app/lib/features/a/ui/a_view_model.dart':
              "import '../data/repositories/r.dart';",
        },
      ),
      (
        'viewmodel-no-services-or-views',
        {
          'app/lib/features/a/ui/a_view_model.dart': "import 'a_view.dart';",
        },
        {},
      ),
      (
        'viewmodel-no-buildcontext',
        {
          'app/lib/features/a/ui/a_view_model.dart':
              'void go(BuildContext c) {}',
        },
        {
          'app/lib/features/a/ui/a_view_model.dart':
              "// BuildContext is banned\nconst s = 'BuildContext';",
        },
      ),
      (
        'views-no-data',
        {
          'app/lib/features/a/ui/a_view.dart':
              "import '../data/repositories/r.dart';",
        },
        {'app/lib/features/a/ui/a_view.dart': "import 'a_view_model.dart';"},
      ),
      (
        'views-no-data',
        {
          'app/lib/features/a/ui/widgets/w.dart':
              "import 'package:drift/drift.dart';",
        },
        {},
      ),
      (
        'views-no-data',
        {
          'app/lib/features/a/ui/widgets/w.dart':
              "import 'package:mitlio/features/a/data/services/s.dart';",
        },
        {},
      ),
      (
        'debug-no-views',
        {
          'app/lib/debug/d.dart': "import '../features/a/ui/a_view.dart';",
        },
        {
          'app/lib/debug/d.dart':
              "import '../features/a/ui/a_view_model.dart';",
        },
      ),
      (
        'no-nondeterminism-outside-core',
        {'app/lib/features/a/x.dart': 'final t = DateTime.now();'},
        {'app/lib/core/x.dart': 'final t = DateTime.now();'},
      ),
      (
        'no-nondeterminism-outside-core',
        {'packages/domain/lib/x.dart': 'final r = Random(4);'},
        {'app/lib/features/a/x.dart': 'final r = Random r; // Random()'},
      ),
      (
        'no-nondeterminism-outside-core',
        {'app/lib/features/a/x.dart': 'final r = Random.secure();'},
        {},
      ),
      (
        'no-nondeterminism-outside-core',
        {'app/lib/features/a/x.dart': 'final id = const Uuid().v4();'},
        {},
      ),
      (
        'no-print',
        {'app/lib/x.dart': "void f() { print('hi'); }"},
        {'app/lib/x.dart': "void f() { debugPrint('hi'); log.print('x'); }"},
      ),
      (
        'no-print',
        {'packages/domain/lib/x.dart': "void f() => print('x');"},
        {'packages/domain/lib/x.dart': "// print('x')"},
      ),
      (
        'no-double-money',
        {'packages/domain/lib/m.dart': 'class M { final double amount; }'},
        {'packages/domain/lib/m.dart': 'class M { final int amountCents; }'},
      ),
      (
        'no-double-money',
        {'packages/domain/lib/m.dart': 'M(double? unitPrice, this.x);'},
        {},
      ),
      (
        'no-double-money',
        {'packages/domain/lib/m.dart': 'double get totalCents => 0;'},
        {'packages/domain/lib/m.dart': 'final double ratio;'},
      ),
      (
        'viewmodel-has-test',
        {'app/lib/features/a/ui/a_view_model.dart': 'class A {}'},
        {
          'app/lib/features/a/ui/a_view_model.dart': 'class A {}',
          'app/test/features/a/a_view_model_test.dart': 'void main() {}',
        },
      ),
      (
        'no-raw-style',
        {'app/lib/features/a/x.dart': 'final c = Color(0xFF000000);'},
        {'app/lib/core/theme/t.dart': 'final c = Color(0xFF000000);'},
      ),
      (
        'no-raw-style',
        {'app/lib/features/a/x.dart': 'const s = TextStyle(fontSize: 3);'},
        {'app/lib/features/a/x.dart': 'const s = DefaultTextStyle(x);'},
      ),
      (
        'no-hardcoded-strings',
        {'app/lib/features/a/ui/x.dart': "final w = Text('Hallo Welt');"},
        {'app/lib/features/a/ui/x.dart': 'final w = Text(l10n.hello);'},
      ),
      (
        'no-hardcoded-strings',
        {'app/lib/core/x.dart': "final w = TextField(labelText: 'Betrag');"},
        {'app/lib/core/x.dart': r"final w = Text('$a/${b}');"},
      ),
      (
        'no-hardcoded-strings',
        {'app/lib/core/x.dart': 'final w = Icon(i, semanticLabel: "Zurück");'},
        {'app/lib/core/x.dart': "// Text('Hallo') in a comment"},
      ),
      (
        'dialog-allowlist',
        {'app/lib/features/a/ui/b_view.dart': 'x() => showDialog(context: c);'},
        {
          'app/lib/features/a/ui/allowed_view.dart':
              'x() => showDialog(context: c);',
        },
      ),
      (
        'dialog-allowlist',
        {'app/lib/features/a/ui/b_view.dart': 'x() => showDialog<void>(a);'},
        {},
      ),
      (
        'skip-needs-issue',
        {'app/test/t_test.dart': "test('x', () {}, skip: 'flaky');"},
        {
          'app/test/t_test.dart': "test('x', () {}, skip: 'flaky, see #123');",
        },
      ),
      (
        'skip-needs-issue',
        {'packages/domain/test/t_test.dart': 'test("x", () {}, skip: true);'},
        {},
      ),
    ];

    for (final (i, c) in cases.indexed) {
      test('#$i ${c.$1}: bad fixture is flagged', () {
        final violations = run(c.$1, c.$2);
        expect(violations, isNotEmpty);
        expect(violations.every((v) => v.ruleId == c.$1), isTrue);
      });
      if (c.$3.isNotEmpty) {
        test('#$i ${c.$1}: good fixture passes', () {
          expect(run(c.$1, c.$3), isEmpty);
        });
      }
    }

    test('every rule has at least one self-test case', () {
      final covered = cases.map((c) => c.$1).toSet();
      final all = rules.map((r) => r.id).toSet();
      expect(all.difference(covered), isEmpty);
      expect(all.length, rules.length, reason: 'duplicate rule ids');
    });

    test('relative imports resolve against the importing file', () {
      File('${tmp.path}/app/lib/features/a/data/services/s.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("import '../../ui/a_view.dart';");
      final f = SourceTree.load(tmp.path).files.single;
      expect(f.directives.single.target, 'app/lib/features/a/ui/a_view.dart');
    });

    test('findRepoRoot locates the workspace pubspec', () {
      File('${tmp.path}/pubspec.yaml')
          .writeAsStringSync('workspace:\n  - app\n');
      final deep = Directory('${tmp.path}/app/x')..createSync(recursive: true);
      expect(
        Directory(findRepoRoot(deep)).resolveSymbolicLinksSync(),
        tmp.resolveSymbolicLinksSync(),
      );
    });
  });
}
