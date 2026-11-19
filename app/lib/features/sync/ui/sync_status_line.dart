import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/sync/ui/sync_status_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// The words of a shared group's status line (P6-T12, ADR-27 §3): "Aktuell",
/// "Wird gesendet …", "3 Änderungen warten", or the du-form text of the
/// error. A refused change has a short line; the details are in the sheet.
String syncStatusText(AppLocalizations l10n, SyncLineShown line) =>
    switch (line.kind) {
      SyncLineKind.upToDate => l10n.syncStatusUpToDate,
      SyncLineKind.sending => l10n.syncStatusSending,
      SyncLineKind.pending => l10n.syncStatusPending(line.pendingCount),
      SyncLineKind.uploading =>
        (line.remaining ?? 0) > 0
            ? l10n.syncStatusUploadingLeft(line.remaining!)
            : l10n.syncStatusUploading,
      SyncLineKind.error =>
        line.error is Rejected
            ? l10n.syncRejectedLine
            : remoteErrorText(l10n, line.error!, title: line.title),
    };

/// Status line in the header of a shared group; nothing for a local-only
/// group. No badge, no popup: one line and at most one action.
class SyncStatusLine extends ConsumerWidget {
  const SyncStatusLine({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(syncStatusViewModelProvider(groupId));
    if (line is! SyncLineShown) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isError = line.kind == SyncLineKind.error;
    final color = isError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    final vm = ref.read(syncStatusViewModelProvider(groupId).notifier);
    final action = line.action;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon(line.kind), size: Spacing.md, color: color),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    syncStatusText(l10n, line),
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            // Below the text, not next to it: at large text sizes a button
            // beside it would not fit.
            if (action != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => switch (action) {
                    SyncLineAction.retry => unawaited(vm.retry()),
                    SyncLineAction.update => unawaited(_openStore(context, vm)),
                    SyncLineAction.showRejected => unawaited(
                      showRejectedChangeSheet(
                        context,
                        text: remoteErrorText(
                          l10n,
                          line.error!,
                          title: line.title,
                        ),
                        onOk: vm.acknowledge,
                      ),
                    ),
                  },
                  child: Text(switch (action) {
                    SyncLineAction.retry => l10n.retry,
                    SyncLineAction.showRejected => l10n.syncRejectedShow,
                    SyncLineAction.update => l10n.syncUpdateAction,
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "Aktualisieren": the store page, or plain words when it cannot open.
  static Future<void> _openStore(
    BuildContext context,
    SyncStatusViewModel vm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (await vm.openStore()) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.syncUpdateOpenFailed)));
  }

  static IconData _icon(SyncLineKind kind) => switch (kind) {
    SyncLineKind.upToDate => Icons.check_circle_outline,
    SyncLineKind.sending => Icons.sync,
    SyncLineKind.pending => Icons.cloud_upload_outlined,
    SyncLineKind.uploading => Icons.cloud_upload_outlined,
    SyncLineKind.error => Icons.error_outline,
  };
}

/// Small sheet for a change the server refused: what was not shared, and "OK"
/// to forget it. Dismissing without "OK" keeps the line.
Future<void> showRejectedChangeSheet(
  BuildContext context, {
  required String text,
  required Future<void> Function() onOk,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => RejectedChangeSheet(text: text, onOk: onOk),
);

/// The sheet's content (public for tests).
class RejectedChangeSheet extends StatelessWidget {
  const RejectedChangeSheet({
    required this.text,
    required this.onOk,
    super.key,
  });

  final String text;
  final Future<void> Function() onOk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: Spacing.screen.copyWith(top: Spacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.syncRejectedSheetTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Text(text, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Spacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await onOk();
                  navigator.pop();
                },
                child: Text(l10n.syncRejectedOk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
