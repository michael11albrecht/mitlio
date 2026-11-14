// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// Why a hybrid logical clock operation failed.
sealed class HlcError {
  const HlcError();
}

/// A remote wall clock is too far ahead of local time to be adopted.
final class ClockDrift extends HlcError {
  /// Creates the error.
  const ClockDrift({required this.remoteWallMillis, required this.nowMillis});

  final int remoteWallMillis;
  final int nowMillis;

  @override
  bool operator ==(Object other) =>
      other is ClockDrift &&
      other.remoteWallMillis == remoteWallMillis &&
      other.nowMillis == nowMillis;

  @override
  int get hashCode => Object.hash(ClockDrift, remoteWallMillis, nowMillis);

  @override
  String toString() => 'ClockDrift(remote: $remoteWallMillis, now: $nowMillis)';
}

/// The logical counter would exceed 9999 within one millisecond.
final class CounterOverflow extends HlcError {
  /// Creates the error.
  const CounterOverflow();

  @override
  bool operator ==(Object other) => other is CounterOverflow;

  @override
  int get hashCode => (CounterOverflow).hashCode;

  @override
  String toString() => 'CounterOverflow()';
}

/// A string is not a valid serialized timestamp.
final class HlcInvalidFormat extends HlcError {
  /// Creates the error.
  const HlcInvalidFormat(this.input);

  final String input;

  @override
  bool operator ==(Object other) =>
      other is HlcInvalidFormat && other.input == input;

  @override
  int get hashCode => Object.hash(HlcInvalidFormat, input);

  @override
  String toString() => 'HlcInvalidFormat($input)';
}
