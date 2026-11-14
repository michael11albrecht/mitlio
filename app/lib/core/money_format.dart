import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Formats integer minor units ("cents") per locale: `12,34 €` (de),
/// `€12.34` (en).
///
/// Integer in, string out: whole and fractional parts are split with integer
/// arithmetic, so no amount ever passes through a `double`. `intl` only
/// supplies the locale's separators, grouping, currency symbol and pattern.
class MoneyFormat {
  /// Creates a formatter for [locale] (e.g. `de`, `en`, `de_AT`). Unknown
  /// locales fall back to `en`.
  MoneyFormat(String locale) : this._(_canonical(locale));

  MoneyFormat._(this.locale) : _whole = NumberFormat.decimalPattern(locale);

  /// Formatter for the ambient locale of [context].
  factory MoneyFormat.of(BuildContext context) =>
      MoneyFormat(Localizations.localeOf(context).toString());

  static String _canonical(String locale) =>
      Intl.verifiedLocale(
        locale,
        NumberFormat.localeExists,
        onFailure: (_) => 'en',
      ) ??
      'en';

  /// Canonical locale actually used.
  final String locale;

  final NumberFormat _whole;

  NumberSymbols get _symbols => numberFormatSymbols[locale]!;

  /// Locale decimal separator (`,` for de, `.` for en).
  String get decimalSeparator => _symbols.DECIMAL_SEP;

  /// Formats [cents] of [currency]; negatives get a leading `-`.
  String format(int cents, Currency currency) {
    final parts = split(cents, currency);
    final whole = _whole.format(parts.whole);
    final number = parts.fraction == null
        ? whole
        : '$whole$decimalSeparator${parts.fraction}';

    final symbol = currencySymbol(currency);
    final pattern = _symbols.CURRENCY_PATTERN.split(';').first;
    final start = pattern.indexOf(RegExp('[#0]'));
    final end = pattern.lastIndexOf(RegExp('[#0]')) + 1;
    final prefix = pattern.substring(0, start).replaceAll('¤', symbol);
    final suffix = pattern.substring(end).replaceAll('¤', symbol);
    return '${parts.negative ? '-' : ''}$prefix$number$suffix';
  }

  /// Plain number for editing: no grouping, no symbol (`12,34` in de).
  String formatPlain(int cents, Currency currency) {
    final parts = split(cents, currency);
    final fraction = parts.fraction;
    return '${parts.negative ? '-' : ''}${parts.whole}'
        '${fraction == null ? '' : '$decimalSeparator$fraction'}';
  }

  /// Locale currency symbol (`€`, `$`, `CHF`).
  String currencySymbol(Currency currency) => NumberFormat.simpleCurrency(
    locale: locale,
    name: currency.code,
  ).currencySymbol;

  /// Splits [cents] into sign, whole units and zero-padded fraction digits
  /// (`null` for zero-decimal currencies) using integer arithmetic only.
  static ({bool negative, int whole, String? fraction}) split(
    int cents,
    Currency currency,
  ) {
    final places = currency.minorUnits;
    final negative = cents < 0;
    final abs = negative ? -cents : cents;
    final unit = _pow10(places);
    return (
      negative: negative,
      whole: abs ~/ unit,
      fraction: places == 0
          ? null
          : (abs % unit).toString().padLeft(places, '0'),
    );
  }

  /// Formats a domain [Money].
  String formatMoney(Money money) => format(money.cents, money.currency);

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
