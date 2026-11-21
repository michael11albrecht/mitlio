import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

enum SetupFlowStatus {
  /// Reading the saved progress.
  loading,

  /// On a step or on the finish screen.
  ready,

  /// The saved progress could not be read; [SetupFlowViewModel.retry].
  failed,
}

/// Everything a setup screen shows: the step, the answers so far, progress.
final class SetupFlowState {
  const SetupFlowState({
    required this.config,
    this.status = SetupFlowStatus.loading,
    this.stepIndex = 0,
    this.answers = const {},
    this.skipped = const [],
    this.finished = false,
    this.error,
  });

  final SetupFlowConfig config;
  final SetupFlowStatus status;

  /// Index of the current step; the last step while [finished].
  final int stepIndex;
  final Map<String, Object?> answers;
  final List<String> skipped;

  /// The finish screen is showing.
  final bool finished;

  /// Why [status] is `failed`.
  final RepositoryError? error;

  bool _visible(int index, Map<String, Object?> from) =>
      config.steps[index].visibleWhen?.call(from) ?? true;

  /// Index of the nearest visible step before ([forward] false) or after
  /// [from], judged by [given] answers (default: the current ones); null if
  /// there is none.
  int? neighbour(
    int from, {
    required bool forward,
    Map<String, Object?>? given,
  }) {
    final step = forward ? 1 : -1;
    for (var i = from + step; i >= 0 && i < config.steps.length; i += step) {
      if (_visible(i, given ?? answers)) return i;
    }
    return null;
  }

  /// Number of visible steps, for "Schritt 2 von 5" (the finish screen is
  /// not one).
  int get total => [
    for (var i = 0; i < config.steps.length; i++)
      if (_visible(i, answers)) i,
  ].length;

  /// 1-based position of the current step among the visible ones.
  int get position => [
    for (var i = 0; i <= stepIndex && i < config.steps.length; i++)
      if (_visible(i, answers)) i,
  ].length;

  /// The current step; null while loading, failed or finished.
  SetupStepSpec? get step => status == SetupFlowStatus.ready && !finished
      ? config.steps[stepIndex]
      : null;

  Object? answerOf(String stepId) => answers[stepId];

  bool get canSkip => step?.skippable ?? false;

  /// Back is possible from the finish screen and from every step but the
  /// first.
  bool get canGoBack =>
      status == SetupFlowStatus.ready &&
      (finished || neighbour(stepIndex, forward: false) != null);

  SetupProgress get progress => SetupProgress(
    stepIndex: stepIndex,
    answers: answers,
    skipped: skipped,
    finished: finished,
  );

  SetupFlowState _copy({
    SetupFlowStatus? status,
    int? stepIndex,
    Map<String, Object?>? answers,
    List<String>? skipped,
    bool? finished,
    RepositoryError? error,
  }) => SetupFlowState(
    config: config,
    status: status ?? this.status,
    stepIndex: stepIndex ?? this.stepIndex,
    answers: answers ?? this.answers,
    skipped: skipped ?? this.skipped,
    finished: finished ?? this.finished,
    error: error,
  );
}

/// The step-flow engine behind every guided setup (PU-T05): steps, skip,
/// back, and autosave after every move so a restart resumes at the same
/// step. Screens hold no logic; they call these commands, as do the
/// `ext.mitlio.setup.*` DebugDrive handlers.
class SetupFlowViewModel extends Notifier<SetupFlowState> {
  SetupFlowViewModel(this.config);

  final SetupFlowConfig config;

  /// Completes when the saved progress is read (tests await it).
  Future<void> restoring = Future.value();

  bool _saving = false;

  @override
  SetupFlowState build() {
    restoring = _restore();
    return SetupFlowState(config: config);
  }

