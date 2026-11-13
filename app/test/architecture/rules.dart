import 'source_scanner.dart';

class Violation {
  const Violation(this.ruleId, this.path, this.line, this.message);

  final String ruleId;
  final String path;
  final int line;
  final String message;

  @override
  String toString() => '[$ruleId] $path:$line  $message';
}

class Rule {
  const Rule({
    required this.id,
    required this.description,
    required this.check,
  });

  final String id;
  final String description;
  final List<Violation> Function(SourceTree tree) check;
}

/// Import/export directives of files matching [appliesTo] must not satisfy
/// [forbidden].
Rule importRule({
  required String id,
  required String description,
  required bool Function(String path) appliesTo,
  required bool Function(DirectiveRef directive) forbidden,
}) => Rule(
  id: id,
  description: description,
  check: (tree) => [
    for (final f in tree.where(appliesTo))
      for (final d in f.directives)
        if (forbidden(d))
          Violation(id, f.path, d.line, '$description: ${d.uri}'),
  ],
);

/// Code lines (comments and string contents removed) of files matching
/// [appliesTo] must not match [pattern].
Rule codeRule({
  required String id,
  required String description,
  required bool Function(String path) appliesTo,
  required RegExp pattern,
}) => Rule(
  id: id,
  description: description,
  check: (tree) => [
    for (final f in tree.where(appliesTo))
      for (var i = 0; i < f.codeLines.length; i++)
        if (pattern.hasMatch(f.codeLines[i]))
          Violation(id, f.path, i + 1, '$description: ${f.rawLines[i].trim()}'),
  ],
);

bool _inDir(String path, String dir) => path.startsWith(dir);

bool _isLib(String path) =>
    _inDir(path, 'app/lib/') || RegExp('^packages/[^/]+/lib/').hasMatch(path);

bool _isCoreLib(String path) => _inDir(path, 'app/lib/core/');

bool _isThemeLib(String path) => _inDir(path, 'app/lib/core/theme/');

final _viewModel = RegExp(r'^app/lib/.+/ui/[^/]+_view_model\.dart$');
final _featureUi = RegExp('^app/lib/features/[^/]+/ui/');
final _featureServices = RegExp('^app/lib/features/[^/]+/data/services/');
final _featureRepos = RegExp('^app/lib/features/[^/]+/data/repositories/');
final _uiSegment = RegExp('(^|/)ui/');
final _forbiddenDomain = RegExp(
  r'^package:(flutter|flutter_\w+|drift\w*|supabase\w*|\w*riverpod\w*|mitlio)/',
);

