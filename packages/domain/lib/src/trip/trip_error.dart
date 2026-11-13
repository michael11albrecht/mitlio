// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// Why a trip cost could not be computed.
sealed class TripError {
  const TripError();
}

/// The distance is zero or negative.
final class NonPositiveDistance extends TripError {
  /// Creates the error.
  const NonPositiveDistance();

  @override
  bool operator ==(Object other) => other is NonPositiveDistance;

  @override
  int get hashCode => (NonPositiveDistance).hashCode;

  @override
  String toString() => 'NonPositiveDistance()';
}

/// A numeric input named [field] is negative.
final class TripNegativeValue extends TripError {
  /// Creates the error for [field].
  const TripNegativeValue(this.field);

  /// Name of the offending input field.
  final String field;

  @override
  bool operator ==(Object other) =>
      other is TripNegativeValue && other.field == field;

  @override
  int get hashCode => Object.hash(TripNegativeValue, field);

  @override
  String toString() => 'TripNegativeValue($field)';
}

/// Nobody takes part in the cost split.
final class TripNoParticipants extends TripError {
  /// Creates the error.
  const TripNoParticipants();

  @override
  bool operator ==(Object other) => other is TripNoParticipants;

  @override
  int get hashCode => (TripNoParticipants).hashCode;

  @override
  String toString() => 'TripNoParticipants()';
}

/// The driver is also listed as a passenger.
final class DriverIsPassenger extends TripError {
  /// Creates the error.
  const DriverIsPassenger();

  @override
  bool operator ==(Object other) => other is DriverIsPassenger;

  @override
  int get hashCode => (DriverIsPassenger).hashCode;

  @override
  String toString() => 'DriverIsPassenger()';
}

/// The driver or a passenger is not in the member list.
final class TripUnknownMember extends TripError {
  /// Creates the error for member [id].
  const TripUnknownMember(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      other is TripUnknownMember && other.id == id;

  @override
  int get hashCode => Object.hash(TripUnknownMember, id);

  @override
  String toString() => 'TripUnknownMember($id)';
}

/// The currency has more than three minor-unit digits.
final class UnsupportedCurrency extends TripError {
  /// Creates the error.
  const UnsupportedCurrency();

  @override
  bool operator ==(Object other) => other is UnsupportedCurrency;

  @override
  int get hashCode => (UnsupportedCurrency).hashCode;

  @override
  String toString() => 'UnsupportedCurrency()';
}
