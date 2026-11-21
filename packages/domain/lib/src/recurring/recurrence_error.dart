// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// Why a recurrence rule could not be created.
sealed class RecurrenceError {
  const RecurrenceError();
}

/// The interval is below 1.
final class InvalidInterval extends RecurrenceError {
  /// Creates the error for the offending [interval].
  const InvalidInterval(this.interval);

  final int interval;

  @override
  bool operator ==(Object other) =>
      other is InvalidInterval && other.interval == interval;

  @override
  int get hashCode => Object.hash(InvalidInterval, interval);

  @override
  String toString() => 'InvalidInterval($interval)';
}

/// The end date lies before the start date.
final class EndBeforeStart extends RecurrenceError {
  /// Creates the error.
  const EndBeforeStart();

  @override
  bool operator ==(Object other) => other is EndBeforeStart;

  @override
  int get hashCode => (EndBeforeStart).hashCode;

  @override
  String toString() => 'EndBeforeStart()';
}
