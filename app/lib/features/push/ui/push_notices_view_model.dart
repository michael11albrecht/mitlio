import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio/features/push/data/push_providers.dart';
import 'package:mitlio/features/push/data/repositories/push_routing.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Plain words for a failed push step: what happened and what to do next.
String pushErrorText(AppLocalizations l10n, PushError error) => switch (error) {
  PushRemoteError(:final error) => remoteErrorText(l10n, error),
  PushPlatformError() => l10n.pushErrorPlatform,
  PushUnavailable() => l10n.pushUnavailable,
};

/// One quiet note the app shows as a snack bar (never a dialog): the offer
/// after the first share or join, what arrived while the app was open, and
/// what went wrong.
sealed class PushNotice {
  const PushNotice();

  String text(AppLocalizations l10n);

  /// The one action next to the text, or null.
  String? actionLabel(AppLocalizations l10n) => null;
}

/// "Soll mitlio dir Bescheid geben ...?" (asked once, contextually).
final class PushNoticeOffer extends PushNotice {
  const PushNoticeOffer();

  @override
  String text(AppLocalizations l10n) => l10n.pushPromptText;

  @override
  String? actionLabel(AppLocalizations l10n) => l10n.pushPromptAction;
}

/// A change arrived while the app was open.
final class PushNoticeIncoming extends PushNotice {
  const PushNoticeIncoming(this.payload, {this.body});

  final PushPayload payload;
  final String? body;

  @override
  String text(AppLocalizations l10n) => body ?? l10n.pushIncomingGeneric;

  @override
  String? actionLabel(AppLocalizations l10n) => l10n.pushIncomingOpen;
}

/// The OS said no.
final class PushNoticeDenied extends PushNotice {
  const PushNoticeDenied();

  @override
  String text(AppLocalizations l10n) => l10n.pushPermissionDenied;
}

/// Turning notifications on failed.
final class PushNoticeFailed extends PushNotice {
  const PushNoticeFailed(this.error);

  final PushError error;

  @override
  String text(AppLocalizations l10n) => pushErrorText(l10n, error);
}

/// A tapped notification could not be opened.
final class PushNoticeOpenFailed extends PushNotice {
  const PushNoticeOpenFailed();

  @override
  String text(AppLocalizations l10n) => l10n.pushOpenFailed;
}

/// The app-wide push notes (P6b-T06, T07). `PushHost` starts it and shows the
/// state; the share and join view models call [offer].
class PushNoticesViewModel extends Notifier<PushNotice?> {
  StreamSubscription<PushAnnouncement>? _announcements;

  @override
  PushNotice? build() {
    ref.onDispose(() => unawaited(_announcements?.cancel()));
    return null;
  }

  /// Starts routing messages (taps, foreground, background) and keeping the
  /// token current. Safe to call again.
  Future<void> start() async {
    final routing = ref.read(pushRoutingProvider);
    _announcements ??= routing.announcements.listen(_onAnnouncement);
    await routing.start();
    await ref.read(pushRepositoryProvider).start();
  }

  void _onAnnouncement(PushAnnouncement a) {
    if (!ref.mounted) return;
    state = switch (a) {
      PushIncoming(:final payload, :final text) => PushNoticeIncoming(
        payload,
        body: text,
      ),
      PushOpenFailed() => const PushNoticeOpenFailed(),
    };
  }

  /// After the first share or join: offers the notifications once, when
  /// pushes exist, the user was not asked and the OS has not decided yet.
  Future<void> offer() async {
    if (!await ref.read(pushRepositoryProvider).shouldOffer()) return;
    if (ref.mounted && state == null) state = const PushNoticeOffer();
  }

  /// The action of [notice]: "Ja, bitte" asks the OS and registers the
  /// device, "Ansehen" opens the change.
  Future<void> act(PushNotice notice) async {
    clear(notice);
    switch (notice) {
      case PushNoticeOffer():
        await enable();
      case PushNoticeIncoming(:final payload):
        ref.read(pushRoutingProvider).open(payload);
      case PushNoticeDenied() || PushNoticeFailed() || PushNoticeOpenFailed():
        break;
    }
  }

  /// Asks the OS and registers the device; the outcome shows as a note.
  Future<void> enable() async {
    final result = await ref.read(pushRepositoryProvider).enable();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(value: PushPermission.granted) => null,
      Ok() => const PushNoticeDenied(),
      Err(:final error) => PushNoticeFailed(error),
    };
  }

  /// The note went away without its action (swiped, timed out). An unanswered
  /// offer is not made again; Settings keeps the switch.
  Future<void> dismissed(PushNotice notice) async {
    clear(notice);
    if (notice is PushNoticeOffer) {
      await ref.read(pushRepositoryProvider).markAsked();
    }
  }

  /// Drops [notice] from the state when it is still the current one.
  void clear(PushNotice notice) {
    if (ref.mounted && identical(state, notice)) state = null;
  }
}

final pushNoticesViewModelProvider =
    NotifierProvider<PushNoticesViewModel, PushNotice?>(
      PushNoticesViewModel.new,
    );
