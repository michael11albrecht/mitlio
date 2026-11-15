import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/settings/ui/crash_reporting_view_model.dart';
import 'package:mitlio/features/settings/ui/legal_links_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Settings: today only the "Datenschutz" section (summary, links to the
/// website texts, opt-in crash reports, delete my data).
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(crashReportingViewModelProvider);
    final vm = ref.read(crashReportingViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: Spacing.screen,
        children: [
          Text(
            l10n.privacySection,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Text(l10n.privacySummary),
          ),
          ListTile(
            title: Text(l10n.privacyPolicyEntry),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(_open(context, ref, privacy: true)),
          ),
          ListTile(
            title: Text(l10n.imprintEntry),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(_open(context, ref, privacy: false)),
          ),
          SwitchListTile(
            title: Text(l10n.crashReportsLabel),
            subtitle: Text(
              state.available
                  ? l10n.crashReportsHint
                  : l10n.crashReportsUnavailable,
            ),
            value: state.enabled,
            onChanged: state.available
                ? (v) => unawaited(vm.setEnabled(enabled: v))
                : null,
          ),
          ListTile(
            title: Text(
              l10n.deleteMyDataEntry,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            subtitle: Text(l10n.deleteMyDataEntryHint),
            onTap: () => unawaited(context.push('/settings/delete-data')),
          ),
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    required bool privacy,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = AppLocalizations.of(context).paymentLinkCopied;
    final vm = ref.read(legalLinksViewModelProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final opened = await (privacy
        ? vm.openPrivacy(lang)
        : vm.openImprint(lang));
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(copied)));
    }
  }
}
