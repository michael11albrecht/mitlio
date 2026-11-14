import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/statistics/data/statistics_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

const _anna = Member(id: 'a', position: 0);
const _ben = Member(id: 'b', position: 1);
const List<Member> _members = [_anna, _ben];

ExpenseEntry _expense(
  int cents,
  DateTime date, {
  String? category,
  String payer = 'a',
  Map<String, int>? shares,
  ForeignAmount? foreign,
  String id = 'e',
}) {
  final split = shares == null ? EqualSplit({'a', 'b'}) : ExactSplit(shares);
  final result = Expense.create(
    id: id,
    title: 'x',
    amountCents: cents,
    currency: Currency.eur,
    date: date,
    payers: {payer: cents},
    split: split,
    members: _members,
  );
  return ExpenseEntry(
    groupId: 'g',
    expense: (result as Ok<Expense, ExpenseError>).value,
    split: split,
    category: category,
    foreign: foreign,
    createdAt: date,
  );
}

final _today = DateTime.utc(2026, 3, 15);

StatisticsInput _input(
  List<ExpenseEntry> expenses, {
  List<RideEntry> rides = const [],
  List<Vehicle> vehicles = const [],
  DateTime? today,
}) => StatisticsInput(
  expenses: expenses,
  members: _members,
  currency: Currency.eur,
  today: today ?? _today,
  rides: rides,
  vehicles: vehicles,
);

RideEntry _ride(
  String id,
  DateTime date, {
  int meters = 10000,
  bool roundTrip = false,
  String vehicle = 'v',
}) => RideEntry(
  groupId: 'g',
  createdAt: date,
  ride: Ride(
    id: id,
    date: date,
    distanceMeters: meters,
    roundTrip: roundTrip,
    vehicleId: vehicle,
    driverId: 'a',
    pricePerUnitMilli: 2000,
    passengerIds: const {'b'},
  ),
);

