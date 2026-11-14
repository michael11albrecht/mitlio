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
    id: 'ui-no-debug',
    description:
        'ui/, core/ and data/ must not import app/lib/debug (debug reads '
        'ViewModels, never the other way round)',
    appliesTo: (p) =>
        _inDir(p, 'app/lib/core/') ||
        RegExp('^app/lib/features/[^/]+/(ui|data)/').hasMatch(p),
    forbidden: (d) =>
        d.uri.startsWith('package:mitlio/debug/') ||
        d.target.startsWith('app/lib/debug/'),
  ),
  importRule(
    id: 'debug-no-views',
    description: 'app/lib/debug must not import *_view.dart',
    appliesTo: (p) => _inDir(p, 'app/lib/debug/'),
    forbidden: (d) => d.target.endsWith('_view.dart'),
  ),
  importRule(
    id: 'sync-no-local-bank',
    description:
        'sync code (app/lib/features/sync/ or any *sync* file) must not '
        'import the local bank DAO or the payment details repository '
        '(IBAN data never leaves the device, plan §8)',
    appliesTo: (p) =>
        _isLib(p) &&
        (_inDir(p, 'app/lib/features/sync/') ||
            p.split('/').last.contains('sync')),
    forbidden: (d) => RegExp(
      'local_member_bank|payment_details|iban_cipher',
    ).hasMatch(d.target),
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
  Rule(
    id: 'screen-has-a11y-test',
    description:
        'every *_view.dart needs a test that calls expectAccessible and '
        'names its primary widget class',
    check: (tree) {
      final tests = [
        for (final f in tree.where(
          (p) => _inDir(p, 'app/test/') && p.endsWith('_test.dart'),
        ))
          if (f.codeLines.any((l) => l.contains('expectAccessible('))) f,
      ];
      final widgetClass = RegExp(
        r'^class\s+([A-Z]\w*)\s+extends\s+\w*(?:Widget|Sheet)\b',
      );
      return [
        for (final f in tree.where(
          (p) => _inDir(p, 'app/lib/') && p.endsWith('_view.dart'),
        ))
          if (!_hasA11yTest(f, tests, widgetClass))
            Violation(
              'screen-has-a11y-test',
              f.path,
              1,
              'no test calls expectAccessible for the screen widget of '
                  '${f.basename}',
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
  codeRule(
    id: 'no-magic-spacing',
    description:
        'no numeric literals in EdgeInsets/SizedBox sizes outside '
        'app/lib/core/theme (use Spacing/Sizes tokens)',
    appliesTo: (p) => _inDir(p, 'app/lib/') && !_isThemeLib(p),
    pattern: RegExp(
      r'EdgeInsets(?:Directional)?\.(?:all|symmetric|only|fromLTRB|fromSTEB)'
      r'\([^)]*\b[1-9]\d*(?:\.\d+)?\b'
      r'|\bSizedBox\(\s*(?:width|height):\s*[1-9]',
    ),
  ),
  Rule(
    id: 'no-hardcoded-strings',
    description:
        'user-visible strings come from l10n (ARB), not literals in '
        'Text()/labelText:/tooltip:/semanticLabel: ...',
    check: (tree) {
      final literal = RegExp(
        r'''(?:\b(?:Text|SelectableText)\(|\b(?:labelText|hintText|helperText|errorText|semanticLabel|semanticsLabel|tooltip|title|label|prefixText|suffixText):)\s*r?(['"])((?:(?!\1).)*)\1''',
      );
      final interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');
      return [
        for (final f in tree.where(
          (p) =>
              _inDir(p, 'app/lib/') &&
              !_inDir(p, 'app/lib/debug/') &&
              p != 'app/lib/main.dart',
        ))
          for (var i = 0; i < f.rawLines.length; i++)
            // codeLines is blank for pure comment lines.
            if (f.codeLines[i].trim().isNotEmpty)
              for (final m in literal.allMatches(f.rawLines[i]))
                if (m
                    .group(2)!
                    .replaceAll(interpolation, '')
                    .contains(
                      RegExp('[A-Za-z]'),
                    ))
                  Violation(
                    'no-hardcoded-strings',
                    f.path,
                    i + 1,
                    'hardcoded UI string, use AppLocalizations: '
                        '${f.rawLines[i].trim()}',
                  ),
      ];
    },
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
  // TODO(P3-T14): once ViewModels with destructive commands exist (delete,
  // remove member, ...), add a rule that each such command exposes an undo
  // (convention documented in docs/ux-budgets.md, plan §2.6 #5). Not added
  // yet: there is nothing to match, and a fake rule would give false comfort.
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

bool _hasA11yTest(SourceFile view, List<SourceFile> tests, RegExp widgetClass) {
  final name = widgetClass
      .firstMatch(
        view.codeLines.firstWhere(widgetClass.hasMatch, orElse: () => ''),
      )
      ?.group(1);
  if (name == null) return false;
  final usage = RegExp('\\b$name\\b');
  return tests.any((t) => t.codeLines.any(usage.hasMatch));
}
