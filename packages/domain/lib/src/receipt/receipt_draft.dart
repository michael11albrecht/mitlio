// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/money/currency.dart';

/// Fields below this confidence (0..100) are reported empty, never guessed.
const receiptMinConfidence = 50;

/// What kind of purchase a receipt looks like (guessed from the merchant).
enum ReceiptCategory { groceries, fuel, restaurant, pharmacy, drugstore }

/// Axis-aligned box of one recognised text line, in any consistent unit
/// (the OCR service normalises to 0..1 of the page). Geometry only, never
/// money.
final class ReceiptBox {
  const ReceiptBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;

  double get centerY => (top + bottom) / 2;
}

/// One text line from the OCR service, optionally with its box.
final class ReceiptLine {
  const ReceiptLine(this.text, {this.box});

  final String text;
  final ReceiptBox? box;
}

/// A recognised value with a confidence of 0..100. An empty field has
/// `value == null` and `confidence == 0`.
final class ReceiptField<T extends Object> {
  const ReceiptField(this.value, this.confidence);

  const ReceiptField.empty() : value = null, confidence = 0;

  final T? value;
  final int confidence;

  bool get isEmpty => value == null;

  @override
  bool operator ==(Object other) =>
      other is ReceiptField<T> &&
      other.value == value &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(value, confidence);

  @override
  String toString() => 'ReceiptField($value, $confidence)';
}

/// The prefill for an expense, extracted from a receipt. Every field is empty
/// when it could not be found with at least [receiptMinConfidence].
final class ReceiptDraft {
  const ReceiptDraft({
    this.totalCents = const ReceiptField.empty(),
    this.merchant = const ReceiptField.empty(),
    this.date = const ReceiptField.empty(),
    this.currency = const ReceiptField.empty(),
    this.category = const ReceiptField.empty(),
  });

  /// Total in minor units (cents), always > 0 when present.
  final ReceiptField<int> totalCents;
  final ReceiptField<String> merchant;

  /// Calendar date as UTC midnight.
  final ReceiptField<DateTime> date;
  final ReceiptField<Currency> currency;
  final ReceiptField<ReceiptCategory> category;

  @override
  bool operator ==(Object other) =>
      other is ReceiptDraft &&
      other.totalCents == totalCents &&
      other.merchant == merchant &&
      other.date == date &&
      other.currency == currency &&
      other.category == category;

  @override
  int get hashCode =>
      Object.hash(totalCents, merchant, date, currency, category);

  @override
  String toString() =>
      'ReceiptDraft(total: $totalCents, merchant: $merchant, date: $date, '
      'currency: $currency, category: $category)';
}
