import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'themed_app.dart';

/// Runs [body] for light/dark x text scale 1.0/2.0 with a fresh pump each.
void forEachMode(
  String description,
  Widget Function() child,
  Future<void> Function(WidgetTester tester, Brightness b, double scale) body,
) {
  for (final brightness in Brightness.values) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('$description (${brightness.name}, x$scale)', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          themedApp(child(), brightness: brightness, textScale: scale),
        );
        await tester.pumpAndSettle();
        await body(tester, brightness, scale);
        semantics.dispose();
      });
    }
  }
}

/// Standard guideline set from plan §2.6.
Future<void> expectAccessible(WidgetTester tester) async {
  // Overflow or clipping errors (e.g. at text scale 2.0) surface as exceptions.
  expect(tester.takeException(), isNull);
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
}
