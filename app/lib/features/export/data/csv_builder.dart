import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/features/export/data/export_data.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// The expenses of a group as RFC 4180 CSV (CRLF rows), one row per expense:
/// date, title, category, amount, currency, payers, then one share column per
/// member. A blank row and a balances section (person, balance, currency)
/// follow, so one file carries everything and needs no zip.
///
/// Locale rules: German uses `;` as separator and `,` as decimal mark,
/// everything else `,` and `.`. Amounts are plain numbers (no grouping, no
/// symbol) so spreadsheets read them as numbers. Text cells that a
/// spreadsheet could take for a formula are prefixed with `'`.
String buildExpensesCsv(ExportData data, AppLocalizations l10n) {
  final lang = l10n.localeName.split('_').first;
  final separator = lang == 'de' ? ';' : ',';
  final money = MoneyFormat(l10n.localeName);
  final currency = data.group.currency;
  String amount(int cents) => money.formatPlain(cents, currency);

  final rows = <List<String>>[
    [
      l10n.exportColDate,
      l10n.exportColTitle,
      l10n.exportColCategory,
      l10n.exportColAmount,
      l10n.exportColCurrency,
      l10n.exportColPaidBy,
      for (final m in data.members) '${l10n.exportColShare} ${_safe(m.name)}',
    ],
    for (final e in data.expenses)
      [
        exportDate(e.expense.date, lang),
        _safe(e.expense.title),
        _safe(exportCategory(l10n, e.category)),
        amount(e.expense.amountCents),
        currency.code,
        [
          for (final m in data.members)
            if (e.expense.payers[m.id] case final paid? when paid > 0)
              '${_safe(m.name)} (${amount(paid)})',
        ].join(' / '),
        for (final m in data.members) amount(e.expense.shares[m.id] ?? 0),
      ],
    <String>[],
    [l10n.exportBalances],
    [l10n.exportColMember, l10n.exportColBalance, l10n.exportColCurrency],
    for (final m in data.members)
      [_safe(m.name), amount(data.balances[m.id] ?? 0), currency.code],
  ];
  return [
    for (final row in rows)
      '${row.map((c) => _cell(c, separator)).join(separator)}\r\n',
  ].join();
}

/// RFC 4180: quote a cell holding the separator, a quote or a line break.
String _cell(String value, String separator) =>
    value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')
    ? '"${value.replaceAll('"', '""')}"'
    : value;

const _formulaStarts = ['=', '+', '-', '@', '\t', '\r'];

/// Neutralises spreadsheet formula injection in user-entered text.
String _safe(String text) =>
    _formulaStarts.any(text.startsWith) ? "'$text" : text;
