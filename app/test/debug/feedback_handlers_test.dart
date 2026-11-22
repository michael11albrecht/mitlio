import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/fakes/fake_feedback_service.dart';
import 'package:mitlio/debug/handlers/feedback.dart';
import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio/features/feedback/data/feedback_providers.dart';

import '../features/feedback/ui/feedback_fixtures.dart';

/// `ext.mitlio.feedback.*` (ADR-29): the commands the form uses.
void main() {
  late FakeFeedbackService service;
  late ProviderContainer c;
  late Map<String, DriveHandler> h;

  setUp(() {
    service = FakeFeedbackService();
    c = ProviderContainer(
      overrides: [
        feedbackServiceProvider.overrideWithValue(service),
        feedbackOsProvider.overrideWithValue('iOS 18.1'),
      ],
    );
    addTearDown(c.dispose);
    h = feedbackDriveHandlers(c);
  });

  test('available reports what the probe says', () async {
    expect(await h['feedback.available']!({}), {'availability': 'available'});
    service.availabilityResult = FeedbackAvailability.unavailable;
    expect(await h['feedback.available']!({}), {'availability': 'unavailable'});
  });

  test('draft, screenshot and submit go through the view model', () async {
    var r = await h['feedback.draft']!({
      'type': 'problem',
      'message': 'Die Abrechnung zeigt einen falschen Betrag.',
      'email': 'mia@example.org',
      'diagnostics': 'true',
    });
    expect(r['type'], 'problem');
    expect(r['canSubmit'], isTrue);
    expect(r['includeDiagnostics'], isTrue);
    expect(r['hasEmail'], isTrue);

    r = await h['feedback.addScreenshot']!({});
    expect(r['screenshots'], 1);
    r = await h['feedback.addScreenshot']!({'data': base64Encode(pngPixel)});
    expect(r['screenshots'], 2);
    r = await h['feedback.removeScreenshot']!({'index': '0'});
    expect(r['screenshots'], 1);

    r = await h['feedback.submit']!({'locale': 'en'});
    expect(r['sent'], isTrue);
    expect(r['status'], 'sent');
    expect(service.sent.single.locale, 'en');
    expect(service.sent.single.diagnostics?.os, 'iOS 18.1');
    expect(service.sent.single.screenshots, hasLength(1));

    r = await h['feedback.reset']!({});
    expect(r['status'], 'editing');
    expect(r['messageLength'], 0);
  });

  test('diagnostics shows exactly what would be sent', () async {
    final r = await h['feedback.diagnostics']!({});
    expect(r['os'], 'iOS 18.1');
    expect(r['preview'], contains('iOS 18.1'));
  });

  test('failures use the error convention and keep the draft', () async {
    await h['feedback.draft']!({
      'type': 'idea',
      'message': 'Ein Vorschlag, der lang genug ist.',
    });
    service.failWith = const FeedbackRateLimited(Duration(minutes: 5));
    var r = await h['feedback.submit']!({});
    expect(r['error'], 'rate_limited');
    expect((await h['feedback.state']!({}))['messageLength'], greaterThan(10));

    service.failWith = const FeedbackOffline();
    r = await h['feedback.submit']!({});
    expect(r['error'], 'internal');

    service.failWith = const FeedbackUnavailable();
    r = await h['feedback.submit']!({});
    expect(r['error'], 'unavailable');

    service.failWith = const FeedbackRejected('invalid_screenshot');
    r = await h['feedback.submit']!({});
    expect(r['error'], 'invalid_params');
  });

  test('invalid input is invalid_params', () async {
    expect(
      (await h['feedback.draft']!({'type': 'bug'}))['error'],
      'invalid_params',
    );
    expect(
      (await h['feedback.removeScreenshot']!({'index': 'x'}))['error'],
      'invalid_params',
    );
    expect((await h['feedback.submit']!({}))['error'], 'invalid_params');
    await h['feedback.draft']!({
      'type': 'idea',
      'message': 'Genug Text für eine Idee.',
    });
    for (var i = 0; i < 3; i++) {
      await h['feedback.addScreenshot']!({});
    }
    expect((await h['feedback.addScreenshot']!({}))['screenshots'], 3);
  });
}
