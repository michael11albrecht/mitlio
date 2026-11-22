import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';
import 'package:mitlio/features/profile/ui/profile_entry_view_model.dart';
import 'package:mitlio/features/settings/ui/author_credit_view_model.dart';
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
    final profile = ref.watch(profileEntryViewModelProvider);
    Future<void> openProfile() async {
      await context.push<void>('/settings/profile');
      await ref.read(profileEntryViewModelProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: Spacing.screen,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.profileSettingsEntry),
            subtitle: Text(switch (profile) {
              ProfileSummary.none => l10n.profileSettingsEntryHint,
              ProfileSummary.noPayment => l10n.profileEntrySaved('none'),
              ProfileSummary.paypal => l10n.profileEntrySaved('paypal'),
              ProfileSummary.iban => l10n.profileEntrySaved('iban'),
              ProfileSummary.both => l10n.profileEntrySaved('both'),
            }),
            onTap: () => unawaited(openProfile()),
          ),
          if (profile == ProfileSummary.iban || profile == ProfileSummary.both)
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: Text(l10n.myQrEntry),
              subtitle: Text(l10n.myQrEntryHint),
              onTap: () => unawaited(context.push('/settings/my-qr')),
            ),
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: Text(l10n.carsEntry),
            subtitle: Text(l10n.carsEntryHint),
            onTap: () => unawaited(context.push('/settings/cars')),
          ),
          const SizedBox(height: Spacing.md),
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
                ? (v) => unawaited(_setCrashReports(context, vm, enabled: v))
                : null,
          ),
          ListTile(
            title: Text(l10n.licensesEntry),
            subtitle: Text(l10n.licensesEntryHint),
            onTap: () => unawaited(context.push('/settings/licenses')),
          ),
          // Hidden until the server reports that feedback is set up (ADR-29).
          if (ref.watch(feedbackEntryVisibleProvider))
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(l10n.feedbackEntry),
              subtitle: Text(l10n.feedbackEntryHint),
              onTap: () => unawaited(context.push('/settings/feedback')),
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
          const SizedBox(height: Spacing.lg),
          const _AuthorCredit(),
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

/// "Made with ♥ by Michael Albrecht": discreet credit at the end of Settings.
class _AuthorCredit extends ConsumerWidget {
  const _AuthorCredit();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.xs,
      children: [
        Text(l10n.creditLead, style: style),
        ExcludeSemantics(
          child: Text('♥', style: style?.copyWith(color: scheme.primary)),
        ),
        Text(l10n.creditMid, style: style),
        TextButton(
          // No side padding: it would widen the gap before the name.
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          onPressed: () => unawaited(_open(context, ref)),
          child: Text(l10n.creditName),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).creditOpenFailed;
    final opened = await ref.read(authorCreditViewModelProvider).openProfile();
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}

Future<void> _setCrashReports(
  BuildContext context,
  CrashReportingViewModel vm, {
  required bool enabled,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final saved = await vm.setEnabled(enabled: enabled);
  if (!saved) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.errorSettingNotSaved)));
  }
}
