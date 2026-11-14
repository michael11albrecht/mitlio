// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Pure aggregation behind the statistics screen. No state, no I/O, no
/// clock: "today" is an input.

/// The span of time the breakdowns cover.
enum StatsPeriod {
  /// The calendar month of "today".
  month,

  /// "Today"'s month and the two before it.
  last3Months,

  /// The calendar year of "today".
  year,

  /// Every expense.
  all,
}

/// Months shown in the "over time" rows (the current one and five before).
const statsMonthCount = 6;

/// Everything the calculator needs; all amounts are in the group currency
/// (an expense paid abroad counts with its converted amount).
final class StatisticsInput {
  const StatisticsInput({
    required this.expenses,
    required this.members,
    required this.currency,
    required this.today,
    this.rides = const [],
    this.vehicles = const [],
  });

  final List<ExpenseEntry> expenses;

  /// In position order.
  final List<Member> members;
  final Currency currency;

  /// Decides which months "this month", "last 3 months" and "this year" are.
  final DateTime today;
  final List<RideEntry> rides;
  final List<Vehicle> vehicles;
}

/// One category of the breakdown. [key] is null for expenses without one.
final class CategoryStat {
  const CategoryStat({
    required this.key,
    required this.cents,
    required this.percent,
    required this.count,
  });

  final String? key;
  final int cents;

  /// Share of the period total, rounded half up (the rows can add up to 99
  /// or 101).
  final int percent;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is CategoryStat &&
      other.key == key &&
      other.cents == cents &&
      other.percent == percent &&
      other.count == count;

  @override
  int get hashCode => Object.hash(key, cents, percent, count);

  @override
  String toString() => 'CategoryStat($key, $cents, $percent%, $count)';
}

/// What one member paid out and what they consumed (their share) in the
/// period. Paid minus consumed is the period's net, not the balance (that
/// also counts settlements).
final class MemberStat {
  const MemberStat({
    required this.memberId,
    required this.paidCents,
    required this.shareCents,
  });

  final String memberId;
  final int paidCents;
  final int shareCents;

  @override
  bool operator ==(Object other) =>
      other is MemberStat &&
      other.memberId == memberId &&
      other.paidCents == paidCents &&
      other.shareCents == shareCents;

  @override
  int get hashCode => Object.hash(memberId, paidCents, shareCents);

  @override
  String toString() => 'MemberStat($memberId, $paidCents, $shareCents)';
}

/// One calendar month of the "over time" rows.
final class MonthStat {
  const MonthStat({
    required this.year,
    required this.month,
    required this.expenseCents,
    required this.rideMeters,
    required this.rideCents,
  });

  final int year;

  /// 1-12.
  final int month;
  final int expenseCents;

  /// Metres driven (round trips count twice).
  final int rideMeters;

  /// Cost of the rides in the group currency.
  final int rideCents;

  @override
  bool operator ==(Object other) =>
      other is MonthStat &&
      other.year == year &&
      other.month == month &&
      other.expenseCents == expenseCents &&
      other.rideMeters == rideMeters &&
      other.rideCents == rideCents;

  @override
  int get hashCode =>
      Object.hash(year, month, expenseCents, rideMeters, rideCents);

  @override
  String toString() =>
      'MonthStat($year-$month, $expenseCents, ${rideMeters}m, $rideCents)';
}

/// The result for one [period].
final class Statistics {
  const Statistics({
    required this.period,
    required this.totalCents,
    required this.expenseCount,
    required this.categories,
    required this.members,
    required this.months,
  });

  final StatsPeriod period;
  final int totalCents;
  final int expenseCount;

  /// Largest first; ties by key, the uncategorised row last.
  final List<CategoryStat> categories;

  /// In position order, every member.
  final List<MemberStat> members;

  /// Oldest first, always [statsMonthCount] entries ending in "today"'s
  /// month; independent of [period].
  final List<MonthStat> months;

  bool get isEmpty => expenseCount == 0;

  /// The biggest category, when it is a real one: "mostly fuel (38 %)".
  /// Null if nothing is categorised or the uncategorised row is biggest.
  CategoryStat? get topCategory {
    final first = categories.firstOrNull;
    return first?.key == null ? null : first;
  }

  /// Any ride in the six months shown.
  bool get hasRides => months.any((m) => m.rideMeters > 0);

  @override
  String toString() =>
      'Statistics($period, $totalCents in $expenseCount expenses)';
}

