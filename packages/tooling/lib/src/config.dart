import 'package:yaml/yaml.dart';

/// Minimum line coverage for all files matching [glob].
class Threshold {
  const Threshold(this.glob, this.min);

  final String glob;
  final double min;
}

class GateConfig {
  const GateConfig({required this.exclude, required this.thresholds});

  /// Parses `tool/coverage_thresholds.yaml` content.
  factory GateConfig.parse(String source) {
    final doc = loadYaml(source);
    if (doc is! YamlMap) {
      throw const FormatException('Config must be a YAML mapping.');
    }
    final exclude = <String>[];
    final rawExclude = doc['exclude'];
    if (rawExclude != null) {
      if (rawExclude is! YamlList) {
        throw const FormatException('"exclude" must be a list of globs.');
      }
      exclude.addAll(rawExclude.map((e) => e.toString()));
    }
    final rawThresholds = doc['thresholds'];
    if (rawThresholds is! YamlList || rawThresholds.isEmpty) {
      throw const FormatException('"thresholds" must be a non-empty list.');
    }
    final thresholds = <Threshold>[];
    for (final entry in rawThresholds) {
      final glob = entry is YamlMap ? entry['glob'] : null;
      final min = entry is YamlMap ? entry['min'] : null;
      if (glob is! String || min is! num) {
        throw FormatException(
          'Each threshold needs a string "glob" and numeric "min": $entry',
        );
      }
      thresholds.add(Threshold(glob, min.toDouble()));
    }
    return GateConfig(exclude: exclude, thresholds: thresholds);
  }

  /// Globs of files removed before any computation (generated code).
  final List<String> exclude;
  final List<Threshold> thresholds;
}