  Future<void> _restore() async {
    final result = await ref.read(setupStateRepositoryProvider).load(config.id);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(value: final saved?) => _fromSaved(saved),
      Ok() => state._copy(status: SetupFlowStatus.ready),
      // Unreadable data is not worth blocking the user: start over.
      Err(error: InvalidData()) => state._copy(status: SetupFlowStatus.ready),
      Err(:final error) => state._copy(
        status: SetupFlowStatus.failed,
        error: error,
      ),
    };
  }

  SetupFlowState _fromSaved(SetupProgress saved) {
    final ids = {for (final s in config.steps) s.id};
    return state._copy(
      status: SetupFlowStatus.ready,
      stepIndex: saved.stepIndex.clamp(0, config.steps.length - 1),
      answers: {
        for (final e in saved.answers.entries)
          if (ids.contains(e.key)) e.key: e.value,
      },
      skipped: [
        for (final id in saved.skipped)
          if (ids.contains(id)) id,
      ],
      finished: saved.finished,
    );
  }

  /// Reads the saved progress again after a failure.
  Future<void> retry() {
    state = state._copy(status: SetupFlowStatus.loading);
    return restoring = _restore();
  }

  /// Remembers the answer of the current step in memory (live result,
  /// selected card). It is saved with [next]. No-op off a step.
  void answer(Object? value) {
    final step = state.step;
    if (step == null) return;
    state = state._copy(
      answers: {...state.answers, step.id: value}
        ..removeWhere((_, v) => v == null),
      skipped: [
        for (final id in state.skipped)
          if (id != step.id) id,
      ],
    );
  }

  /// "Weiter": checks the answer of the current step (given here or set with
  /// [answer]), saves, and moves on, to the finish screen after the last
  /// step. On an error nothing moves and nothing is lost.
  Future<RepoResult<void>> next({Object? answer}) async {
    final step = state.step;
    if (step == null) return const Err(Conflict('no step to continue from'));
    // A committing step keeps its raw answer out of the state: `back` would
    // save it with the progress.
    final commit = step.commit;
    if (answer != null && commit == null) this.answer(answer);
    final value = commit == null
        ? state.answerOf(step.id)
        : answer ?? state.answerOf(step.id);
    if (value == null && !step.skippable) {
      return Err(InvalidData('step ${step.id} needs an answer'));
    }
    final problem = value == null ? null : step.validate?.call(value);
    if (problem != null) return Err(InvalidData('step ${step.id}: $problem'));
    if (commit == null || value == null) return _moveTo(state);
    final stored = await commit(ref, value);
    if (!ref.mounted) return const Err(Conflict('flow closed'));
    return switch (stored) {
      Err(:final error) => Err(error),
      Ok(value: final kept) => _moveTo(
        state._copy(
          answers: {...state.answers, step.id: kept},
          skipped: [
            for (final id in state.skipped)
              if (id != step.id) id,
          ],
        ),
      ),
    };
  }

  /// "Überspringen": forgets the answer of the current optional step, saves,
  /// and moves on.
  Future<RepoResult<void>> skip() async {
    final step = state.step;
    if (step == null) return const Err(Conflict('no step to skip'));
    if (!step.skippable) {
      return Err(InvalidData('step ${step.id} cannot be skipped'));
    }
    return _moveTo(
      state._copy(
        answers: {...state.answers}..remove(step.id),
        skipped: [...state.skipped.where((id) => id != step.id), step.id],
      ),
    );
  }

  /// Back one step, or from the finish screen to the last step. Answers stay.
  Future<RepoResult<void>> back() async {
    if (!state.canGoBack) return const Err(Conflict('already at the start'));
    final goal = state.finished
        ? state._copy(finished: false)
        : state._copy(
            stepIndex: state.neighbour(state.stepIndex, forward: false),
          );
    return _save(goal);
  }

  /// Saves [from] advanced by one step (or finished after the last).
  Future<RepoResult<void>> _moveTo(SetupFlowState from) {
    final following = from.neighbour(from.stepIndex, forward: true);
    return _save(
      following == null
          ? from._copy(finished: true)
          : from._copy(stepIndex: following),
    );
  }

  Future<RepoResult<void>> _save(SetupFlowState goal) async {
    if (_saving) return const Err(Conflict('already saving'));
    _saving = true;
    try {
      final result = await ref
          .read(setupStateRepositoryProvider)
          .save(config.id, goal.progress);
      if (result is Ok && ref.mounted) state = goal;
      return result;
    } finally {
      _saving = false;
    }
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final setupFlowViewModelProvider =
    NotifierProvider.family<
      SetupFlowViewModel,
      SetupFlowState,
      SetupFlowConfig
    >(SetupFlowViewModel.new);

/// The flows DebugDrive can drive, by id. Features add theirs (profile,
/// car, ...) by overriding this provider's value in their wiring.
final setupFlowConfigsProvider = Provider<Map<String, SetupFlowConfig>>(
  (ref) => const {},
);
