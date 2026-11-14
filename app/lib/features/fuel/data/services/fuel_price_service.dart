import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mitlio/features/fuel/data/fuel_price.dart';

/// Result of one call to the price API.
sealed class FuelServiceResult {
  const FuelServiceResult();
}

final class FuelServiceOk extends FuelServiceResult {
  const FuelServiceOk(this.price);

  final FuelPrice price;
}

final class FuelServiceFailure extends FuelServiceResult {
  const FuelServiceFailure(this.reason);

  final FuelFailure reason;
}

/// The fuel price API (contract: docs/fuel-prices-api.md).
abstract interface class FuelPriceService {
  /// Whether a backend is configured. `false` hides the whole feature.
  bool get isConfigured;

  /// Without [area] this is the national average: no location involved.
  Future<FuelServiceResult> fetch(FuelGrade grade, {FuelArea? area});
}

/// No backend configured (empty `SUPABASE_URL`): reports `unavailable`, the
/// UI shows nothing.
class UnavailableFuelPriceService implements FuelPriceService {
  const UnavailableFuelPriceService();

  @override
  bool get isConfigured => false;

  @override
  Future<FuelServiceResult> fetch(FuelGrade grade, {FuelArea? area}) async =>
      const FuelServiceFailure(FuelFailure.unavailable);
}

/// Calls the `fuel-prices` Edge Function over `dart:io` (no extra package).
/// Coordinates are rounded to two decimals (about 1 km) before they leave
/// the device; the server rounds again and never stores the exact spot.
class HttpFuelPriceService implements FuelPriceService {
  HttpFuelPriceService({
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

  /// The request URI for [grade] and [area].
  Uri uriFor(FuelGrade grade, FuelArea? area) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base/functions/v1/fuel-prices').replace(
      queryParameters: {
        'type': grade.apiName,
        ...switch (area) {
          null => const <String, String>{},
          PlzArea(:final plz) => {'plz': plz},
          NearbyArea(:final lat, :final lng, :final radiusKm) => {
            'lat': lat.toStringAsFixed(2),
            'lng': lng.toStringAsFixed(2),
            'radius': '$radiusKm',
          },
        },
      },
    );
  }

  @override
  Future<FuelServiceResult> fetch(FuelGrade grade, {FuelArea? area}) async {
    if (!isConfigured) return const FuelServiceFailure(FuelFailure.unavailable);
    final client = _clientFactory()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uriFor(grade, area));
      request.headers
        ..set('apikey', anonKey)
        ..set(HttpHeaders.authorizationHeader, 'Bearer $anonKey')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return _parse(response.statusCode, body);
    } on Object {
      return const FuelServiceFailure(FuelFailure.offline);
    } finally {
      client.close(force: true);
    }
  }

  static FuelServiceResult _parse(int status, String body) {
    if (status == 200) {
      final price = parseFuelPrice(body);
      return price == null
          ? const FuelServiceFailure(FuelFailure.provider)
          : FuelServiceOk(price);
    }
    return FuelServiceFailure(switch (status) {
      429 => FuelFailure.rateLimited,
      >= 400 && < 500 => FuelFailure.invalidParams,
      _ => FuelFailure.provider,
    });
  }
}

/// Reads a 200 body of the contract; null when it is malformed.
FuelPrice? parseFuelPrice(String body) {
  try {
    final json = jsonDecode(body);
    if (json is! Map<String, Object?>) return null;
    final grade = FuelGrade.values.asNameMap()[json['type']];
    final scope = FuelScope.values.asNameMap()[json['scope']];
    final milli = json['priceMilli'];
    final fetched = json['fetchedAt'];
    if (grade == null ||
        scope == null ||
        milli is! int ||
        milli <= 0 ||
        fetched is! String) {
      return null;
    }
    final at = DateTime.tryParse(fetched);
    if (at == null) return null;
    final stations = json['stations'];
    return FuelPrice(
      grade: grade,
      priceMilli: milli,
      scope: scope,
      fetchedAt: at.toUtc(),
      stations: stations is int ? stations : 0,
      source: json['source'] is String ? json['source']! as String : '',
      attribution: json['attribution'] is String
          ? json['attribution']! as String
          : '',
      approximation: FuelGrade.values.asNameMap()[json['approximation']],
    );
  } on FormatException {
    return null;
  }
}
