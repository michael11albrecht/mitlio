import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/profile/ui/profile_photo_rig.dart';
import 'golden_matrix.dart';

/// The profile avatar step with the camera/gallery buttons (PU-T13), without
/// and with a photo, light/dark x 1.0/2.0. The photo is a fixed gradient
/// picture, not a real photo.
Future<void> main() async {
  Future<void> golden(String name, {required bool withPhoto}) async {
    final scope = await PhotoFlowRig().view(withPhoto: withPhoto);
    await matrixGolden(
      name,
      () => scope,
      width: 360,
      height: 760,
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await precacheImages(tester);
        await tester.pumpAndSettle();
      },
    );
  }

  await golden('profile_photo_empty', withPhoto: false);
  await golden('profile_photo_set', withPhoto: true);
}
