// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/mitlio_domain.dart';

/// Why a repository command failed. Repositories return these, never throw.
sealed class RepositoryError {
  const RepositoryError();
}

/// The entity does not exist (or is soft deleted).
final class NotFound extends RepositoryError {
  const NotFound(this.entity, this.id);

  final String entity;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is NotFound && other.entity == entity && other.id == id;

  @override
  int get hashCode => Object.hash(NotFound, entity, id);

  @override
  String toString() => 'NotFound($entity, $id)';
}

/// The command conflicts with the current state, e.g. restoring a live row.
final class Conflict extends RepositoryError {
  const Conflict(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is Conflict && other.message == message;

  @override
  int get hashCode => Object.hash(Conflict, message);

  @override
  String toString() => 'Conflict($message)';
}

/// The entity is locked and cannot be edited or deleted, e.g. a ride that a
/// period settlement already turned into an expense.
final class Locked extends RepositoryError {
  const Locked(this.entity, this.id);

  final String entity;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is Locked && other.entity == entity && other.id == id;

  @override
  int get hashCode => Object.hash(Locked, entity, id);

  @override
  String toString() => 'Locked($entity, $id)';
}

/// Input or stored data violates a domain or schema rule.
final class InvalidData extends RepositoryError {
  const InvalidData(this.details);

  final String details;

  @override
  bool operator ==(Object other) =>
      other is InvalidData && other.details == details;

  @override
  int get hashCode => Object.hash(InvalidData, details);

  @override
  String toString() => 'InvalidData($details)';
}

/// The storage layer failed unexpectedly.
final class Storage extends RepositoryError {
  const Storage(this.cause);

  final Object cause;

  @override
  bool operator ==(Object other) => other is Storage && other.cause == cause;

  @override
  int get hashCode => Object.hash(Storage, cause);

  @override
  String toString() => 'Storage($cause)';
}

typedef RepoResult<T> = Result<T, RepositoryError>;

extension RepoResultX<T> on RepoResult<T> {
  /// The value, or throws the [RepositoryError] (used to surface errors on
  /// streams, which have no result channel).
  T orThrow() => switch (this) {
    Ok<T, RepositoryError>(:final value) => value,
    Err<T, RepositoryError>(:final error) => throw error, // ignore: only_throw_errors, stream error channel carries RepositoryError
  };
}

/// Handle returned by soft deletes. Calling it restores the entity, so the UI
/// can offer "undo" instead of a confirm dialog (plan §2.6).
final class Undo {
  const Undo(this._restore);

  final Future<RepoResult<void>> Function() _restore;

  Future<RepoResult<void>> call() => _restore();
}

/// Runs [body] and converts any thrown storage failure into `Err(Storage)`.
Future<RepoResult<T>> guardStorage<T>(
  Future<RepoResult<T>> Function() body,
) async {
  try {
    return await body();
  } on Object catch (e) {
    return Err(Storage(e));
  }
}

/// Emits `snapshot()` on listen and after every [changes] event, skipping
/// emissions equal to the previous one (like Drift query streams). Used by
/// the in-memory fakes.
Stream<List<T>> watchSnapshots<T>(
  Stream<void> changes,
  List<T> Function() snapshot,
) => Stream.multi((controller) {
  List<T>? last;
  void emit() {
    final next = List<T>.unmodifiable(snapshot());
    final prev = last;
    if (prev != null &&
        prev.length == next.length &&
        Iterable<int>.generate(next.length).every((i) => prev[i] == next[i])) {
      return;
    }
    last = next;
    controller.add(next);
  }

  emit();
  final sub = changes.listen((_) => emit());
  controller.onCancel = sub.cancel;
});
