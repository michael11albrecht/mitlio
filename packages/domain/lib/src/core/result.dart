// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// Outcome of an operation that can fail with a user-reachable error.
sealed class Result<T, E> {
  const Result();
}

/// Successful result carrying [value].
final class Ok<T, E> extends Result<T, E> {
  /// Creates a successful result.
  const Ok(this.value);

  /// The success value.
  final T value;

  @override
  bool operator ==(Object other) => other is Ok && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Failed result carrying [error].
final class Err<T, E> extends Result<T, E> {
  /// Creates a failed result.
  const Err(this.error);

  /// The error value.
  final E error;

  @override
  bool operator ==(Object other) => other is Err && other.error == error;

  @override
  int get hashCode => Object.hash(Err, error);

  @override
  String toString() => 'Err($error)';
}
