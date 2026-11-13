import 'dart:io';

import 'package:args/args.dart';

import 'package:mitlio_tooling/src/config.dart';
import 'package:mitlio_tooling/src/gate.dart';
import 'package:mitlio_tooling/src/lcov.dart';

ArgParser _parser() => ArgParser()
  ..addMultiOption(
    'lcov',
    help:
        'lcov file, optionally "<path>=<package-root-prefix>" to make its '
        'paths repo-relative (e.g. coverage/lcov.info=packages/domain). '
        'Positional args are treated like --lcov.',
    valueHelp: 'path[=prefix]',
  )
  ..addOption(
    'config',
    defaultsTo: 'tool/coverage_thresholds.yaml',
    help: 'Threshold config file.',
  )
  ..addOption('baseline', help: 'Summary JSON from a previous run.')
  ..addOption('write-summary', help: 'Write a summary JSON for later use.')
  ..addOption(
    'root',
    help: 'Repo root; absolute lcov paths below it become repo-relative.',
    defaultsTo: '.',
  )
  ..addFlag('help', abbr: 'h', negatable: false);

/// Runs the gate. Returns the process exit code (0 ok, 1 gate failed,
/// 64 usage error, 66 missing input).
Future<int> runCoverageGate(
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
    out.writeln(
      'usage: coverage_gate [options] [lcov paths...]\n\n${parser.usage}',
    );
    return 0;
  }
  final inputs = [...(parsed['lcov'] as List<String>), ...parsed.rest];
  if (inputs.isEmpty) {
    err.writeln('No lcov files given.\n\n${parser.usage}');
    return 64;
  }
  final root = Directory(parsed['root'] as String).absolute.path;

  try {
    final configFile = File(parsed['config'] as String);
    if (!configFile.existsSync()) {
      err.writeln('Config not found: ${configFile.path}');
      return 66;
    }
    final config = GateConfig.parse(configFile.readAsStringSync());

    final maps = <Map<String, FileCoverage>>[];
    for (final input in inputs) {
      final eq = input.indexOf('=');
      final path = eq < 0 ? input : input.substring(0, eq);
      final prefix = eq < 0 ? '' : input.substring(eq + 1);
      final file = File(path);
      if (!file.existsSync()) {
        err.writeln('lcov file not found: $path');
        return 66;
      }
      maps.add(
        parseLcov(file.readAsStringSync(), prefix: prefix, root: root),
      );
    }

    var baseline = <String, double>{};
    final baselinePath = parsed['baseline'] as String?;
    if (baselinePath != null) {
      final file = File(baselinePath);
      if (!file.existsSync()) {
        err.writeln('Baseline not found: $baselinePath');
        return 66;
      }
      baseline = parseBaseline(file.readAsStringSync());
    }

    final report = evaluate(
      mergeCoverage(maps),
      config,
      baseline: baseline,
    );
    out.write(renderReport(report));

    final summaryPath = parsed['write-summary'] as String?;
    if (summaryPath != null) {
      File(summaryPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(report.toSummaryJson());
    }
    return report.passed ? 0 : 1;
  } on FormatException catch (e) {
    err.writeln('Invalid input: ${e.message}');
    return 65;
  }
}
