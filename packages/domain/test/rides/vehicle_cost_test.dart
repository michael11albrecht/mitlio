import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';

/// Random profile as plain values; no shrinking so mutation runs stay fast.
final class _Case {
  _Case(this.km, this.costs, this.dep);
  final int km;
  final Map<CostCategory, CostEntry> costs;
  final Depreciation? dep;

  VehicleCostProfile get profile => VehicleCostProfile(
    annualKm: km,
    currency: Currency.eur,
    costs: costs,
    depreciation: dep,
  );

  @override
  String toString() => '_Case($km, $costs, $dep)';
}

extension _Gens on Any {
  Generator<_Case> get costCase => simple(
    generate: (random, size) {
      final costs = <CostCategory, CostEntry>{};
      for (final c in CostCategory.values) {
        if (random.nextInt(3) == 0) continue;
        costs[c] = CostEntry(
          random.nextIntInRange(0, 2000000),
          random.nextBool() ? CostPeriod.month : CostPeriod.year,
        );
      }
      final purchase = random.nextIntInRange(0, 10000000);
      return _Case(
        random.nextIntInRange(1, 200000),
        costs,
        random.nextBool()
            ? null
            : Depreciation(
                purchaseCents: purchase,
                resaleCents: random.nextIntInRange(0, purchase + 1),
                keepYears: random.nextIntInRange(1, 20),
              ),
      );
    },
    shrink: (_) => const [],
  );
}

VehicleExtraCost _ok(VehicleCostProfile p, CostBasis b) =>
    (vehicleExtraCostPerKm(
      p,
      b,
    ) as Ok<VehicleExtraCost, VehicleCostError>).value;

VehicleCostError _err(VehicleCostProfile p, [CostBasis b = CostBasis.full]) =>
    (vehicleExtraCostPerKm(
      p,
      b,
    ) as Err<VehicleExtraCost, VehicleCostError>).error;

VehicleCostProfile _p({
  int km = 10000,
  Map<CostCategory, CostEntry> costs = const {},
  Depreciation? dep,
  Currency currency = Currency.eur,
}) => VehicleCostProfile(
  annualKm: km,
  currency: currency,
  costs: costs,
  depreciation: dep,
);

