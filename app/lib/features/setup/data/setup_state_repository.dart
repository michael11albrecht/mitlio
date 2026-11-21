import 'dart:convert';

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Where a guided setup flow stands (ADR-25 §4): the step the user is on,
/// what they answered, which optional steps they skipped, and whether they
/// reached the finish screen. Stored locally after every "Weiter", so leaving
/// the app (or a process kill) and coming back resumes at the same step.
final class SetupProgress {
  const SetupProgress({
    this.stepIndex = 0,
    this.answers = const {},
    this.skipped = const [],
    this.finished = false,
  });

  /// Reads what [toJson] wrote. Unreadable or foreign data is [InvalidData]
  /// (the flow then starts from the first step instead of crashing).
  static RepoResult<SetupProgress> fromJson(String json) {
    try {
      final map = jsonDecode(json);
      if (map is! Map<String, dynamic>) {
        return const Err(InvalidData('setup progress is not an object'));
      }
      final index = map['stepIndex'];
      final answers = map['answers'];
      final skipped = map['skipped'];
      final finished = map['finished'];
      if (index is! int ||
          index < 0 ||
          answers is! Map<String, dynamic> ||
          skipped is! List<dynamic> ||
          skipped.any((s) => s is! String) ||
          finished is! bool) {
        return const Err(InvalidData('setup progress has the wrong shape'));
      }
      return Ok(
        SetupProgress(
          stepIndex: index,
          answers: Map.unmodifiable(answers),
          skipped: List.unmodifiable(skipped.cast<String>()),
          finished: finished,
        ),
      );
    } on FormatException catch (e) {
      return Err(InvalidData('setup progress is not JSON: ${e.message}'));
    }
  }

  /// Index into the flow's steps (the finish screen is not a step).
  final int stepIndex;

  /// Answer per step id: JSON values only (bool, int, double, String).
  final Map<String, Object?> answers;

  /// Ids of optional steps the user skipped.
  final List<String> skipped;
  final bool finished;

  String toJson() => jsonEncode({
    'stepIndex': stepIndex,
    'answers': answers,
    'skipped': skipped,
    'finished': finished,
  });
}

/// Local store of [SetupProgress] per flow id. Repositories return errors,
/// never throw.
abstract interface class SetupStateRepository {
  /// Null when the flow was never started on this device.
  Future<RepoResult<SetupProgress?>> load(String flowId);

  Future<RepoResult<void>> save(String flowId, SetupProgress progress);
}
