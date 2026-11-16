import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Data and font sources with their licences. The EEA car list needs this
/// acknowledgement (CC BY 4.0); see docs/car-catalog.md.
class LicensesView extends StatelessWidget {
  const LicensesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget entry(String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.xs),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.licensesTitle)),
      body: ListView(
        padding: Spacing.screen,
        children: [
          entry(l10n.licensesEeaTitle, l10n.licensesEea),
          entry(l10n.licensesFontTitle, l10n.licensesFont),
        ],
      ),
    );
  }
}
