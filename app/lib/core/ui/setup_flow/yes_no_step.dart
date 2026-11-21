import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// A yes/no question as two big cards: one tap answers and moves on (no
/// "Weiter"). [selected] marks the earlier answer when the user comes back.
class YesNoStep extends StatelessWidget {
  const YesNoStep({
    required this.current,
    required this.total,
    required this.title,
    required this.onAnswer,
    this.selected,
    this.visual,
    this.result,
    this.onSkip,
    this.onBack,
    super.key,
  });

  final int current;
  final int total;
  final String title;
  final ValueChanged<bool> onAnswer;
  final bool? selected;
  final Widget? visual;
  final Widget? result;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StepScaffold(
      current: current,
      total: total,
      title: title,
      visual: visual,
      result: result,
      onSkip: onSkip,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceCard(
            label: l10n.setupYes,
            selected: selected ?? false,
            onTap: () => onAnswer(true),
          ),
          const SizedBox(height: Spacing.sm),
          _ChoiceCard(
            label: l10n.setupNo,
            selected: selected == false,
            onTap: () => onAnswer(false),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: Card(
          color: selected ? scheme.primaryContainer : null,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sizes.choiceCard),
              child: Padding(
                padding: Spacing.allMd,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected ? scheme.onPrimaryContainer : null,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check, color: scheme.onPrimaryContainer),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
