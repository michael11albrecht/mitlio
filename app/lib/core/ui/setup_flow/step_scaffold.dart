import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/setup_progress_bar.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// The frame of one setup step (ADR-25 §4): progress, a [visual] that
/// explains the step, the [title] question, at most two inputs in [child],
/// the live [result] (read aloud when it changes), the primary "Weiter" and
/// an optional "Überspringen". Back is always there when [onBack] is set.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    required this.current,
    required this.total,
    required this.title,
    this.visual,
    this.child,
    this.result,
    this.onNext,
    this.onSkip,
    this.onBack,
    super.key,
  });

  /// 1-based number of this step.
  final int current;
  final int total;
  final String title;
  final Widget? visual;

  /// The inputs, at most two related values.
  final Widget? child;

  /// What the answer amounts to right now ("≈ 7,4 ct/km"), result first.
  final Widget? result;

  /// "Weiter". Without it the step has no primary button (yes/no cards
  /// answer by tapping).
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Sizes.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: Spacing.screen,
                child: Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: l10n.setupBack,
                        onPressed: onBack,
                      ),
                    Expanded(
                      child: SetupProgressBar(current: current, total: total),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: Spacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (visual != null) ...[
                        ExcludeSemantics(child: Center(child: visual)),
                        const SizedBox(height: Spacing.lg),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (child != null) ...[
                        const SizedBox(height: Spacing.lg),
                        child!,
                      ],
                      if (result != null) ...[
                        const SizedBox(height: Spacing.lg),
                        Semantics(liveRegion: true, child: result),
                      ],
                    ],
                  ),
                ),
              ),
              if (onNext != null || onSkip != null)
                Padding(
                  padding: Spacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (onNext != null)
                        FilledButton(
                          onPressed: onNext,
                          child: Text(l10n.setupNext),
                        ),
                      if (onSkip != null)
                        TextButton(
                          onPressed: onSkip,
                          child: Text(l10n.setupSkip),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
