import 'dart:async';

import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/services/push_service.dart';

/// What the app tells the user about a message (the view shows it).
sealed class PushAnnouncement {
  const PushAnnouncement();
}

/// A change arrived while the app was open: a quiet in-app note instead of a
/// system banner, with "Ansehen" to open it. [text] is what the OS would have
/// shown; null (also with "hide amounts") means the generic words.
final class PushIncoming extends PushAnnouncement {
  const PushIncoming(this.payload, {this.text});

  final PushPayload payload;
  final String? text;
}

/// A tapped notification could not be opened (no usable ids in it).
final class PushOpenFailed extends PushAnnouncement {
  const PushOpenFailed();
}

/// What [PushRouting.handle] did, for DebugDrive and tests.
class PushHandled {
  const PushHandled({
    this.payload,
    this.pulled = false,
    this.opened = const [],
    this.announced,
  });

  /// Null when the message carried no usable group id.
  final PushPayload? payload;
  final bool pulled;

  /// The screens opened, bottom first (taps only).
  final List<String> opened;
  final PushAnnouncement? announced;
}

/// Routes messages from the platform to the app (P6b-T07):
/// - tap (cold start or background): pull the group, then open the group, or
///   the expense when the message names one;
/// - foreground: pull and announce in the app, no system banner;
/// - background: pull only.
/// A notification is a hint, never a data channel: only ids are used, and the
/// app always syncs from the server, so a dropped push cannot make data
/// inconsistent. A pull problem is on the group's status line already.
class PushRouting {
  PushRouting({
    required this._service,
    required this._pull,
    required this._navigate,
    required this._onError,
  });

  final PushService _service;
  final Future<void> Function(String groupId) _pull;

  /// Shows the screens, bottom first: the first replaces the stack, the
  /// others are pushed on top (back returns to the group).
  final void Function(List<String> locations) _navigate;
  final void Function(Object error, StackTrace stack) _onError;

  final _announcements = StreamController<PushAnnouncement>.broadcast();
  final _subs = <StreamSubscription<PushMessage>>[];
  var _started = false;

  Stream<PushAnnouncement> get announcements => _announcements.stream;

  /// Handles the launch notification and listens to the platform streams.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subs.addAll([
      _service.foregroundMessages.listen(
        (m) => unawaited(handle(m, PushSource.foreground)),
      ),
      _service.backgroundMessages.listen(
        (m) => unawaited(handle(m, PushSource.background)),
      ),
      _service.openedMessages.listen(
        (m) => unawaited(handle(m, PushSource.tap)),
      ),
    ]);
    final launch = await _service.initialMessage();
    if (launch != null) await handle(launch, PushSource.tap);
  }

  /// The one entry for every message; the platform streams and DebugDrive's
  /// `push.simulate` both call it. Never throws.
  Future<PushHandled> handle(PushMessage message, PushSource source) async {
    final payload = PushPayload.parse(message.data);
    if (payload == null) {
      _onError(
        const FormatException('push message without a usable group id'),
        StackTrace.current,
      );
      if (source != PushSource.tap) return const PushHandled();
      const failed = PushOpenFailed();
      _announcements.add(failed);
      return const PushHandled(announced: failed);
    }
    final pulled = await _pullSafely(payload.groupId);
    switch (source) {
      case PushSource.tap:
        _navigate(payload.locations);
        return PushHandled(
          payload: payload,
          pulled: pulled,
          opened: payload.locations,
        );
      case PushSource.foreground:
        final note = PushIncoming(
          payload,
          text: payload.hideAmounts ? null : message.body,
        );
        _announcements.add(note);
        return PushHandled(payload: payload, pulled: pulled, announced: note);
      case PushSource.background:
        return PushHandled(payload: payload, pulled: pulled);
    }
  }

  /// "Ansehen" on an in-app note.
  void open(PushPayload payload) => _navigate(payload.locations);

  Future<bool> _pullSafely(String groupId) async {
    try {
      await _pull(groupId);
      return true;
    } on Object catch (e, st) {
      _onError(e, st);
      return false;
    }
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _announcements.close();
  }
}
