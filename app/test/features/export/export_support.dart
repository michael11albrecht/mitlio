import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/export/data/export_actions_repository.dart';
import 'package:mitlio/features/export/data/export_data.dart';
import 'package:mitlio/features/export/data/report_builder.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

AppLocalizations l10nOf(String language) =>
    lookupAppLocalizations(Locale(language));

/// Records what would be rendered and shared; can be made to fail.
class FakeExportActions implements ExportActionsRepository {
  final reports = <ReportModel>[];
  final shared = <({String name, String mimeType, Uint8List bytes})>[];
  RepositoryError? failRender;
  RepositoryError? failShare;

  @override
  Future<RepoResult<Uint8List>> renderPdf(ReportModel report) async {
    if (failRender != null) return Err(failRender!);
    reports.add(report);
    return Ok(Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));
  }

  @override
  Future<RepoResult<void>> shareFile({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (failShare != null) return Err(failShare!);
    shared.add((name: name, mimeType: mimeType, bytes: bytes));
    return const Ok(null);
  }
}

List<Override> exportOverrides(FakeExportActions actions) => [
  exportActionsRepositoryProvider.overrideWithValue(actions),
];

/// Hand-built data for the pure builders: Anna and Ben, one shared dinner and
/// one expense whose title would be a formula.
ExportData sampleData({
  Currency currency = Currency.eur,
  String annaName = 'Anna',
}) {
  final members = [
    GroupMember(
      id: 'a',
      groupId: 'g',
      name: annaName,
      position: 0,
      paypalMe: 'anna',
    ),
    const GroupMember(
      id: 'b',
      groupId: 'g',
      name: 'Ben',
      position: 1,
      ibanHint: 'DE89 •••• 3000',
    ),
  ];
  Expense expense(
    String id,
    String title,
    int cents,
    DateTime date,
    Map<String, int> payers,
  ) => (Expense.create(
    id: id,
    title: title,
    amountCents: cents,
    currency: currency,
    date: date,
    payers: payers,
    split: EqualSplit({'a', 'b'}),
    members: [for (final m in members) m.toDomain()],
  ) as Ok<Expense, ExpenseError>).value;

  return ExportData(
    group: Group(
      id: 'g',
      name: 'Rom',
      currency: currency,
      createdBy: 'dev',
      createdAt: DateTime.utc(2026),
    ),
    members: members,
    expenses: [
      ExpenseEntry(
        groupId: 'g',
        expense: expense('e1', 'Abendessen', 4001, DateTime.utc(2026, 3, 5), {
          'a': 4001,
        }),
        split: EqualSplit({'a', 'b'}),
        category: 'food',
        createdAt: DateTime.utc(2026, 3, 5),
      ),
      ExpenseEntry(
        groupId: 'g',
        expense: expense(
          'e2',
          '=Taxi, "Flughafen"',
          1250,
          DateTime.utc(2026, 3, 7),
          {
            'a': 250,
            'b': 1000,
          },
        ),
        split: EqualSplit({'a', 'b'}),
        createdAt: DateTime.utc(2026, 3, 7),
      ),
    ],
    balances: {'a': 1625, 'b': -1625},
    transfers: [Transfer(fromId: 'b', toId: 'a', amountCents: 1625)],
  );
}
