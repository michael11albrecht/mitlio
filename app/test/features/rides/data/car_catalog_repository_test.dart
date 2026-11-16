import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/data/repositories/car_catalog_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';

Uint8List _gz(Object json) =>
    Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(json))));

Map<String, Object?> _catalog(List<List<Object?>> cars) => {
  'v': 1,
  'makes': ['VW', 'Tesla'],
  'cars': cars,
};

/// Serves one fixed byte string; counts loads and can fail the first ones.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.bytes, {this.failFirst = 0});

  final Uint8List bytes;
  int failFirst;
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    if (failFirst > 0) {
      failFirst--;
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the shipped asset', () {
    test('loads, searches and stays small', () async {
      final catalog = ok(await AssetCarCatalogRepository().load());
      expect(catalog.length, greaterThan(5000));

      final golf = catalog.search('golf');
      expect(golf, isNotEmpty);
      expect(golf.first.name, 'VW Golf');
      expect(golf.first.fuelType, FuelType.petrol);
      expect(
        golf.first.consumptionMilliPer100km,
        inInclusiveRange(3000, 12000),
      );

      final tesla = catalog.search('tesla model 3');
      expect(tesla, isNotEmpty);
      expect(tesla.first.fuelType, FuelType.electric);
      expect(
        tesla.first.consumptionMilliPer100km,
        inInclusiveRange(10000, 25000),
      );

      expect(catalog.search('volkswagen golf'), isNotEmpty);
      expect(catalog.search('zzzzqq'), isEmpty);
    });

    test('every entry is plausible and under 300 KB gzipped', () async {
      final bytes = File('assets/car_catalog/catalog_v1.json.gz');
      expect(bytes.lengthSync(), lessThan(300 * 1024));
      final entries = decodeCarCatalog(bytes.readAsBytesSync());
      for (final e in entries) {
        expect(e.make, isNotEmpty);
        expect(e.model, isNotEmpty);
        expect(e.fuelType, isNot(FuelType.other));
        expect(
          e.consumptionMilliPer100km,
          e.fuelType == FuelType.electric
              ? inInclusiveRange(8000, 40000)
              : inInclusiveRange(2000, 25000),
          reason: e.toString(),
        );
        expect(e.hybrid && e.fuelType == FuelType.electric, isFalse);
      }
    });

    test('the header names the source and licence', () {
      final json = jsonDecode(
        utf8.decode(
          gzip.decode(
            File('assets/car_catalog/catalog_v1.json.gz').readAsBytesSync(),
          ),
        ),
      ) as Map<String, Object?>;
      expect(json['v'], 1);
      expect(json['licence'], contains('CC BY 4.0'));
      expect(json['source'], contains('EEA'));
      expect(json['years'], hasLength(2));
    });
  });

  group('decodeCarCatalog', () {
    test('maps fuel codes, units and rounding classes', () {
      final entries = decodeCarCatalog(
        _gz(
          _catalog([
            [0, 'Golf', 0, 15, 17, 563],
            [0, 'Golf', 1, 20, 30, 450],
            [0, 'Golf', 3, 14, 22, 520],
            [0, 'Golf', 4, 20, 22, 470],
            [1, 'Model 3', 2, 0, 38, 1490],
          ]),
        ),
      );
      expect(entries, const [
        CarCatalogEntry(
          make: 'VW',
          model: 'Golf',
          fuelType: FuelType.petrol,
          engineCc: 1500,
          powerKw: 85,
          consumptionMilliPer100km: 5630,
        ),
        CarCatalogEntry(
          make: 'VW',
          model: 'Golf',
          fuelType: FuelType.diesel,
          engineCc: 2000,
          powerKw: 150,
          consumptionMilliPer100km: 4500,
        ),
        CarCatalogEntry(
          make: 'VW',
          model: 'Golf',
          fuelType: FuelType.petrol,
          hybrid: true,
          engineCc: 1400,
          powerKw: 110,
          consumptionMilliPer100km: 5200,
        ),
        CarCatalogEntry(
          make: 'VW',
          model: 'Golf',
          fuelType: FuelType.diesel,
          hybrid: true,
          engineCc: 2000,
          powerKw: 110,
          consumptionMilliPer100km: 4700,
        ),
        CarCatalogEntry(
          make: 'Tesla',
          model: 'Model 3',
          fuelType: FuelType.electric,
          powerKw: 190,
          consumptionMilliPer100km: 14900,
        ),
      ]);
    });

    test('rejects other versions, unknown fuels and bad values', () {
      expect(
        () => decodeCarCatalog(
          _gz({'v': 2, 'makes': <String>[], 'cars': <Object?>[]}),
        ),
        throwsFormatException,
      );
      expect(() => decodeCarCatalog(_gz([1, 2])), throwsFormatException);
      expect(
        () => decodeCarCatalog(
          _gz(
            _catalog([
              [0, 'Golf', 9, 15, 17, 563],
            ]),
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => decodeCarCatalog(
          _gz(
            _catalog([
              [0, 'Golf', -1, 15, 17, 563],
            ]),
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => decodeCarCatalog(
          _gz(
            _catalog([
              [0, 'Golf', 0, 15, 17, 0],
            ]),
          ),
        ),
        throwsFormatException,
      );
    });
  });

  group('loading', () {
    final good = _gz(
      _catalog([
        [0, 'Golf', 0, 15, 17, 563],
      ]),
    );

    test('loads once and caches the result', () async {
      final bundle = _Bundle(good);
      final repo = AssetCarCatalogRepository(bundle: bundle);
      final first = ok(await repo.load());
      final second = ok(await repo.load());
      expect(identical(first, second), isTrue);
      expect(first.search('golf'), hasLength(1));
      expect(bundle.loads, 1);
    });

    test(
      'a missing asset is a storage error, and a retry can succeed',
      () async {
        final bundle = _Bundle(good, failFirst: 1);
        final repo = AssetCarCatalogRepository(bundle: bundle);
        expect(err(await repo.load()), isA<Storage>());
        expect(ok(await repo.load()).length, 1);
        expect(bundle.loads, 2);
      },
    );

    test('a corrupt asset is a storage error', () async {
      final repo = AssetCarCatalogRepository(
        bundle: _Bundle(Uint8List.fromList([1, 2, 3])),
      );
      expect(err(await repo.load()), isA<Storage>());
    });

    test('a decoder that throws is a storage error', () async {
      final repo = AssetCarCatalogRepository(
        bundle: _Bundle(good),
        decode: (_) async => throw const FormatException('nope'),
      );
      final error = err(await repo.load());
      expect(error, isA<Storage>());
      expect((error as Storage).cause, isA<FormatException>());
    });

    test('an unknown asset path fails the same way', () async {
      final repo = AssetCarCatalogRepository(assetPath: 'assets/nothing.gz');
      expect(err(await repo.load()), isA<Storage>());
    });
  });
}
