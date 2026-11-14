import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A denylisted package with its category and the reason it is banned.
class DenyEntry {
  const DenyEntry(this.category, this.reason);

  final String category;
  final String reason;
}

/// Parsed `tool/deps_policy.yaml`.
class DepsPolicy {
  const DepsPolicy({required this.denylist, required this.allowlist});

  /// Parses the policy. Throws [FormatException] on bad input; every
  /// allowlist entry needs a non-empty `reason`.
  factory DepsPolicy.parse(String source) {
    final doc = loadYaml(source);
    if (doc is! YamlMap) {
      throw const FormatException('Policy must be a YAML mapping.');
    }
    final deny = <String, DenyEntry>{};
    final rawDeny = doc['denylist'];
    if (rawDeny is! YamlList || rawDeny.isEmpty) {
      throw const FormatException('"denylist" must be a non-empty list.');
    }
    for (final group in rawDeny) {
      final category = group is YamlMap ? group['category'] : null;
      final reason = group is YamlMap ? group['reason'] : null;
      final packages = group is YamlMap ? group['packages'] : null;
      if (category is! String || reason is! String || packages is! YamlList) {
        throw FormatException(
          'Each denylist group needs "category", "reason" and "packages": '
          '$group',
        );
      }
      for (final name in packages) {
        deny[name.toString()] = DenyEntry(category, reason.trim());
      }
    }
    final allow = <String, String>{};
    final rawAllow = doc['allowlist'];
    if (rawAllow != null) {
      if (rawAllow is! YamlList) {
        throw const FormatException('"allowlist" must be a list.');
      }
      for (final entry in rawAllow) {
        final name = entry is YamlMap ? entry['package'] : null;
        final reason = entry is YamlMap ? entry['reason'] : null;
        if (name is! String || reason is! String || reason.trim().isEmpty) {
          throw FormatException(
            'Each allowlist entry needs "package" and a non-empty "reason": '
            '$entry',
          );
        }
        allow[name] = reason.trim();
      }
    }
    return DepsPolicy(denylist: deny, allowlist: allow);
  }

  final Map<String, DenyEntry> denylist;
  final Map<String, String> allowlist;
}

/// Package names (direct and transitive) from a `pubspec.lock`.
Set<String> parsePubspecLock(String source) {
  final doc = loadYaml(source);
  final packages = doc is YamlMap ? doc['packages'] : null;
  if (packages is! YamlMap) {
    throw const FormatException('pubspec.lock has no "packages" mapping.');
  }
  return {for (final k in packages.keys) k.toString()};
}

/// Package names from an npm `package-lock.json` (lockfileVersion 2/3):
/// keys of `packages` of the form `node_modules/<name>`, nested ones included.
Set<String> parsePackageLock(String source) {
  final doc = jsonDecode(source);
  final packages = doc is Map<String, dynamic> ? doc['packages'] : null;
  if (packages is! Map<String, dynamic>) {
    throw const FormatException('package-lock.json has no "packages" map.');
  }
  const marker = 'node_modules/';
  return {
    for (final k in packages.keys)
      if (k.contains(marker))
        k.substring(k.lastIndexOf(marker) + marker.length),
  };
}

/// One offending package in one lockfile.
class PolicyViolation {
  const PolicyViolation(this.file, this.package, this.entry);

  final String file;
  final String package;
  final DenyEntry entry;

  @override
  String toString() =>
      '$file: "$package" is denied [${entry.category}]: ${entry.reason}';
}

List<PolicyViolation> checkPackages(
  String file,
  Set<String> packages,
  DepsPolicy policy,
) => [
  for (final name in packages.toList()..sort())
    if (policy.denylist[name] case final entry?
        when !policy.allowlist.containsKey(name))
      PolicyViolation(file, name, entry),
];

const _skipDirs = {'node_modules', '.dart_tool', 'build', '.git'};

/// Lockfiles under [root]: every `pubspec.lock` and `package-lock.json`.
List<File> findLockfiles(Directory root) => [
  for (final e in root.listSync(recursive: true, followLinks: false))
    if (e is File &&
        const {
          'pubspec.lock',
          'package-lock.json',
        }.contains(p.basename(e.path)) &&
        !p.split(p.relative(e.path, from: root.path)).any(_skipDirs.contains))
      e,
]..sort((a, b) => a.path.compareTo(b.path));

ArgParser _parser() => ArgParser()
  ..addOption('policy', defaultsTo: 'tool/deps_policy.yaml')
  ..addOption('root', defaultsTo: '.', help: 'Repo root to scan for lockfiles.')
  ..addFlag('help', abbr: 'h', negatable: false);

/// Runs the policy check. Returns the exit code (0 ok, 1 violations,
/// 64 usage error, 66 missing/invalid input).
Future<int> runDepsPolicy(
  List<String> args, {
  required StringSink out,
  required StringSink err,
}) async {
  final parser = _parser();
  final ArgResults parsed;
  try {
    parsed = parser.parse(args);
  } on FormatException catch (e) {
    err.writeln('${e.message}\n\n${parser.usage}');
    return 64;
  }
  if (parsed['help'] as bool) {
    out.writeln('usage: deps_policy [options]\n\n${parser.usage}');
    return 0;
  }
  final root = Directory(parsed['root'] as String);
  final policyFile = File(parsed['policy'] as String);
  if (!policyFile.existsSync()) {
    err.writeln('Policy file not found: ${policyFile.path}');
    return 66;
  }
  try {
    final policy = DepsPolicy.parse(policyFile.readAsStringSync());
    final violations = <PolicyViolation>[];
    final files = findLockfiles(root);
    for (final f in files) {
      final rel = p.relative(f.path, from: root.path);
      final source = f.readAsStringSync();
      final names = p.basename(f.path) == 'pubspec.lock'
          ? parsePubspecLock(source)
          : parsePackageLock(source);
      violations.addAll(checkPackages(rel, names, policy));
    }
    if (violations.isEmpty) {
      out.writeln('Deps policy: OK (${files.length} lockfiles)');
      return 0;
    }
    out.writeln('Deps policy: FAIL');
    for (final v in violations) {
      out.writeln('  $v');
    }
    out.writeln(
      'Remove the dependency, or (with owner approval) add it to the '
      'allowlist in ${policyFile.path} with a "reason".',
    );
    return 1;
  } on FormatException catch (e) {
    err.writeln('Invalid input: ${e.message}');
    return 66;
  }
}
