import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/recurring/ui/recurring_catch_up_view_model.dart';
import 'package:mitlio/features/recurring/ui/recurring_labels.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Wraps the app (`MaterialApp.builder`): makes the expenses recurring rules
/// owe on start and whenever the app comes back to the foreground, and tells
/// the user what happened in a snack bar (never a dialog, plan §2.6).
class RecurringHost extends ConsumerStatefulWidget {
  const RecurringHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RecurringHost> createState() => _RecurringHostState();
}

class _RecurringHostState extends ConsumerState<RecurringHost> {
  StreamSubscription<void>? _resume;

  @override
  void initState() {
    super.initState();
    // After the first frame: the messenger exists by then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_run());
      _resume = ref
          .read(lifecycleSourceProvider)
          .onResume
          .listen((_) => unawaited(_run()));
    });
  }

  @override
  void dispose() {
    unawaited(_resume?.cancel());
    super.dispose();
  }

  Future<void> _run() =>
      ref.read(recurringCatchUpViewModelProvider.notifier).run();

  void _show(RecurringCatchUpNotice notice) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            recurringNoticeText(
              l10n,
              notice,
              (f) => repositoryErrorMessage(l10n, f.error),
            ),
          ),
          // Notes time out; a failure stays long enough to be read.
          persist: false,
          duration: notice.failures.isEmpty
              ? const Duration(seconds: 5)
              : const Duration(seconds: 10),
        ),
      );
    ref.read(recurringCatchUpViewModelProvider.notifier).consume();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recurringCatchUpViewModelProvider, (previous, next) {
      if (next != null) _show(next);
    });
    return widget.child;
  }
}
