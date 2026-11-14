import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/first_value.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/statistics/data/statistics_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

export 'package:mitlio/features/statistics/data/statistics_calculator.dart'
    show
        CategoryStat,
        MemberStat,
        MonthStat,
        Statistics,
        StatsPeriod,
        statsMonthCount;

sealed class StatisticsState {
  const StatisticsState();
}

final class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

/// Also covers a group that does not exist (or was archived): [NotFound].
final class StatisticsFailure extends StatisticsState {
  const StatisticsFailure(this.error);

  final RepositoryError error;
}

final class StatisticsLoaded extends StatisticsState {
  const StatisticsLoaded({
    required this.group,
    required this.members,
    required this.stats,
    required this.today,
  });

  final Group group;

  /// In position order.
  final List<GroupMember> members;
  final Statistics stats;

  /// The day the periods are counted from.
  final DateTime today;

  Currency get currency => group.currency;
  StatsPeriod get period => stats.period;

  String nameOf(String memberId) =>
      members.where((m) => m.id == memberId).firstOrNull?.name ?? '?';
}

/// Statistics of one group, live from expenses and rides. Read-only; the only
/// command is the period picker.
class StatisticsViewModel extends Notifier<StatisticsState> {
  StatisticsViewModel(this.groupId);

  final String groupId;

  Group? _group;
  var _groupKnown = false;
  List<GroupMember>? _members;
  List<ExpenseEntry>? _expenses;
  List<RideEntry>? _rides;
  List<Vehicle>? _vehicles;
  StatsPeriod _period = StatsPeriod.month;
  RepositoryError? _failure;

  /// All rides: the "over time" rows need the last six months whatever the
  /// period is.
  static final _everything = Custom(DateTime.utc(2000), DateTime.utc(2100));

  @override
  StatisticsState build() {
    _group = null;
    _groupKnown = false;
    _members = null;
    _expenses = null;
    _rides = null;
    _vehicles = null;
    _failure = null;
    final subs = [
      _listen(ref.watch(groupsRepositoryProvider).watchGroups(), (groups) {
        _group = groups.where((g) => g.id == groupId).firstOrNull;
        _groupKnown = true;
      }),
      _listen(
        ref.watch(membersRepositoryProvider).watchMembers(groupId),
        (members) => _members = members,
      ),
      _listen(
        ref.watch(expensesRepositoryProvider).watchExpenses(groupId),
        (entries) => _expenses = entries,
      ),
      _listen(
        ref.watch(ridesRepositoryProvider).watchRides(groupId, _everything),
        (entries) => _rides = entries,
      ),
      _listen(
        ref.watch(vehiclesRepositoryProvider).watchVehicles(groupId),
        (vehicles) => _vehicles = vehicles,
      ),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    return const StatisticsLoading();
  }

  StreamSubscription<T> _listen<T>(Stream<T> stream, void Function(T) onData) =>
      stream.listen(
        (data) {
          onData(data);
          _emit();
        },
        onError: (Object e) {
          _failure = e is RepositoryError ? e : Storage(e);
          _emit();
        },
      );

  void _emit() {
    if (!ref.mounted) return;
    final failure = _failure;
    final members = _members;
    final expenses = _expenses;
    final rides = _rides;
    final vehicles = _vehicles;
    if (failure != null) {
      state = StatisticsFailure(failure);
    } else if (!_groupKnown ||
        members == null ||
        expenses == null ||
        rides == null ||
        vehicles == null) {
      state = const StatisticsLoading();
    } else if (_group case final group?) {
      state = _build(group, members, expenses, rides, vehicles, _period);
    } else {
      state = StatisticsFailure(NotFound('group', groupId));
    }
  }

  void retry() {
    state = const StatisticsLoading();
    ref.invalidateSelf();
  }

  /// Switches the period of the breakdowns.
  void setPeriod(StatsPeriod period) {
    _period = period;
    _emit();
  }

  /// Statistics as of now for [period] (DebugDrive; the UI watches the
  /// state).
  Future<RepoResult<StatisticsLoaded>> load([StatsPeriod? period]) async {
    try {
      final group = (await firstValue(
        ref.read(groupsRepositoryProvider).watchGroups(),
      )).where((g) => g.id == groupId).firstOrNull;
      if (group == null) return Err(NotFound('group', groupId));
      final members = await firstValue(
        ref.read(membersRepositoryProvider).watchMembers(groupId),
      );
      final expenses = await firstValue(
        ref.read(expensesRepositoryProvider).watchExpenses(groupId),
      );
      final rides = await firstValue(
        ref.read(ridesRepositoryProvider).watchRides(groupId, _everything),
      );
      final vehicles = await firstValue(
        ref.read(vehiclesRepositoryProvider).watchVehicles(groupId),
      );
      return Ok(
        _build(group, members, expenses, rides, vehicles, period ?? _period),
      );
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  StatisticsLoaded _build(
    Group group,
    List<GroupMember> members,
    List<ExpenseEntry> expenses,
    List<RideEntry> rides,
    List<Vehicle> vehicles,
    StatsPeriod period,
  ) {
    final now = ref.read(clockProvider).now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    return StatisticsLoaded(
      group: group,
      members: members,
      today: today,
      stats: computeStatistics(
        StatisticsInput(
          expenses: expenses,
          members: [for (final m in members) m.toDomain()],
          currency: group.currency,
          today: today,
          rides: rides,
          vehicles: vehicles,
        ),
        period,
      ),
    );
  }

  JsonMap debugSnapshot() => switch (state) {
    StatisticsLoading() => {'status': 'loading', 'groupId': groupId},
    StatisticsFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    final StatisticsLoaded loaded => {
      'status': loaded.stats.isEmpty ? 'empty' : 'data',
      'groupId': groupId,
      ...statisticsJson(loaded),
    },
  };
}

/// The numbers of [s]; the DebugDrive payload and the debug snapshot.
JsonMap statisticsJson(StatisticsLoaded s) => {
  'currency': s.currency.code,
  'period': s.period.name,
  'totalCents': s.stats.totalCents,
  'expenseCount': s.stats.expenseCount,
  'categories': [
    for (final c in s.stats.categories)
      {
        'key': c.key,
        'cents': c.cents,
        'percent': c.percent,
        'count': c.count,
      },
  ],
  'members': [
    for (final m in s.stats.members)
      {
        'id': m.memberId,
        'name': s.nameOf(m.memberId),
        'paidCents': m.paidCents,
        'shareCents': m.shareCents,
      },
  ],
  'months': [
    for (final m in s.stats.months)
      {
        'year': m.year,
        'month': m.month,
        'expenseCents': m.expenseCents,
        'rideMeters': m.rideMeters,
        'rideCents': m.rideCents,
      },
  ],
};

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final statisticsViewModelProvider =
    NotifierProvider.family<StatisticsViewModel, StatisticsState, String>(
      StatisticsViewModel.new,
    );
