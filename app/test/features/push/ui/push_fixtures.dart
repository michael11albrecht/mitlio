import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/push_providers.dart';
import 'package:mitlio/features/push/data/push_state_store.dart';
import 'package:mitlio/features/push/data/services/fake_push_remote.dart';
import 'package:mitlio/features/push/data/services/fake_push_service.dart';
import 'package:mitlio/features/push/ui/notification_settings_view_model.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';

import '../../../db/test_support.dart';

/// Push with fakes on an in-memory database; group `g1` is shared and the
/// account is a member of it.
class PushWorld {
  PushWorld._(this.db);

  static Future<PushWorld> create() async {
    final w = PushWorld._(openTestDb());
    await w.db.groupsDao.insertGroup(newGroup('g1'));
    await w.db.syncStateDao.setState('g1', SyncState.shared);
    return w;
  }

  final AppDatabase db;
  final service = FakePushService();
  final remote = FakePushRemote(groups: {'g1'});
  final auth = FakeAuthService(userId: 'fake-user-1');
  final store = MemoryPushStateStore();
  final clock = FixedClock(DateTime.utc(2026, 11, 21, 10));
  final errors = <Object>[];

  List<Override> get overrides => [
    appDatabaseProvider.overrideWithValue(db),
    pushServiceProvider.overrideWithValue(service),
    pushRemoteProvider.overrideWithValue(remote),
    authServiceProvider.overrideWithValue(auth),
    pushStateStoreProvider.overrideWithValue(store),
    clockProvider.overrideWithValue(clock),
    deviceLocaleTagProvider.overrideWithValue('de-DE'),
  ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);

  Future<void> close() async {
    await service.dispose();
    await db.close();
  }
}

/// Fixed settings state for goldens and widget tests; commands do nothing.
class StubNotificationSettingsViewModel extends NotificationSettingsViewModel {
  StubNotificationSettingsViewModel(super.groupId, this.fixed);

  final NotificationSettingsState fixed;

  @override
  NotificationSettingsState build() => fixed;

  @override
  Future<void> load() async {}
}

List<Override> notificationSettingsOverride(NotificationSettingsState s) => [
  notificationSettingsViewModelProvider.overrideWith2(
    (id) => StubNotificationSettingsViewModel(id, s),
  ),
];

/// Named states for goldens.
final notificationSettingsStates = <(String, NotificationSettingsState)>[
  ('loading', const NotificationSettingsLoading()),
  ('not_shared', const NotificationSettingsNotShared()),
  (
    'failed',
    const NotificationSettingsFailed(
      PushPlatformError('x'),
    ),
  ),
  (
    'defaults',
    const NotificationSettingsReady(
      prefs: NotificationPrefs(),
      pushAvailable: true,
      permission: PushPermission.granted,
    ),
  ),
  (
    'customized',
    const NotificationSettingsReady(
      prefs: NotificationPrefs(
        level: NotificationLevel.mine,
        quietHours: QuietHours(
          startMinutes: 22 * 60,
          endMinutes: 7 * 60,
          utcOffsetMinutes: 60,
        ),
        hideAmounts: true,
      ),
      pushAvailable: true,
      permission: PushPermission.granted,
    ),
  ),
  (
    'can_enable',
    const NotificationSettingsReady(
      prefs: NotificationPrefs(),
      pushAvailable: true,
      permission: PushPermission.undetermined,
    ),
  ),
  (
    'denied',
    const NotificationSettingsReady(
      prefs: NotificationPrefs(level: NotificationLevel.none),
      pushAvailable: true,
      permission: PushPermission.denied,
    ),
  ),
  (
    'unavailable',
    const NotificationSettingsReady(
      prefs: NotificationPrefs(),
      pushAvailable: false,
      permission: null,
    ),
  ),
];
