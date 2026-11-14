import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settle/data/repositories/settle_actions_providers.dart';
import 'package:mitlio/features/settle/data/repositories/settle_actions_repository.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

// The options a receiver can be paid with are part of this state.
export 'package:mitlio/features/settle/data/repositories/settle_actions_repository.dart'
    show PayoutOptions;

/// Which transfer the sheet is about. Equal keys share one ViewModel.
typedef TransferKey = ({
  String groupId,
  String fromId,
  String toId,
  int amountCents,
});

/// Why the entered amount cannot be booked.
enum AmountProblem {
  /// Empty, zero or not a number.
  invalid,

  /// More than the open transfer.
  tooHigh,
}

/// A calm one-line note under the actions.
enum SheetNotice {
  /// No app could open PayPal; the link is on the clipboard.
  linkCopied,

  ibanCopied,

  /// A payment action did not work.
  actionFailed,
}

sealed class TransferSheetState {
  const TransferSheetState();
}

final class TransferSheetLoading extends TransferSheetState {
  const TransferSheetLoading();
}

final class TransferSheetFailure extends TransferSheetState {
  const TransferSheetFailure(this.error);

  final RepositoryError error;
}

final class TransferSheetLoaded extends TransferSheetState {
  const TransferSheetLoaded({
    required this.key,
    required this.fromName,
    required this.toName,
    required this.currency,
    required this.options,
    required this.amountCents,
    this.epcPayload,
    this.method = SettlementMethod.other,
    this.notice,
    this.busy = false,
  });

  final TransferKey key;
  final String fromName;
  final String toName;
  final Currency currency;
  final PayoutOptions options;

  /// The amount to book; null while the field is empty or unreadable.
  final int? amountCents;

  /// The EPC QR payload for [amountCents]; null without IBAN, for other
  /// currencies than euro or while the amount is not valid. Contains the
  /// IBAN: never log it, never put it into a debug snapshot.
  final String? epcPayload;

  /// What the user did to pay, recorded with the settlement.
  final SettlementMethod method;
  final SheetNotice? notice;
  final bool busy;

  int get fullCents => key.amountCents;

  /// The whole open transfer, not a partial payment.
  bool get isFull => amountCents == fullCents;

  AmountProblem? get problem {
    final a = amountCents;
    if (a == null || a <= 0) return AmountProblem.invalid;
    if (a > fullCents) return AmountProblem.tooHigh;
    return null;
  }

  bool get canMarkPaid => problem == null && !busy;

  /// Neither PayPal nor a bank transfer is possible.
  bool get hasNoPaymentDetails => options.isEmpty;

  TransferSheetLoaded copyWith({
    int? amountCents,
    bool clearAmount = false,
    String? epcPayload,
    bool clearEpc = false,
    SettlementMethod? method,
    SheetNotice? notice,
    bool clearNotice = false,
    bool? busy,
  }) => TransferSheetLoaded(
    key: key,
    fromName: fromName,
    toName: toName,
    currency: currency,
    options: options,
    amountCents: clearAmount ? null : (amountCents ?? this.amountCents),
    epcPayload: clearEpc ? null : (epcPayload ?? this.epcPayload),
    method: method ?? this.method,
    notice: clearNotice ? null : (notice ?? this.notice),
    busy: busy ?? this.busy,
  );
}

/// One transfer in the bottom sheet: pay (PayPal, EPC QR, copy IBAN), edit
/// the amount for a partial payment, mark as paid. Auto-disposed, so the
/// QR payload does not outlive the sheet.
class TransferSheetViewModel extends Notifier<TransferSheetState> {
  TransferSheetViewModel(this.key);

  final TransferKey key;

  var _epcRun = 0;

  @override
  TransferSheetState build() {
    // After build: a state set synchronously in here would be overwritten.
    unawaited(Future.microtask(_load));
    return const TransferSheetLoading();
  }

  Money _money(Currency currency, int cents) => Money(cents, currency);

  Future<void> _load() async {
    try {
      final settle = ref.read(settleViewModelProvider(key.groupId));
      if (settle is! SettleLoaded) {
        state = TransferSheetFailure(NotFound('group', key.groupId));
        return;
      }
      final options = await ref
          .read(settleActionsRepositoryProvider)
          .options(key.toId);
      if (!ref.mounted) return;
      switch (options) {
        case Err<PayoutOptions, RepositoryError>(:final error):
          state = TransferSheetFailure(error);
        case Ok<PayoutOptions, RepositoryError>(:final value):
          state = TransferSheetLoaded(
            key: key,
            fromName: settle.nameOf(key.fromId),
            toName: settle.nameOf(key.toId),
            currency: settle.currency,
            options: value,
            amountCents: key.amountCents,
          );
          await _refreshEpc();
      }
    } on Object catch (e) {
      if (ref.mounted) {
        state = TransferSheetFailure(e is RepositoryError ? e : Storage(e));
      }
    }
  }

  void retry() {
    state = const TransferSheetLoading();
    unawaited(_load());
  }

