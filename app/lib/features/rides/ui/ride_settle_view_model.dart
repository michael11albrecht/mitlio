import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/first_value.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/rides/ui/ride_settlement.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `YYYY-MM` of [month] (the form DebugDrive speaks).
String monthKey(Month month) =>
    '${month.year.toString().padLeft(4, '0')}-'
    '${month.month.toString().padLeft(2, '0')}';

/// A settlement that just happened: what to tell the user and how to take it
/// back.
final class SettledMonth {
  const SettledMonth({
    required this.month,
    required this.expenses,
    required this.rideCount,
    required this.undo,
  });

  final Month month;

  /// One expense per driver, in the domain's driver order.
  final List<ExpenseEntry> expenses;
  final int rideCount;

  /// Deletes the expenses and unlocks the rides again.
  final Undo undo;
}

/// Everything the settlement and the fairness view need, loaded fresh from
/// the repositories (so DebugDrive works before the screen has loaded).
final class _Loaded {
  const _Loaded({
    required this.group,
    required this.members,
    required this.vehicles,
    required this.entries,
  });

  final Group group;
  final List<GroupMember> members;
  final Map<String, Vehicle> vehicles;
  final List<RideEntry> entries;

  List<Member> get domainMembers => [for (final m in members) m.toDomain()];
}

/// Names the expense of one driver ("Fahrten Oktober 2026 · Anna"); the View
/// passes the l10n string.
typedef SettlementTitle = String Function(String driverName, Month month);

/// "Abrechnen für Oktober": the one command behind the settle sheet's
/// primary button and `ext.mitlio.rides.settle`. The state says whether a
/// settlement is running, so the button cannot be tapped twice.
class RideSettleViewModel extends Notifier<bool> {
  RideSettleViewModel(this.groupId);

  final String groupId;

  @override
  bool build() => false;

  Future<RepoResult<_Loaded>> _load(Month month) async {
    try {
      final group = await ref.read(groupsRepositoryProvider).get(groupId);
      if (group case Err<Group, RepositoryError>(:final error)) {
        return Err(error);
      }
      final members = await ref.read(membersRepositoryProvider).list(groupId);
      if (members case Err<List<GroupMember>, RepositoryError>(:final error)) {
        return Err(error);
      }
      final vehicles = await firstValue(
        ref.read(vehiclesRepositoryProvider).watchVehicles(groupId),
      );
      final entries = await firstValue(
        ref.read(ridesRepositoryProvider).watchRides(groupId, month),
      );
      return Ok(
        _Loaded(
          group: (group as Ok<Group, RepositoryError>).value,
          members: (members as Ok<List<GroupMember>, RepositoryError>).value,
          vehicles: {for (final v in vehicles) v.id: v},
          entries: entries,
        ),
      );
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  /// Turns the unsettled rides of [month] into one expense per driver and
  /// locks them, all in one transaction. [InvalidData] if there is nothing
  /// to settle. Settled rides stay out, so settling again only picks up the
  /// rides logged since.
  Future<RepoResult<SettledMonth>> settle(
    Month month, {
    required SettlementTitle titleOf,
  }) async {
    if (state) return const Err(Conflict('a settlement is already running'));
    state = true;
    try {
      return await _settle(month, titleOf);
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    } finally {
      if (ref.mounted) state = false;
    }
  }

  Future<RepoResult<SettledMonth>> _settle(
    Month month,
    SettlementTitle titleOf,
  ) async {
    final result = await _load(month);
    if (result case Err<_Loaded, RepositoryError>(:final error)) {
      return Err(error);
    }
    final loaded = (result as Ok<_Loaded, RepositoryError>).value;
    final plan = planSettlement(
      unsettled: [
        for (final e in loaded.entries)
          if (!e.isSettled) e.ride,
      ],
      month: month,
      vehicles: loaded.vehicles,
      currency: loaded.group.currency,
      members: loaded.domainMembers,
    );
    if (plan == null || plan.isEmpty) {
      return const Err(InvalidData('nothing to settle'));
    }

    final now = ref.read(clockProvider).now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final lastDay = DateTime.utc(month.year, month.month + 1, 0);
    final date = lastDay.isBefore(today) ? lastDay : today;
    String nameOf(String id) =>
        loaded.members.where((m) => m.id == id).firstOrNull?.name ?? '';
    final items = <PeriodSettlement>[];
    for (final driver in plan.drivers) {
      final expense = rideAggregateToExpense(
        id: 'settlement-draft',
        title: titleOf(nameOf(driver.driverId), month),
        date: date,
        aggregate: driver.aggregate,
        currency: loaded.group.currency,
        members: loaded.domainMembers,
      );
      if (expense case Err<Expense, ExpenseError>(:final error)) {
        return Err(InvalidData('$error'));
      }
      final valid = (expense as Ok<Expense, ExpenseError>).value;
      items.add(
        PeriodSettlement(
          rideIds: driver.rideIds,
          draft: ExpenseDraft(
            title: valid.title,
            amountCents: valid.amountCents,
            currency: valid.currency,
            date: valid.date,
            payers: valid.payers,
            split: ExactSplit(valid.shares),
            // Type `trip` without trip inputs: the trip form skips documents
            // it does not know (version 2).
            tripMeta: jsonEncode({
              'v': 2,
              'source': 'rides',
              'period': monthKey(month),
              'driverId': driver.driverId,
              'rideIds': driver.rideIds,
            }),
          ),
        ),
      );
    }

    final rides = ref.read(ridesRepositoryProvider);
    return switch (await rides.settlePeriod(groupId, items)) {
      Ok<List<ExpenseEntry>, RepositoryError>(:final value) => Ok(
        SettledMonth(
          month: month,
          expenses: value,
          rideCount: plan.rideCount,
          undo: Undo(
            () => rides.unsettle([for (final e in value) e.expense.id]),
          ),
        ),
      ),
      Err<List<ExpenseEntry>, RepositoryError>(:final error) => Err(error),
    };
  }

  /// Who drove and rode how far in [month], and the net in cents (for
  /// DebugDrive; the screen derives the same from its state).
  Future<RepoResult<JsonMap>> fairness(Month month) async {
    final result = await _load(month);
    if (result case Err<_Loaded, RepositoryError>(:final error)) {
      return Err(error);
    }
    final data = (result as Ok<_Loaded, RepositoryError>).value;
    final rows = computeFairness(
      rides: [for (final e in data.entries) e.ride],
      vehicles: data.vehicles,
      currency: data.group.currency,
      members: data.domainMembers,
    );
    return Ok({
      'month': monthKey(month),
      'rows': [
        for (final r in rows)
          {
            'memberId': r.memberId,
            'metersDriven': r.metersDriven,
            'metersRidden': r.metersRidden,
            'netCents': r.netCents,
          },
      ],
    });
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final rideSettleViewModelProvider =
    NotifierProvider.family<RideSettleViewModel, bool, String>(
      RideSettleViewModel.new,
    );
