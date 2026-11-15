import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

enum _Answer { mark, keep, manage }

/// Asks once whether somebody who only ever rides along is a driver at all.
/// Any way out (a button or dismissing the sheet) counts as an answer, so it
/// never comes back. Marking as non-driver offers undo.
Future<void> showDriverPromptSheet(
  BuildContext context, {
  required String groupId,
  required RidesViewModel vm,
  required DriverPrompt prompt,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final answer = await showModalBottomSheet<_Answer>(
    context: context,
    showDragHandle: true,
    builder: (_) => DriverPromptSheet(name: name, rides: prompt.rides),
  );
  final result = await vm.answerDriverPrompt(
    prompt.memberId,
    canDrive: answer != _Answer.mark,
  );
  if (!context.mounted) return;
  switch (result) {
    case Ok(:final value?):
      showUndoSnackBar(
        context,
        message: l10n.ridesDriverNotSuggested(name),
        undo: value,
      );
    case Ok():
      if (answer == _Answer.manage) {
        unawaited(router.push('/groups/$groupId/rides/settings'));
      }
    case Err(:final error):
      showErrorSnackBar(messenger, l10n, error);
  }
}

/// The sheet's content (public for the accessibility tests).
class DriverPromptSheet extends StatelessWidget {
  const DriverPromptSheet({required this.name, required this.rides, super.key});

  final String name;
  final int rides;

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
              l10n.ridesDriverPromptTitle(name),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.ridesDriverPromptBody(name, rides),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_Answer.mark),
              child: Text(l10n.ridesDriverPromptMark),
            ),
            const SizedBox(height: Spacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(_Answer.keep),
              child: Text(l10n.ridesDriverPromptKeep(name)),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(_Answer.manage),
                child: Text(l10n.ridesDriverPromptManage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
