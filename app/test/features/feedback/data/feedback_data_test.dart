import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/fakes/fake_feedback_service.dart';
import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio/features/feedback/data/feedback_providers.dart';
import 'package:mitlio/features/feedback/data/repositories/feedback_repository.dart';
import 'package:mitlio/features/feedback/data/services/feedback_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../ui/feedback_fixtures.dart';

FeedbackSubmission _submission({List<FeedbackScreenshot> shots = const []}) =>
    FeedbackSubmission(
      type: FeedbackType.idea,
      message: 'Eine Idee für die Abrechnung.',
      locale: 'de',
      email: 'mia@example.org',
      diagnostics: const FeedbackDiagnostics(
        appVersion: '0.3.0',
        os: 'iOS 18',
        locale: 'de_DE',
      ),
      screenshots: shots,
    );

void main() {
  group('request body (docs/feedback-api.md)', () {
    test('has the contract fields and base64 screenshots', () {
      final body = buildFeedbackBody(
        _submission(shots: [FeedbackScreenshot(pngPixel)]),
      );
      expect(body['type'], 'idea');
      expect(body['message'], 'Eine Idee für die Abrechnung.');
      expect(body['email'], 'mia@example.org');
      expect(body['locale'], 'de');
      expect(body['diagnostics'], {
        'appVersion': '0.3.0',
        'os': 'iOS 18',
        'locale': 'de_DE',
      });
      expect(body['screenshots'], [
        {'data': base64Encode(pngPixel)},
      ]);
    });

    test('without the opt-in no diagnostics key carries data', () {
      const s = FeedbackSubmission(
        type: FeedbackType.problem,
        message: 'Etwas geht nicht, bitte ansehen.',
        locale: 'en',
      );
      expect(buildFeedbackBody(s)['diagnostics'], isNull);
      expect(buildFeedbackBody(s)['screenshots'], isEmpty);
    });

    test('the GitHub token has no place in the app', () {
      final json = jsonEncode(buildFeedbackBody(_submission()));
      expect(json.toLowerCase(), isNot(contains('github')));
    });
  });

  group('answers', () {
    FeedbackError? error(int status, String body) =>
        switch (parseFeedbackResponse(status, body)) {
          Ok() => null,
          Err(:final error) => error,
        };

    test('200 is success', () {
      expect(
        parseFeedbackResponse(200, '{"ok":true}'),
        isA<Ok<void, FeedbackError>>(),
      );
    });

    test('rate limit carries the wait, busy is its own case', () {
      expect(
        error(429, '{"error":"rate_limited","retryAfter":720}'),
        const FeedbackRateLimited(Duration(seconds: 720)),
      );
      expect(
        error(429, '{"error":"rate_limited"}'),
        const FeedbackRateLimited(null),
      );
      expect(
        error(429, '{"error":"busy","retryAfter":864}'),
        const FeedbackBusy(Duration(seconds: 864)),
      );
    });

    test('unconfigured is not "offline"', () {
      expect(
        error(503, '{"error":"provider_unconfigured"}'),
        const FeedbackUnavailable(),
      );
      expect(
        error(503, '{"error":"rate_limit_unavailable"}'),
        const FeedbackServerDown(),
      );
    });

    test('refused content keeps the code', () {
      expect(
        error(413, '{"error":"screenshot_too_large"}'),
        const FeedbackRejected('screenshot_too_large'),
      );
      expect(
        (error(400, '{"error":"invalid_screenshot"}')! as FeedbackRejected)
            .badScreenshot,
        isTrue,
      );
      expect(error(400, 'not json'), const FeedbackRejected('invalid'));
    });

    test('server failures and unreadable answers are server problems', () {
      expect(error(502, '{"error":"send_failed"}'), const FeedbackServerDown());
      expect(
        error(502, '{"error":"upload_failed"}'),
        const FeedbackServerDown(),
      );
      expect(error(500, ''), const FeedbackServerDown());
      expect(error(405, '[]'), const FeedbackServerDown());
    });
  });

  group('HttpFeedbackService', () {
    late HttpServer server;
    late HttpFeedbackService service;
    late List<(String method, Map<String, String> headers, String body)> seen;
    var status = 200;
    var answer = '{"ok":true}';

    setUp(() async {
      seen = [];
      status = 200;
      answer = '{"ok":true}';
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((req) async {
          final body = await utf8.decodeStream(req);
          final headers = <String, String>{};
          req.headers.forEach((k, v) => headers[k] = v.join(','));
          seen.add((req.method, headers, body));
          req.response
            ..statusCode = status
            ..write(answer);
          await req.response.close();
        });
      service = HttpFeedbackService(
        baseUrl: 'http://127.0.0.1:${server.port}/',
        anonKey: 'anon',
      );
    });

    tearDown(() => server.close(force: true));

    test('posts to the function with the anon key', () async {
      final result = await service.submit(_submission());
      expect(result, isA<Ok<void, FeedbackError>>());
      final (method, headers, body) = seen.single;
      expect(method, 'POST');
      expect(headers['apikey'], 'anon');
      expect(headers['authorization'], 'Bearer anon');
      expect((jsonDecode(body) as Map<String, Object?>)['type'], 'idea');
      expect(service.uri.path, '/functions/v1/submit-feedback');
    });

    test('maps an answer', () async {
      status = 429;
      answer = '{"error":"rate_limited","retryAfter":60}';
      expect(
        await service.submit(_submission()),
        const Err<void, FeedbackError>(
          FeedbackRateLimited(Duration(seconds: 60)),
        ),
      );
    });

    test('probe: available, unconfigured, unknown', () async {
      expect(await service.availability(), FeedbackAvailability.available);
      expect(seen.single.$1, 'GET');
      status = 503;
      answer = '{"error":"provider_unconfigured"}';
      expect(await service.availability(), FeedbackAvailability.unavailable);
      status = 503;
      answer = '{"error":"rate_limit_unavailable"}';
      expect(await service.availability(), FeedbackAvailability.unknown);
      status = 500;
      answer = '';
      expect(await service.availability(), FeedbackAvailability.unknown);
    });

    test('no answer at all is the only "offline"', () async {
      final dead = HttpFeedbackService(
        baseUrl: 'http://127.0.0.1:1',
        anonKey: 'a',
      );
      expect(
        await dead.submit(_submission()),
        const Err<void, FeedbackError>(FeedbackOffline()),
      );
      expect(await dead.availability(), FeedbackAvailability.unknown);
    });
  });

  group('no backend', () {
    test('the row stays hidden and sending says it is unavailable', () async {
      const service = UnavailableFeedbackService();
      expect(await service.availability(), FeedbackAvailability.unavailable);
      expect(
        await service.submit(_submission()),
        const Err<void, FeedbackError>(FeedbackUnavailable()),
      );
    });
  });

  group('ServiceFeedbackRepository', () {
    test('refuses what the server would refuse, without calling it', () async {
      final service = FakeFeedbackService();
      final repo = ServiceFeedbackRepository(
        service: service,
        picker: FakeScreenshotPicker(),
      );
      final four = List.filled(4, FeedbackScreenshot(pngPixel));
      expect(
        await repo.submit(_submission(shots: four)),
        const Err<void, FeedbackError>(
          FeedbackRejected('too_many_screenshots'),
        ),
      );
      final big = FeedbackScreenshot(Uint8List(feedbackMaxScreenshotBytes + 1));
      expect(
        await repo.submit(_submission(shots: [big])),
        const Err<void, FeedbackError>(
          FeedbackRejected('screenshot_too_large'),
        ),
      );
      expect(service.sent, isEmpty);
      expect(await repo.submit(_submission()), isA<Ok<void, FeedbackError>>());
      expect(service.sent, hasLength(1));
      expect(await repo.availability(), FeedbackAvailability.available);
    });
  });

  group('diagnostics', () {
    test('values stay inside what the server accepts', () {
      expect(
        sanitizeDiagnostic('ios Version 18.1 (Build 22B83)'),
        'ios Version 18.1 (Build 22B83)',
      );
      expect(sanitizeDiagnostic('a\nb;c`d'), 'a b c d');
      expect(sanitizeDiagnostic('x' * 80), hasLength(40));
      expect(sanitizeDiagnostic('   '), 'unknown');
      expect(sanitizeDiagnostic('de_DE'), 'de_DE');
    });

    test('preview is one line with the three values', () {
      const d = FeedbackDiagnostics(
        appVersion: '0.3.0',
        os: 'iOS 18',
        locale: 'de_DE',
      );
      expect(d.preview, '0.3.0 · iOS 18 · de_DE');
    });
  });
}
