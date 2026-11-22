import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mitlio/features/feedback/data/feedback_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The `submit-feedback` Edge Function (contract: docs/feedback-api.md).
abstract interface class FeedbackService {
  /// The probe: does the backend take feedback?
  Future<FeedbackAvailability> availability();

  Future<FeedbackResult<void>> submit(FeedbackSubmission submission);
}

/// No backend configured (empty `SUPABASE_URL`): no Feedback row.
class UnavailableFeedbackService implements FeedbackService {
  const UnavailableFeedbackService();

  @override
  Future<FeedbackAvailability> availability() async =>
      FeedbackAvailability.unavailable;

  @override
  Future<FeedbackResult<void>> submit(FeedbackSubmission submission) async =>
      const Err(FeedbackUnavailable());
}

/// Calls the Edge Function over `dart:io` (no extra package). The GitHub
/// token is server-side only; the app sends the report and the anon key.
class HttpFeedbackService implements FeedbackService {
  HttpFeedbackService({
    required this.baseUrl,
    required this.anonKey,
    HttpClient Function()? clientFactory,
    this.probeTimeout = const Duration(seconds: 6),
    this.submitTimeout = const Duration(seconds: 60),
  }) : _clientFactory = clientFactory ?? HttpClient.new;

  final String baseUrl;
  final String anonKey;
  final Duration probeTimeout;
  final Duration submitTimeout;
  final HttpClient Function() _clientFactory;

  Uri get uri {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root/functions/v1/submit-feedback');
  }

  @override
  Future<FeedbackAvailability> availability() async {
    final client = _clientFactory()..connectionTimeout = probeTimeout;
    try {
      final request = await client.getUrl(uri);
      _authorize(request);
      final response = await request.close().timeout(probeTimeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(probeTimeout);
      return switch (response.statusCode) {
        200 => FeedbackAvailability.available,
        503 when body.contains('provider_unconfigured') =>
          FeedbackAvailability.unavailable,
        // Anything else (gateway error, rate limit, ...) says nothing about
        // the setup: keep the row, the send shows the real answer.
        _ => FeedbackAvailability.unknown,
      };
    } on Object {
      return FeedbackAvailability.unknown;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<FeedbackResult<void>> submit(FeedbackSubmission submission) async {
    final client = _clientFactory()..connectionTimeout = probeTimeout;
    try {
      final request = await client.postUrl(uri);
      _authorize(request);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(buildFeedbackBody(submission))));
      final response = await request.close().timeout(submitTimeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(submitTimeout);
      return parseFeedbackResponse(response.statusCode, body);
    } on Object {
      // The server never answered (socket, TLS, timeout): the only case that
      // may say "no connection".
      return const Err(FeedbackOffline());
    } finally {
      client.close(force: true);
    }
  }

  void _authorize(HttpClientRequest request) => request.headers
    ..set('apikey', anonKey)
    ..set(HttpHeaders.authorizationHeader, 'Bearer $anonKey')
    ..set(HttpHeaders.acceptHeader, 'application/json');
}

/// The JSON body of the contract.
Map<String, Object?> buildFeedbackBody(FeedbackSubmission s) => {
  'type': s.type.name,
  'message': s.message,
  'email': s.email,
  'locale': s.locale,
  'diagnostics': s.diagnostics?.toJson(),
  'screenshots': [
    for (final shot in s.screenshots) {'data': base64Encode(shot.bytes)},
  ],
};

/// Maps the function's answer to a result (docs/feedback-api.md).
FeedbackResult<void> parseFeedbackResponse(int status, String body) {
  if (status == 200) return const Ok(null);
  final json = _json(body);
  final code = json?['error'] is String ? json!['error']! as String : '';
  final retry = json?['retryAfter'];
  final wait = retry is int && retry > 0 ? Duration(seconds: retry) : null;
  return Err(switch (status) {
    429 when code == 'busy' => FeedbackBusy(wait),
    429 => FeedbackRateLimited(wait),
    503 when code == 'provider_unconfigured' => const FeedbackUnavailable(),
    400 || 413 => FeedbackRejected(code.isEmpty ? 'invalid' : code),
    _ => const FeedbackServerDown(),
  });
}

Map<String, Object?>? _json(String body) {
  try {
    final decoded = jsonDecode(body);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}
