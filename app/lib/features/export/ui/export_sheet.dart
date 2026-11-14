import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/export/ui/export_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Opens the export choices (CSV or PDF) in a bottom sheet, no dialog.
Future<void> showExportSheet(BuildContext context, String groupId) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => ExportSheet(groupId: groupId),
    );

class ExportSheet extends ConsumerWidget {
  const ExportSheet({required this.groupId, super.key});

  final String groupId;

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    Future<RepoResult<void>> Function(ExportViewModel vm, AppLocalizations l10n)
    command,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await command(
      ref.read(exportViewModelProvider(groupId).notifier),
      l10n,
    );
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        navigator.pop();
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final busy =
        ref.watch(exportViewModelProvider(groupId)) == ExportState.working;
    return SafeArea(
      child: Padding(
        padding: Spacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exportTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ListTile(
              enabled: !busy,
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(l10n.exportCsv),
              subtitle: Text(l10n.exportCsvHint),
              onTap: () =>
                  unawaited(_export(context, ref, (vm, l) => vm.shareCsv(l))),
            ),
            ListTile(
              enabled: !busy,
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.exportPdf),
              subtitle: Text(l10n.exportPdfHint),
              onTap: () =>
                  unawaited(_export(context, ref, (vm, l) => vm.sharePdf(l))),
            ),
          ],
        ),
      ),
    );
  }
}
