import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';

import '../helpers/themed_app.dart';

/// Golden matrix (plan §2.6, ADR 0022): light/dark x text scale 1.0/2.0.
/// One file per brightness `<name>_<light|dark>.png`, two columns per file
/// (scale 1.0, 2.0). Each column is a full themed app with forced brightness
/// and text scale, so goldens do not depend on platform settings.
///
/// Plain fixed-size columns instead of `GoldenTestGroup` (see ADR 0022).
Future<void> matrixGolden(
  String name,
  Widget Function() child, {
  double width = 320,
  double height = 320,
}) async {
  for (final brightness in Brightness.values) {
    await goldenTest(
      '$name, ${brightness.name}',
      fileName: '${name}_${brightness.name}',
      builder: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final scale in const [1.0, 2.0])
            SizedBox(
              width: width,
              height: height,
              child: themedApp(
                child(),
                brightness: brightness,
                textScale: scale,
              ),
            ),
        ],
      ),
    );
  }
}
