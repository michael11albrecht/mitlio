import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/amount_field.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/core/widgets/result_card.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'golden_matrix.dart';

const _members = [
  ('m-anna', 'Anna Berg'),
  ('m-ben', 'Ben'),
  ('m-chiara', 'Chiara Rossi'),
  ('m-dino', 'Dino Kovač'),
  ('m-eva', 'Eva Lindqvist'),
  ('m-felix', 'Felix Wagner'),
  ('m-greta', 'Greta Holm'),
  ('m-hans', 'Hans Meier'),
];

Widget _resultCard() => const Align(
  alignment: Alignment.topCenter,
  child: Padding(
    padding: Spacing.screen,
    child: ResultCard(
      caption: 'Jede Person zahlt',
      cents: 1240,
      currency: Currency.eur,
      detail: '3 Personen, 42 km',
    ),
  ),
);

Widget _moneyText() => const Padding(
  padding: Spacing.screen,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MoneyText(cents: 1240, currency: Currency.eur),
      MoneyText(cents: 123456789, currency: Currency.eur),
      MoneyText(cents: -2340, currency: Currency.eur),
      MoneyText(cents: 5, currency: Currency.usd),
    ],
  ),
);

Widget _avatars() => Padding(
  padding: Spacing.screen,
  child: Wrap(
    spacing: Spacing.sm,
    runSpacing: Spacing.sm,
    children: [
      for (final (id, name) in _members) MemberAvatar(memberId: id, name: name),
    ],
  ),
);

Widget _amountField() => Padding(
  padding: Spacing.screen,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AmountField(
        currency: Currency.eur,
        label: 'Betrag',
        cents: 1234,
        onChanged: (_) {},
      ),
      const SizedBox(height: Spacing.md),
      AmountField(currency: Currency.eur, label: 'Betrag', onChanged: (_) {}),
    ],
  ),
);

Widget _emptyState() => EmptyState(
  icon: Icons.directions_car_outlined,
  title: 'Noch keine Fahrten',
  message: 'Trag deine erste Fahrt ein, den Rest rechnen wir.',
  action: FilledButton(onPressed: () {}, child: const Text('Fahrt eintragen')),
);

Widget _errorState() => ErrorState(onRetry: () {});

Widget _gallery() => ListView(
  padding: Spacing.screen,
  children: [
    const ResultCard(
      caption: 'Jede Person zahlt',
      cents: 1240,
      currency: Currency.eur,
      detail: '3 Personen, 42 km',
    ),
    const SizedBox(height: Spacing.md),
    AmountField(
      currency: Currency.eur,
      label: 'Betrag',
      cents: 1234,
      onChanged: (_) {},
    ),
    const SizedBox(height: Spacing.md),
    Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final (id, name) in _members.take(4))
          MemberAvatar(memberId: id, name: name),
      ],
    ),
    const SizedBox(height: Spacing.md),
    const MoneyText(cents: 2340, currency: Currency.eur),
    const SizedBox(height: Spacing.md),
    SizedBox(height: 320, child: _emptyState()),
    SizedBox(height: 320, child: _errorState()),
  ],
);

Future<void> main() async {
  await matrixGolden('money_text', _moneyText, height: 220);
  await matrixGolden('member_avatar', _avatars, height: 220);
  await matrixGolden('amount_field', _amountField, height: 300);
  await matrixGolden('empty_state', _emptyState, height: 640);
  await matrixGolden('error_state', _errorState, height: 640);
  await matrixGolden('result_card', _resultCard, height: 560);
  await matrixGolden('gallery', _gallery, width: 360, height: 1800);
}
