import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mitlio/features/fx/data/fx_suggestion.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The FX rate API (contract: docs/fx-rates-api.md).
abstract interface class FxRateService {
  /// Whether a backend is configured. `false` hides the whole feature.
  bool get isConfigured;

  /// The rate of 1 [base] in [quote] on [date] (null: the latest). Null when
  /// there is none for any reason (offline, unknown currency, rate limit):
  /// the user types the rate.
  Future<FxSuggestion?> fetch({
    required Currency base,
    required Currency quote,
    DateTime? date,
  });
}

/// No backend configured (empty `SUPABASE_URL`): no suggestion, the form
/// shows nothing.
class UnavailableFxRateService implements FxRateService {
  const UnavailableFxRateService();

  @override
  bool get isConfigured => false;

  @override
  Future<FxSuggestion?> fetch({
    required Currency base,
    required Currency quote,
    DateTime? date,
  }) async => null;
}

/// Calls the `fx-rates` Edge Function over `dart:io` (no extra package). Only
/// the currency pair and the day are sent: no amounts, no user data.
class HttpFxRateService implements FxRateService {
  HttpFxRateService({
    required this.baseUrl,
    required this.anonKey,
    HttpClient Function()? clientFactory,
    this.timeout = const Duration(seconds: 8),
  }) : _clientFactory = clientFactory ?? HttpClient.new;

  final String baseUrl;
  final String anonKey;
  final Duration timeout;
  final HttpClient Function() _clientFactory;

  @override
  bool get isConfigured => baseUrl.isNotEmpty;

  /// The request URI for the pair and day.
  Uri uriFor(Currency base, Currency quote, DateTime? date) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root/functions/v1/fx-rates').replace(
      queryParameters: {
        'base': base.code,
        'quote': quote.code,
        if (date != null) 'date': _day(date),
      },
    );
  }

  @override
  Future<FxSuggestion?> fetch({
    required Currency base,
    required Currency quote,
    DateTime? date,
  }) async {
    if (!isConfigured) return null;
    final client = _clientFactory()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uriFor(base, quote, date));
      request.headers
        ..set('apikey', anonKey)
        ..set(HttpHeaders.authorizationHeader, 'Bearer $anonKey')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return response.statusCode == 200 ? parseFxSuggestion(body) : null;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Reads a 200 body of the contract; null when it is malformed.
FxSuggestion? parseFxSuggestion(String body) {
  try {
    final json = jsonDecode(body);
    if (json is! Map<String, Object?>) return null;
    final ppm = json['ratePpm'];
    final date = json['date'];
    if (ppm is! int || ppm <= 0 || date is! String) return null;
    final day = DateTime.tryParse(date);
    if (day == null) return null;
    final attribution = json['attribution'];
    return FxSuggestion(
      ppm: ppm,
      date: DateTime.utc(day.year, day.month, day.day),
      attribution: attribution is String ? attribution : '',
    );
  } on FormatException {
    return null;
  }
}
