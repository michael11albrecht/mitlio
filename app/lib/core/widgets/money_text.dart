import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// An amount in the ambient locale (`12,34 €` / `€12.34`) with tabular
/// figures. Screen readers get a spoken label ("12 Euro 34", "minus 5 Euro")
/// instead of the symbol-laden visual text.
class MoneyText extends StatelessWidget {
  const MoneyText({
    required this.cents,
    required this.currency,
    this.style,
    this.textAlign,
    super.key,
  });

  final int cents;
  final Currency currency;

  /// Merged over the ambient text style; tabular figures are always on.
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final text = MoneyFormat.of(context).format(cents, currency);
    return Semantics(
      label: spokenMoney(AppLocalizations.of(context), cents, currency),
      excludeSemantics: true,
      child: Text(
        text,
        style: MitlioTypography.tabular(style),
        textAlign: textAlign,
      ),
    );
  }
}

/// Screen-reader wording of an amount: `12 Euro 34`, `12 Euro`, `minus 3 Euro`.
String spokenMoney(AppLocalizations l10n, int cents, Currency currency) {
  final parts = MoneyFormat.split(cents, currency);
  final name = l10n.currencyName(currency.code);
  final fraction = parts.fraction;
  final spoken = fraction == null || int.parse(fraction) == 0
      ? l10n.moneySpoken(parts.whole, name)
      : l10n.moneySpokenWithFraction(parts.whole, name, fraction);
  return parts.negative ? l10n.moneySpokenNegative(spoken) : spoken;
}
