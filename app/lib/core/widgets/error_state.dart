import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Something failed: plain words, no blame, one way forward ([onRetry]).
class ErrorState extends StatelessWidget {
  const ErrorState({required this.onRetry, this.message, super.key});

  final VoidCallback onRetry;

  /// Overrides the generic explanation.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: l10n.errorTitle,
      message: message ?? l10n.errorMessage,
      action: FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
    );
  }
}
