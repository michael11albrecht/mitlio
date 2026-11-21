import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'car_flow_support.dart';

void main() {
  late CarFlowFakes fakes;
  late ProviderContainer c;

  setUp(() {
    fakes = CarFlowFakes();
    c = fakes.container();
    addTearDown(c.dispose);
  });

  CarCostResult? result() => c.read(carCostResultProvider);

  RepositoryError errorOf(RepoResult<void> r) =>
      (r as Err<void, RepositoryError>).error;

  group('steps', () {
    test('has the cost steps in order, only the kilometres required', () {
      expect(
        [for (final s in carCostFlow.steps) s.id],
        [
          'annualKm',
          'insurance',
          'vehicleTax',
          'maintenance',
          'tyres',
          'repairs',
          'loan',
          'depPurchase',
          'depResale',
          'depYears',
          'parking',
          'other',
          'basis',
        ],
      );
      expect(
        [
          for (final s in carCostFlow.steps)
            if (!s.skippable) s.id,
        ],
        ['annualKm', 'basis'],
      );
    });

    test('annual km: required, whole and bounded', () async {
      await c.start(carCostFlow);
      expect(errorOf(await c.flow(carCostFlow).skip()), isA<InvalidData>());
      expect(errorOf(await c.flow(carCostFlow).next()), isA<InvalidData>());
      for (final bad in [0, -5, maxAnnualKm + 1, 'viel', 1.5]) {
        expect(
          errorOf(await c.flow(carCostFlow).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
      await c.answer(carCostFlow, 15000);
      expect(c.flowState(carCostFlow).step?.id, 'insurance');
      expect(result()?.annualKm, 15000);
    });

    test('a category step takes cents with a period, nothing else', () async {
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 15000);
      for (final bad in [
        42,
        'viel',
        {'cents': -1, 'period': 'year'},
        {'cents': 100, 'period': 'week'},
        {'cents': maxCostCents + 1, 'period': 'year'},
        {'cents': 1.5, 'period': 'year'},
      ]) {
        expect(
          errorOf(await c.flow(carCostFlow).next(answer: bad)),
          isA<InvalidData>(),
          reason: '$bad',
        );
      }
      expect(c.flowState(carCostFlow).step?.id, 'insurance');
      await c.answer(carCostFlow, costEntryAnswer(500, CostPeriod.month));
      expect(c.flowState(carCostFlow).step?.id, 'vehicleTax');
    });

    test('every category step moves on and counts', () async {
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 10000);
      for (final (step, category) in [
        ('insurance', CostCategory.insurance),
        ('vehicleTax', CostCategory.vehicleTax),
        ('maintenance', CostCategory.maintenance),
        ('tyres', CostCategory.tyres),
        ('repairs', CostCategory.repairs),
        ('loan', CostCategory.loan),
      ]) {
        expect(c.flowState(carCostFlow).step?.id, step);
        await c.answer(carCostFlow, costEntryAnswer(1000, CostPeriod.year));
        expect(result()?.annualCents[category], 1000, reason: step);
      }
      expect(c.flowState(carCostFlow).step?.id, 'depPurchase');
    });

    test(
      'depreciation: purchase, resale, years; years 0 or 51 refused',
      () async {
        await c.start(carCostFlow);
        await c.answer(carCostFlow, 10000);
        for (var i = 0; i < 6; i++) {
          await c.skip(carCostFlow);
        }
        await c.answer(carCostFlow, 2000000);
        await c.answer(carCostFlow, 1000000);
        for (final bad in [0, maxKeepYears + 1, -1]) {
          expect(
            errorOf(await c.flow(carCostFlow).next(answer: bad)),
            isA<InvalidData>(),
          );
        }
        await c.answer(carCostFlow, 4);
        expect(result()?.annualCents[CostCategory.depreciation], 250000);
        expect(c.flowState(carCostFlow).step?.id, 'parking');
      },
    );

    test('basis: running or full, one of the two', () async {
      await answerCostFixture(c);
      expect(c.flowState(carCostFlow).finished, isTrue);
      await c.flow(carCostFlow).back();
      for (final bad in ['all', 7, true]) {
        expect(
          errorOf(await c.flow(carCostFlow).next(answer: bad)),
          isA<InvalidData>(),
        );
      }
      await c.answer(carCostFlow, 'full');
      expect(result()?.basis, CostBasis.full);
    });
  });

  group('result (domain fixtures vehicle_cost)', () {
    test('null until the annual km are known', () async {
      await c.start(carCostFlow);
      expect(result(), isNull);
    });

    test('running basis is 240 milli per km, shown as 24.0 ct/km', () async {
      await answerCostFixture(c);
      final r = result()!;
      expect(r.basis, CostBasis.running);
      expect(r.runningTenthsPerKm, 240);
      expect(r.chosenTenthsPerKm, 240);
      expect(r.chosen.breakdownMilliPerKm, {
        CostCategory.maintenance: 32,
        CostCategory.tyres: 8,
        CostCategory.repairs: 0,
        CostCategory.depreciation: 200,
      });
      expect(formatTenths(r.chosenTenthsPerKm, ','), '24,0');
    });

    test('full basis is 293 milli per km with the fixed costs', () async {
      await answerCostFixture(c, basis: 'full');
      final r = result()!;
      expect(r.fullTenthsPerKm, 293);
      expect(r.chosenTenthsPerKm, 293);
      expect(r.chosen.breakdownMilliPerKm[CostCategory.insurance], 40);
      expect(r.chosen.breakdownMilliPerKm[CostCategory.vehicleTax], 13);
      expect(r.annualCents, {
        CostCategory.insurance: 60000,
        CostCategory.vehicleTax: 20000,
        CostCategory.maintenance: 48000,
        CostCategory.tyres: 12000,
        CostCategory.depreciation: 300000,
      });
    });

    test('is live: it follows the answer typed so far', () async {
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 12000);
      c.flow(carCostFlow).answer(costEntryAnswer(10000, CostPeriod.month));
      // The insurance is fixed: only the full basis counts it.
      expect(result()?.runningTenthsPerKm, 0);
      expect(result()?.fullTenthsPerKm, 100);
      c.flow(carCostFlow).answer(costEntryAnswer(20000, CostPeriod.month));
      expect(result()?.fullTenthsPerKm, 200);
    });

    test('skipping everything is 0 ct/km, not an error', () async {
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 10000);
      for (var i = 0; i < 11; i++) {
        await c.skip(carCostFlow);
      }
      await c.answer(carCostFlow, 'running');
      expect(c.flowState(carCostFlow).finished, isTrue);
      expect(result()?.chosenTenthsPerKm, 0);
      expect(c.flowState(carCostFlow).skipped.length, 11);
    });

    test('resale above the price is no depreciation', () async {
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 10000);
      for (var i = 0; i < 6; i++) {
        await c.skip(carCostFlow);
      }
      await c.answer(carCostFlow, 100000);
      await c.answer(carCostFlow, 500000);
      await c.answer(carCostFlow, 5);
      expect(result()?.annualCents[CostCategory.depreciation], 0);
    });

    test('depreciation needs the purchase and the years', () async {
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 10000);
      for (var i = 0; i < 6; i++) {
        await c.skip(carCostFlow);
      }
      await c.skip(carCostFlow); // purchase
      await c.answer(carCostFlow, 100000); // resale alone
      await c.answer(carCostFlow, 5);
      expect(result()?.annualCents, isEmpty);
    });
  });

  group('skip path and resume', () {
    test('a skipped step is remembered and forgotten when answered', () async {
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 10000);
      await c.skip(carCostFlow);
      expect(c.flowState(carCostFlow).skipped, ['insurance']);
      await c.flow(carCostFlow).back();
      c.flow(carCostFlow).answer(costEntryAnswer(1, CostPeriod.year));
      expect(c.flowState(carCostFlow).skipped, isEmpty);
    });

    test('a killed app resumes on the same step with its answers', () async {
      await c.start(carCostFlow);
      await c.answer(carCostFlow, 20000);
      await c.answer(carCostFlow, costEntryAnswer(900, CostPeriod.month));
      final again = fakes.container();
      addTearDown(again.dispose);
      await again.start(carCostFlow);
      expect(again.flowState(carCostFlow).step?.id, 'vehicleTax');
      expect(again.read(carCostResultProvider)?.annualKm, 20000);
      expect(again.read(carCostResultProvider)?.annualCents, {
        CostCategory.insurance: 10800,
      });
    });

    test('a failed save keeps the step and the answer', () async {
      await c.start(carCostFlow);
      fakes.setup.failSaveWith = const Storage('disk full');
      final r = await c.flow(carCostFlow).next(answer: 12000);
      expect(errorOf(r), isA<Storage>());
      expect(c.flowState(carCostFlow).stepIndex, 0);
    });
  });

  group('hints (PU-T15)', () {
    test(
      'running basis: passengers never pay above the operating cost',
      () async {
        await answerCostFixture(c);
        expect(result()!.check.exceedsOperatingCost, isFalse);
        expect(result()!.check.hasHint, isFalse);
      },
    );

    test('full basis with fixed costs: the PBefG hint applies', () async {
      await answerCostFixture(c, basis: 'full');
      expect(result()!.check.exceedsOperatingCost, isTrue);
    });
  });
}