/// The rule set. [showDialogAllowlist] holds repo-relative paths of files that
/// may call `showDialog` (empty: undo/snackbar instead of dialogs, plan §2.6).
List<Rule> buildRules({required List<String> showDialogAllowlist}) => [
  importRule(
    id: 'domain-purity',
    description: 'packages/domain/lib must not import flutter/drift/supabase/riverpod/app',
    appliesTo: (p) => _inDir(p, 'packages/domain/lib/'),
    forbidden: (d) => _forbiddenDomain.hasMatch(d.uri),
  ),
  importRule(
    id: 'services-no-ui',
    description: 'data/services must not import ui/',
    appliesTo: _featureServices.hasMatch,
    forbidden: (d) => _uiSegment.hasMatch(d.target),
  ),
  importRule(
    id: 'repositories-no-ui',
    description: 'data/repositories must not import ui/ or Flutter widgets',
    appliesTo: _featureRepos.hasMatch,
    forbidden: (d) =>
        _uiSegment.hasMatch(d.target) ||
        RegExp(
          r'^package:(flutter/(widgets|material|cupertino)\.dart|material_ui/)',
        ).hasMatch(d.uri),
  ),
  importRule(
    id: 'viewmodel-no-services-or-views',
    description: 'view models must not import data/services or *_view.dart',
    appliesTo: _viewModel.hasMatch,
    forbidden: (d) =>
        d.target.contains('data/services/') || d.target.endsWith('_view.dart'),
  ),
  codeRule(
    id: 'viewmodel-no-buildcontext',
    description: 'view models must not use BuildContext',
    appliesTo: _viewModel.hasMatch,
    pattern: RegExp(r'\bBuildContext\b'),
  ),
  importRule(
    id: 'views-no-data',
    description: 'views/widgets must not import data/ or drift',
    appliesTo: (p) => _featureUi.hasMatch(p) && !p.endsWith('_view_model.dart'),
    forbidden: (d) =>
        RegExp('(^|/)data/').hasMatch(d.target) ||
        d.uri.startsWith('package:drift'),
  ),
  importRule(
    id: 'debug-no-views',
    description: 'app/lib/debug must not import *_view.dart',
    appliesTo: (p) => _inDir(p, 'app/lib/debug/'),
    forbidden: (d) => d.target.endsWith('_view.dart'),
  ),
  codeRule(
    id: 'no-nondeterminism-outside-core',
    description:
        'DateTime.now()/Random()/Uuid() only in app/lib/core (inject Clock, '
        'Random, IdGenerator)',
    appliesTo: (p) => _isLib(p) && !_isCoreLib(p),
    pattern: RegExp(
      r'\bDateTime\.now\s*\(|\bRandom\s*\(|\bRandom\.secure\s*\(|\bUuid\s*\(',
    ),
  ),
  codeRule(
    id: 'no-print',
    description: 'no print() in lib code (use a logger)',
    appliesTo: _isLib,
    pattern: RegExp(r'(?<![\w.$])print\s*\('),
  ),
  codeRule(
    id: 'no-double-money',
    description: 'money is int cents, never double',
    appliesTo: (p) => _inDir(p, 'packages/domain/lib/'),
    pattern: RegExp(
      r'\bdouble\??\s+(?:get\s+)?(?:this\.)?\w*(?:amount|cents|price)\w*',
      caseSensitive: false,
    ),
  ),
  Rule(
    id: 'viewmodel-has-test',
    description: 'every *_view_model.dart needs a *_view_model_test.dart',
    check: (tree) {
      final tests = {
        for (final f in tree.where((p) => _inDir(p, 'app/test/'))) f.basename,
      };
      return [
        for (final f in tree.where(_viewModel.hasMatch))
          if (!tests.contains(
            '${f.basename.substring(0, f.basename.length - 5)}_test.dart',
          ))
            Violation(
              'viewmodel-has-test',
              f.path,
              1,
              'missing app/test/**/'
                  '${f.basename.substring(0, f.basename.length - 5)}_test.dart',
            ),
      ];
    },
  ),
  codeRule(
    id: 'no-raw-style',
    description: 'Color(0x...)/TextStyle( only in app/lib/core/theme',
    appliesTo: (p) => _inDir(p, 'app/lib/') && !_isThemeLib(p),
    pattern: RegExp(r'\bColor\(\s*0x|\bTextStyle\('),
  ),
  Rule(
    id: 'dialog-allowlist',
    description: 'showDialog only in allowlisted files (undo, not confirm)',
    check: (tree) => [
      for (final f in tree.where(
        (p) => _inDir(p, 'app/lib/') && !showDialogAllowlist.contains(p),
      ))
        for (var i = 0; i < f.codeLines.length; i++)
          if (RegExp(r'\bshowDialog\s*[<(]').hasMatch(f.codeLines[i]))
            Violation(
              'dialog-allowlist',
              f.path,
              i + 1,
              'showDialog not allowlisted: ${f.rawLines[i].trim()}',
            ),
    ],
  ),
  Rule(
    id: 'skip-needs-issue',
    description: 'skip: in tests needs an issue link (#123 or issue URL)',
    check: (tree) {
      final link = RegExp(r'#\d+|https?://\S*/(issues|pull)/\d+');
      return [
        for (final f in tree.where(
          (p) => RegExp('^(app|packages/[^/]+)/test/').hasMatch(p),
        ))
          for (var i = 0; i < f.codeLines.length; i++)
            if (RegExp(r'\bskip\s*:').hasMatch(f.codeLines[i]) &&
                !link.hasMatch(
                  [
                    f.rawLines[i],
                    if (i + 1 < f.rawLines.length) f.rawLines[i + 1],
                  ].join('\n'),
                ))
              Violation(
                'skip-needs-issue',
                f.path,
                i + 1,
                'skip without issue link: ${f.rawLines[i].trim()}',
              ),
      ];
    },
  ),
];
