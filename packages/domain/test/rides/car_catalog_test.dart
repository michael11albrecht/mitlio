import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/no_shrink.dart';

CarCatalogEntry car(
  String make,
  String model, {
  FuelType fuel = FuelType.petrol,
  int cc = 1500,
  int kw = 100,
  int milli = 5600,
  bool hybrid = false,
}) => CarCatalogEntry(
  make: make,
  model: model,
  fuelType: fuel,
  engineCc: cc,
  powerKw: kw,
  consumptionMilliPer100km: milli,
  hybrid: hybrid,
);

final List<CarCatalogEntry> _entries = [
  car('VW', 'Golf'),
  car('VW', 'Golf', fuel: FuelType.diesel, cc: 2000, milli: 4500),
  car('VW', 'Golf', cc: 1000, kw: 65, milli: 5200),
  car('VW', 'Golf', cc: 1400, kw: 110, milli: 5300, hybrid: true),
  car('VW', 'Golf Variant', kw: 85),
  car('VW', 'Golf Plus', cc: 1600, kw: 77),
  car('VW', 'Polo'),
  car('VW', 'ID.3', fuel: FuelType.electric, cc: 0, kw: 150, milli: 15500),
  car('Tesla', 'Model 3', fuel: FuelType.electric, cc: 0, milli: 14900),
  car('Citroën', 'C3'),
  car('Mercedes-Benz', 'A 180'),
  car('Skoda', 'Octavia'),
  car('Audi', 'A3'),
];