void main() {
  group('vehicleExtraCostPerKm examples (examples:vehicle_cost)', () {
    for (final row in domainRulesRows('vehicle_cost')) {
      test(row['name'] as String, () {
        final profile = VehicleCostProfile(
          annualKm: row['annualKm'] as int,
          currency: Currency.tryParse(row['currency'] as String)!,
          costs: {
            for (final e in (row['costs'] as Map<String, dynamic>).entries)
              CostCategory.values.byName(e.key): CostEntry(
                (e.value as List)[0] as int,
                CostPeriod.values.byName((e.value as List)[1] as String),
              ),
          },
          depreciation: row['depreciation'] == null
              ? null
              : Depreciation(
                  purchaseCents: (row['depreciation'] as List)[0] as int,
                  resaleCents: (row['depreciation'] as List)[1] as int,
                  keepYears: (row['depreciation'] as List)[2] as int,
                ),
        );
        final basis = CostBasis.values.byName(row['basis'] as String);
        if (row.containsKey('error')) {
          expect(_err(profile, basis).toString(), row['error']);
          return;
        }
        final r = _ok(profile, basis);
        expect(r.wearMilliPerKm, row['wear']);
        expect({
          for (final e in r.breakdownMilliPerKm.entries) e.key.name: e.value,
        }, (row['breakdown'] as Map).cast<String, int>());
      });
    }
  });

  group('vehicleExtraCostPerKm edge cases', () {
    test('categories are tagged running or fixed', () {
      expect(
        CostCategory.values.where((c) => c.running).toSet(),
        {
          CostCategory.maintenance,
          CostCategory.tyres,
          CostCategory.repairs,
          CostCategory.depreciation,
        },
      );
    });
    test('annual km 0 and negative are rejected', () {
      expect(_err(_p(km: 0)), const NonPositiveAnnualKm());
      expect(_err(_p(km: -5)), const NonPositiveAnnualKm());
    });
    test('annual km 1 is accepted', () {
      final r = _ok(
        _p(
          km: 1,
          costs: {CostCategory.tyres: const CostEntry(1, CostPeriod.year)},
        ),
        CostBasis.running,
      );
      expect(r.wearMilliPerKm, 10);
    });
    test('annual km is validated before costs', () {
      expect(
        _err(
          _p(
            km: 0,
            costs: {CostCategory.tyres: const CostEntry(-1, CostPeriod.year)},
          ),
        ),
        const NonPositiveAnnualKm(),
      );
    });
    test('negative costs name the first offending category', () {
      expect(
        _err(
          _p(
            costs: {
              CostCategory.parking: const CostEntry(-1, CostPeriod.month),
              CostCategory.insurance: const CostEntry(-1, CostPeriod.year),
            },
          ),
        ),
        const VehicleCostNegativeValue('insurance'),
      );
    });
    test('a negative fixed cost is rejected on running basis too', () {
      expect(
        _err(
          _p(costs: {CostCategory.loan: const CostEntry(-1, CostPeriod.year)}),
          CostBasis.running,
        ),
        const VehicleCostNegativeValue('loan'),
      );
    });
    test('zero costs are accepted', () {
      for (final c in CostCategory.values) {
        final r = _ok(
          _p(costs: {c: const CostEntry(0, CostPeriod.year)}),
          CostBasis.full,
        );
        expect(r.wearMilliPerKm, 0);
      }
    });
    test('depreciation validation', () {
      Depreciation d(int p, int r, int y) =>
          Depreciation(purchaseCents: p, resaleCents: r, keepYears: y);
      expect(
        _err(_p(dep: d(-1, 0, 5))),
        const VehicleCostNegativeValue('depreciation'),
      );
      expect(
        _err(_p(dep: d(100, -1, 5))),
        const VehicleCostNegativeValue('depreciation'),
      );
      expect(_err(_p(dep: d(100, 0, 0))), const InvalidDepreciation());
      expect(_err(_p(dep: d(100, 0, -1))), const InvalidDepreciation());
      expect(_err(_p(dep: d(100, 101, 5))), const InvalidDepreciation());
      // resale == purchase is fine (no depreciation).
      expect(_ok(_p(dep: d(100, 100, 5)), CostBasis.running).wearMilliPerKm, 0);
    });
    test('depreciation is (purchase - resale) / years, rounded half up', () {
      // 1000 / 4 = 250 per year; 250 x 10 / 10000 = 0.25 -> 0
      // 3000000 / 3 = 1000000 per year; x 10 / 10000 = 1000.
      expect(
        _ok(
          _p(
            dep: const Depreciation(
              purchaseCents: 3000000,
              resaleCents: 0,
              keepYears: 3,
            ),
          ),
          CostBasis.running,
        ).wearMilliPerKm,
        1000,
      );
      // 5 / 2 = 2.5 -> 3 per year; 3 x 10 / 10 km = 3.
      expect(
        _ok(
          _p(
            km: 10,
            dep: const Depreciation(
              purchaseCents: 5,
              resaleCents: 0,
              keepYears: 2,
            ),
          ),
          CostBasis.running,
        ).wearMilliPerKm,
        3,
      );
    });
    test(
      'depreciation entry in costs is ignored in favour of depreciation',
      () {
        final r = _ok(
          _p(
            costs: {
              CostCategory.depreciation: const CostEntry(-5, CostPeriod.year),
            },
          ),
          CostBasis.running,
        );
        expect(r.wearMilliPerKm, 0);
      },
    );
    test('running basis ignores fixed costs, full counts them', () {
      final p = _p(
        costs: {
          CostCategory.insurance: const CostEntry(100000, CostPeriod.year),
          CostCategory.other: const CostEntry(100000, CostPeriod.year),
        },
      );
      final running = _ok(p, CostBasis.running);
      expect(running.wearMilliPerKm, 0);
      expect(running.breakdownMilliPerKm.keys, [
        CostCategory.maintenance,
        CostCategory.tyres,
        CostCategory.repairs,
        CostCategory.depreciation,
      ]);
      final full = _ok(p, CostBasis.full);
      expect(full.wearMilliPerKm, 200);
      expect(full.breakdownMilliPerKm.keys, CostCategory.values);
      expect(full.breakdownMilliPerKm[CostCategory.insurance], 100);
      expect(full.breakdownMilliPerKm[CostCategory.other], 100);
    });
    test('ties in largest remainder go to the earlier category', () {
      // 2 milli over two equal weights: 1 each. 3 over two: first gets 2.
      final r = _ok(
        _p(
          km: 20,
          costs: {
            CostCategory.maintenance: const CostEntry(3, CostPeriod.year),
            CostCategory.tyres: const CostEntry(3, CostPeriod.year),
          },
        ),
        CostBasis.running,
      );
      expect(r.wearMilliPerKm, 3);
      expect(r.breakdownMilliPerKm[CostCategory.maintenance], 2);
      expect(r.breakdownMilliPerKm[CostCategory.tyres], 1);
    });
    test('breakdown map is unmodifiable', () {
      final r = _ok(_p(), CostBasis.running);
      expect(
        () => r.breakdownMilliPerKm[CostCategory.tyres] = 1,
        throwsUnsupportedError,
      );
    });
    test('KWD (3 decimals) needs no scaling', () {
      final r = _ok(
        _p(
          currency: Currency.kwd,
          km: 10,
          costs: {CostCategory.tyres: const CostEntry(5000, CostPeriod.year)},
        ),
        CostBasis.running,
      );
      expect(r.wearMilliPerKm, 500);
    });
    test('overflow throws', () {
      expect(
        () => vehicleExtraCostPerKm(
          _p(
            km: 1,
            costs: {
              CostCategory.tyres: const CostEntry(
                Money.maxAbsCents,
                CostPeriod.year,
              ),
            },
          ),
          CostBasis.running,
        ),
        throwsA(
          isA<MoneyOverflow>().having(
            (e) => e.cents,
            'cents',
            Money.maxAbsCents + 1,
          ),
        ),
      );
      // Exactly at the limit is fine.
      final ok = _ok(
        _p(
          km: 10,
          costs: {
            CostCategory.tyres: const CostEntry(
              Money.maxAbsCents,
              CostPeriod.year,
            ),
          },
        ),
        CostBasis.running,
      );
      expect(ok.wearMilliPerKm, Money.maxAbsCents);
    });
    test('error value semantics', () {
      expect(const NonPositiveAnnualKm(), const NonPositiveAnnualKm());
      expect(
        const NonPositiveAnnualKm().hashCode,
        const NonPositiveAnnualKm().hashCode,
      );
      expect(const InvalidDepreciation(), const InvalidDepreciation());
      expect(
        const InvalidDepreciation().hashCode,
        const InvalidDepreciation().hashCode,
      );
      expect(
        const VehicleCostNegativeValue('a'),
        const VehicleCostNegativeValue('a'),
      );
      expect(
        const VehicleCostNegativeValue('a').hashCode,
        const VehicleCostNegativeValue('a').hashCode,
      );
      expect(
        const VehicleCostNegativeValue('a') ==
            const VehicleCostNegativeValue('b'),
        isFalse,
      );
      expect(
        const NonPositiveAnnualKm() == const InvalidDepreciation(),
        isFalse,
      );
      expect(
        const InvalidDepreciation() == const NonPositiveAnnualKm(),
        isFalse,
      );
      expect(
        const VehicleCostNegativeValue('a') == const NonPositiveAnnualKm(),
        isFalse,
      );
      expect(const NonPositiveAnnualKm().toString(), 'NonPositiveAnnualKm()');
      expect(const InvalidDepreciation().toString(), 'InvalidDepreciation()');
      expect(
        const VehicleCostNegativeValue('a').toString(),
        'VehicleCostNegativeValue(a)',
      );
    });
    test('value types compare by value', () {
      expect(
        const CostEntry(1, CostPeriod.year),
        const CostEntry(1, CostPeriod.year),
      );
      expect(
        const CostEntry(1, CostPeriod.year).hashCode,
        const CostEntry(1, CostPeriod.year).hashCode,
      );
      expect(
        const CostEntry(1, CostPeriod.year) ==
            const CostEntry(2, CostPeriod.year),
        isFalse,
      );
      expect(
        const CostEntry(1, CostPeriod.year) ==
            const CostEntry(1, CostPeriod.month),
        isFalse,
      );
      const d = Depreciation(purchaseCents: 3, resaleCents: 2, keepYears: 1);
      expect(
        d,
        const Depreciation(purchaseCents: 3, resaleCents: 2, keepYears: 1),
      );
      expect(
        d.hashCode,
        const Depreciation(
          purchaseCents: 3,
          resaleCents: 2,
          keepYears: 1,
        ).hashCode,
      );
      expect(
        d == const Depreciation(purchaseCents: 4, resaleCents: 2, keepYears: 1),
        isFalse,
      );
      expect(
        d == const Depreciation(purchaseCents: 3, resaleCents: 1, keepYears: 1),
        isFalse,
      );
      expect(
        d == const Depreciation(purchaseCents: 3, resaleCents: 2, keepYears: 2),
        isFalse,
      );
    });
  });

  group('vehicleExtraCostPerKm properties', () {
    Glados(any.costCase).test('breakdown sums to the total (both bases)', (c) {
      for (final b in CostBasis.values) {
        final r = _ok(c.profile, b);
        expect(
          r.breakdownMilliPerKm.values.fold<int>(0, (a, v) => a + v),
          r.wearMilliPerKm,
        );
        expect(r.breakdownMilliPerKm.values.every((v) => v >= 0), isTrue);
      }
    });
    Glados(any.costCase).test('running <= full', (c) {
      expect(
        _ok(c.profile, CostBasis.running).wearMilliPerKm,
        lessThanOrEqualTo(_ok(c.profile, CostBasis.full).wearMilliPerKm),
      );
    });
    Glados2(any.costCase, any.intInRange(0, 9)).test(
      'monotonic in each cost',
      (c, idx) {
        final cat = CostCategory.values[idx];
        final base = c.costs[cat] ?? const CostEntry(0, CostPeriod.year);
        final more = {
          ...c.costs,
          cat: CostEntry(base.amountCents + 1000, base.period),
        };
        for (final b in CostBasis.values) {
          final before = _ok(c.profile, b).wearMilliPerKm;
          final after = _ok(
            VehicleCostProfile(
              annualKm: c.km,
              currency: Currency.eur,
              costs: more,
              depreciation: c.dep,
            ),
            b,
          ).wearMilliPerKm;
          expect(after, greaterThanOrEqualTo(before));
        }
      },
    );
    Glados(any.costCase).test('monthly = 12 x yearly', (c) {
      final monthly = {
        for (final e in c.costs.entries)
          e.key: CostEntry(e.value.amountCents, CostPeriod.month),
      };
      final yearly = {
        for (final e in c.costs.entries)
          e.key: CostEntry(e.value.amountCents * 12, CostPeriod.year),
      };
      VehicleCostProfile of(Map<CostCategory, CostEntry> m) =>
          VehicleCostProfile(annualKm: c.km, currency: Currency.eur, costs: m);
      expect(
        _ok(of(monthly), CostBasis.full).wearMilliPerKm,
        _ok(of(yearly), CostBasis.full).wearMilliPerKm,
      );
    });
    Glados(any.costCase).test('more kilometres never cost more per km', (c) {
      final doubled = VehicleCostProfile(
        annualKm: c.km * 2,
        currency: Currency.eur,
        costs: c.costs,
        depreciation: c.dep,
      );
      expect(
        _ok(doubled, CostBasis.full).wearMilliPerKm,
        lessThanOrEqualTo(_ok(c.profile, CostBasis.full).wearMilliPerKm),
      );
    });
  });
}
