import 'dart:convert';

import 'package:glob/glob.dart';

import 'package:mitlio_tooling/src/config.dart';
import 'package:mitlio_tooling/src/lcov.dart';

enum GateStatus { pass, fail, skip }

class GlobResult {
  const GlobResult({
    required this.glob,
    required this.hit,
    required this.found,
    required this.threshold,
  });

  final String glob;
  final int hit;
  final int found;
  final double threshold;

  /// Percent in 0..100, or null when no lines matched.
  double? get percent => found == 0 ? null : hit * 100 / found;

  GateStatus get status {
    final pct = percent;
    if (pct == null) return GateStatus.skip;
    return pct >= threshold ? GateStatus.pass : GateStatus.fail;
  }
}

class RatchetFailure {
  const RatchetFailure(this.glob, this.baseline, this.current);

  final String glob;
  final double baseline;
  final double current;

  double get drop => baseline - current;
}

class GateReport {
  const GateReport(this.results, this.ratchetFailures);

  final List<GlobResult> results;
  final List<RatchetFailure> ratchetFailures;

  bool get passed =>
      ratchetFailures.isEmpty &&
      results.every((r) => r.status != GateStatus.fail);

  /// JSON summary usable as a later `--baseline`.
  String toSummaryJson() => const JsonEncoder.withIndent('  ').convert({
    'globs': {
      for (final r in results)
        r.glob: {'hit': r.hit, 'found': r.found, 'percent': r.percent},
    },
  });
}

/// Removes files matching any [excludes] glob.
Map<String, FileCoverage> applyExcludes(
  Map<String, FileCoverage> files,
  List<String> excludes,
) {
  final globs = excludes.map((e) => Glob(e, recursive: true)).toList();
  return {
    for (final e in files.entries)
      if (!globs.any((g) => g.matches(e.key))) e.key: e.value,
  };
}

/// Reads per-glob percentages from a summary written by
/// [GateReport.toSummaryJson]. Globs without lines are omitted.
Map<String, double> parseBaseline(String json) {
  final decoded = jsonDecode(json);
  final globs = decoded is Map<String, dynamic> ? decoded['globs'] : null;
  if (globs is! Map<String, dynamic>) {
    throw const FormatException('Baseline has no "globs" object.');
  }
  return {
    for (final e in globs.entries)
      if (e.value is Map<String, dynamic> &&
          (e.value as Map<String, dynamic>)['percent'] is num)
        e.key: ((e.value as Map<String, dynamic>)['percent'] as num).toDouble(),
  };
}

/// Evaluates [config] against [files] (already merged and normalised).
GateReport evaluate(
  Map<String, FileCoverage> files,
  GateConfig config, {
  Map<String, double> baseline = const {},
  double maxDrop = 0.5,
}) {
  final included = applyExcludes(files, config.exclude);
  final results = <GlobResult>[];
  for (final t in config.thresholds) {
    final glob = Glob(t.glob, recursive: true);
    var hit = 0;
    var found = 0;
    for (final f in included.values) {
      if (glob.matches(f.path)) {
        hit += f.hit;
        found += f.found;
      }
    }
    results.add(
      GlobResult(glob: t.glob, hit: hit, found: found, threshold: t.min),
    );
  }
  final failures = <RatchetFailure>[];
  for (final r in results) {
    final before = baseline[r.glob];
    final now = r.percent;
    if (before != null && now != null && before - now > maxDrop) {
      failures.add(RatchetFailure(r.glob, before, now));
    }
  }
  return GateReport(results, failures);
}

/// Human/agent readable table plus failure explanation.
String renderReport(GateReport report) {
  final rows = <List<String>>[
    ['GLOB', 'HIT/FOUND', 'COVERAGE', 'THRESHOLD', 'STATUS'],
    for (final r in report.results)
      [
        r.glob,
        '${r.hit}/${r.found}',
        if (r.percent case final pct?) '${pct.toStringAsFixed(2)}%' else '-',
        '>= ${r.threshold.toStringAsFixed(1)}%',
        switch (r.status) {
          GateStatus.pass => 'PASS',
          GateStatus.fail => 'FAIL',
          GateStatus.skip => 'SKIP (no lines)',
        },
      ],
  ];
  final widths = List.generate(
    rows.first.length,
    (i) => rows.map((r) => r[i].length).reduce((a, b) => a > b ? a : b),
  );
  final buf = StringBuffer();
  for (final row in rows) {
    buf.writeln(
      [for (var i = 0; i < row.length; i++) row[i].padRight(widths[i])]
          .join('  ')
          .trimRight(),
    );
  }
  for (final f in report.ratchetFailures) {
    buf.writeln(
      'RATCHET FAIL: ${f.glob} dropped ${f.drop.toStringAsFixed(2)} pp '
      '(${f.baseline.toStringAsFixed(2)}% -> '
      '${f.current.toStringAsFixed(2)}%, max 0.5 pp)',
    );
  }
  buf.writeln(
    report.passed ? 'Coverage gate: PASS' : 'Coverage gate: FAIL',
  );
  return buf.toString();
}
