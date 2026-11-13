import 'package:path/path.dart' as p;

/// Line coverage of one source file: line number -> execution count.
class FileCoverage {
  FileCoverage(this.path, [Map<int, int>? lines]) : lines = lines ?? {};

  /// Repo-relative, forward-slash path.
  final String path;
  final Map<int, int> lines;

  int get found => lines.length;
  int get hit => lines.values.where((h) => h > 0).length;
}

/// Normalises an lcov `SF:` path to a repo-relative, forward-slash path.
///
/// Absolute paths are made relative to [root] when they live below it.
/// Relative paths get [prefix] (the package root, e.g. `packages/domain`)
/// prepended.
String normalizePath(String raw, {String prefix = '', String? root}) {
  var path = raw.trim().replaceAll(r'\', '/');
  if (p.posix.isAbsolute(path)) {
    final base = root?.replaceAll(r'\', '/');
    if (base != null && p.posix.isWithin(base, path)) {
      return p.posix.normalize(p.posix.relative(path, from: base));
    }
    return p.posix.normalize(path);
  }
  final pre = prefix.replaceAll(r'\', '/');
  path = pre.isEmpty ? path : p.posix.join(pre, path);
  return p.posix.normalize(path);
}

/// Parses lcov [content] into per-file line coverage.
///
/// Only `SF`, `DA` and `end_of_record` records are used; everything else
/// (function and branch data) is ignored. Malformed `DA` lines throw a
/// [FormatException].
Map<String, FileCoverage> parseLcov(
  String content, {
  String prefix = '',
  String? root,
}) {
  final result = <String, FileCoverage>{};
  FileCoverage? current;
  for (final raw in content.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      final path = normalizePath(
        line.substring(3),
        prefix: prefix,
        root: root,
      );
      current = result.putIfAbsent(path, () => FileCoverage(path));
    } else if (line.startsWith('DA:')) {
      final file = current;
      if (file == null) {
        throw FormatException('DA record outside of SF block: $line');
      }
      final parts = line.substring(3).split(',');
      final number = parts.length >= 2 ? int.tryParse(parts[0]) : null;
      final hits = parts.length >= 2 ? int.tryParse(parts[1]) : null;
      if (number == null || hits == null) {
        throw FormatException('Malformed DA record: $line');
      }
      final previous = file.lines[number] ?? 0;
      file.lines[number] = hits > previous ? hits : previous;
    } else if (line == 'end_of_record') {
      current = null;
    }
  }
  return result;
}

/// Merges [others] into one map; same file and line keeps the max hit count.
Map<String, FileCoverage> mergeCoverage(
  Iterable<Map<String, FileCoverage>> others,
) {
  final merged = <String, FileCoverage>{};
  for (final map in others) {
    for (final file in map.values) {
      final target = merged.putIfAbsent(
        file.path,
        () => FileCoverage(file.path),
      );
      file.lines.forEach((line, hits) {
        final previous = target.lines[line] ?? 0;
        target.lines[line] = hits > previous ? hits : previous;
      });
    }
  }
  return merged;
}
