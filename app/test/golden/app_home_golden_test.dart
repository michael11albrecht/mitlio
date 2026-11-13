import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';

/// Golden matrix (plan §2.6): light/dark x text scale 1.0/2.0.
/// Brightness comes from the platform dispatcher (what `ThemeMode.system`
/// reads), text scale from a per-column `MediaQuery`.
///
/// Plain fixed-size columns instead of `GoldenTestGroup`: its table border
/// sits on fractional pixels and antialiases differently on macOS and Linux.
Widget _scale(BuildContext context, double scale) {
  return SizedBox(
    width: 200,
    height: 200,
    child: MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: const MitlioApp(),
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
    builder: () => Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [_scale(context, 1), _scale(context, 2)],
      ),
    ),
  );
}

Future<void> main() async {
  await _matrixGolden(Brightness.light);
  await _matrixGolden(Brightness.dark);
}
