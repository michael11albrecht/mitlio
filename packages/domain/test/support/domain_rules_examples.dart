import 'dart:convert';
import 'dart:io';

/// Golden data from `docs/domain-rules.md`: every `<!-- examples:NAME -->`
/// marker followed by a fenced `json` block. The doc is the single source of
/// truth; tests load it instead of copying the tables.
const _docPath = 'docs/domain-rules.md';

final _block = RegExp(
  r'<!--\s*examples:(\w+)\s*-->\s*```json\s*\n(.*?)\n\s*```',
  dotAll: true,
);

/// Walks up from the current directory (the package dir under `dart test`)
/// until `docs/domain-rules.md` is found.
File _findDoc() {
  var dir = Directory.current.absolute;
  while (true) {
    final f = File('${dir.path}/$_docPath');
    if (f.existsSync()) return f;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('$_docPath not found above ${Directory.current.path}');
    }
    dir = parent;
  }
}

Map<String, Object?>? _cache;

/// All example blocks by name, parsed from the doc.
Map<String, Object?> allDomainRulesExamples() => _cache ??= {
  for (final m in _block.allMatches(_findDoc().readAsStringSync()))
    m.group(1)!: jsonDecode(m.group(2)!),
};

/// The parsed JSON of `<!-- examples:name -->`. Throws if the block is missing.
Object? domainRulesExamples(String name) {
  final all = allDomainRulesExamples();
  if (!all.containsKey(name)) {
    throw StateError(
      'examples:$name not found in $_docPath (found: ${all.keys.join(', ')})',
    );
  }
  return all[name];
}

/// Like [domainRulesExamples] for blocks that are a JSON array of objects.
List<Map<String, dynamic>> domainRulesRows(String name) =>
    (domainRulesExamples(name)! as List).cast<Map<String, dynamic>>();
