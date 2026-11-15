import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Where the bundled catalog lives; built by
/// `dart run packages/tooling/bin/build_car_catalog.dart` (docs/car-catalog.md).
const carCatalogAsset = 'assets/car_catalog/catalog_v1.json.gz';

/// The offline car list for the vehicle form. Loads once, lazily; a failed
/// load is not cached, so the next call tries again.
// ignore: one_member_abstracts, repository interface, faked in tests
abstract interface class CarCatalogRepository {
  /// [Storage] when the asset is missing or unreadable.
  Future<RepoResult<CarCatalog>> load();
}

/// Reads [carCatalogAsset] from the app bundle and decodes it off the UI
/// isolate (about 11 000 cars, gunzip + JSON).
class AssetCarCatalogRepository implements CarCatalogRepository {
  AssetCarCatalogRepository({
    AssetBundle? bundle,
    this.assetPath = carCatalogAsset,
    Future<List<CarCatalogEntry>> Function(Uint8List bytes)? decode,
  }) : _bundle = bundle ?? rootBundle,
       _decode = decode ?? _decodeInIsolate;

  final AssetBundle _bundle;
  final String assetPath;
  final Future<List<CarCatalogEntry>> Function(Uint8List bytes) _decode;
  Future<RepoResult<CarCatalog>>? _cached;

  @override
  Future<RepoResult<CarCatalog>> load() {
    final cached = _cached ??= _load();
    return cached.then((result) {
      if (result is Err) _cached = null;
      return result;
    });
  }

  Future<RepoResult<CarCatalog>> _load() => guardStorage(() async {
    final data = await _bundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return Ok(CarCatalog(await _decode(bytes)));
  });

  static Future<List<CarCatalogEntry>> _decodeInIsolate(Uint8List bytes) =>
      Isolate.run(() => decodeCarCatalog(bytes));
}

/// Decodes the gzipped catalog JSON (format v1, see `CarCatalogBuilder`).
/// Throws [FormatException] for anything unexpected.
List<CarCatalogEntry> decodeCarCatalog(List<int> gzipped) {
  final json = jsonDecode(utf8.decode(gzip.decode(gzipped)));
  if (json is! Map<String, Object?> || json['v'] != 1) {
    throw const FormatException('unsupported car catalog version');
  }
  final makes = (json['makes']! as List).cast<String>();
  return [
    for (final row in (json['cars']! as List).cast<List<Object?>>())
      _entry(makes, row),
  ];
}

CarCatalogEntry _entry(List<String> makes, List<Object?> row) {
  final fuelCode = row[2]! as int;
  if (fuelCode < 0 || fuelCode > 4) {
    throw FormatException('unknown fuel code $fuelCode');
  }
  final hundredths = row[5]! as int;
  if (hundredths <= 0) throw FormatException('bad consumption $hundredths');
  return CarCatalogEntry(
    make: makes[row[0]! as int],
    model: row[1]! as String,
    fuelType: switch (fuelCode) {
      1 || 4 => FuelType.diesel,
      2 => FuelType.electric,
      _ => FuelType.petrol,
    },
    hybrid: fuelCode >= 3,
    engineCc: (row[3]! as int) * 100,
    powerKw: (row[4]! as int) * 5,
    consumptionMilliPer100km: hundredths * 10,
  );
}
