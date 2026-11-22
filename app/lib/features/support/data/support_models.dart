// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// The three tip sizes of the tip jar (ADR-28). The price is the store's:
/// the app never formats or converts a tip amount itself.
enum TipSize {
  small,
  medium,
  large;

  /// Product id of the consumable in App Store Connect and Play Console.
  String get productId => 'tip_$name';
}

/// A tip size the store offers, with the price as the store formats it.
class TipProduct {
  const TipProduct({required this.size, required this.price});

  final TipSize size;
  final String price;

  @override
  bool operator ==(Object other) =>
      other is TipProduct && other.size == size && other.price == price;

  @override
  int get hashCode => Object.hash(TipProduct, size, price);

  @override
  String toString() => 'TipProduct($size, $price)';
}

/// Why the tip jar could not load or finish a purchase.
enum TipFailure {
  /// The store cannot be reached (offline, no store on this device).
  storeUnavailable,

  /// The store answered but does not list the tip products (yet).
  productsUnavailable,

  /// The purchase did not go through.
  purchaseFailed,
}

/// How a tip purchase ended.
sealed class TipOutcome {
  const TipOutcome();
}

/// The store confirmed the purchase.
final class TipThanks extends TipOutcome {
  const TipThanks();
}

/// The user backed out. Not an error: nothing to tell them.
final class TipCancelled extends TipOutcome {
  const TipCancelled();
}

final class TipFailed extends TipOutcome {
  const TipFailed(this.failure);

  final TipFailure failure;

  @override
  bool operator ==(Object other) =>
      other is TipFailed && other.failure == failure;

  @override
  int get hashCode => Object.hash(TipFailed, failure);

  @override
  String toString() => 'TipFailed($failure)';
}

/// At most one success-screen line per this many settlements ...
const supportPromptEverySettlements = 5;

/// ... and never twice within this time (ADR-28 §2).
const supportPromptMinGap = Duration(days: 30);

/// What the app remembers about the success-screen line. Local only, never
/// synced, never analysed (ADR-28 §4).
class SupportPromptState {
  const SupportPromptState({
    this.settledSinceShown = 0,
    this.lastShown,
    this.dismissed = false,
  });

  /// Settled screens reached since the line was last shown.
  final int settledSinceShown;
  final DateTime? lastShown;

  /// "Nicht mehr zeigen": permanent.
  final bool dismissed;

  SupportPromptState copyWith({
    int? settledSinceShown,
    DateTime? lastShown,
    bool? dismissed,
  }) => SupportPromptState(
    settledSinceShown: settledSinceShown ?? this.settledSinceShown,
    lastShown: lastShown ?? this.lastShown,
    dismissed: dismissed ?? this.dismissed,
  );

  @override
  bool operator ==(Object other) =>
      other is SupportPromptState &&
      other.settledSinceShown == settledSinceShown &&
      other.lastShown == lastShown &&
      other.dismissed == dismissed;

  @override
  int get hashCode =>
      Object.hash(SupportPromptState, settledSinceShown, lastShown, dismissed);

  @override
  String toString() =>
      'SupportPromptState($settledSinceShown, $lastShown, $dismissed)';
}
