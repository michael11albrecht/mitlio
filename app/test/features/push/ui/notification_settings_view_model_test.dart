import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/ui/notification_settings_view_model.dart';

import 'push_fixtures.dart';

void main() {
  late PushWorld w;
  late ProviderContainer c;
  final provider = notificationSettingsViewModelProvider('g1');

  NotificationSettingsViewModel vm() => c.read(provider.notifier);
  NotificationSettingsReady ready() =>
      c.read(provider) as NotificationSettingsReady;

  setUp(() async {
    w = await PushWorld.create();
    c = w.container()..listen(provider, (_, _) {});
  });
  tearDown(() async {
    c.dispose();
    await w.close();
  });

  Future<void> loaded() async {
    await vm().load();
    expect(c.read(provider), isA<NotificationSettingsReady>());
  }

  group('load', () {
    test('starts loading, then shows the defaults', () async {
      expect(c.read(provider), isA<NotificationSettingsLoading>());
      w.service.permissionState = PushPermission.granted;
      await vm().load();
      final s = ready();
      expect(s.level, NotificationLevel.all);
      expect(s.hideAmounts, isFalse);
      expect(s.quietHoursOn, isFalse);
      expect(s.quietFrom, isNull);
      expect(s.pushAvailable, isTrue);
      expect(s.canEnable, isFalse);
      expect(s.permissionDenied, isFalse);
    });

    test('shows what the server has', () async {
      w.remote.prefs['fake-user-1|g1'] = const NotificationPrefs(
        level: NotificationLevel.mine,
        quietHours: QuietHours(
          startMinutes: 23 * 60,
          endMinutes: 6 * 60 + 30,
          utcOffsetMinutes: 0,
        ),
        hideAmounts: true,
      );
      await loaded();
      final s = ready();
      expect(s.level, NotificationLevel.mine);
      expect(s.hideAmounts, isTrue);
      expect(s.quietFrom, '23:00');
      expect(s.quietTo, '06:30');
      expect(s.quietFromMinutes, 23 * 60);
      expect(s.quietToMinutes, 6 * 60 + 30);
    });

    test('a local group has nothing to notify about', () async {
      await w.db.syncStateDao.setState('g1', SyncState.removed);
      await vm().load();
      expect(c.read(provider), isA<NotificationSettingsNotShared>());
      expect(w.remote.calls, 0);
    });

    test('a failure is kept with its cause and can be retried', () async {
      w.remote.offline = true;
      await vm().load();
      final failed = c.read(provider) as NotificationSettingsFailed;
      expect(
        (failed.error as PushRemoteError).error,
        const Offline(),
      );
      w.remote.offline = false;
      await loaded();
    });

    test('no push in this build: ready, says so', () async {
      w.service.available = false;
      await loaded();
      expect(ready().pushAvailable, isFalse);
      expect(ready().canEnable, isFalse);
      expect(ready().permission, isNull);
    });
  });

  group('commands save at once', () {
    setUp(() async {
      w.service.permissionState = PushPermission.granted;
      await loaded();
    });

    test('level', () async {
      expect(await vm().setLevel(NotificationLevel.none), isNull);
      expect(ready().level, NotificationLevel.none);
      expect(
        w.remote.prefs['fake-user-1|g1']!.level,
        NotificationLevel.none,
      );
      expect(await vm().setLevel(NotificationLevel.mine), isNull);
      expect(w.remote.prefs['fake-user-1|g1']!.level, NotificationLevel.mine);
    });

    test('the same value is no call', () async {
      final before = w.remote.calls;
      expect(await vm().setLevel(NotificationLevel.all), isNull);
      expect(w.remote.calls, before);
    });

    test('hide amounts', () async {
      expect(await vm().setHideAmounts(hide: true), isNull);
      expect(ready().hideAmounts, isTrue);
      expect(w.remote.prefs['fake-user-1|g1']!.hideAmounts, isTrue);
    });

    test('quiet hours: on with defaults, change, off', () async {
      expect(await vm().setQuietHoursOn(on: true), isNull);
      expect(
        ready().quietFromMinutes,
        NotificationSettingsViewModel.defaultQuietFrom,
      );
      expect(
        ready().quietToMinutes,
        NotificationSettingsViewModel.defaultQuietTo,
      );
      expect(
        await vm().setQuietHours(fromMinutes: 21 * 60, toMinutes: 6 * 60),
        isNull,
      );
      final saved = w.remote.prefs['fake-user-1|g1']!.quietHours!;
      expect(saved.startMinutes, 21 * 60);
      expect(saved.endMinutes, 6 * 60);
      expect(await vm().setQuietHoursOn(on: false), isNull);
      expect(ready().quietHoursOn, isFalse);
      expect(w.remote.prefs['fake-user-1|g1']!.quietHours, isNull);
    });

    test('equal start and end is ignored', () async {
      await vm().setQuietHoursOn(on: true);
      final before = w.remote.calls;
      expect(await vm().setQuietHours(fromMinutes: 60, toMinutes: 60), isNull);
      expect(w.remote.calls, before);
    });

    test('a failed save returns the cause and snaps back', () async {
      w.remote.offline = true;
      final e = await vm().setLevel(NotificationLevel.none);
      expect((e! as PushRemoteError).error, const Offline());
      expect(ready().level, NotificationLevel.all);
      expect(w.remote.prefs, isEmpty);
    });

    test('a rate limit keeps its wait', () async {
      w.remote.failNext(const RateLimitedRemote(Duration(minutes: 5)));
      final e = await vm().setHideAmounts(hide: true);
      expect(
        (e! as PushRemoteError).error,
        const RateLimitedRemote(Duration(minutes: 5)),
      );
      expect(ready().hideAmounts, isFalse);
    });

    test('a group the account left is NotMember', () async {
      w.remote.groups.clear();
      final e = await vm().setLevel(NotificationLevel.none);
      expect((e! as PushRemoteError).error, const NotMember());
    });

    test('commands before the settings are loaded do nothing', () async {
      c.dispose();
      c = w.container();
      final fresh = c.read(provider.notifier);
      expect(await fresh.setLevel(NotificationLevel.none), isNull);
      expect(w.remote.prefs, isEmpty);
    });
  });

  group('enableNotifications', () {
    test('asks the OS, registers, and updates the permission', () async {
      await loaded();
      expect(ready().canEnable, isTrue);
      expect(await vm().enableNotifications(), isNull);
      expect(ready().permission, PushPermission.granted);
      expect(ready().canEnable, isFalse);
      expect(w.remote.tokens, hasLength(1));
    });

    test('no from the user: denied, no error', () async {
      w.service.permissionAnswer = PushPermission.denied;
      await loaded();
      expect(await vm().enableNotifications(), isNull);
      expect(ready().permissionDenied, isTrue);
      expect(w.remote.tokens, isEmpty);
    });

    test('a failure comes back and the permission stays', () async {
      await loaded();
      w.remote.offline = true;
      final e = await vm().enableNotifications();
      expect((e! as PushRemoteError).error, const Offline());
      expect(ready().permission, PushPermission.granted);
    });

    test('an OS failure keeps the old permission', () async {
      await loaded();
      w.service.failWith = const PushPlatformError('x');
      expect(await vm().enableNotifications(), isA<PushPlatformError>());
      expect(ready().permission, PushPermission.undetermined);
    });
  });
}
