import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const _header =
    'GENERATED from app/app_identity.yaml by '
    'packages/tooling/bin/gen_app_identity.dart. Do not edit; run `make identity`.';

/// One build flavor from `app_identity.yaml`.
class FlavorIdentity {
  const FlavorIdentity({
    required this.name,
    required this.displayName,
    required this.bundleId,
  });

  final String name;
  final String displayName;
  final String bundleId;
}

/// Parsed `app/app_identity.yaml` (ADR-16).
class AppIdentity {
  const AppIdentity({required this.flavors});

  /// Throws [FormatException] when a required key is missing or not a string.
  factory AppIdentity.parse(String source) {
    final root = loadYaml(source);
    if (root is! YamlMap || root['flavors'] is! YamlMap) {
      throw const FormatException('app_identity.yaml: missing `flavors` map');
    }
    String field(YamlMap map, String key, String flavor) {
      final value = map[key];
      if (value is! String || value.isEmpty) {
        throw FormatException(
          'app_identity.yaml: flavors.$flavor.$key must be a non-empty string',
        );
      }
      return value;
    }

    final flavors = <FlavorIdentity>[];
    for (final entry in (root['flavors'] as YamlMap).entries) {
      final name = entry.key.toString();
      final value = entry.value;
      if (value is! YamlMap) {
        throw FormatException('app_identity.yaml: flavors.$name must be a map');
      }
      flavors.add(
        FlavorIdentity(
          name: name,
          displayName: field(value, 'display_name', name),
          bundleId: field(value, 'bundle_id', name),
        ),
      );
    }
    if (flavors.isEmpty) {
      throw const FormatException('app_identity.yaml: no flavors defined');
    }
    return AppIdentity(flavors: flavors);
  }

  final List<FlavorIdentity> flavors;

  /// Generated files, keyed by path relative to the repository root.
  Map<String, String> generate() => {
    'app/android/app_identity.properties': _androidProperties(),
    for (final f in flavors)
      'app/ios/Flutter/Flavor-${f.name}.xcconfig': _xcconfig(f),
  };

  String _androidProperties() {
    final b = StringBuffer('# $_header\n');
    for (final f in flavors) {
      b
        ..writeln('${f.name}.applicationId=${f.bundleId}')
        ..writeln('${f.name}.appName=${f.displayName}');
    }
    return b.toString();
  }

  String _xcconfig(FlavorIdentity f) =>
      '// $_header\n'
      'PRODUCT_BUNDLE_IDENTIFIER = ${f.bundleId}\n'
      'APP_DISPLAY_NAME = ${f.displayName}\n';
}

/// Paths (relative to the repo root) whose content differs from [identity].
List<String> identityDrift(String root, AppIdentity identity) => [
  for (final e in identity.generate().entries)
    if (_read(p.join(root, e.key)) != e.value) e.key,
];

String? _read(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
}

/// CLI: `gen_app_identity [--root <repo>] [--check]`. Returns the exit code.
Future<int> runGenAppIdentity(
  List<String> args, {
  required StringSink out,
  required StringSink err,
}) async {
  var root = '.';
  var check = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--check':
        check = true;
      case '--root' when i + 1 < args.length:
        root = args[++i];
      default:
        err.writeln('usage: gen_app_identity [--root <repo>] [--check]');
        return 64;
    }
  }
  final AppIdentity identity;
  try {
    identity = AppIdentity.parse(
      File(p.join(root, 'app/app_identity.yaml')).readAsStringSync(),
    );
  } on FormatException catch (e) {
    err.writeln(e.message);
    return 1;
  } on FileSystemException catch (e) {
    err.writeln('cannot read app_identity.yaml: ${e.message}');
    return 1;
  }
  if (check) {
    final drift = identityDrift(root, identity);
    if (drift.isEmpty) {
      out.writeln('app identity: up to date');
      return 0;
    }
    err.writeln(
      'app identity drift (run `make identity`):\n  ${drift.join('\n  ')}',
    );
    return 1;
  }
  for (final e in identity.generate().entries) {
    final file = File(p.join(root, e.key));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(e.value);
    out.writeln('wrote ${e.key}');
  }
  return 0;
}
