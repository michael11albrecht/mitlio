import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What a step builder gets for the current step: where it is, the answer so
/// far, and the commands wired to the ViewModel (failures already shown).
final class SetupStepContext {
  const SetupStepContext({
    required this.step,
    required this.current,
    required this.total,
    required this.answer,
    required this.onAnswer,
    required this.onNext,
    required this.onBack,
    this.onSkip,
  });

  final SetupStepSpec step;

  /// 1-based number for "Schritt 2 von 5".
  final int current;
  final int total;
  final Object? answer;

  /// Keeps the answer for the live result; saved on [onNext].
  final ValueChanged<Object?> onAnswer;

  /// "Weiter", optionally with the answer (a yes/no card answers and moves
  /// on in one tap).
  final void Function([Object? answer]) onNext;

  /// Null on a step that cannot be skipped.
  final VoidCallback? onSkip;

  /// Null on the first step.
  final VoidCallback? onBack;
}

/// Hosts a [SetupFlowConfig]: restores the saved progress, shows the step
/// [stepBuilder] draws (usually a `StepScaffold` or `YesNoStep`) or the
/// [finishBuilder] screen, shows failures in plain words, and lets the
/// system back gesture go one step back. Logic stays in the ViewModel.
class SetupFlowView extends ConsumerWidget {
  const SetupFlowView({
    required this.config,
    required this.stepBuilder,
    required this.finishBuilder,
    super.key,
  });

  final SetupFlowConfig config;
  final Widget Function(BuildContext context, SetupStepContext step)
  stepBuilder;

  /// The finish screen (usually a `FinishStep`); gets "back to the last step".
  final Widget Function(BuildContext context, VoidCallback onBack)
  finishBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupFlowViewModelProvider(config));
    final vm = ref.read(setupFlowViewModelProvider(config).notifier);
    final l10n = AppLocalizations.of(context);

    void show(RepoResult<void> result) {
      if (result case Err(:final error) when context.mounted) {
        showErrorSnackBar(ScaffoldMessenger.of(context), l10n, error);
      }
    }

    void run(Future<RepoResult<void>> Function() command) =>
        unawaited(command().then(show));

    final step = state.step;
    final body = switch (state.status) {
      SetupFlowStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      SetupFlowStatus.failed => ErrorState(
        onRetry: () => unawaited(vm.retry()),
        message: state.error == null
            ? null
            : repositoryErrorMessage(l10n, state.error!),
      ),
      SetupFlowStatus.ready when step == null => finishBuilder(
        context,
        () => run(vm.back),
      ),
      // Keyed by step: input state (text fields) never leaks to the next step.
      SetupFlowStatus.ready => KeyedSubtree(
        key: ValueKey(step!.id),
        child: stepBuilder(
          context,
          SetupStepContext(
            step: step,
            current: state.stepIndex + 1,
            total: state.total,
            answer: state.answerOf(step.id),
            onAnswer: vm.answer,
            onNext: ([answer]) => run(() => vm.next(answer: answer)),
            onSkip: state.canSkip ? () => run(vm.skip) : null,
            onBack: state.canGoBack ? () => run(vm.back) : null,
          ),
        ),
      ),
    };
    return PopScope(
      canPop: !state.canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) run(vm.back);
      },
      child: Scaffold(body: body),
    );
  }
}
