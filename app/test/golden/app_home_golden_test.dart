import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';

/// Golden matrix (plan §2.6): light/dark x text scale 1.0/2.0.
/// Brightness comes from the platform dispatcher (what `ThemeMode.system`
/// reads), text scale from a per-scenario `MediaQuery`.
Widget _scale(double scale) {
  return GoldenTestScenario.builder(
    name: 'text scale $scale',
    builder: (context) => SizedBox(
      width: 200,
      height: 200,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: const MitlioApp(),
      ),
    ),
  );
}

Future<void> _matrixGolden(Brightness brightness) async {
  await goldenTest(
    'MitlioApp home, ${brightness.name}',
    fileName: 'app_home_${brightness.name}',
    pumpWidget: (tester, widget) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(widget);
    },
    builder: () => GoldenTestGroup(
      // Integer column widths: fractional intrinsic widths antialias the
      // table border differently on macOS and Linux.
      columnWidthBuilder: (_) => const FixedColumnWidth(256),
      children: [_scale(1), _scale(2)],
    ),
  );
}

Future<void> main() async {
  await _matrixGolden(Brightness.light);
  await _matrixGolden(Brightness.dark);
}
