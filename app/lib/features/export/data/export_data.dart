import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Everything an export needs, already computed by the balances logic: the
/// exports only format it.
final class ExportData {
  const ExportData({
    required this.group,
    required this.members,
    required this.expenses,
    required this.balances,
    required this.transfers,
  });

  final Group group;

  /// In position order.
  final List<GroupMember> members;

  /// Oldest first.
  final List<ExpenseEntry> expenses;

  /// Member id to net cents (positive = gets money back).
  final Map<String, int> balances;

  /// The simplified "who pays whom".
  final List<Transfer> transfers;

  String nameOf(String memberId) =>
      members.where((m) => m.id == memberId).firstOrNull?.name ?? '?';
}

/// Localised label of a stored category key; custom keys show as they are.
/// (Same keys as the expenses screen; kept here so exports do not import a
/// View.)
String exportCategory(AppLocalizations l10n, String? key) => switch (key) {
  null => '',
  'food' => l10n.exportCategoryFood,
  'stay' => l10n.exportCategoryStay,
  'transport' => l10n.exportCategoryTransport,
  'fun' => l10n.exportCategoryFun,
  'other' => l10n.exportCategoryOther,
  _ => key,
};

/// `dd.MM.yyyy` for German, ISO `yyyy-MM-dd` otherwise (no `intl` date data
/// needed, so this also works in plain unit tests).
String exportDate(DateTime date, String languageCode) {
  final d = date.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  final y = d.year.toString().padLeft(4, '0');
  return languageCode == 'de'
      ? '${two(d.day)}.${two(d.month)}.$y'
      : '$y-${two(d.month)}-${two(d.day)}';
}
