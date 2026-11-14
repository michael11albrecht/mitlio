import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/settle/ui/settle_view.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio/features/settle/ui/transfer_sheet.dart';
import 'package:mitlio/features/settle/ui/transfer_sheet_view_model.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Fixed state for goldens and a11y tests: no repository is touched.
class StubSettleViewModel extends SettleViewModel {
  StubSettleViewModel(super.groupId, this.fixed);

  final SettleState fixed;

  @override
  SettleState build() => fixed;
}

/// Fixed state for the sheet; marking as paid is never reached here.
class StubTransferSheetViewModel extends TransferSheetViewModel {
  StubTransferSheetViewModel(super.key, this.fixed);

  final TransferSheetState fixed;

  @override
  TransferSheetState build() => fixed;
}

List<Override> settleStateOverride(SettleState state) => [
  settleViewModelProvider.overrideWith2(
    (id) => StubSettleViewModel(id, state),
  ),
];

List<Override> sheetStateOverride(TransferSheetState state) => [
  transferSheetViewModelProvider.overrideWith2(
    (key) => StubTransferSheetViewModel(key, state),
  ),
];

final _group = Group(
  id: 'g-1',
  name: 'Wochenende in den Bergen',
  currency: Currency.eur,
  createdBy: 'local',
  createdAt: DateTime.utc(2026),
);

const _names = {
  'm-0': 'Anna Berg',
  'm-1': 'Ben',
  'm-2': 'Chiara Rossi',
  'm-3': 'Dino Kovač',
};

final List<Member> _members = [
  for (final (i, _) in _names.keys.indexed) Member(id: 'm-$i', position: i),
];

HistoryItem _paid(String id, String from, String to, int cents, int day) {
  final settlement = switch (Settlement.create(
    id: id,
    fromId: from,
    toId: to,
    amountCents: cents,
    currency: Currency.eur,
    date: DateTime.utc(2026, 3, day),
    members: _members,
  )) {
    Ok<Settlement, SettlementError>(:final value) => value,
    Err<Settlement, SettlementError>(:final error) => throw StateError(
      '$error',
    ),
  };
  return HistoryItem(
    entry: SettlementEntry(
      groupId: 'g-1',
      settlement: settlement,
      method: SettlementMethod.paypal,
      createdAt: DateTime.utc(2026, 3, day),
    ),
    fromName: _names[from]!,
    toName: _names[to]!,
  );
}

/// Chiara owes Anna 16,40, Ben owes Anna 7,00 and Dino 5,00; one payment
/// was already booked.
final SettleLoaded sampleSettle = SettleLoaded(
  group: _group,
  names: _names,
  transfers: [
    Transfer(fromId: 'm-2', toId: 'm-0', amountCents: 1640),
    Transfer(fromId: 'm-1', toId: 'm-0', amountCents: 700),
    Transfer(fromId: 'm-1', toId: 'm-3', amountCents: 500),
  ],
  history: [
    _paid('s-2', 'm-1', 'm-0', 500, 8),
    _paid('s-1', 'm-2', 'm-3', 1200, 3),
  ],
);

/// Everything paid, the history stays visible.
final SettleLoaded settledSettle = SettleLoaded(
  group: _group,
  names: _names,
  transfers: const [],
  history: [_paid('s-1', 'm-1', 'm-0', 1200, 3)],
);

final SettleLoaded emptySettle = SettleLoaded(
  group: _group,
  names: _names,
  transfers: const [],
  history: const [],
);

const TransferKey sheetKey = (
  groupId: 'g-1',
  fromId: 'm-1',
  toId: 'm-0',
  amountCents: 1240,
);

/// A real, valid EPC payload (the test IBAN of the domain rules).
const _epc =
    'BCD\n002\n1\nSCT\n\nAnna Muster\nDE89370400440532013000\nEUR12.40\n\n\n'
    'mitlio: Wochenende in den Bergen';

TransferSheetLoaded _sheet({
  required PayoutOptions options,
  String? epc,
  int? amount = 1240,
  SheetNotice? notice,
}) => TransferSheetLoaded(
  key: sheetKey,
  fromName: 'Ben',
  toName: 'Anna Berg',
  currency: Currency.eur,
  options: options,
  amountCents: amount,
  epcPayload: epc,
  notice: notice,
);

/// PayPal and a bank account: PayPal button, QR and copy IBAN.
final TransferSheetLoaded sheetFull = _sheet(
  options: const PayoutOptions(
    hasPaypal: true,
    hasIban: true,
    ibanHint: 'DE89 •••• 3000',
  ),
  epc: _epc,
);

/// Partial payment of 5,00 with the link copied.
final TransferSheetLoaded sheetPartial = _sheet(
  options: const PayoutOptions(hasPaypal: true, hasIban: false),
  amount: 500,
  notice: SheetNotice.linkCopied,
);

/// No payment details: the calm hint, marking still possible.
final TransferSheetLoaded sheetNoDetails = _sheet(
  options: const PayoutOptions(hasPaypal: false, hasIban: false),
);

/// More than the open transfer.
final TransferSheetLoaded sheetTooHigh = _sheet(
  options: const PayoutOptions(hasPaypal: false, hasIban: false),
  amount: 5000,
);

Widget scopedSettle(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: child);

const SettleView settleView = SettleView(groupId: 'g-1');
const TransferSheet transferSheet = TransferSheet(transferKey: sheetKey);
