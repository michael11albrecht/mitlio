import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/first_value.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/settle/data/repositories/settle_actions_providers.dart';
import 'package:mitlio/features/settle/ui/settle_summary.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

// Views pick the payment method of a settlement.
export 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart'
    show SettlementMethod;

/// Formats an amount of the group currency for display (the View supplies
/// the locale).
typedef CentsFormatter = String Function(int cents);

/// One recorded settlement, with names for display.
final class HistoryItem {
  const HistoryItem({
    required this.entry,
    required this.fromName,
    required this.toName,
  });

  final SettlementEntry entry;
  final String fromName;
  final String toName;

  String get id => entry.settlement.id;
  int get amountCents => entry.settlement.amountCents;
  DateTime get date => entry.settlement.date;
}

sealed class SettleState {
  const SettleState();
}

final class SettleLoading extends SettleState {
  const SettleLoading();
}

final class SettleFailure extends SettleState {
  const SettleFailure(this.error);

  final RepositoryError error;
}

final class SettleLoaded extends SettleState {
  const SettleLoaded({
    required this.group,
    required this.transfers,
    required this.history,
    required this.names,
  });

  final Group group;

  /// What is still to pay: the simplified transfers.
  final List<Transfer> transfers;

  /// Recorded settlements, newest first.
  final List<HistoryItem> history;

  /// Member id to name.
  final Map<String, String> names;

  Currency get currency => group.currency;

  /// Nothing left to pay.
  bool get isSettled => transfers.isEmpty;

  String nameOf(String memberId) => names[memberId] ?? '?';
}

/// A settlement that was just recorded and how to take it back.
final class PaidTransfer {
  const PaidTransfer({required this.entry, required this.undo});

  final SettlementEntry entry;

  /// Deletes the settlement again (soft delete).
  final Undo undo;
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final _historyProvider = StreamProvider.autoDispose
    .family<List<SettlementEntry>, String>(
      (ref, groupId) =>
          ref.watch(settlementsRepositoryProvider).watchSettlements(groupId),
    );

/// "Ausgleichen": what is left to pay (simplified transfers, live from
/// balances), the recorded settlements, and the commands behind them.
class SettleViewModel extends Notifier<SettleState> {
  SettleViewModel(this.groupId);

  final String groupId;

  @override
  SettleState build() {
    final balances = ref.watch(balancesViewModelProvider(groupId));
    final history = ref.watch(_historyProvider(groupId));
    switch (balances) {
      case BalancesFailure(:final error):
        return SettleFailure(error);
      case BalancesLoading():
        return const SettleLoading();
      case BalancesLoaded():
        break;
    }
    if (history.hasError) {
      final e = history.error;
      return SettleFailure(e is RepositoryError ? e : Storage(e!));
    }
    final entries = history.value;
    if (entries == null) return const SettleLoading();
    final names = {
      for (final b in balances.balances) b.member.id: b.member.name,
    };
    String nameOf(String id) => names[id] ?? '?';
    final sorted = _newestFirst(entries);
    return SettleLoaded(
      group: balances.group,
      transfers: balances.simplified,
      history: [
        for (final e in sorted)
          HistoryItem(
            entry: e,
            fromName: nameOf(e.settlement.fromId),
            toName: nameOf(e.settlement.toId),
          ),
      ],
      names: names,
    );
  }

  void retry() {
    state = const SettleLoading();
    ref
      ..invalidate(balancesViewModelProvider(groupId))
      ..invalidateSelf();
  }

