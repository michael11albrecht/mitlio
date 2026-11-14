import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Result first": the answer as one big figure under a short caption
/// ("Jede Person zahlt" / `12,40 €`), optional detail line below.
/// Read by screen readers as one sentence.
class ResultCard extends StatelessWidget {
  const ResultCard({
    required this.caption,
    required this.cents,
    required this.currency,
    this.detail,
    super.key,
  });

  final String caption;
  final int cents;
  final Currency currency;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: Spacing.allLg,
        child: SizedBox(
          width: double.infinity,
          child: MergeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                // Huge text scales: shrink the figure, never clip or wrap it.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: MoneyText(
                    cents: cents,
                    currency: currency,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(detail!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
