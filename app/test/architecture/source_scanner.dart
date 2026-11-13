import 'dart:io';

/// One `import` / `export` directive.
class DirectiveRef {
  const DirectiveRef({
    required this.uri,
    required this.target,
    required this.line,
  });

  /// The URI exactly as written.
  final String uri;

  /// Repo-relative path when the URI points into this repo (relative imports,
  /// `package:mitlio/`, `package:mitlio_domain/`), otherwise the raw URI.
  final String target;

  /// 1-based line number.
  final int line;
}

/// A scanned Dart source file.
class SourceFile {
  SourceFile({required this.path, required this.rawLines})
    : codeLines = stripNonCode(rawLines),
      directives = _parseDirectives(path, rawLines);

  /// Repo-relative path with `/` separators.
  final String path;
  final List<String> rawLines;

  /// Same line count as [rawLines], with comments removed and string literal
  /// contents blanked (`'...'` becomes `''`).
  final List<String> codeLines;
  final List<DirectiveRef> directives;

  String get basename => path.substring(path.lastIndexOf('/') + 1);
}

/// All Dart files of interest in a repo checkout.
class SourceTree {
  SourceTree(this.files);

  /// Scans `app/{lib,test}` and `packages/*/{lib,test}` below [root].
  factory SourceTree.load(String root) {
    final dirs = <Directory>[
      Directory('$root/app/lib'),
      Directory('$root/app/test'),
    ];
    final packages = Directory('$root/packages');
    if (packages.existsSync()) {
      for (final pkg in packages.listSync().whereType<Directory>()) {
        dirs
          ..add(Directory('${pkg.path}/lib'))
          ..add(Directory('${pkg.path}/test'));
      }
    }
    final files = <SourceFile>[];
    for (final dir in dirs.where((d) => d.existsSync())) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final rel = entity.path
            .substring(root.length + 1)
            .replaceAll(r'\', '/');
        if (_isIgnored(rel)) continue;
        files.add(
          SourceFile(path: rel, rawLines: entity.readAsLinesSync()),
        );
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return SourceTree(files);
  }

  final List<SourceFile> files;

  Iterable<SourceFile> where(bool Function(String path) test) =>
      files.where((f) => test(f.path));
}

/// Walks up from [start] to the directory whose `pubspec.yaml` declares a
/// `workspace:`.
String findRepoRoot([Directory? start]) {
  var dir = (start ?? Directory.current).absolute;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync() &&
        RegExp(
          '^workspace:',
          multiLine: true,
        ).hasMatch(pubspec.readAsStringSync())) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('No workspace root pubspec.yaml above ${start?.path}');
    }
    dir = parent;
  }
}

bool _isIgnored(String rel) =>
    rel.contains('/.dart_tool/') ||
    rel.contains('/build/') ||
    rel.contains('/l10n/') ||
    rel.endsWith('.g.dart') ||
    rel.endsWith('.freezed.dart') ||
    rel.endsWith('.drift.dart');

/// Removes comments and blanks string literal contents, line by line.
/// Heuristic: no multi-line strings, no `${}` interpolation awareness.
List<String> stripNonCode(List<String> lines) {
  var inBlock = false;
  final out = <String>[];
  for (final line in lines) {
    final buf = StringBuffer();
    var i = 0;
    while (i < line.length) {
      if (inBlock) {
        final end = line.indexOf('*/', i);
        if (end == -1) {
          i = line.length;
        } else {
          inBlock = false;
          i = end + 2;
        }
        continue;
      }
      if (line.startsWith('//', i)) break;
      if (line.startsWith('/*', i)) {
        inBlock = true;
        i += 2;
        continue;
      }
      final c = line[i];
      if (c == "'" || c == '"') {
        var j = i + 1;
        while (j < line.length && line[j] != c) {
          j += line[j] == r'\' ? 2 : 1;
        }
        buf.write("''");
        i = j + 1;
        continue;
      }
      buf.write(c);
      i++;
    }
    out.add(buf.toString());
  }
  return out;
}

final _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

List<DirectiveRef> _parseDirectives(String path, List<String> lines) {
  final result = <DirectiveRef>[];
  for (var i = 0; i < lines.length; i++) {
    final m = _directive.firstMatch(lines[i]);
    if (m == null) continue;
    final uri = m.group(1)!;
    result.add(
      DirectiveRef(uri: uri, target: _resolve(path, uri), line: i + 1),
    );
  }
  return result;
}

String _resolve(String from, String uri) {
  if (uri.startsWith('package:mitlio/')) {
    return 'app/lib/${uri.substring('package:mitlio/'.length)}';
  }
  if (uri.startsWith('package:mitlio_domain/')) {
    return 'packages/domain/lib/'
        '${uri.substring('package:mitlio_domain/'.length)}';
  }
  if (uri.contains(':')) return uri;
  final segments = from.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else if (part != '.' && part.isNotEmpty) {
      segments.add(part);
    }
  }
  return segments.join('/');
}
