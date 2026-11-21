import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/push/ui/notification_settings_view_model.dart';
import 'package:mitlio/features/push/ui/push_notices_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Notification settings of one group: level, quiet hours, hide amounts
/// (P6b-T08). Changes save at once; a failure says why and what to do.
class NotificationSettingsView extends ConsumerStatefulWidget {
  const NotificationSettingsView({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState
    extends ConsumerState<NotificationSettingsView> {
  @override
  void initState() {
    super.initState();
    // Not during build: the command changes provider state.
    unawaited(
      Future.microtask(
        () => ref
            .read(
              notificationSettingsViewModelProvider(widget.groupId).notifier,
            )
            .load(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = notificationSettingsViewModelProvider(widget.groupId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
      body: switch (state) {
        NotificationSettingsLoading() => Center(
          child: Semantics(
            label: l10n.notifLoading,
            child: const CircularProgressIndicator(),
          ),
        ),
        NotificationSettingsNotShared() => Padding(
          padding: Spacing.screen,
          child: Text(l10n.notifNotShared),
        ),
        NotificationSettingsFailed(:final error) => Padding(
          padding: Spacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pushErrorText(l10n, error)),
              const SizedBox(height: Spacing.md),
              FilledButton(
                onPressed: () => unawaited(vm.load()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        NotificationSettingsReady() => _Ready(state: state, vm: vm),
      },
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state, required this.vm});

  final NotificationSettingsReady state;
  final NotificationSettingsViewModel vm;

  /// Runs [command], and shows its failure as a snack bar.
  Future<void> _run(
    BuildContext context,
    Future<PushError?> Function() command,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final error = await command();
    if (error == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pushErrorText(l10n, error))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: Spacing.screen,
      children: [
        if (!state.pushAvailable)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Text(l10n.pushUnavailable),
          ),
        if (state.permissionDenied)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Text(l10n.pushPermissionDenied),
          ),
        if (state.canEnable)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: FilledButton.tonal(
                onPressed: () =>
                    unawaited(_run(context, vm.enableNotifications)),
                child: Text(l10n.notifEnable),
              ),
            ),
          ),
        Text(l10n.notifLevelLabel, style: text.titleSmall),
        RadioGroup<NotificationLevel>(
          groupValue: state.level,
          onChanged: (level) {
            if (level != null) {
              unawaited(_run(context, () => vm.setLevel(level)));
            }
          },
          child: Column(
            children: [
              RadioListTile<NotificationLevel>(
                value: NotificationLevel.all,
                title: Text(l10n.notifLevelAll),
              ),
              RadioListTile<NotificationLevel>(
                value: NotificationLevel.mine,
                title: Text(l10n.notifLevelMine),
              ),
              RadioListTile<NotificationLevel>(
                value: NotificationLevel.none,
                title: Text(l10n.notifLevelNone),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        SwitchListTile(
          title: Text(l10n.notifQuietHoursLabel),
          subtitle: Text(l10n.notifQuietHoursHint),
          value: state.quietHoursOn,
          onChanged: (on) =>
              unawaited(_run(context, () => vm.setQuietHoursOn(on: on))),
        ),
        if (state.quietHoursOn)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            // Stacked, not side by side: two fields do not fit at text scale 2.
            child: Column(
              children: [
                _HourField(
                  label: l10n.notifQuietHoursFrom,
                  minutes: state.quietFromMinutes!,
                  other: state.quietToMinutes!,
                  onChanged: (m) => unawaited(
                    _run(
                      context,
                      () => vm.setQuietHours(
                        fromMinutes: m,
                        toMinutes: state.quietToMinutes!,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                _HourField(
                  label: l10n.notifQuietHoursTo,
                  minutes: state.quietToMinutes!,
                  other: state.quietFromMinutes!,
                  onChanged: (m) => unawaited(
                    _run(
                      context,
                      () => vm.setQuietHours(
                        fromMinutes: state.quietFromMinutes!,
                        toMinutes: m,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        SwitchListTile(
          title: Text(l10n.notifHideAmountsLabel),
          subtitle: Text(l10n.notifHideAmountsHint),
          value: state.hideAmounts,
          onChanged: (hide) => unawaited(
            _run(context, () => vm.setHideAmounts(hide: hide)),
          ),
        ),
      ],
    );
  }
}

/// Full hours; the other end of the window is left out (equal start and end
/// would be no window).
class _HourField extends StatelessWidget {
  const _HourField({
    required this.label,
    required this.minutes,
    required this.other,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final int other;
  final ValueChanged<int> onChanged;

  static String _text(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$minutes'),
      isExpanded: true,
      initialValue: minutes - minutes % 60,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var h = 0; h < 24; h++)
          if (h * 60 != other - other % 60)
            DropdownMenuItem(value: h * 60, child: Text(_text(h * 60))),
      ],
      onChanged: (m) {
        if (m != null) onChanged(m);
      },
    );
  }
}