/// The half-open day range `[from, to)` of [period] (UTC); null ends are open.
({DateTime? from, DateTime? to}) periodBounds(
  StatsPeriod period,
  DateTime today,
) {
  final y = today.year;
  final m = today.month;
  return switch (period) {
    StatsPeriod.month => (from: DateTime.utc(y, m), to: DateTime.utc(y, m + 1)),
    StatsPeriod.last3Months => (
      from: DateTime.utc(y, m - 2),
      to: DateTime.utc(y, m + 1),
    ),
    StatsPeriod.year => (from: DateTime.utc(y), to: DateTime.utc(y + 1)),
    StatsPeriod.all => (from: null, to: null),
  };
}

/// Aggregates [input] for [period].
///
/// Expenses count in the group currency, so a foreign-currency expense
/// contributes its converted amount. Members unknown to
/// [StatisticsInput.members] (removed ones) are left out of the per-member
/// rows but not of the totals.
Statistics computeStatistics(StatisticsInput input, StatsPeriod period) {
  final bounds = periodBounds(period, input.today);
  final from = bounds.from;
  final to = bounds.to;

  final categoryCents = <String?, int>{};
  final categoryCount = <String?, int>{};
  final paid = {for (final m in input.members) m.id: 0};
  final share = {for (final m in input.members) m.id: 0};
  var total = 0;
  var count = 0;

  // Month buckets for the "over time" rows, oldest first.
  final months = [
    for (var i = statsMonthCount - 1; i >= 0; i--)
      DateTime.utc(input.today.year, input.today.month - i),
  ];
  final monthIndex = {
    for (var i = 0; i < months.length; i++) _monthKey(months[i]): i,
  };
  final monthExpense = List.filled(months.length, 0);
  final monthMeters = List.filled(months.length, 0);
  final monthRide = List.filled(months.length, 0);

  for (final entry in input.expenses) {
    final e = entry.expense;
    final date = e.date.toUtc();
    final bucket = monthIndex[_monthKey(date)];
    if (bucket != null) monthExpense[bucket] += e.amountCents;

    if (from != null && date.isBefore(from)) continue;
    if (to != null && !date.isBefore(to)) continue;
    total += e.amountCents;
    count++;
    final raw = entry.category?.trim();
    final key = raw == null || raw.isEmpty ? null : raw;
    categoryCents[key] = (categoryCents[key] ?? 0) + e.amountCents;
    categoryCount[key] = (categoryCount[key] ?? 0) + 1;
    for (final p in e.payers.entries) {
      if (paid.containsKey(p.key)) paid[p.key] = paid[p.key]! + p.value;
    }
    for (final s in e.shares.entries) {
      if (share.containsKey(s.key)) share[s.key] = share[s.key]! + s.value;
    }
  }

  if (input.rides.isNotEmpty) {
    final vehicles = {for (final v in input.vehicles) v.id: v};
    for (final entry in input.rides) {
      final ride = entry.ride;
      final bucket = monthIndex[_monthKey(ride.date)];
      if (bucket == null) continue;
      monthMeters[bucket] += ride.distanceMeters * (ride.roundTrip ? 2 : 1);
      final vehicle = vehicles[ride.vehicleId];
      if (vehicle == null) continue;
      final cost = rideCost(ride, vehicle, input.currency, input.members);
      // A ride the domain refuses to price still counts its distance.
      if (cost case Ok<TripCost, TripError>(:final value)) {
        monthRide[bucket] += value.totalCents;
      }
    }
  }

  final categories = [
    for (final e in categoryCents.entries)
      CategoryStat(
        key: e.key,
        cents: e.value,
        percent: _percent(e.value, total),
        count: categoryCount[e.key]!,
      ),
  ]..sort(_byCentsThenKey);

  return Statistics(
    period: period,
    totalCents: total,
    expenseCount: count,
    categories: categories,
    members: [
      for (final m in input.members)
        MemberStat(
          memberId: m.id,
          paidCents: paid[m.id]!,
          shareCents: share[m.id]!,
        ),
    ],
    months: [
      for (var i = 0; i < months.length; i++)
        MonthStat(
          year: months[i].year,
          month: months[i].month,
          expenseCents: monthExpense[i],
          rideMeters: monthMeters[i],
          rideCents: monthRide[i],
        ),
    ],
  );
}

int _monthKey(DateTime d) => d.year * 12 + d.month - 1;

/// [part] of [whole] in whole percent, half up; 0 for an empty whole.
int _percent(int part, int whole) =>
    whole <= 0 ? 0 : (part * 100 + whole ~/ 2) ~/ whole;

int _byCentsThenKey(CategoryStat a, CategoryStat b) {
  final byCents = b.cents.compareTo(a.cents);
  if (byCents != 0) return byCents;
  final ka = a.key;
  final kb = b.key;
  if (ka == null) return kb == null ? 0 : 1;
  if (kb == null) return -1;
  return ka.compareTo(kb);
}
