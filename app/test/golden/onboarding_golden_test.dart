import 'package:flutter/widgets.dart';
import 'package:mitlio/core/widgets/brand_mark.dart';
import 'package:mitlio/features/onboarding/ui/onboarding_view.dart';

import '../features/groups/ui/groups_fixtures.dart';
import 'golden_matrix.dart';

/// First-run screen and the brand mark (the v1 launcher icon geometry, see
/// `docs/brand.md`), light/dark x 1.0/2.0.
Future<void> main() async {
  await matrixGolden(
    'onboarding',
    () => scoped(const [], const OnboardingView()),
    width: 360,
    height: 640,
  );
  await matrixGolden(
    'brand_mark',
    () => const Center(child: BrandMark(size: 160)),
    width: 200,
    height: 200,
  );
}
