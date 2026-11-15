import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/widgets/number_pad_done.dart';

import '../../helpers/themed_app.dart';

Widget _form() => const Column(
  children: [
    NumberPadDone(
      child: TextField(
        key: Key('num'),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    ),
    TextField(key: Key('text')),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  double textScale = 1,
  bool keyboard = true,
}) async {
  if (keyboard) {
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);
  }
  await tester.pumpWidget(themedApp(_form(), textScale: textScale));
}

void main() {
  testWidgets('iOS: bar shows for a numeric field and Fertig closes it', (
    tester,
  ) async {
    _platform(TargetPlatform.iOS);
    await _pump(tester);
    expect(find.text('Fertig'), findsNothing);

    await tester.tap(find.byKey(const Key('num')));
    await tester.pump();
    expect(find.text('Fertig'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextButton)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('Fertig'));
    await tester.pump();
    expect(find.text('Fertig'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('iOS: no bar for a plain text field', (tester) async {
    _platform(TargetPlatform.iOS);
    await _pump(tester);
    await tester.tap(find.byKey(const Key('text')));
    await tester.pump();
    expect(find.text('Fertig'), findsNothing);
  });

  testWidgets('iOS: bar leaves when focus moves to a text field', (
    tester,
  ) async {
    _platform(TargetPlatform.iOS);
    await _pump(tester);
    await tester.tap(find.byKey(const Key('num')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('text')));
    await tester.pump();
    expect(find.text('Fertig'), findsNothing);
  });

  testWidgets('Android: no bar', (tester) async {
    _platform(TargetPlatform.android);
    await _pump(tester);
    await tester.tap(find.byKey(const Key('num')));
    await tester.pump();
    expect(find.text('Fertig'), findsNothing);
  });

  testWidgets('iOS: no bar without an on-screen keyboard', (tester) async {
    _platform(TargetPlatform.iOS);
    await _pump(tester, keyboard: false);
    await tester.tap(find.byKey(const Key('num')));
    await tester.pump();
    expect(find.text('Fertig'), findsNothing);
  });

  testWidgets('iOS: usable at text scale 2.0 and exposed as a button', (
    tester,
  ) async {
    _platform(TargetPlatform.iOS);
    final handle = tester.ensureSemantics();
    await _pump(tester, textScale: 2);
    await tester.tap(find.byKey(const Key('num')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(TextButton)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      find.bySemanticsLabel('Fertig'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Fertig')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });
}

void _platform(TargetPlatform p) {
  debugDefaultTargetPlatformOverride = p;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
}
