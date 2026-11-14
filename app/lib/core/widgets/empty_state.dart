import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';

/// Calm placeholder for "nothing here yet": icon, short title, optional
/// explanation and one optional action (the single obvious next step).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Usually a `FilledButton`; its label is the caller's localised copy.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: Spacing.allXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: Sizes.stateIcon,
                height: Sizes.stateIcon,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: Spacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
