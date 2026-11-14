import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/rides/ui/quick_log_card.dart';
import 'package:mitlio/features/rides/ui/ride_calendar.dart';
import 'package:mitlio/features/rides/ui/ride_settle_widgets.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Group detail, rides tab: the "Heute gefahren" card on top, the month
/// calendar (who drove which day) and the month's rides below. First run:
/// one calm prompt to set up the car and the route.
class RidesView extends ConsumerWidget {
  const RidesView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(ridesViewModelProvider(groupId).notifier);
    return Scaffold(
      body: switch (ref.watch(ridesViewModelProvider(groupId))) {
        RidesLoading() => const Center(child: CircularProgressIndicator()),
        RidesFailure() => ErrorState(onRetry: vm.retry),
        RidesLoaded(hasMembers: false) => EmptyState(
          icon: Icons.person_add_alt_outlined,
          title: l10n.membersEmptyTitle,
          message: l10n.ridesNoMembersMessage,
          action: FilledButton(
            onPressed: () =>
                DefaultTabController.maybeOf(context)?.animateTo(0),
            child: Text(l10n.expensesNoMembersAction),
          ),
        ),
        RidesLoaded(:final isOnboarding, :final vehicles) when isOnboarding =>
          EmptyState(
            icon: Icons.directions_car_outlined,
            title: l10n.ridesEmptyTitle,
            message: l10n.ridesEmptyMessage,
            action: FilledButton(
              // Car first, then the route: the vehicle form hands over to the
              // template form.
              onPressed: () => unawaited(
                context.push(
                  vehicles.isEmpty
                      ? '/groups/$groupId/rides/vehicles/new?next=template'
                      : '/groups/$groupId/rides/templates/new',
                ),
              ),
              child: Text(
                vehicles.isEmpty
                    ? l10n.ridesEmptyActionVehicle
                    : l10n.ridesEmptyActionTemplate,
              ),
            ),
          ),
        final RidesLoaded loaded => _RidesBody(
          groupId: groupId,
          state: loaded,
          vm: vm,
        ),
      },
    );
  }
}

class _RidesBody extends StatelessWidget {
  const _RidesBody({
    required this.groupId,
    required this.state,
    required this.vm,
  });

  final String groupId;
  final RidesLoaded state;
  final RidesViewModel vm;

  Future<void> _delete(BuildContext context, RideEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await vm.deleteRide(entry.ride.id);
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: l10n.ridesRideDeleted,
          undo: value,
        );
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entries = state.monthEntries.reversed.toList();
    final plan = state.settlementPlan;
    return ListView(
      padding: Spacing.screen,
      children: [
        if (state.quick != null)
          QuickLogCard(groupId: groupId, state: state, vm: vm),
        if (plan != null && state.isMonthOver) ...[
          const SizedBox(height: Spacing.md),
          SettleCard(
            plan: plan,
            onOpen: () => unawaited(showRideSettleSheet(context, groupId)),
          ),
        ],
        const SizedBox(height: Spacing.md),
        RideCalendar(
          state: state,
          onSettle: plan == null
              ? null
              : () => unawaited(showRideSettleSheet(context, groupId)),
          onPreviousMonth: () => vm.shiftMonth(-1),
          onNextMonth: () => vm.shiftMonth(1),
          onDay: (day) => unawaited(_openDay(context, day)),
        ),
        const SizedBox(height: Spacing.sm),
        if (entries.isNotEmpty) ...[
          FairnessSection(state: state),
          const SizedBox(height: Spacing.md),
        ],
        if (entries.isEmpty)
          Padding(
            padding: Spacing.allMd,
            child: Text(
              l10n.ridesMonthEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final entry in entries)
            RideRow(
              key: ValueKey(entry.ride.id),
              state: state,
              entry: entry,
              onDelete: () => unawaited(_delete(context, entry)),
            ),
      ],
    );
  }

  Future<void> _openDay(BuildContext context, DateTime day) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _DaySheet(groupId: groupId, day: day),
      );
}

/// One logged ride: who drove, how far, who rode along, what it cost. Swipe
/// to delete (undo in the snackbar); rides of a settled period are locked.
class RideRow extends StatelessWidget {
  const RideRow({
    required this.state,
    required this.entry,
    required this.onDelete,
    super.key,
  });

  final RidesLoaded state;
  final RideEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ride = entry.ride;
    final driver = state.member(ride.driverId);
    final passengers = [
      for (final m in state.members)
        if (ride.passengerIds.contains(m.id)) m.name,
    ];
    final summary = state.summary(entry);
    final date = MaterialLocalizations.of(context).formatMediumDate(ride.date);
    final subtitle = passengers.isEmpty
        ? date
        : '$date · ${l10n.ridesRidePassengers(passengers.join(', '))}';
    final tile = Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: ListTile(
        leading: MemberAvatar(
          memberId: ride.driverId,
          name: driver?.name ?? '',
        ),
        title: Text(
          l10n.ridesRideTitle(
            driver?.name ?? '',
            distanceText(
              context,
              ride.distanceMeters,
              roundTrip: ride.roundTrip,
            ),
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (summary != null)
              MoneyText(
                cents: summary.totalCents,
                currency: state.group.currency,
                style: theme.textTheme.titleSmall,
              ),
            if (entry.isSettled) ...[
              const SizedBox(width: Spacing.sm),
              Semantics(
                label: l10n.ridesLocked,
                image: true,
                excludeSemantics: true,
                child: Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
    if (entry.isSettled) return tile;
    return ClipRRect(
      borderRadius: Radii.mdAll,
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.ridesRideDelete): onDelete,
        },
        child: Dismissible(
          key: ValueKey('dismiss-${ride.id}'),
          direction: DismissDirection.endToStart,
          // The list removes the row itself (and brings it back if the delete
          // fails), so the swipe never "completes" on its own.
          confirmDismiss: (_) async {
            onDelete();
            return false;
          },
          background: ColoredBox(
            color: scheme.errorContainer,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.delete_outline,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ),
          child: tile,
        ),
      ),
    );
  }
}

/// Bottom sheet of one calendar day: its rides (delete with undo, lock for
/// settled ones) or, if empty, the way to log a ride for that day.
class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.groupId, required this.day});

  final String groupId;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = ref.read(ridesViewModelProvider(groupId).notifier);
    final state = ref.watch(ridesViewModelProvider(groupId));
    if (state is! RidesLoaded) return const SizedBox.shrink();
    final entries = state.entriesOn(day);
    final date = MaterialLocalizations.of(context).formatFullDate(day);
    return SafeArea(
      child: SingleChildScrollView(
        padding: Spacing.screen.copyWith(top: Spacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(date, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: Spacing.sm),
            if (entries.isEmpty)
              Text(
                l10n.ridesDayNoRides,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            for (final entry in entries)
              RideRow(
                key: ValueKey('sheet-${entry.ride.id}'),
                state: state,
                entry: entry,
                onDelete: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await vm.deleteRide(entry.ride.id);
                  if (!context.mounted) return;
                  switch (result) {
                    case Ok(:final value):
                      showUndoSnackBar(
                        context,
                        message: l10n.ridesRideDeleted,
                        undo: value,
                      );
                    case Err():
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.errorTitle)),
                      );
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            if (state.quick != null) ...[
              const SizedBox(height: Spacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    vm.setDate(day);
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.ridesDayLog),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
