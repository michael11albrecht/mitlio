import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/profile/ui/my_qr_view.dart';

import '../features/profile/ui/profile_flow_rig.dart';
import 'golden_matrix.dart';

/// "Mein QR-Code teilen" (PU-T16), light/dark x 1.0/2.0: the code is black on
/// white in both themes, with the holder and the trust hint under it.
Future<void> main() async {
  final rig = ProfileFlowRig();
  await rig.profile.save(displayName: 'Anna Beispiel');
  await rig.bank.save(
    iban: 'DE89370400440532013000',
    accountName: 'Anna Beispiel',
  );
  await matrixGolden(
    'my_qr',
    () => ProviderScope(overrides: rig.overrides, child: const MyQrView()),
    width: 360,
    height: 640,
  );
}
