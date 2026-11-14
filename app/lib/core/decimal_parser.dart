/// Parses a user-typed plain decimal such as `250`, `6,5`, `1.799` or `,5`
/// (comma or dot as the decimal separator, spaces ignored) into a number for
/// `scaleDecimal`.
///
/// This is not for money: amounts go through `parseAmountCents`, which never
/// creates a `double`. Rates and distances are converted to integer domain
/// units right away at the boundary. A lone separator is always the decimal
/// one. Returns `null` for blank input, grouping (two separators), signs,
/// letters or more than nine digits in total.
num? parseDecimal(String input) {
  final text = input.replaceAll(RegExp(r'[\s  ]'), '');
  if (!RegExp(r'^(?:\d+[.,]?\d*|[.,]\d+)$').hasMatch(text)) return null;
  if (text.replaceAll(RegExp('[.,]'), '').length > 9) return null;
  return double.parse(text.replaceAll(',', '.'));
}

/// Parses a typed exchange rate (`0,92`, `1.0834`, `160`) into parts per
/// million, the unit the domain freezes on an expense (`FxRate.ppm`).
///
/// Works on the digits, never through a `double`. More than six decimals
/// are rounded half-even to the ppm (`0,9200005` becomes 920000, `0,9200015`
/// becomes 920002). Returns `null` for blank or malformed input, a rate that
/// rounds to zero, or more than nine whole digits.
int? parseRatePpm(String input) {
  final text = input.replaceAll(RegExp(r'[\s  ]'), '');
  final match = RegExp(r'^(\d*)[.,]?(\d*)$').firstMatch(text);
  if (match == null) return null;
  final whole = match.group(1)!.replaceFirst(RegExp('^0+'), '');
  final fraction = match.group(2)!;
  if (whole.isEmpty && fraction.isEmpty) return null;
  if (whole.length > 9 || fraction.length > 12) return null;
  final padded = fraction.padRight(6, '0');
  var ppm =
      (whole.isEmpty ? 0 : int.parse(whole)) * 1000000 +
      int.parse(padded.substring(0, 6));
  final rest = padded.substring(6);
  if (rest.isNotEmpty) {
    final first = int.parse(rest[0]);
    final beyond = rest.substring(1).contains(RegExp('[1-9]'));
    if (first > 5 || (first == 5 && (beyond || ppm.isOdd))) ppm += 1;
  }
  return ppm > 0 ? ppm : null;
}
