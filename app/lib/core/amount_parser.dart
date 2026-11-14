import 'package:mitlio_domain/mitlio_domain.dart';

/// Parses user-typed amounts into integer minor units without ever creating
/// a `double`. Accepts `12`, `12,3`, `12.34`, `,5`, `12,` and grouped input
/// like `1.234,56` / `1,234.56` (the last separator is the decimal one when
/// two kinds are present, grouping must be 3-digit groups). Spaces (also
/// no-break) are ignored.
///
/// Returns `null` for blank input, more fraction digits than the currency
/// has, stray characters, signs, or amounts above [Money.maxAbsCents].
int? parseAmountCents(String input, Currency currency) {
  final text = input.replaceAll(RegExp(r'[\s\u00A0\u202F]'), '');
  if (text.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(text)) return null;

  final lastSep = text.lastIndexOf(RegExp('[.,]'));
  var whole = text;
  var fraction = '';
  if (lastSep >= 0) {
    final sep = text[lastSep];
    final head = text.substring(0, lastSep);
    final other = sep == ',' ? '.' : ',';
    // The other kind of separator before the last one is a grouping mark
    // and must be well-formed (`1.234`, not `1.23`). A lone separator is
    // always the decimal one: `1.234` is rejected for EUR rather than
    // guessed as 1234, because a silent 100x error costs real money.
    if (head.contains(sep)) return null;
    if (head.contains(other) &&
        !RegExp(r'^\d{1,3}(\' + other + r'\d{3})+$').hasMatch(head)) {
      return null;
    }
    whole = head.replaceAll(other, '');
    fraction = text.substring(lastSep + 1);
  }

  final places = currency.minorUnits;
  if (fraction.length > places) return null;
  if (whole.isEmpty && fraction.isEmpty) return null;

  // Digit strings only from here; int.parse keeps this exact. Cap the length
  // first (ignoring leading zeros) so parse can never overflow.
  whole = whole.replaceFirst(RegExp('^0+'), '');
  if (whole.length > 15) return null;
  final wholeValue = whole.isEmpty ? 0 : int.parse(whole);
  final fractionValue = fraction.isEmpty
      ? 0
      : int.parse(fraction.padRight(places, '0'));
  var unit = 1;
  for (var i = 0; i < places; i++) {
    unit *= 10;
  }
  if (wholeValue > Money.maxAbsCents ~/ unit) return null;
  final cents = wholeValue * unit + fractionValue;
  return cents > Money.maxAbsCents ? null : cents;
}
