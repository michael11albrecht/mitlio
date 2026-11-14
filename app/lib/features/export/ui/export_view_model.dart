import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/first_value.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/export/data/csv_builder.dart';
import 'package:mitlio/features/export/data/export_actions_repository.dart';
import 'package:mitlio/features/export/data/export_data.dart';
import 'package:mitlio/features/export/data/report_builder.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

enum ExportState { idle, working }

/// Export of one group: the expenses as CSV and the settlement report as
/// PDF, both handed to the share sheet. Numbers come from the balances view
/// model, so an export always agrees with the screen.
class ExportViewModel extends Notifier<ExportState> {
  ExportViewModel(this.groupId);

  final String groupId;

  @override
  ExportState build() => ExportState.idle;

  Future<RepoResult<ExportData>> _load() async {
    try {
      final balances = await ref
          .read(balancesViewModelProvider(groupId).notifier)
          .load();
      if (balances case Err<BalancesLoaded, RepositoryError>(:final error)) {
        return Err(error);
      }
      final loaded = (balances as Ok<BalancesLoaded, RepositoryError>).value;
      final entries = await firstValue(
        ref.read(expensesRepositoryProvider).watchExpenses(groupId),
      );
      return Ok(
        ExportData(
          group: loaded.group,
          members: [for (final b in loaded.balances) b.member],
          expenses: [...entries]
            ..sort((a, b) {
              final byDate = a.expense.date.compareTo(b.expense.date);
              return byDate != 0
                  ? byDate
                  : a.expense.id.compareTo(b.expense.id);
            }),
          balances: {for (final b in loaded.balances) b.member.id: b.cents},
          transfers: loaded.simplified,
        ),
      );
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  /// The CSV text (also behind `ext.mitlio.export.csv`).
  Future<RepoResult<String>> csv(AppLocalizations l10n) async =>
      switch (await _load()) {
        Ok<ExportData, RepositoryError>(:final value) => Ok(
          buildExpensesCsv(value, l10n),
        ),
        Err<ExportData, RepositoryError>(:final error) => Err(error),
      };

  /// Opens the share sheet with the CSV file (UTF-8 with BOM, so Excel reads
  /// umlauts right).
  Future<RepoResult<void>> shareCsv(AppLocalizations l10n) => _run(
    () async => switch (await _load()) {
      Ok<ExportData, RepositoryError>(:final value) => await _share(
        '${_fileName(value.group.name)}.csv',
        'text/csv',
        Uint8List.fromList([
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode(buildExpensesCsv(value, l10n)),
        ]),
      ),
      Err<ExportData, RepositoryError>(:final error) => Err(error),
    },
  );

  /// Opens the share sheet with the settlement report as PDF.
  Future<RepoResult<void>> sharePdf(AppLocalizations l10n) => _run(
    () async => switch (await _load()) {
      Ok<ExportData, RepositoryError>(:final value) => await _renderAndShare(
        value,
        l10n,
      ),
      Err<ExportData, RepositoryError>(:final error) => Err(error),
    },
  );

  Future<RepoResult<void>> _renderAndShare(
    ExportData data,
    AppLocalizations l10n,
  ) async {
    final actions = ref.read(exportActionsRepositoryProvider);
    return switch (await actions.renderPdf(buildReportModel(data, l10n))) {
      Ok<Uint8List, RepositoryError>(:final value) => await _share(
        '${_fileName(data.group.name)}.pdf',
        'application/pdf',
        value,
      ),
      Err<Uint8List, RepositoryError>(:final error) => Err(error),
    };
  }

  Future<RepoResult<void>> _share(
    String name,
    String mimeType,
    Uint8List bytes,
  ) => ref
      .read(exportActionsRepositoryProvider)
      .shareFile(name: name, mimeType: mimeType, bytes: bytes);

  /// Runs [body] while [state] is `working`; a second call meanwhile fails
  /// with [Conflict] instead of opening two share sheets.
  Future<RepoResult<void>> _run(
    Future<RepoResult<void>> Function() body,
  ) async {
    if (state == ExportState.working) return const Err(Conflict('exporting'));
    state = ExportState.working;
    try {
      return await body();
    } finally {
      if (ref.mounted) state = ExportState.idle;
    }
  }
}

/// `Urlaub in Rom` to `urlaub-in-rom`: safe as a file name everywhere.
String _fileName(String groupName) {
  final slug = groupName
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'mitlio' : slug;
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final exportViewModelProvider =
    NotifierProvider.family<ExportViewModel, ExportState, String>(
      ExportViewModel.new,
    );
