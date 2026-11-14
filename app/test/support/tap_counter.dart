import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tap budgets per flow, parsed from the fenced JSON block of
/// `docs/ux-budgets.md` (single source, plan §2.6).
class UxBudgets {
  const UxBudgets(this.maxTaps);

  /// Parses the first fenced json block of [markdown]. Throws
  /// [FormatException] if it is missing or not `{flow: {maxTaps: int}}`.
  factory UxBudgets.parse(String markdown) {
    final match = RegExp(
      r'```json\s*\n(.*?)```',
      dotAll: true,
    ).firstMatch(markdown);
    if (match == null) {
      throw const FormatException('No fenced json block in ux-budgets.md.');
    }
    final doc = jsonDecode(match.group(1)!);
    if (doc is! Map<String, dynamic> || doc.isEmpty) {
      throw const FormatException('Budget block must be a non-empty object.');
    }
    return UxBudgets({
      for (final e in doc.entries)
        e.key: switch (e.value) {
          {'maxTaps': final int n} when n >= 0 => n,
          _ => throw FormatException(
            'Flow "${e.key}" needs {"maxTaps": <int >= 0>}.',
          ),
        },
    });
  }

  /// Loads `docs/ux-budgets.md` by walking up from the working directory.
  factory UxBudgets.load() {
    var dir = Directory.current.absolute;
    while (true) {
      final file = File('${dir.path}/docs/ux-budgets.md');
      if (file.existsSync()) return UxBudgets.parse(file.readAsStringSync());
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError('docs/ux-budgets.md not found above the cwd.');
      }
      dir = parent;
    }
  }

  final Map<String, int> maxTaps;
}

/// Wraps [WidgetTester] taps and text entry for one flow and checks the tap
/// count against `docs/ux-budgets.md`. Text entry is counted separately and
/// does not consume the tap budget.
class TapCounter {
  TapCounter(this.tester, {this.budgets});

  final WidgetTester tester;

  /// Defaults to `docs/ux-budgets.md`, loaded on first use.
  UxBudgets? budgets;

  int taps = 0;
  int textEntries = 0;

  /// Taps [finder] and counts it.
  Future<void> tap(Finder finder, {bool warnIfMissed = true}) async {
    taps++;
    await tester.tap(finder, warnIfMissed: warnIfMissed);
  }

  /// Enters [text] into [finder]; not counted as a tap.
  Future<void> enterText(Finder finder, String text) async {
    textEntries++;
    await tester.enterText(finder, text);
  }

  /// Fails if the taps counted so far exceed the budget of [flow].
  void expectWithinBudget(String flow) {
    final max = (budgets ??= UxBudgets.load()).maxTaps[flow];
    if (max == null) {
      fail('No tap budget for flow "$flow" in docs/ux-budgets.md.');
    }
    expect(
      taps,
      lessThanOrEqualTo(max),
      reason: 'Flow "$flow" used $taps taps, budget is $max.',
    );
  }
}
