import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';

/// A calm inline card that offers a setup where its data is needed (ADR-25
/// §5): one sentence of why, one obvious action, and a quiet way to never
/// see it again. Not a dialog, never blocks anything.
class InlineSetupCard extends StatelessWidget {
  const InlineSetupCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.dismissLabel,
    required this.onDismiss,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  /// Tooltip and semantics of the close button ("Nicht mehr anzeigen").
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Padding(
        padding: Spacing.allMd,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: dismissLabel,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
