import 'package:alchemist/alchemist.dart';
import 'package:mitlio/features/sync/ui/share_sheet.dart';

import '../features/groups/ui/groups_fixtures.dart';
import '../features/sync/ui/share_fixtures.dart';
import 'golden_matrix.dart';

/// "Gruppe teilen": preparing, owner (link, QR, new link), the inline second
/// step with an error, a member (no new link) and a rotated link.
Future<void> main() async {
  for (final (name, state) in shareStates) {
    await matrixGolden(
      'share_sheet_$name',
      () => scoped(
        shareStateOverride(state),
        const ShareSheet(groupId: 'g-1'),
      ),
      width: 360,
      height: 760,
      pumpBeforeTest: name == 'loading' ? pumpOnce : onlyPumpAndSettle,
    );
  }
}
