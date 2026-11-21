import 'package:flutter/widgets.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/illustrations/illustrations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'golden_matrix.dart';

Widget _grid(List<Widget> children) => SingleChildScrollView(
  child: Padding(
    padding: Spacing.allMd,
    child: Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.md,
      children: children,
    ),
  ),
);

Future<void> main() async {
  await matrixGolden(
    'illustrations_profile',
    () => _grid([
      for (var i = 0; i < 4; i++)
        ProfileAvatarIllustration(semanticLabel: 'Profil', colorIndex: i * 2),
    ]),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'illustrations_paypal_steps',
    () => _grid([
      for (final step in PayPalStep.values)
        PayPalStepIllustration(
          step: step,
          semanticLabel: step.name,
          width: 148,
        ),
    ]),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'illustrations_iban_qr',
    () => _grid([
      const IbanQrIllustration(semanticLabel: 'IBAN und QR', width: 300),
    ]),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'illustrations_car',
    () => _grid([
      for (final type in CarBodyType.values)
        CarTypeIllustration(type: type, semanticLabel: type.name, width: 140),
      for (final fuel in FuelType.values)
        FuelIllustration(fuel: fuel, semanticLabel: fuel.name),
    ]),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'illustrations_cost_categories',
    () => _grid([
      for (final c in CostCategory.values)
        CostCategoryIllustration(category: c, semanticLabel: c.name),
    ]),
    width: 360,
    height: 640,
  );
  // Final frame (also what reduce-motion shows); the burst mid-flight is
  // covered by a painter golden below.
  await matrixGolden(
    'illustrations_finish',
    () => _grid([
      const FinishCelebration(semanticLabel: 'Fertig', size: 140),
      Illustration(
        semanticLabel: '',
        width: 140,
        painterBuilder: (p) => FinishCelebrationPainter(p, 0.35),
      ),
    ]),
    width: 360,
    height: 640,
    // Reduce-motion is not set here; settle the one-shot animation.
  );
}