void main() {
  group('periods', () {
    final expenses = [
      _expense(100, DateTime.utc(2026, 3), id: '1'),
      _expense(200, DateTime.utc(2026, 3, 31, 23, 59), id: '2'),
      _expense(400, DateTime.utc(2026, 2, 28), id: '3'),
      _expense(800, DateTime.utc(2026), id: '4'),
      _expense(1600, DateTime.utc(2025, 12, 31), id: '5'),
      _expense(3200, DateTime.utc(2026, 4), id: '6'),
    ];
    int total(StatsPeriod p) =>
        computeStatistics(_input(expenses), p).totalCents;

    test('month is the calendar month of today, both ends inclusive', () {
      expect(total(StatsPeriod.month), 300);
    });

    test('last 3 months are this and the two before', () {
      expect(total(StatsPeriod.last3Months), 300 + 400 + 800);
    });

    test('year is the calendar year of today', () {
      expect(total(StatsPeriod.year), 300 + 400 + 800 + 3200);
    });

    test('all counts everything', () {
      expect(total(StatsPeriod.all), 6300);
      expect(
        computeStatistics(_input(expenses), StatsPeriod.all).expenseCount,
        6,
      );
    });

    test('last 3 months reach across the new year', () {
      final s = computeStatistics(
        _input(expenses, today: DateTime.utc(2026, 2, 10)),
        StatsPeriod.last3Months,
      );
      // Dec 2025, Jan 2026, Feb 2026.
      expect(s.totalCents, 1600 + 800 + 400);
    });

    test('bounds are half open UTC month starts', () {
      final b = periodBounds(StatsPeriod.month, DateTime.utc(2026, 12, 5));
      expect(b.from, DateTime.utc(2026, 12));
      expect(b.to, DateTime.utc(2027));
      expect(periodBounds(StatsPeriod.all, _today), (from: null, to: null));
    });
  });

  group('categories', () {
    test('largest first with rounded percent and counts', () {
      final s = computeStatistics(
        _input([
          _expense(3800, DateTime.utc(2026, 3), category: 'fuel', id: '1'),
          _expense(1000, DateTime.utc(2026, 3, 2), category: 'food', id: '2'),
          _expense(1200, DateTime.utc(2026, 3, 3), category: 'food', id: '3'),
          _expense(4000, DateTime.utc(2026, 3, 4), id: '4'),
        ]),
        StatsPeriod.month,
      );
      expect(s.totalCents, 10000);
      expect(s.categories, const [
        CategoryStat(key: null, cents: 4000, percent: 40, count: 1),
        CategoryStat(key: 'fuel', cents: 3800, percent: 38, count: 1),
        CategoryStat(key: 'food', cents: 2200, percent: 22, count: 2),
      ]);
    });

    test('top category is a real one: uncategorised never wins', () {
      final s = computeStatistics(
        _input([
          _expense(3800, DateTime.utc(2026, 3), category: 'fuel', id: '1'),
          _expense(4000, DateTime.utc(2026, 3, 4), id: '4'),
        ]),
        StatsPeriod.month,
      );
      expect(s.topCategory, isNull);
      final t = computeStatistics(
        _input([
          _expense(3800, DateTime.utc(2026, 3), category: 'fuel', id: '1'),
          _expense(400, DateTime.utc(2026, 3, 4), id: '4'),
        ]),
        StatsPeriod.month,
      );
      expect(t.topCategory?.key, 'fuel');
      expect(t.topCategory?.percent, 90);
    });

    test('blank category counts as none; ties order by key', () {
      final s = computeStatistics(
        _input([
          _expense(100, DateTime.utc(2026, 3), category: ' ', id: '1'),
          _expense(100, DateTime.utc(2026, 3), category: 'b', id: '2'),
          _expense(100, DateTime.utc(2026, 3), category: 'a', id: '3'),
        ]),
        StatsPeriod.month,
      );
      expect([for (final c in s.categories) c.key], ['a', 'b', null]);
      expect(s.categories.map((c) => c.percent), [33, 33, 33]);
    });

    test('percent rounds half up', () {
      final s = computeStatistics(
        _input([
          _expense(1, DateTime.utc(2026, 3), category: 'a', id: '1'),
          _expense(7, DateTime.utc(2026, 3), category: 'b', id: '2'),
        ]),
        StatsPeriod.month,
      );
      // 12.5 % rounds to 13, 87.5 % to 88.
      expect(s.categories.map((c) => c.percent), [88, 13]);
    });
  });

  group('members', () {
    test('paid and consumed come from payers and shares', () {
      final s = computeStatistics(
        _input([
          _expense(1000, DateTime.utc(2026, 3), id: '1'),
          _expense(
            600,
            DateTime.utc(2026, 3, 2),
            payer: 'b',
            shares: {'a': 100, 'b': 500},
            id: '2',
          ),
        ]),
        StatsPeriod.month,
      );
      expect(s.members, const [
        MemberStat(memberId: 'a', paidCents: 1000, shareCents: 600),
        MemberStat(memberId: 'b', paidCents: 600, shareCents: 1000),
      ]);
    });

    test('a member without expenses is still listed at zero', () {
      final s = computeStatistics(_input(const []), StatsPeriod.month);
      expect(s.members, const [
        MemberStat(memberId: 'a', paidCents: 0, shareCents: 0),
        MemberStat(memberId: 'b', paidCents: 0, shareCents: 0),
      ]);
    });

    test('a removed member stays in the totals, not in the rows', () {
      final s = computeStatistics(
        StatisticsInput(
          expenses: [_expense(1000, DateTime.utc(2026, 3))],
          members: const [_anna],
          currency: Currency.eur,
          today: _today,
        ),
        StatsPeriod.month,
      );
      expect(s.totalCents, 1000);
      expect(s.members, const [
        MemberStat(memberId: 'a', paidCents: 1000, shareCents: 500),
      ]);
    });
  });

  group('multi-currency', () {
    test('a foreign expense counts with its converted group amount', () {
      // 50 USD at 0,92 -> 46,00 EUR is stored as 4600 in the group currency.
      final s = computeStatistics(
        _input([
          _expense(
            4600,
            DateTime.utc(2026, 3, 2),
            category: 'food',
            foreign: const ForeignAmount(
              currency: Currency.usd,
              amountCents: 5000,
              ratePpm: 920000,
            ),
            id: '1',
          ),
          _expense(1000, DateTime.utc(2026, 3, 3), category: 'food', id: '2'),
        ]),
        StatsPeriod.month,
      );
      expect(s.totalCents, 5600);
      expect(s.categories.single.cents, 5600);
      expect(s.members.map((m) => m.paidCents).sum, 5600);
      expect(s.months.last.expenseCents, 5600);
    });
  });

  group('months', () {
    test('six months, oldest first, independent of the period', () {
      final s = computeStatistics(
        _input([
          _expense(100, DateTime.utc(2026, 3, 2), id: '1'),
          _expense(200, DateTime.utc(2026, 1, 9), id: '2'),
          _expense(400, DateTime.utc(2025, 10, 31), id: '3'),
          _expense(800, DateTime.utc(2025, 9, 30), id: '4'),
        ]),
        StatsPeriod.month,
      );
      expect(
        [for (final m in s.months) (m.year, m.month)],
        [
          (2025, 10),
          (2025, 11),
          (2025, 12),
          (2026, 1),
          (2026, 2),
          (2026, 3),
        ],
      );
      expect(
        [for (final m in s.months) m.expenseCents],
        [
          400,
          0,
          0,
          200,
          0,
          100,
        ],
      );
      // September is out of the window; the period total ignores the window.
      expect(s.totalCents, 100);
    });
  });

  group('rides', () {
    final golf = Vehicle(
      id: 'v',
      name: 'Golf',
      fuelType: FuelType.petrol,
      consumptionMilliPer100km: 6000,
    );

    test('km and cost per month; a round trip counts twice', () {
      final s = computeStatistics(
        _input(
          const [],
          vehicles: [golf],
          rides: [
            _ride('r1', DateTime.utc(2026, 3)),
            _ride('r2', DateTime.utc(2026, 3, 2), roundTrip: true),
            _ride('r3', DateTime.utc(2026, 2, 2), meters: 50000),
            _ride('old', DateTime.utc(2025, 8, 2)),
          ],
        ),
        StatsPeriod.month,
      );
      expect(s.hasRides, isTrue);
      final march = s.months.last;
      expect(march.rideMeters, 30000);
      final feb = s.months[4];
      expect(feb.rideMeters, 50000);
      // 6 l/100 km at 2,00 per litre: 0,12 per km -> 10 km = 1,20.
      expect(march.rideCents, 120 + 240);
      expect(feb.rideCents, 600);
    });

    test('an unpriceable ride still counts its distance', () {
      final s = computeStatistics(
        _input(
          const [],
          vehicles: [golf],
          rides: [
            // Unknown vehicle: distance only.
            _ride('r1', DateTime.utc(2026, 3), vehicle: 'gone'),
          ],
        ),
        StatsPeriod.month,
      );
      expect(s.months.last.rideMeters, 10000);
      expect(s.months.last.rideCents, 0);
    });

    test('no rides: hasRides is false', () {
      expect(
        computeStatistics(_input(const []), StatsPeriod.month).hasRides,
        isFalse,
      );
    });
  });

  group('empty', () {
    test('nothing in the period is empty with zero totals', () {
      final s = computeStatistics(
        _input([_expense(100, DateTime.utc(2024))]),
        StatsPeriod.month,
      );
      expect(s.isEmpty, isTrue);
      expect(s.totalCents, 0);
      expect(s.categories, isEmpty);
      expect(s.topCategory, isNull);
      expect(s.months, hasLength(statsMonthCount));
    });
  });

  group('value types', () {
    test('equality and toString', () {
      const c = CategoryStat(key: 'a', cents: 1, percent: 100, count: 1);
      expect(c, const CategoryStat(key: 'a', cents: 1, percent: 100, count: 1));
      expect(c.hashCode, c.hashCode);
      expect(
        c,
        isNot(const CategoryStat(key: 'b', cents: 1, percent: 100, count: 1)),
      );
      expect(c.toString(), contains('100%'));
      const m = MemberStat(memberId: 'a', paidCents: 1, shareCents: 2);
      expect(m, const MemberStat(memberId: 'a', paidCents: 1, shareCents: 2));
      expect(m.hashCode, m.hashCode);
      expect(
        m,
        isNot(const MemberStat(memberId: 'a', paidCents: 1, shareCents: 3)),
      );
      expect(m.toString(), contains('a'));
      const t = MonthStat(
        year: 2026,
        month: 3,
        expenseCents: 1,
        rideMeters: 2,
        rideCents: 3,
      );
      expect(
        t,
        const MonthStat(
          year: 2026,
          month: 3,
          expenseCents: 1,
          rideMeters: 2,
          rideCents: 3,
        ),
      );
      expect(t.hashCode, t.hashCode);
      expect(t.toString(), contains('2026-3'));
      expect(
        computeStatistics(_input(const []), StatsPeriod.all).toString(),
        contains('all'),
      );
    });
  });

  group('properties', () {
    test('categories, paid and shares each add up to the total', () {
      final random = Random(88);
      for (var run = 0; run < 100; run++) {
        final expenses = [
          for (var i = 0; i < 1 + random.nextInt(30); i++)
            _expense(
              1 + random.nextInt(50000),
              DateTime.utc(
                2025 + random.nextInt(2),
                1 + random.nextInt(12),
                1 + random.nextInt(28),
              ),
              category: [null, 'food', 'stay', 'x'][random.nextInt(4)],
              payer: random.nextBool() ? 'a' : 'b',
              id: 'e$i',
            ),
        ];
        for (final period in StatsPeriod.values) {
          final s = computeStatistics(_input(expenses), period);
          expect(s.categories.map((c) => c.cents).sum, s.totalCents);
          expect(s.categories.map((c) => c.count).sum, s.expenseCount);
          expect(s.members.map((m) => m.paidCents).sum, s.totalCents);
          expect(s.members.map((m) => m.shareCents).sum, s.totalCents);
          if (s.totalCents > 0) {
            expect(
              s.categories.map((c) => c.percent).sum,
              inInclusiveRange(
                100 - s.categories.length,
                100 + s.categories.length,
              ),
            );
          }
        }
      }
    });

    test('a bigger period never has a smaller total', () {
      final random = Random(7);
      final expenses = [
        for (var i = 0; i < 60; i++)
          _expense(
            1 + random.nextInt(9999),
            DateTime.utc(
              2025 + random.nextInt(2),
              1 + random.nextInt(12),
              1 + random.nextInt(28),
            ),
            id: 'e$i',
          ),
      ];
      int total(StatsPeriod p) =>
          computeStatistics(_input(expenses), p).totalCents;
      expect(
        total(StatsPeriod.last3Months),
        greaterThanOrEqualTo(total(StatsPeriod.month)),
      );
      expect(
        total(StatsPeriod.all),
        greaterThanOrEqualTo(total(StatsPeriod.year)),
      );
      expect(
        total(StatsPeriod.all),
        greaterThanOrEqualTo(total(StatsPeriod.last3Months)),
      );
    });
  });
}

extension on Iterable<int> {
  int get sum => fold(0, (a, b) => a + b);
}
