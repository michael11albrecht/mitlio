import 'package:flutter/widgets.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/expenses/ui/fx_suggestion_line.dart';
import 'package:mitlio/features/fx/data/fx_suggestion.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'golden_matrix.dart';

/// The ECB rate line under the rate field (P7-T02): once with the "Übernehmen"
/// button (the field holds another rate), once without (already applied).
Widget _host({required bool applied}) => Padding(
  padding: Spacing.screen,
  child: FxSuggestionLine(
    suggestion: FxSuggestion(ppm: 920000, date: DateTime.utc(2026, 11, 13)),
    from: Currency.usd,
    to: Currency.eur,
    applied: applied,
    onUse: () {},
  ),
);

Future<void> main() async {
  await matrixGolden(
    'fx_suggestion_applied',
    () => _host(applied: true),
    width: 360,
    height: 120,
  );
  await matrixGolden(
    'fx_suggestion_offer',
    () => _host(applied: false),
    width: 360,
    height: 120,
  );
}