  /// The QR payload follows the amount; only the newest request wins.
  Future<void> _refreshEpc() async {
    final s = state;
    if (s is! TransferSheetLoaded) return;
    final run = ++_epcRun;
    final cents = s.amountCents;
    String? payload;
    if (s.options.hasIban && s.problem == null && cents != null) {
      final settle = ref.read(settleViewModelProvider(key.groupId));
      final result = await ref
          .read(settleActionsRepositoryProvider)
          .epcPayload(
            memberId: key.toId,
            memberName: s.toName,
            amount: _money(s.currency, cents),
            remittance: settle is SettleLoaded
                ? 'mitlio: ${settle.group.name}'
                : 'mitlio',
          );
      if (result case Ok<String?, RepositoryError>(:final value)) {
        payload = value;
      }
    }
    if (!ref.mounted || run != _epcRun) return;
    final now = state;
    if (now is! TransferSheetLoaded) return;
    state = payload == null
        ? now.copyWith(clearEpc: true)
        : now.copyWith(epcPayload: payload);
  }

  /// The edited amount (null while empty or unreadable). Partial payments
  /// are allowed; more than the open transfer is not.
  void setAmount(int? cents) {
    final s = state;
    if (s is! TransferSheetLoaded) return;
    state = cents == null
        ? s.copyWith(clearAmount: true, clearEpc: true)
        : s.copyWith(amountCents: cents);
    unawaited(_refreshEpc());
  }

  /// Opens the PayPal.Me link for the current amount. If nothing can open
  /// it, the link is copied and the notice says so.
  Future<void> openPayPal() async {
    final s = state;
    if (s is! TransferSheetLoaded || !s.options.hasPaypal) return;
    final cents = s.amountCents;
    if (s.problem != null || cents == null) return;
    final result = await ref
        .read(settleActionsRepositoryProvider)
        .openPayPal(key.toId, _money(s.currency, cents));
    if (!ref.mounted) return;
    final now = state;
    if (now is! TransferSheetLoaded) return;
    state = switch (result) {
      Ok<PayPalOutcome, RepositoryError>(:final value) => now.copyWith(
        method: SettlementMethod.paypal,
        notice: value == PayPalOutcome.copied ? SheetNotice.linkCopied : null,
        clearNotice: value == PayPalOutcome.opened,
      ),
      Err<PayPalOutcome, RepositoryError>() => now.copyWith(
        notice: SheetNotice.actionFailed,
      ),
    };
  }

  /// Puts the receiver's IBAN on the clipboard.
  Future<void> copyIban() async {
    final s = state;
    if (s is! TransferSheetLoaded || !s.options.hasIban) return;
    final result = await ref
        .read(settleActionsRepositoryProvider)
        .copyIban(key.toId);
    if (!ref.mounted) return;
    final now = state;
    if (now is! TransferSheetLoaded) return;
    state = switch (result) {
      Ok<void, RepositoryError>() => now.copyWith(
        method: SettlementMethod.sepa,
        notice: SheetNotice.ibanCopied,
      ),
      Err<void, RepositoryError>() => now.copyWith(
        notice: SheetNotice.actionFailed,
      ),
    };
  }

  /// Books the entered amount as paid. [InvalidData] if the amount is not
  /// valid. Balances update live; the returned [PaidTransfer] undoes it.
  Future<RepoResult<PaidTransfer>> markPaid() async {
    final s = state;
    final cents = s is TransferSheetLoaded ? s.amountCents : null;
    if (s is! TransferSheetLoaded || !s.canMarkPaid || cents == null) {
      return const Err(InvalidData('amount not valid'));
    }
    state = s.copyWith(busy: true);
    final result = await ref
        .read(settleViewModelProvider(key.groupId).notifier)
        .markPaid(
          fromId: key.fromId,
          toId: key.toId,
          amountCents: cents,
          method: s.method,
        );
    if (ref.mounted) {
      final now = state;
      if (now is TransferSheetLoaded) {
        state = result is Err
            ? now.copyWith(busy: false, notice: SheetNotice.actionFailed)
            : now.copyWith(busy: false);
      }
    }
    return result;
  }

  /// Never contains the IBAN, BIC, account name or the QR payload: only
  /// whether PayPal and a bank account are available.
  JsonMap debugSnapshot() => switch (state) {
    TransferSheetLoading() => {'status': 'loading'},
    TransferSheetFailure(:final error) => {
      'status': 'error',
      'error': error.toString(),
    },
    final TransferSheetLoaded s => {
      'status': 'data',
      'from': key.fromId,
      'to': key.toId,
      'fullCents': s.fullCents,
      'amountCents': s.amountCents,
      'problem': s.problem?.name,
      'hasPaypal': s.options.hasPaypal,
      'hasIban': s.options.hasIban,
      'hasQr': s.epcPayload != null,
      'method': s.method.name,
      'notice': s.notice?.name,
    },
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final transferSheetViewModelProvider = NotifierProvider.autoDispose
    .family<TransferSheetViewModel, TransferSheetState, TransferKey>(
      TransferSheetViewModel.new,
    );