  /// Records that [fromId] paid [toId] [amountCents] (today, group
  /// currency). Less than the transfer is a partial payment: the rest stays
  /// open. Balances update live. [InvalidData] for a non-positive amount or a
  /// self payment.
  Future<RepoResult<PaidTransfer>> markPaid({
    required String fromId,
    required String toId,
    required int amountCents,
    SettlementMethod method = SettlementMethod.other,
  }) async {
    try {
      final Group group;
      switch (await ref.read(groupsRepositoryProvider).get(groupId)) {
        case Err<Group, RepositoryError>(:final error):
          return Err(error);
        case Ok<Group, RepositoryError>(:final value):
          group = value;
      }
      final now = ref.read(clockProvider).now().toUtc();
      final repo = ref.read(settlementsRepositoryProvider);
      final created = await repo.create(
        groupId,
        SettlementDraft(
          fromId: fromId,
          toId: toId,
          amountCents: amountCents,
          currency: group.currency,
          date: DateTime.utc(now.year, now.month, now.day),
          method: method,
        ),
      );
      return switch (created) {
        Ok<SettlementEntry, RepositoryError>(:final value) => Ok(
          PaidTransfer(
            entry: value,
            undo: Undo(
              () async => _asVoid(await repo.softDelete(value.settlement.id)),
            ),
          ),
        ),
        Err<SettlementEntry, RepositoryError>(:final error) => Err(error),
      };
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  /// Soft delete of a recorded settlement; call the [Undo] to bring it back.
  Future<RepoResult<Undo>> deleteSettlement(String id) async {
    try {
      return await ref.read(settlementsRepositoryProvider).softDelete(id);
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  /// The share text, e.g. `Urlaub: Ben → Anna 12,40 €`. Null when nothing is
  /// left to pay.
  String? summary(CentsFormatter format) {
    final s = state;
    if (s is! SettleLoaded || s.isSettled) return null;
    return buildSettleSummary(s.group.name, [
      for (final t in s.transfers)
        (
          from: s.nameOf(t.fromId),
          to: s.nameOf(t.toId),
          amount: format(t.amountCents),
        ),
    ]);
  }

  /// Opens the share sheet with the [summary]. Null when there is nothing to
  /// share.
  Future<RepoResult<void>?> share(CentsFormatter format) async {
    final text = summary(format);
    if (text == null) return null;
    return ref.read(settleActionsRepositoryProvider).shareText(text);
  }

  /// Open transfers and recorded settlements as of now, for
  /// `ext.mitlio.settle.list` (the screen watches the state instead). No
  /// payment details, ever.
  Future<RepoResult<JsonMap>> list() async {
    try {
      final balances = await ref
          .read(balancesViewModelProvider(groupId).notifier)
          .load();
      if (balances case Err<BalancesLoaded, RepositoryError>(:final error)) {
        return Err(error);
      }
      final entries = await firstValue(
        ref.read(settlementsRepositoryProvider).watchSettlements(groupId),
      );
      return Ok(
        _listJson(
          (balances as Ok<BalancesLoaded, RepositoryError>).value.simplified,
          _newestFirst(entries),
        ),
      );
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  JsonMap debugSnapshot() => switch (state) {
    SettleLoading() => {'status': 'loading', 'groupId': groupId},
    SettleFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    final SettleLoaded loaded => {
      'status': loaded.isSettled ? 'settled' : 'data',
      'groupId': groupId,
      'currency': loaded.currency.code,
      ..._listJson(loaded.transfers, [for (final h in loaded.history) h.entry]),
    },
  };
}

List<SettlementEntry> _newestFirst(List<SettlementEntry> entries) =>
    [...entries]..sort((a, b) {
      final byDate = b.settlement.date.compareTo(a.settlement.date);
      if (byDate != 0) return byDate;
      final byCreated = b.createdAt.compareTo(a.createdAt);
      return byCreated != 0
          ? byCreated
          : b.settlement.id.compareTo(a.settlement.id);
    });

JsonMap _listJson(List<Transfer> transfers, List<SettlementEntry> history) => {
  'transfers': [
    for (final t in transfers)
      {'from': t.fromId, 'to': t.toId, 'amount': t.amountCents},
  ],
  'history': [
    for (final e in history)
      {
        'id': e.settlement.id,
        'from': e.settlement.fromId,
        'to': e.settlement.toId,
        'amount': e.settlement.amountCents,
        'date': e.settlement.date.toIso8601String(),
        'method': e.method.name,
      },
  ],
};

RepoResult<void> _asVoid(RepoResult<Object?> result) => switch (result) {
  Ok<Object?, RepositoryError>() => const Ok(null),
  Err<Object?, RepositoryError>(:final error) => Err(error),
};

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final settleViewModelProvider =
    NotifierProvider.family<SettleViewModel, SettleState, String>(
      SettleViewModel.new,
    );
