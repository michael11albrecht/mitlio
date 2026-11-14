import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/features/export/data/export_data.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// The text of the settlement report, fully formatted and localised. The PDF
/// renderer only lays it out, so tests assert on this model (PDF text is
/// glyph-encoded and cannot be grepped).
final class ReportModel {
  const ReportModel({
    required this.title,
    required this.groupName,
    required this.period,
    required this.membersHeading,
    required this.members,
    required this.totalsHeading,
    required this.totalsHeader,
    required this.totals,
    required this.transfersHeading,
    required this.transfers,
    required this.settledNote,
    required this.expensesHeading,
    required this.expensesHeader,
    required this.expenses,
  });

  final String title;
  final String groupName;
  final String period;
  final String membersHeading;

  /// One line per member: name and the payment hint (PayPal handle or masked
  /// IBAN), never a full IBAN.
  final List<String> members;
  final String totalsHeading;
  final List<String> totalsHeader;
  final List<List<String>> totals;
  final String transfersHeading;

  /// "Ben → Anna 12,40 €" per transfer; empty when everyone is square.
  final List<ReportTransfer> transfers;

  /// Shown instead of [transfers] when there are none.
  final String settledNote;
  final String expensesHeading;
  final List<String> expensesHeader;
  final List<List<String>> expenses;
}

/// One payment to make. The PDF draws the arrow itself (the bundled font has
/// no `→`); [text] is the plain form.
final class ReportTransfer {
  const ReportTransfer({
    required this.from,
    required this.to,
    required this.amount,
  });

  final String from;
  final String to;
  final String amount;

  String get text => '$from → $to $amount';
}

/// Builds the report: title, period, members, totals per person, the
/// simplified transfers and the expense list.
ReportModel buildReportModel(ExportData data, AppLocalizations l10n) {
  final lang = l10n.localeName.split('_').first;
  final money = MoneyFormat(l10n.localeName);
  final currency = data.group.currency;
  String fmt(int cents) => money.format(cents, currency);

  final paid = <String, int>{};
  final share = <String, int>{};
  for (final e in data.expenses) {
    e.expense.payers.forEach((id, c) => paid[id] = (paid[id] ?? 0) + c);
    e.expense.shares.forEach((id, c) => share[id] = (share[id] ?? 0) + c);
  }

  final dates = [for (final e in data.expenses) e.expense.date]..sort();
  return ReportModel(
    title: l10n.exportReportTitle,
    groupName: data.group.name,
    period: dates.isEmpty
        ? l10n.exportPeriodNone
        : l10n.exportPeriod(
            exportDate(dates.first, lang),
            exportDate(dates.last, lang),
          ),
    membersHeading: l10n.exportMembers,
    members: [
      for (final m in data.members)
        [
          m.name,
          if (m.paypalMe != null) l10n.exportPaypal(m.paypalMe!),
          if (m.ibanHint != null) l10n.exportIbanHint(m.ibanHint!),
        ].join(' · '),
    ],
    totalsHeading: l10n.exportTotals,
    totalsHeader: [
      l10n.exportColMember,
      l10n.exportColPaid,
      l10n.exportColShare,
      l10n.exportColBalance,
    ],
    totals: [
      for (final m in data.members)
        [
          m.name,
          fmt(paid[m.id] ?? 0),
          fmt(share[m.id] ?? 0),
          fmt(data.balances[m.id] ?? 0),
        ],
    ],
    transfersHeading: l10n.exportTransfers,
    transfers: [
      for (final t in data.transfers)
        ReportTransfer(
          from: data.nameOf(t.fromId),
          to: data.nameOf(t.toId),
          amount: fmt(t.amountCents),
        ),
    ],
    settledNote: l10n.exportAllSettled,
    expensesHeading: l10n.exportExpenses,
    expensesHeader: [
      l10n.exportColDate,
      l10n.exportColTitle,
      l10n.exportColPaidBy,
      l10n.exportColAmount,
    ],
    expenses: [
      for (final e in data.expenses)
        [
          exportDate(e.expense.date, lang),
          e.expense.title,
          [
            for (final m in data.members)
              if ((e.expense.payers[m.id] ?? 0) > 0) m.name,
          ].join(', '),
          fmt(e.expense.amountCents),
        ],
    ],
  );
}
