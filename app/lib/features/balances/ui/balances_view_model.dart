import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/balances/ui/balances_calculator.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Which "who pays whom" list is shown.
enum BalancesMode {
  /// Fewest payments (`simplifyDebts`).
  simplified,

  /// Every debt as it arose, between the two people involved.
  pairwise,
}

/// One member and their net position (positive = gets money back).
final class MemberBalance {
  const MemberBalance({required this.member, required this.cents});

  final GroupMember member;
  final int cents;
}

sealed class BalancesState {
  const BalancesState();
}

final class BalancesLoading extends BalancesState {
  const BalancesLoading();
}

/// Also covers a group that does not exist (or was archived): [NotFound].
final class BalancesFailure extends BalancesState {
  const BalancesFailure(this.error);

  final RepositoryError error;
}

final class BalancesLoaded extends BalancesState {
  const BalancesLoaded({
    required this.group,
    required this.balances,
    required this.simplified,
    required this.pairwise,
    required this.mode,
    required this.hasEntries,
  });

  final Group group;

  /// In position order.
  final List<MemberBalance> balances;
  final List<Transfer> simplified;
  final List<Transfer> pairwise;
  final BalancesMode mode;

  /// Any expense or settlement exists.
  final bool hasEntries;

  Currency get currency => group.currency;

  /// The transfers for the selected [mode].
  List<Transfer> get transfers =>
      mode == BalancesMode.simplified ? simplified : pairwise;

  /// Entries exist and everyone is square.
  bool get isSettled => hasEntries && simplified.isEmpty;

  String nameOf(String memberId) => balances
      .firstWhere(
        (b) => b.member.id == memberId,
        orElse: () => MemberBalance(
          member: GroupMember(
            id: memberId,
            groupId: group.id,
            name: '?',
            position: 0,
          ),
          cents: 0,
        ),
      )
      .member
      .name;
}

/// Balances tab: net per person and who pays whom, live from expenses and
/// settlements. Read-only (marking as paid is P4).
class BalancesViewModel extends Notifier<BalancesState> {
  BalancesViewModel(this.groupId);

  final String groupId;

  Group? _group;
  var _groupKnown = false;
  List<GroupMember>? _members;
  List<ExpenseEntry>? _expenses;
  List<SettlementEntry>? _settlements;
  BalancesMode _mode = BalancesMode.simplified;
  RepositoryError? _failure;

  @override
  BalancesState build() {
    _group = null;
    _groupKnown = false;
    _members = null;
    _expenses = null;
    _settlements = null;
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
        ref.watch(settlementsRepositoryProvider).watchSettlements(groupId),
        (entries) => _settlements = entries,
      ),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    return const BalancesLoading();
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
    final settlements = _settlements;
    if (failure != null) {
      state = BalancesFailure(failure);
    } else if (!_groupKnown ||
        members == null ||
        expenses == null ||
        settlements == null) {
      state = const BalancesLoading();
    } else if (_group case final group?) {
      state = _build(group, members, expenses, settlements, _mode);
    } else {
      state = BalancesFailure(NotFound('group', groupId));
    }
  }

  BalancesState _build(
    Group group,
    List<GroupMember> members,
    List<ExpenseEntry> expenses,
    List<SettlementEntry> settlements,
    BalancesMode mode,
  ) {
    try {
      final result = computeBalancesResult(
        members: [for (final m in members) m.toDomain()],
        expenses: [for (final e in expenses) e.expense],
        settlements: [for (final s in settlements) s.settlement],
      );
      return BalancesLoaded(
        group: group,
        balances: [
          for (final m in members)
            MemberBalance(member: m, cents: result.balances[m.id] ?? 0),
        ],
        simplified: result.simplified,
        pairwise: result.pairwise,
        mode: mode,
        hasEntries: expenses.isNotEmpty || settlements.isNotEmpty,
      );
      // ignore: avoid_catching_errors, the domain signals bad stored data with ArgumentError
    } on ArgumentError catch (e) {
      // Unknown member or mixed currencies: stored data the domain refuses.
      return BalancesFailure(InvalidData('$e'));
    }
  }

  void retry() {
    state = const BalancesLoading();
    ref.invalidateSelf();
  }

  /// Switches between the simplified and the direct list.
  void setMode(BalancesMode mode) {
    _mode = mode;
    _emit();
  }

  /// Balances as of now (for DebugDrive; the UI watches the state).
  Future<RepoResult<BalancesLoaded>> load() async {
    try {
      final group =
          (await ref.read(groupsRepositoryProvider).watchGroups().first)
              .where((g) => g.id == groupId)
              .firstOrNull;
      if (group == null) return Err(NotFound('group', groupId));
      final members = await ref
          .read(membersRepositoryProvider)
          .watchMembers(groupId)
          .first;
      final expenses = await ref
          .read(expensesRepositoryProvider)
          .watchExpenses(groupId)
          .first;
      final settlements = await ref
          .read(settlementsRepositoryProvider)
          .watchSettlements(groupId)
          .first;
      return switch (_build(group, members, expenses, settlements, _mode)) {
        final BalancesLoaded loaded => Ok(loaded),
        BalancesFailure(:final error) => Err(error),
        BalancesLoading() => const Err(Storage('balances not computed')),
      };
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  JsonMap debugSnapshot() => switch (state) {
    BalancesLoading() => {'status': 'loading', 'groupId': groupId},
    BalancesFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    final BalancesLoaded loaded => {
      'status': !loaded.hasEntries
          ? 'empty'
          : loaded.isSettled
          ? 'settled'
          : 'data',
      'groupId': groupId,
      'currency': loaded.currency.code,
      'mode': loaded.mode.name,
      ...balancesJson(loaded),
    },
  };
}

/// `{balances, transfers}` of the selected mode; the DebugDrive payload.
JsonMap balancesJson(BalancesLoaded s, {List<Transfer>? transfers}) => {
  'balances': {for (final b in s.balances) b.member.id: b.cents},
  'transfers': [
    for (final t in transfers ?? s.transfers)
      {'from': t.fromId, 'to': t.toId, 'amount': t.amountCents},
  ],
};

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final balancesViewModelProvider =
    NotifierProvider.family<BalancesViewModel, BalancesState, String>(
      BalancesViewModel.new,
    );
