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
