import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/statistics/ui/statistics_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Fixed state for goldens and a11y tests: no repository is touched.
class StubStatisticsViewModel extends StatisticsViewModel {
  StubStatisticsViewModel(super.groupId, this.fixed);

  final StatisticsState fixed;
  StatsPeriod? lastPeriod;

  @override
  StatisticsState build() => fixed;

  @override
  void setPeriod(StatsPeriod period) {
    lastPeriod = period;
    final s = fixed;
    if (s is StatisticsLoaded) {
      state = StatisticsLoaded(
        group: s.group,
        members: s.members,
        today: s.today,
        stats: Statistics(
          period: period,
          totalCents: s.stats.totalCents,
          expenseCount: s.stats.expenseCount,
          categories: s.stats.categories,
          members: s.stats.members,
          months: s.stats.months,
        ),
      );
    }
  }
}

List<Override> statisticsStateOverride(StatisticsState state) => [
  statisticsViewModelProvider.overrideWith2(
    (id) => StubStatisticsViewModel(id, state),
  ),
];

final _group = Group(
  id: 'g-1',
  name: 'Wochenende in den Bergen',
  currency: Currency.eur,
  createdBy: 'local',
  createdAt: DateTime.utc(2026),
);

GroupMember _m(int i, String name) =>
    GroupMember(id: 'm-$i', groupId: 'g-1', name: name, position: i);

final List<GroupMember> _members = [
  _m(0, 'Anna Berg'),
  _m(1, 'Ben'),
  _m(2, 'Chiara Rossi'),
];

MonthStat _month(
  int year,
  int month,
  int cents, [
  int meters = 0,
  int ride = 0,
]) => MonthStat(
  year: year,
  month: month,
  expenseCents: cents,
  rideMeters: meters,
  rideCents: ride,
);

/// "Diesen Monat: 412,30 EUR, meist Sprit (38 %)": 412,30 over three
/// categories, three people and six months, with rides in two of them.
final sampleStatistics = StatisticsLoaded(
  group: _group,
  members: _members,
  today: DateTime.utc(2026, 3, 15),
  stats: Statistics(
    period: StatsPeriod.month,
    totalCents: 41230,
    expenseCount: 9,
    categories: const [
      CategoryStat(key: 'transport', cents: 15670, percent: 38, count: 3),
      CategoryStat(key: 'food', cents: 12400, percent: 30, count: 4),
      CategoryStat(key: null, cents: 13160, percent: 32, count: 2),
    ],
    members: const [
      MemberStat(memberId: 'm-0', paidCents: 26000, shareCents: 13743),
      MemberStat(memberId: 'm-1', paidCents: 9230, shareCents: 13743),
      MemberStat(memberId: 'm-2', paidCents: 6000, shareCents: 13744),
    ],
    months: [
      _month(2025, 10, 30500),
      _month(2025, 11, 0),
      _month(2025, 12, 52000, 46000, 6900),
      _month(2026, 1, 28100),
      _month(2026, 2, 35900, 120000, 18400),
      _month(2026, 3, 41230),
    ],
  ),
);

/// Same period, nothing spent.
final emptyStatistics = StatisticsLoaded(
  group: _group,
  members: _members,
  today: DateTime.utc(2026, 3, 15),
  stats: Statistics(
    period: StatsPeriod.month,
    totalCents: 0,
    expenseCount: 0,
    categories: const [],
    members: const [
      MemberStat(memberId: 'm-0', paidCents: 0, shareCents: 0),
      MemberStat(memberId: 'm-1', paidCents: 0, shareCents: 0),
      MemberStat(memberId: 'm-2', paidCents: 0, shareCents: 0),
    ],
    months: [
      for (final (y, m) in [
        (2025, 10),
        (2025, 11),
        (2025, 12),
        (2026, 1),
        (2026, 2),
        (2026, 3),
      ])
        _month(y, m, 0),
    ],
  ),
);

Widget scopedStatistics(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: child);
