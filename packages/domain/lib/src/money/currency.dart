// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// An ISO 4217 currency with its number of minor-unit digits.
final class Currency {
  const Currency._(this.code, this.minorUnits);

  /// Upper-case ISO 4217 code.
  final String code;

  /// Decimal digits of the minor unit (EUR 2, JPY 0, KWD 3).
  final int minorUnits;

  static const eur = Currency._('EUR', 2);
  static const usd = Currency._('USD', 2);
  static const gbp = Currency._('GBP', 2);
  static const chf = Currency._('CHF', 2);
  static const jpy = Currency._('JPY', 0);
  static const sek = Currency._('SEK', 2);
  static const nok = Currency._('NOK', 2);
  static const dkk = Currency._('DKK', 2);
  static const pln = Currency._('PLN', 2);
  static const czk = Currency._('CZK', 2);
  static const huf = Currency._('HUF', 2);
  static const ron = Currency._('RON', 2);
  static const bgn = Currency._('BGN', 2);
  static const try_ = Currency._('TRY', 2);
  static const isk = Currency._('ISK', 0);
  static const kwd = Currency._('KWD', 3);
  static const cad = Currency._('CAD', 2);
  static const aud = Currency._('AUD', 2);
  static const nzd = Currency._('NZD', 2);

  /// All known currencies.
  static const List<Currency> all = [
    eur, usd, gbp, chf, jpy, sek, nok, dkk, pln, czk, //
    huf, ron, bgn, try_, isk, kwd, cad, aud, nzd,
  ];

  static final Map<String, Currency> _byCode = {
    for (final c in all) c.code: c,
  };

  /// Looks up a known currency by [code] (exact upper-case match).
  /// Returns null for unknown or non-canonical codes.
  static Currency? tryParse(String code) => _byCode[code];

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
