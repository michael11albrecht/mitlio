import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/illustrations/illustrations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/themed_app.dart';

void main() {
  testWidgets('every illustration exposes its semantics label', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      themedApp(
        const SingleChildScrollView(
          child: Column(
            children: [
              ProfileAvatarIllustration(semanticLabel: 'avatar'),
              PayPalStepIllustration(
                step: PayPalStep.copyLink,
                semanticLabel: 'step',
              ),
              IbanQrIllustration(semanticLabel: 'iban'),
              CarTypeIllustration(
                type: CarBodyType.suv,
                semanticLabel: 'car',
              ),
              FuelIllustration(
                fuel: FuelType.electric,
                semanticLabel: 'fuel',
              ),
              CostCategoryIllustration(
                category: CostCategory.tyres,
                semanticLabel: 'category',
              ),
              FinishCelebration(semanticLabel: 'finish'),
            ],
          ),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 2));
    for (final label in [
      'avatar',
      'step',
      'iban',
      'car',
      'fuel',
      'category',
      'finish',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    handle.dispose();
  });

  testWidgets('empty label hides the illustration from semantics', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      themedApp(const ProfileAvatarIllustration(semanticLabel: '')),
    );
    expect(
      t.getSemantics(find.byType(ProfileAvatarIllustration)).label,
      isEmpty,
    );
    handle.dispose();
  });

  Widget celebration({required bool reduceMotion}) => themedApp(
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: reduceMotion),
        child: const FinishCelebration(semanticLabel: 'finish'),
      ),
    ),
  );

  testWidgets('celebration plays once without reduce-motion', (t) async {
    await t.pumpWidget(celebration(reduceMotion: false));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpAndSettle();
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('celebration does not animate with reduce-motion', (t) async {
    await t.pumpWidget(celebration(reduceMotion: true));
    expect(t.hasRunningAnimations, isFalse);
  });
}