void main() {
  final catalog = CarCatalog(_entries);

  group('foldCatalogText', () {
    test('folds case, umlauts, accents and punctuation', () {
      expect(foldCatalogText('Citroën C3'), 'citroen c3');
      expect(foldCatalogText('ID.3'), 'id 3');
      expect(
        foldCatalogText('  Mercedes-Benz   A 180 '),
        'mercedes benz a 180',
      );
      expect(foldCatalogText('Škoda Fabia'), 'skoda fabia');
      expect(foldCatalogText('Weiß'), 'weiss');
    });
  });

  group('search', () {
    test('needs at least two characters', () {
      expect(catalog.search(''), isEmpty);
      expect(catalog.search('g'), isEmpty);
      expect(catalog.search(' g '), isEmpty);
      expect(catalog.search('go'), isNotEmpty);
      expect(catalog.search('golf', limit: 0), isEmpty);
    });

    test('finds by model prefix, any case', () {
      expect(
        catalog.search('GOL').map((e) => e.name).toSet(),
        {'VW Golf', 'VW Golf Variant', 'VW Golf Plus'},
      );
    });

    test('"vw golf" and "volkswagen golf" are the same search', () {
      expect(catalog.search('vw golf'), catalog.search('volkswagen golf'));
      expect(catalog.search('vw golf'), isNotEmpty);
    });

    test('word order does not matter, every word must match', () {
      expect(catalog.search('golf vw'), isNotEmpty);
      expect(catalog.search('golf tesla'), isEmpty);
    });

    test('umlaut and accent free typing', () {
      expect(catalog.search('citroen').single.name, 'Citroën C3');
      expect(catalog.search('Citroën').single.name, 'Citroën C3');
      expect(catalog.search('skoda').single.name, 'Skoda Octavia');
    });

    test('joined and split spellings: id3, id.3, model3, model 3', () {
      expect(catalog.search('id3').single.name, 'VW ID.3');
      expect(catalog.search('id.3').single.name, 'VW ID.3');
      expect(catalog.search('model3').single.name, 'Tesla Model 3');
      expect(catalog.search('model 3').single.name, 'Tesla Model 3');
      expect(catalog.search('tesla model').single.name, 'Tesla Model 3');
    });

    test('make aliases and Mercedes spellings', () {
      expect(catalog.search('mercedes a').single.name, 'Mercedes-Benz A 180');
      expect(catalog.search('benz').single.name, 'Mercedes-Benz A 180');
    });

    test('alias plus model reads as one word: "mercedesa", "benza 180"', () {
      expect(catalog.search('mercedesa').single.name, 'Mercedes-Benz A 180');
      expect(catalog.search('benza180').single.name, 'Mercedes-Benz A 180');
    });

    test('same variant sorts by engine size first, then by power', () {
      final cars = CarCatalog([
        car('Zed', 'Zap', cc: 1600, kw: 65),
        car('Zed', 'Zap', cc: 1000, kw: 110),
        car('Zed', 'Zap', cc: 1000, kw: 70),
      ]);
      expect(
        cars.search('zap').map((e) => (e.engineCc, e.powerKw)).toList(),
        [(1000, 70), (1000, 110), (1600, 65)],
      );
    });

    test('no match gives an empty list', () {
      expect(catalog.search('xyzzy'), isEmpty);
      expect(catalog.search('golf zzz'), isEmpty);
    });

    test('exact model first, then longer models', () {
      final names = catalog.search('golf', limit: 20).map((e) => e.name);
      expect(names.first, 'VW Golf');
      expect(names.toList().indexOf('VW Golf Plus'), greaterThan(0));
    });

    test('keeps variants of one model, preferring different fuels', () {
      final hits = catalog.search('golf');
      expect(hits, hasLength(5));
      // Petrol, petrol hybrid, diesel of "Golf" come before a second plain
      // petrol variant or the longer model names.
      expect(hits.take(3).map((e) => (e.fuelType, e.hybrid)).toList(), [
        (FuelType.petrol, false),
        (FuelType.petrol, true),
        (FuelType.diesel, false),
      ]);
    });

    test('never more than the limit and never duplicates', () {
      for (final limit in [1, 2, 5, 50]) {
        final hits = catalog.search('golf', limit: limit);
        expect(hits.length, lessThanOrEqualTo(limit));
        expect(hits.toSet().length, hits.length);
      }
    });

    test('empty catalog', () {
      expect(CarCatalog(const []).search('golf'), isEmpty);
      expect(CarCatalog(const []).length, 0);
    });

    test('is deterministic', () {
      expect(catalog.search('a'), catalog.search('a'));
      expect(
        CarCatalog(_entries.reversed).search('golf'),
        catalog.search('golf'),
      );
    });

    Glados(any.intNoShrink(0, 1 << 30)).test(
      'every hit matches every typed word and results are bounded',
      (seed) {
        final words = [
          'vw',
          'golf',
          'id',
          'mod',
          'tes',
          'a',
          'cit',
          'c3',
          'oct',
          'xx',
        ];
        final q = [
          words[seed % words.length],
          if (seed % 3 == 0) words[(seed ~/ 7) % words.length],
        ].join(' ');
        final hits = catalog.search(q, minLength: 1);
        expect(hits.length, lessThanOrEqualTo(5));
        for (final h in hits) {
          for (final w in foldCatalogText(q).split(' ')) {
            final hay = foldCatalogText(
              '${h.make} ${h.model} volkswagen mercedes benz',
            );
            final compact = hay.replaceAll(' ', '');
            expect(
              hay.split(' ').any((t) => t.startsWith(w)) || compact.contains(w),
              isTrue,
              reason: '$q vs ${h.name}',
            );
          }
        }
      },
    );
  });

  group('CarCatalogEntry', () {
    test('value equality and name', () {
      expect(car('VW', 'Golf'), car('VW', 'Golf'));
      expect(car('VW', 'Golf').hashCode, car('VW', 'Golf').hashCode);
      expect(car('VW', 'Golf'), isNot(car('VW', 'Golf', milli: 5601)));
      expect(car('VW', 'Golf'), isNot(car('VW', 'Golf', hybrid: true)));
      expect(car('VW', 'Golf'), isNot(car('VW', 'Golf', kw: 1)));
      expect(car('VW', 'Golf'), isNot(car('VW', 'Golf', cc: 1)));
      expect(car('VW', 'Golf'), isNot(car('VW', 'Polo')));
      expect(car('VW', 'Golf'), isNot(car('Audi', 'Golf')));
      expect(
        car('VW', 'Golf'),
        isNot(car('VW', 'Golf', fuel: FuelType.diesel)),
      );
      expect(car('VW', 'Golf').name, 'VW Golf');
      expect(car('VW', 'Golf').toString(), contains('VW Golf'));
    });
  });

  group('realisticConsumptionMilli', () {
    test('adds the documented 20 % gap, rounded half up', () {
      expect(realWorldGapPercent, 20);
      expect(realisticConsumptionMilli(FuelType.petrol, 5600), 6720);
      expect(realisticConsumptionMilli(FuelType.diesel, 4500), 5400);
      expect(realisticConsumptionMilli(FuelType.petrol, 1), 1);
      expect(realisticConsumptionMilli(FuelType.petrol, 4), 5); // 4.8
      expect(realisticConsumptionMilli(FuelType.petrol, 3), 4); // 3.6
      expect(realisticConsumptionMilli(FuelType.petrol, 5), 6);
      expect(realisticConsumptionMilli(FuelType.petrol, 2), 2); // 2.4
      expect(realisticConsumptionMilli(FuelType.petrol, 1250), 1500);
      expect(realisticConsumptionMilli(FuelType.petrol, 1252), 1502); // .4
      expect(realisticConsumptionMilli(FuelType.petrol, 1253), 1504); // .6
      expect(realisticConsumptionMilli(FuelType.petrol, 8), 10); // 9.6
    });

    test('no sourced factor for electric and other fuels', () {
      expect(realisticConsumptionMilli(FuelType.electric, 15000), isNull);
      expect(realisticConsumptionMilli(FuelType.other, 6000), isNull);
    });

    test('rejects a non-positive value', () {
      expect(
        () => realisticConsumptionMilli(FuelType.petrol, 0),
        throwsArgumentError,
      );
      expect(
        () => realisticConsumptionMilli(FuelType.diesel, -5),
        throwsArgumentError,
      );
    });

    test('the error names the argument and the rule', () {
      expect(
        () => realisticConsumptionMilli(FuelType.petrol, 0),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'wltpMilli')
              .having((e) => e.message, 'message', 'must be > 0')
              .having((e) => e.invalidValue, 'invalidValue', 0),
        ),
      );
    });

    Glados(any.intNoShrink(1, 40000)).test(
      'never below the manufacturer value, never more than 20 % + 1 unit above',
      (wltp) {
        final real = realisticConsumptionMilli(FuelType.petrol, wltp)!;
        expect(real, greaterThanOrEqualTo(wltp));
        expect(real * 100, lessThanOrEqualTo(wltp * 120 + 50));
        expect(real * 100, greaterThanOrEqualTo(wltp * 120 - 50));
      },
    );
  });
}
