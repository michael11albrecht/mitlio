import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/push_providers.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

export 'package:mitlio/features/push/data/push_models.dart'
    show NotificationLevel, PushError;

sealed class NotificationSettingsState {
  const NotificationSettingsState();
}

final class NotificationSettingsLoading extends NotificationSettingsState {
  const NotificationSettingsLoading();
}

/// The group was never shared: there is no one to notify about.
final class NotificationSettingsNotShared extends NotificationSettingsState {
  const NotificationSettingsNotShared();
}

/// The prefs could not be read; [error] says why, "Nochmal versuchen" calls
/// [NotificationSettingsViewModel.load] again.
final class NotificationSettingsFailed extends NotificationSettingsState {
  const NotificationSettingsFailed(this.error);

  final PushError error;
}

/// The group's prefs, and whether this phone can receive them at all.
final class NotificationSettingsReady extends NotificationSettingsState {
  const NotificationSettingsReady({
    required this.prefs,
    required this.pushAvailable,
    required this.permission,
  });

  final NotificationPrefs prefs;

  /// False in builds without push (no Firebase config): the choices still
  /// save, but nothing is received yet, and the screen says so.
  final bool pushAvailable;
  final PushPermission? permission;

  NotificationLevel get level => prefs.level;
  bool get hideAmounts => prefs.hideAmounts;
  bool get quietHoursOn => prefs.quietHours != null;

  /// `HH:MM`, null while quiet hours are off.
  String? get quietFrom => prefs.quietHours?.startText;
  String? get quietTo => prefs.quietHours?.endText;

  /// Minutes after midnight, null while quiet hours are off.
  int? get quietFromMinutes => prefs.quietHours?.startMinutes;
  int? get quietToMinutes => prefs.quietHours?.endMinutes;

  /// Offer "Benachrichtigungen einschalten": possible, not decided yet.
  bool get canEnable =>
      pushAvailable && permission == PushPermission.undetermined;

  bool get permissionDenied => permission == PushPermission.denied;

  NotificationSettingsReady withPrefs(NotificationPrefs p) =>
      NotificationSettingsReady(
        prefs: p,
        pushAvailable: pushAvailable,
        permission: permission,
      );
}

/// Per-group notification settings: level (all / only mine / none), quiet
/// hours, hide amounts (P6b-T08). Every change is saved at once (no save
/// button); when saving fails the screen goes back to what the server has and
/// the command returns the error, which the view shows. DebugDrive and tests
/// call the same commands.
class NotificationSettingsViewModel
    extends Notifier<NotificationSettingsState> {
  NotificationSettingsViewModel(this.groupId);

  final String groupId;

  /// Quiet hours when switched on: 22:00 to 07:00.
  static const int defaultQuietFrom = 22 * 60;
  static const int defaultQuietTo = 7 * 60;

  @override
  NotificationSettingsState build() => const NotificationSettingsLoading();

  Future<void> load() async {
    state = const NotificationSettingsLoading();
    final snap = await ref.read(syncStateRepositoryProvider).snapshot(groupId);
    if (!ref.mounted) return;
    if (snap.state != SyncState.shared) {
      state = const NotificationSettingsNotShared();
      return;
    }
    final repo = ref.read(pushRepositoryProvider);
    final loaded = await repo.loadPrefs(groupId);
    final permission = switch (await repo.permission()) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (!ref.mounted) return;
    state = switch (loaded) {
      Ok(:final value) => NotificationSettingsReady(
        prefs: value,
        pushAvailable: repo.isAvailable,
        permission: permission,
      ),
      Err(:final error) => NotificationSettingsFailed(error),
    };
  }

  Future<PushError?> setLevel(NotificationLevel level) =>
      _change((p) => p.copyWith(level: level));

  Future<PushError?> setHideAmounts({required bool hide}) =>
      _change((p) => p.copyWith(hideAmounts: hide));

  /// Switches quiet hours on (with the defaults) or off.
  Future<PushError?> setQuietHoursOn({required bool on}) => _change(
    (p) => on
        ? p.copyWith(
            quietHours: const QuietHours(
              startMinutes: defaultQuietFrom,
              endMinutes: defaultQuietTo,
              utcOffsetMinutes: 0,
            ),
          )
        : p.copyWith(clearQuietHours: true),
  );

  /// Sets the window, in minutes after local midnight. Equal start and end
  /// are no window to the server, so the view never offers them and this
  /// ignores them.
  Future<PushError?> setQuietHours({
    required int fromMinutes,
    required int toMinutes,
  }) async {
    if (fromMinutes == toMinutes) return null;
    return _change(
      (p) => p.copyWith(
        quietHours: QuietHours(
          startMinutes: fromMinutes,
          endMinutes: toMinutes,
          utcOffsetMinutes: 0,
        ),
      ),
    );
  }

  /// "Benachrichtigungen einschalten" on this screen: asks the OS and
  /// registers the device. Returns the failure, null on success or "no".
  Future<PushError?> enableNotifications() async {
    final repo = ref.read(pushRepositoryProvider);
    final result = await repo.enable();
    // What the OS says now, also when registering failed after a yes.
    final now = await repo.permission();
    final s = state;
    if (ref.mounted && s is NotificationSettingsReady) {
      state = NotificationSettingsReady(
        prefs: s.prefs,
        pushAvailable: s.pushAvailable,
        permission: switch (now) {
          Ok(:final value) => value,
          Err() => s.permission,
        },
      );
    }
    return switch (result) {
      Ok() => null,
      Err(:final error) => error,
    };
  }

  Future<PushError?> _change(
    NotificationPrefs Function(NotificationPrefs) edit,
  ) async {
    final s = state;
    if (s is! NotificationSettingsReady) return null;
    final next = edit(s.prefs);
    if (next == s.prefs) return null;
    state = s.withPrefs(next);
    final saved = await ref
        .read(pushRepositoryProvider)
        .savePrefs(groupId, next);
    switch (saved) {
      case Ok():
        return null;
      case Err(:final error):
        // Back to what the server has: the screen never shows a choice that
        // was not saved.
        if (ref.mounted && state is NotificationSettingsReady) {
          state = (state as NotificationSettingsReady).withPrefs(s.prefs);
        }
        return error;
    }
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final notificationSettingsViewModelProvider = NotifierProvider.autoDispose
    .family<NotificationSettingsViewModel, NotificationSettingsState, String>(
      NotificationSettingsViewModel.new,
    );
