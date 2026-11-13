import 'dart:convert';
import 'dart:io';

import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:mitlio_domain_web/mitlio_domain_web.dart';
import 'package:test/test.dart';

Map<String, Object?> _base([Map<String, Object?> overrides = const {}]) => {
  'distanceKm': 250,
  'consumptionPer100km': 6.5,
  'pricePerUnit': 1.799,
  'persons': 2,
  'driverPays': true,
  'roundTrip': false,
  ...overrides,
};

Map<String, Object?> _fail(String error, [String? field]) => {
  'ok': false,
  'error': error,
  'field': ?field,
};

void main() {
  test('version is the domain rules version', () {
    expect(version, domainRulesVersion);
  });

  group('shared fixtures (tool/fixtures/trip_web.json)', () {
    final file = File('../../tool/fixtures/trip_web.json');
    final cases = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, Object?>>();
    for (final c in cases) {
      test(c['name']! as String, () {
        final input = (c['input']! as Map).cast<String, Object?>();
        expect(calculateTrip(input), c['expected']);
      });
    }
  });

  group('boundary conversion', () {
    test('float noise is rounded away (1.799 -> 1799 milli)', () {
      final r = calculateTrip(_base());
      expect(r['totalCents'], 2923);
    });

    test('half up at the milli boundary', () {
      // 0.0005 EUR/km = 0.5 milli/km -> rounds up to 1 milli/km.
      final r = calculateTrip({
        'distanceKm': 1000,
        'kmRate': 0.0005,
        'persons': 1,
        'driverPays': true,
      });
      // 1000 km x 1 milli/km = 1000 milli = 1 EUR -> 100 cents.
      expect(r['totalCents'], 100);
    });

    test('tolls round half up to cents', () {
      final r = calculateTrip(_base({'tollsEur': 1.005}));
      expect((r['breakdown']! as Map)['tollsCents'], 101);
    });

    test('kmRate replaces consumption and price', () {
      final r = calculateTrip({
        'distanceKm': 10,
        'kmRate': 0.5,
        'consumptionPer100km': -3,
        'persons': 1,
        'driverPays': true,
      });
      expect(r['totalCents'], 500);
    });
  });

  group('rejects invalid input with a structured error', () {
    test('NaN', () {
      expect(
        calculateTrip(_base({'distanceKm': double.nan})),
        _fail('InvalidNumber', 'distanceKm'),
      );
    });
    test('infinity', () {
      expect(
        calculateTrip(_base({'pricePerUnit': double.infinity})),
        _fail('InvalidNumber', 'pricePerUnit'),
      );
    });
    test('negative', () {
      expect(
        calculateTrip(_base({'tollsEur': -1})),
        _fail('TripNegativeValue', 'tollsEur'),
      );
    });
    test('wrong type', () {
      expect(
        calculateTrip(_base({'distanceKm': '250'})),
        _fail('InvalidNumber', 'distanceKm'),
      );
    });
    test('missing consumption', () {
      expect(
        calculateTrip(_base({'consumptionPer100km': null})),
        _fail('InvalidNumber', 'consumptionPer100km'),
      );
    });
    test('absurdly large value', () {
      expect(
        calculateTrip(_base({'distanceKm': 1e15})),
        _fail('InvalidNumber', 'distanceKm'),
      );
    });
    test('total beyond Money.maxAbsCents', () {
      expect(
        calculateTrip(_base({'distanceKm': 1e9, 'kmRate': 1e9})),
        _fail('MoneyOverflow'),
      );
    });
    for (final p in <Object?>[0, 101, 1.5, null, 'x', double.nan]) {
      test('persons $p', () {
        expect(
          calculateTrip(_base({'persons': p})),
          _fail('InvalidPersons', 'persons'),
        );
      });
    }
    test('driverPays not a bool', () {
      expect(
        calculateTrip(_base({'driverPays': 1})),
        _fail('InvalidBoolean', 'driverPays'),
      );
    });
    test('roundTrip not a bool', () {
      expect(
        calculateTrip(_base({'roundTrip': 'yes'})),
        _fail('InvalidBoolean', 'roundTrip'),
      );
    });
    test('zero distance', () {
      expect(
        calculateTrip(_base({'distanceKm': 0})),
        _fail('NonPositiveDistance', 'distanceKm'),
      );
    });
    test('no participants', () {
      expect(
        calculateTrip(_base({'persons': 1, 'driverPays': false})),
        _fail('TripNoParticipants', 'persons'),
      );
    });
  });

  test('per-person shares always sum to the total', () {
    for (var persons = 1; persons <= 12; persons++) {
      final r = calculateTrip(_base({'persons': persons, 'distanceKm': 137.3}));
      final shares = (r['perPersonCents']! as List).cast<int>();
      expect(shares, hasLength(persons));
      expect(shares.fold<int>(0, (a, b) => a + b), r['totalCents']);
    }
  });
}
