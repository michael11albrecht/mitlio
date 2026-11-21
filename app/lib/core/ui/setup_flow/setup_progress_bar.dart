import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Segmented progress of a setup flow: one segment per step, filled up to
/// [current] (1-based), with "Schritt 2 von 5" under it. Screen readers get
/// only the text.
class SetupProgressBar extends StatelessWidget {
  const SetupProgressBar({
    required this.current,
    required this.total,
    super.key,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Container(
                    height: Sizes.barHeight,
                    decoration: BoxDecoration(
                      color: i <= current
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: Radii.smAll,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          AppLocalizations.of(context).setupStepProgress(current, total),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
