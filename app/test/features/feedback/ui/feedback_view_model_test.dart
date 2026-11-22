import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/fakes/fake_feedback_service.dart';
import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio/features/feedback/data/feedback_providers.dart';
import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'feedback_fixtures.dart';

const _text = 'Beim Abrechnen der Fahrt steht ein falscher Betrag da.';

(ProviderContainer, FakeFeedbackService, FakeScreenshotPicker) _setup() {
  final service = FakeFeedbackService();
  final picker = FakeScreenshotPicker();
  final c = ProviderContainer(
    overrides: [
      feedbackServiceProvider.overrideWithValue(service),
      screenshotPickerProvider.overrideWithValue(picker),
      feedbackOsProvider.overrideWithValue('iOS 18.1'),
    ],
  );
  addTearDown(c.dispose);
  return (c, service, picker);
}

FeedbackViewModel _vm(ProviderContainer c) =>
    c.read(feedbackViewModelProvider.notifier);
FeedbackState _state(ProviderContainer c) => c.read(feedbackViewModelProvider);

void main() {
  test('starts empty and cannot be sent', () {
    final (c, _, _) = _setup();
    final s = _state(c);
    expect(s.type, isNull);
    expect(s.canSubmit, isFalse);
    expect(s.includeDiagnostics, isFalse, reason: 'diagnostics are opt-in');
    expect(s.toJson()['status'], 'editing');
  });

  test('needs a type, a long enough text and a plausible address', () {
    final (c, _, _) = _setup();
    _vm(c)
      ..setMessage(_text)
      ..setEmail('nope');
    expect(_state(c).canSubmit, isFalse, reason: 'no type yet');
    _vm(c).setType(FeedbackType.idea);
    expect(_state(c).emailValid, isFalse);
    expect(_state(c).canSubmit, isFalse, reason: 'bad address');
    _vm(c).setEmail('');
    expect(_state(c).canSubmit, isTrue, reason: 'the address is optional');
    _vm(c).setMessage('kurz');
    expect(_state(c).canSubmit, isFalse);
    _vm(c).setMessage('😀' * 10);
    expect(_state(c).canSubmit, isTrue, reason: 'counted in characters');
    _vm(c).setMessage('x' * (feedbackMessageMax + 1));
    expect(_state(c).canSubmit, isFalse);
  });

  test(
    'success: sends everything once, then shows thanks with an empty form',
    () async {
      final (c, service, _) = _setup();
      _vm(c)
        ..setType(FeedbackType.problem)
        ..setMessage('  $_text  ')
        ..setEmail(' mia@example.org ')
        ..setIncludeDiagnostics(include: true)
        ..addPicked([FeedbackScreenshot(pngPixel)]);
      final result = await _vm(c).submit(locale: 'de');
      expect(result, isA<Ok<void, FeedbackError>>());
      expect(service.sent, hasLength(1));
      final sent = service.sent.single;
      expect(sent.type, FeedbackType.problem);
      expect(sent.message, _text);
      expect(sent.email, 'mia@example.org');
      expect(sent.locale, 'de');
      expect(sent.screenshots, hasLength(1));
      expect(sent.diagnostics?.os, 'iOS 18.1');
      expect(_state(c).status, FeedbackStatus.sent);
      expect(_state(c).message, isEmpty);
      _vm(c).reset();
      expect(_state(c).status, FeedbackStatus.editing);
    },
  );

  test('diagnostics are only sent when switched on', () async {
    final (c, service, _) = _setup();
    _vm(c)
      ..setType(FeedbackType.question)
      ..setMessage(_text);
    await _vm(c).submit(locale: 'en');
    expect(service.sent.single.diagnostics, isNull);
    expect(service.sent.single.locale, 'en');
  });

  test('validation error: nothing is sent', () async {
    final (c, service, _) = _setup();
    _vm(c).setMessage('kurz');
    final result = await _vm(c).submit(locale: 'de');
    expect(result, isA<Err<void, FeedbackError>>());
    expect(service.sent, isEmpty);
  });

  test(
    'failure keeps the draft and says why; the next try can succeed',
    () async {
      final (c, service, _) = _setup();
      _vm(c)
        ..setType(FeedbackType.problem)
        ..setMessage(_text)
        ..addPicked([FeedbackScreenshot(pngPixel)]);
      service.failWith = const FeedbackOffline();
      final failed = await _vm(c).submit(locale: 'de');
      expect(failed, const Err<void, FeedbackError>(FeedbackOffline()));
      var s = _state(c);
      expect(s.status, FeedbackStatus.editing);
      expect(s.error, const FeedbackOffline());
      expect(s.message, _text);
      expect(s.screenshots, hasLength(1));
      expect(s.canSubmit, isTrue);

      service.failWith = null;
      await _vm(c).submit(locale: 'de');
      s = _state(c);
      expect(s.status, FeedbackStatus.sent);
      expect(s.error, isNull);
      expect(service.sent, hasLength(1));
    },
  );

  test('rate limit keeps the draft and carries the wait', () async {
    final (c, service, _) = _setup();
    _vm(c)
      ..setType(FeedbackType.problem)
      ..setMessage(_text);
    service.failWith = const FeedbackRateLimited(Duration(minutes: 12));
    await _vm(c).submit(locale: 'de');
    expect(_state(c).error, const FeedbackRateLimited(Duration(minutes: 12)));
    expect(_state(c).message, _text);
  });

  test('editing clears the last error', () async {
    final (c, service, _) = _setup();
    _vm(c)
      ..setType(FeedbackType.problem)
      ..setMessage(_text);
    service.failWith = const FeedbackServerDown();
    await _vm(c).submit(locale: 'de');
    expect(_state(c).error, isNotNull);
    _vm(c).setMessage('$_text Mehr.');
    expect(_state(c).error, isNull);
  });

  test('screenshots: at most three, removable, big ones refused', () {
    final (c, _, _) = _setup();
    final shot = FeedbackScreenshot(pngPixel);
    expect(
      _vm(c).addPicked([shot, shot, shot, shot]),
      isA<Ok<void, FeedbackError>>(),
    );
    expect(_state(c).screenshots, hasLength(3));
    expect(_state(c).canAddScreenshot, isFalse);
    _vm(c).removeScreenshot(5);
    expect(_state(c).screenshots, hasLength(3));
    _vm(c).removeScreenshot(0);
    expect(_state(c).screenshots, hasLength(2));
    expect(_state(c).canAddScreenshot, isTrue);

    final big = FeedbackScreenshot(Uint8List(feedbackMaxScreenshotBytes + 1));
    final refused = _vm(c).addPicked([big]);
    expect(
      refused,
      const Err<void, FeedbackError>(FeedbackRejected('screenshot_too_large')),
    );
    expect(_state(c).error, isA<FeedbackRejected>());
    expect(_state(c).screenshots, hasLength(2));
  });

  test(
    'photo picker: adds what was picked, cancel adds nothing, failure is shown',
    () async {
      final (c, _, picker) = _setup();
      picker.next = [
        FeedbackScreenshot(pngPixel),
        FeedbackScreenshot(pngPixel),
      ];
      expect(await _vm(c).addScreenshots(), isA<Ok<void, FeedbackError>>());
      expect(_state(c).screenshots, hasLength(2));

      picker.next = const [];
      await _vm(c).addScreenshots();
      expect(_state(c).screenshots, hasLength(2));

      picker.failWith = const FeedbackPickFailed();
      final failed = await _vm(c).addScreenshots();
      expect(failed, const Err<void, FeedbackError>(FeedbackPickFailed()));
      expect(_state(c).error, const FeedbackPickFailed());

      picker
        ..failWith = null
        ..next = [
          FeedbackScreenshot(pngPixel),
          FeedbackScreenshot(pngPixel),
        ];
      await _vm(c).addScreenshots();
      expect(_state(c).screenshots, hasLength(3), reason: 'only one free slot');
      expect(await _vm(c).addScreenshots(), isA<Err<void, FeedbackError>>());
    },
  );

  test(
    'a picture over 5 MB from the picker is refused with a reason',
    () async {
      final (c, _, picker) = _setup();
      picker.next = [
        FeedbackScreenshot(Uint8List(feedbackMaxScreenshotBytes + 1)),
      ];
      final result = await _vm(c).addScreenshots();
      expect(
        result,
        const Err<void, FeedbackError>(
          FeedbackRejected('screenshot_too_large'),
        ),
      );
      expect(_state(c).screenshots, isEmpty);
    },
  );

  test('entry is hidden when the server says it is not set up', () async {
    final (c, service, _) = _setup();
    expect(c.read(feedbackEntryVisibleProvider), isFalse, reason: 'pending');
    c.listen(feedbackEntryVisibleProvider, (_, _) {});
    await c.read(feedbackAvailabilityProvider.future);
    expect(c.read(feedbackEntryVisibleProvider), isTrue);

    service.availabilityResult = FeedbackAvailability.unavailable;
    c.invalidate(feedbackAvailabilityProvider);
    await c.read(feedbackAvailabilityProvider.future);
    expect(c.read(feedbackEntryVisibleProvider), isFalse);

    service.availabilityResult = FeedbackAvailability.unknown;
    c.invalidate(feedbackAvailabilityProvider);
    await c.read(feedbackAvailabilityProvider.future);
    expect(
      c.read(feedbackEntryVisibleProvider),
      isTrue,
      reason: 'offline probe',
    );
  });

  test('the stub used by goldens is the same state machine', () {
    final c = ProviderContainer(
      overrides: [
        feedbackViewModelProvider.overrideWith(
          () => StubFeedbackViewModel(feedbackStates[1].$2),
        ),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(feedbackViewModelProvider).canSubmit, isTrue);
  });
}
