import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/debug/fakes/fake_feedback_service.dart';
import 'package:mitlio/features/feedback/data/feedback_providers.dart';
import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';

import '../../../helpers/fake_app.dart';
import '../../../support/tap_counter.dart';
import 'feedback_fixtures.dart';

Future<(ProviderContainer, FakeFeedbackService, FakeScreenshotPicker)> _open(
  WidgetTester tester, {
  FeedbackAvailability availability = FeedbackAvailability.available,
}) async {
  tester.platformDispatcher.localesTestValue = [const Locale('de')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final service = FakeFeedbackService(availabilityResult: availability);
  final picker = FakeScreenshotPicker([FeedbackScreenshot(pngPixel)]);
  final c = ProviderContainer(
    overrides: [
      ...FakeApp().overrides,
      feedbackServiceProvider.overrideWithValue(service),
      screenshotPickerProvider.overrideWithValue(picker),
      feedbackOsProvider.overrideWithValue('iOS 18.1'),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const MitlioApp()),
  );
  c.read(routerProvider).go('/settings');
  await tester.pumpAndSettle();
  return (c, service, picker);
}

Future<void> _openForm(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Feedback'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Feedback'));
  await tester.pumpAndSettle();
}

FilledButton _send(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton).first);

void main() {
  testWidgets('the Settings row is hidden while the server says unconfigured', (
    tester,
  ) async {
    await _open(tester, availability: FeedbackAvailability.unavailable);
    expect(find.text('Feedback'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Alle meine Daten löschen'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Feedback'), findsNothing);
  });

  testWidgets('type, text, send: thanks, then an empty form', (tester) async {
    final (_, service, _) = await _open(tester);
    final taps = TapCounter(tester);
    await tester.scrollUntilVisible(
      find.text('Feedback'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await taps.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    expect(_send(tester).onPressed, isNull);
    expect(find.text('Wird gesendet …'), findsNothing);

    await taps.tap(find.text('Idee'));
    await tester.pump();
    await taps.enterText(
      find.byType(TextField).first,
      'Ein Export als Tabelle wäre schön.',
    );
    await tester.pump();
    expect(_send(tester).onPressed, isNotNull);

    await taps.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    taps.expectWithinBudget('send_feedback');
    expect(service.sent.single.type, FeedbackType.idea);
    expect(service.sent.single.message, 'Ein Export als Tabelle wäre schön.');
    expect(find.text('Danke, wir lesen jede Nachricht.'), findsOneWidget);

    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(find.text('Danke, wir lesen jede Nachricht.'), findsNothing);
  });

  testWidgets('a failed send keeps the text and says what to do', (
    tester,
  ) async {
    final (_, service, _) = await _open(tester);
    service.failWith = const FeedbackRateLimited(Duration(minutes: 12));
    await _openForm(tester);
    await tester.tap(find.text('Problem'));
    await tester.enterText(
      find.byType(TextField).first,
      'Die Abrechnung stimmt nicht.',
    );
    await tester.pump();
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('in 12 Min.'), findsWidgets);
    expect(find.text('Die Abrechnung stimmt nicht.'), findsOneWidget);
    expect(_send(tester).onPressed, isNotNull);

    service.failWith = null;
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Danke, wir lesen jede Nachricht.'), findsOneWidget);
  });

  testWidgets('screenshots and the app info preview', (tester) async {
    final (c, _, _) = await _open(tester);
    await _openForm(tester);
    expect(find.textContaining('iOS 18.1'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    await tester.tap(find.text('Screenshot hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byTooltip('Screenshot entfernen'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(c.read(feedbackViewModelProvider).screenshots, isEmpty);
  });

  testWidgets('the draft survives leaving the screen', (tester) async {
    final (c, _, _) = await _open(tester);
    await _openForm(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'Noch nicht fertig geschrieben',
    );
    await tester.pump();
    c.read(routerProvider).pop();
    await tester.pumpAndSettle();
    await _openForm(tester);
    expect(find.text('Noch nicht fertig geschrieben'), findsOneWidget);
  });
}
