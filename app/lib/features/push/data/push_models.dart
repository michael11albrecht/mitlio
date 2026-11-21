// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/remote/remote_error.dart';

/// The OS permission to show notifications.
enum PushPermission { undetermined, granted, denied }

/// Where a message reached the app (plan P6b, "Flow").
enum PushSource {
  /// The user tapped the notification (cold start or from the background):
  /// pull, then open the group or expense.
  tap,

  /// The app was open: no system banner; an in-app note and a pull.
  foreground,

  /// Delivered while the app ran in the background: pull only.
  background,
}

/// A message as the platform side hands it over: the FCM `data` map (ids and
/// display strings only, ADR-13) and the text the OS would show, if known.
class PushMessage {
  const PushMessage(this.data, {this.title, this.body});

  final Map<String, String> data;
  final String? title;
  final String? body;
}

/// The payload of the `notify` Edge Function (`dataFor` in `notify.ts`):
/// `group_id`, `event`, `expense_id` (one added/changed expense), `link`,
/// `hide_amounts`. Notifications are a hint, never a data channel: only the
/// ids are used, and only to pull and to open a screen.
class PushPayload {
  const PushPayload._({
    required this.groupId,
    required this.event,
    required this.expenseId,
    required this.hideAmounts,
  });

  /// Null when the message has no usable group id. An id of any other shape
  /// is refused too: it ends up in a route.
  static PushPayload? parse(Map<String, String> data) {
    final groupId = _id(data['group_id']);
    if (groupId == null) return null;
    final rawExpense = data['expense_id'];
    final expenseId = _id(rawExpense);
    if (rawExpense != null && expenseId == null) return null;
    return PushPayload._(
      groupId: groupId,
      event: data['event'] ?? 'group_updates',
      expenseId: expenseId,
      hideAmounts: data['hide_amounts'] == 'true',
    );
  }

  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static String? _id(String? v) =>
      v != null && _idPattern.hasMatch(v) ? v : null;

  final String groupId;
  final String event;
  final String? expenseId;
  final bool hideAmounts;

  /// The screens to show, bottom first: the group, then its expense.
  List<String> get locations => [
    '/groups/$groupId',
    if (expenseId != null) '/groups/$groupId/expenses/$expenseId',
  ];
}

/// Per group: which changes notify me (server default `all` without a row).
enum NotificationLevel {
  all,
  mine,
  none;

  static NotificationLevel parse(Object? v) => NotificationLevel.values
      .firstWhere((l) => l.name == v, orElse: () => NotificationLevel.all);
}

/// "Do not disturb" window in the local time of the device that set it. The
/// server compares in UTC with [utcOffsetMinutes] (migration 0015).
class QuietHours {
  const QuietHours({
    required this.startMinutes,
    required this.endMinutes,
    required this.utcOffsetMinutes,
  });

  /// From the stored `{start, end, utc_offset_minutes}`; null when malformed.
  static QuietHours? fromJson(Object? json) {
    if (json is! Map) return null;
    final start = _minutes(json['start']);
    final end = _minutes(json['end']);
    final offset = json['utc_offset_minutes'];
    if (start == null || end == null || offset is! int) return null;
    return QuietHours(
      startMinutes: start,
      endMinutes: end,
      utcOffsetMinutes: offset,
    );
  }

  static final _clockPattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  static int? _minutes(Object? v) {
    final m = v is String ? _clockPattern.firstMatch(v) : null;
    return m == null ? null : int.parse(m[1]!) * 60 + int.parse(m[2]!);
  }

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  /// Minutes after local midnight.
  final int startMinutes;
  final int endMinutes;
  final int utcOffsetMinutes;

  Map<String, Object?> toJson() => {
    'start': _clock(startMinutes),
    'end': _clock(endMinutes),
    'utc_offset_minutes': utcOffsetMinutes,
  };

  /// `HH:MM` for display.
  String get startText => _clock(startMinutes);
  String get endText => _clock(endMinutes);

  @override
  bool operator ==(Object other) =>
      other is QuietHours &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes &&
      other.utcOffsetMinutes == utcOffsetMinutes;

  @override
  int get hashCode => Object.hash(startMinutes, endMinutes, utcOffsetMinutes);
}

/// One row of `notification_prefs` (own rows only).
class NotificationPrefs {
  const NotificationPrefs({
    this.level = NotificationLevel.all,
    this.quietHours,
    this.hideAmounts = false,
  });

  final NotificationLevel level;
  final QuietHours? quietHours;

  /// "Beträge auf dem Sperrbildschirm ausblenden": generic body.
  final bool hideAmounts;

  NotificationPrefs copyWith({
    NotificationLevel? level,
    QuietHours? quietHours,
    bool clearQuietHours = false,
    bool? hideAmounts,
  }) => NotificationPrefs(
    level: level ?? this.level,
    quietHours: clearQuietHours ? null : quietHours ?? this.quietHours,
    hideAmounts: hideAmounts ?? this.hideAmounts,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.level == level &&
      other.quietHours == quietHours &&
      other.hideAmounts == hideAmounts;

  @override
  int get hashCode => Object.hash(level, quietHours, hideAmounts);
}

/// Why a push step failed, in a form every layer can show (no silent errors).
sealed class PushError {
  const PushError();
}

/// The backend refused or could not be reached.
final class PushRemoteError extends PushError {
  const PushRemoteError(this.error);

  final RemoteError error;
}

/// The platform side (permission, token) failed; [code] is for logs.
final class PushPlatformError extends PushError {
  const PushPlatformError(this.code);

  final String code;
}

/// No push in this build (no Firebase config) or on this platform.
final class PushUnavailable extends PushError {
  const PushUnavailable();
}
