import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The ECB rate offered under the rate field: "1 USD = 0,9200 € · EZB,
/// 13.11." with a "Übernehmen" button while the field holds another rate.
class FxSuggestionLine extends StatelessWidget {
  const FxSuggestionLine({
    required this.suggestion,
    required this.from,
    required this.to,
    required this.applied,
    required this.onUse,
    super.key,
  });

  final FxSuggestion suggestion;

  /// The foreign currency (`1 USD`).
  final Currency from;

  /// The group currency (the symbol after the number).
  final Currency to;

  /// The rate field already holds this rate: no button.
  final bool applied;
  final VoidCallback onUse;

  /// Four decimals, rounded half up from ppm without going through a double.
  static String _rate(int ppm, String separator) {
    final tenThousandths = (ppm + 50) ~/ 100;
    final fraction = (tenThousandths % 10000).toString().padLeft(4, '0');
    return '${tenThousandths ~/ 10000}$separator$fraction';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat.of(context);
    final locale = Localizations.localeOf(context).toString();
    final text = l10n.expenseRateSuggestion(
      from.code,
      _rate(suggestion.ppm, money.decimalSeparator),
      money.currencySymbol(to),
      DateFormat.Md(locale).format(suggestion.date),
    );
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Spacing.sm,
        children: [
          Text(text, style: Theme.of(context).textTheme.bodySmall),
          if (!applied)
            TextButton(onPressed: onUse, child: Text(l10n.expenseRateUse)),
        ],
      ),
    );
  }
}
