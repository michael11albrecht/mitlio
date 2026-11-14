import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/settings/ui/crash_reporting_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Settings: today only the "Datenschutz" section (opt-in crash reports).
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
        ],
      ),
    );
  }
}
