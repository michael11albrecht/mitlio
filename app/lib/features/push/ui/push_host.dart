import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/push/ui/push_notices_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Wraps the app (`MaterialApp.builder`): starts push routing and shows the
/// push notes (the one-time offer, a change that arrived while the app is
/// open, failures) as snack bars. Notes are never dialogs (plan §2.6).
class PushHost extends ConsumerStatefulWidget {
  const PushHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PushHost> createState() => _PushHostState();
}

class _PushHostState extends ConsumerState<PushHost> {
  @override
  void initState() {
    super.initState();
    // After the first frame: the router and the messenger exist by then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(pushNoticesViewModelProvider.notifier).start());
      }
    });
  }

  void _show(PushNotice notice) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(pushNoticesViewModelProvider.notifier);
    final label = notice.actionLabel(l10n);
    messenger.hideCurrentSnackBar();
    final shown = messenger.showSnackBar(
      SnackBar(
        content: Text(notice.text(l10n)),
        // An action keeps a snack bar on screen by default; notes time out.
        persist: false,
        duration: notice is PushNoticeOffer
            ? const Duration(seconds: 12)
            : const Duration(seconds: 6),
        action: label == null
            ? null
            : SnackBarAction(
                label: label,
                onPressed: () => unawaited(vm.act(notice)),
              ),
      ),
    );
    unawaited(
      shown.closed.then((reason) {
        // Replaced by another note or hidden by a screen change: not an
        // answer, so an unanswered offer stays possible. Swiped away or timed
        // out is "not now".
        final answered =
            reason == SnackBarClosedReason.dismiss ||
            reason == SnackBarClosedReason.swipe ||
            reason == SnackBarClosedReason.timeout;
        if (answered) return vm.dismissed(notice);
        vm.clear(notice);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pushNoticesViewModelProvider, (previous, next) {
      if (next != null && !identical(previous, next)) _show(next);
    });
    return widget.child;
  }
}
