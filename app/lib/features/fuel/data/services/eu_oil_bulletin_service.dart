import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mitlio/core/clock.dart';
import 'package:mitlio/features/fuel/data/fuel_price.dart';
import 'package:mitlio/features/fuel/data/services/eu_oil_bulletin_parser.dart';
import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart';

/// The national average straight from the EU Weekly Oil Bulletin (European
/// Commission): public file, no key, no account, no location, no server of
/// ours. The device sends a plain HTTPS GET (so the Commission's server sees
/// the IP address, like any download) and nothing else.
///
/// Used where no backend is configured (ADR-20, amendment 2026-11-15).
/// National scope only: [supportsAreas] is false, so "in meiner Nähe" and
/// the postcode field stay hidden. The bulletin has no E10: like the Edge
/// Function it serves the E5 value marked as an approximation.
///
/// The last quote is kept in [cacheFile] (when given) so it also works
/// offline; the weekly file is not fetched again within [maxAge].
class EuOilBulletinService implements FuelPriceService {
  EuOilBulletinService({
    required this._clock,
    this.cacheFile,
    Uri? bulletinUri,
    HttpClient Function()? clientFactory,
    this.timeout = const Duration(seconds: 10),
    this.maxAge = const Duration(hours: 12),
    this.country = 'Germany',
  }) : bulletinUri = bulletinUri ?? defaultBulletinUri,
       _clientFactory = clientFactory ?? HttpClient.new;

  /// Same file the Edge Function reads (prices with taxes).
  static final Uri defaultBulletinUri = Uri.parse(
    'https://energy.ec.europa.eu/document/download/'
    '264c2d0f-f161-4ea3-a777-78faae59bea0_en'
    '?filename=weekly-oil-bulletin-prices-with-taxes.xlsx',
  );

  static const sourceName = 'eu-oil-bulletin';
  static const attributionLine =
      'Quelle: EU Weekly Oil Bulletin (Europäische Kommission)';

  static const _maxBytes = 5000000;

  final Clock _clock;
  final File? cacheFile;
  final Uri bulletinUri;
  final Duration timeout;

  /// How long a stored file is reused without asking the Commission again.
  final Duration maxAge;

  /// English country name as in the bulletin.
  final String country;
  final HttpClient Function() _clientFactory;

  @override
  bool get isConfigured => true;

  @override
  bool get supportsAreas => false;

  @override
  Future<FuelServiceResult> fetch(FuelGrade grade, {FuelArea? area}) async {
    if (area != null) return const FuelServiceFailure(FuelFailure.unavailable);
    final stored = await _readCache();
    final now = _clock.now();
    if (stored != null && now.difference(stored.fetchedAt) < maxAge) {
      return FuelServiceOk(_price(grade, stored.prices));
    }
    final fresh = await _download();
    switch (fresh) {
      case _Downloaded(:final prices):
        await _writeCache(prices, now);
        return FuelServiceOk(_price(grade, prices));
      case _Failed(:final reason):
        // Offline or the Commission is down: the last file still tells the
        // weekly price; the age line shows its date.
        return stored == null
            ? FuelServiceFailure(reason)
            : FuelServiceOk(_price(grade, stored.prices));
    }
  }

  FuelPrice _price(FuelGrade grade, BulletinPrices p) => FuelPrice(
    grade: grade,
    priceMilli: grade == FuelGrade.diesel ? p.dieselMilli : p.e5Milli,
    scope: FuelScope.national,
    // The date the prices are in force on, not the download time.
    fetchedAt: p.date,
    source: sourceName,
    attribution: attributionLine,
    approximation: grade == FuelGrade.e10 ? FuelGrade.e5 : null,
  );

  bool get _allowed =>
      bulletinUri.scheme == 'https' ||
      (bulletinUri.scheme == 'http' && _isLoopback(bulletinUri.host));

  static bool _isLoopback(String host) =>
      host == 'localhost' ||
      (InternetAddress.tryParse(host)?.isLoopback ?? false);

  Future<_Download> _download() async {
    if (!_allowed) return const _Failed(FuelFailure.unavailable);
    final client = _clientFactory()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(bulletinUri).timeout(timeout);
      request
        ..followRedirects = true
        ..maxRedirects = 3
        ..headers.set(HttpHeaders.acceptHeader, '*/*');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        await response.drain<void>().timeout(timeout);
        return const _Failed(FuelFailure.provider);
      }
      final bytes = await _readLimited(response).timeout(timeout);
      return _Downloaded(parseBulletinXlsx(bytes, country: country));
    } on BulletinFormatException {
      return const _Failed(FuelFailure.provider);
    } on Object {
      return const _Failed(FuelFailure.offline);
    } finally {
      client.close(force: true);
    }
  }

  static Future<Uint8List> _readLimited(Stream<List<int>> body) async {
    final out = BytesBuilder(copy: false);
    await for (final chunk in body) {
      out.add(chunk);
      if (out.length > _maxBytes) {
        throw const BulletinFormatException('bulletin too large');
      }
    }
    return out.takeBytes();
  }

  Future<({BulletinPrices prices, DateTime fetchedAt})?> _readCache() async {
    final file = cacheFile;
    if (file == null) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?> || json['country'] != country) {
        return null;
      }
      final date = DateTime.tryParse('${json['date']}');
      final fetched = DateTime.tryParse('${json['fetchedAt']}');
      final e5 = json['e5Milli'];
      final diesel = json['dieselMilli'];
      if (date == null ||
          fetched == null ||
          e5 is! int ||
          diesel is! int ||
          e5 <= 0 ||
          diesel <= 0) {
        return null;
      }
      return (
        prices: BulletinPrices(
          date: date.toUtc(),
          e5Milli: e5,
          dieselMilli: diesel,
        ),
        fetchedAt: fetched.toUtc(),
      );
    } on Object {
      return null;
    }
  }

  Future<void> _writeCache(BulletinPrices p, DateTime now) async {
    final file = cacheFile;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'country': country,
          'date': p.date.toIso8601String(),
          'fetchedAt': now.toUtc().toIso8601String(),
          'e5Milli': p.e5Milli,
          'dieselMilli': p.dieselMilli,
        }),
      );
    } on Object {
      // A missing cache only costs one more download.
    }
  }
}

sealed class _Download {
  const _Download();
}

final class _Downloaded extends _Download {
  const _Downloaded(this.prices);

  final BulletinPrices prices;
}

final class _Failed extends _Download {
  const _Failed(this.reason);

  final FuelFailure reason;
}
