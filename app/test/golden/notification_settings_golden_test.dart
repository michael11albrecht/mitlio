import 'package:alchemist/alchemist.dart';
import 'package:mitlio/features/push/ui/notification_settings_view.dart';

import '../features/groups/ui/groups_fixtures.dart';
import '../features/push/ui/push_fixtures.dart';
import 'golden_matrix.dart';

/// Per-group notification settings: loading, local group, failed, defaults,
/// customized (only mine, quiet hours, hidden amounts), offer to enable,
/// denied by the OS, and a build without push.
Future<void> main() async {
  for (final (name, state) in notificationSettingsStates) {
    await matrixGolden(
      'notification_settings_$name',
      () => scoped(
        notificationSettingsOverride(state),
        const NotificationSettingsView(groupId: 'g1'),
      ),
      width: 360,
      height: 1200,
      pumpBeforeTest: name == 'loading' ? pumpOnce : onlyPumpAndSettle,
    );
  }
}
