// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// An ECB reference rate the expense form offers as the exchange rate
/// (contract: docs/fx-rates-api.md).
class FxSuggestion {
  const FxSuggestion({
    required this.ppm,
    required this.date,
    this.attribution = '',
  });

  /// Group currency per 1 foreign unit, times 1e6: what the expense freezes.
  final int ppm;

  /// The ECB working day the rate is from (midnight UTC); earlier than the
  /// expense day on weekends and holidays.
  final DateTime date;

  /// "Quelle: EZB-Referenzkurse via Frankfurter".
  final String attribution;

  @override
  bool operator ==(Object other) =>
      other is FxSuggestion && other.ppm == ppm && other.date == date;

  @override
  int get hashCode => Object.hash(ppm, date);
}
