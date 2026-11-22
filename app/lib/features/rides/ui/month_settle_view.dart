import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/step_icon_visual.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/rides/ui/month_settle_flow_view_model.dart';
import 'package:mitlio/features/rides/ui/ride_settle_widgets.dart';
import 'package:mitlio/features/rides/ui/ride_settlement.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart'
    show formatMilli;
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Abrechnen für Oktober" in two looks and a confirmation (PU-T12, ADR-25
/// §4): the rides of the month, who gets and owes what, then the finish
/// screen with the one button that settles. No celebration: a settlement is
/// bookkeeping. Settling goes back to the rides tab and offers undo.
class MonthSettleView extends ConsumerWidget {
  const MonthSettleView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(ridesViewModelProvider(groupId));
    switch (state) {
      case RidesLoading():
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case RidesFailure():
        return Scaffold(
          appBar: AppBar(),
          body: ErrorState(
            onRetry: ref.read(ridesViewModelProvider(groupId).notifier).retry,
          ),
        );
      case final RidesLoaded loaded:
        final plan = loaded.settlementPlan;
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                l10n.ridesSettleTitle(monthName(context, loaded.month)),
              ),
            ),
            body: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.ridesSettleTitle(monthName(context, loaded.month)),
              message: l10n.ridesSettleNothing,
            ),
          );
        }
        return _Flow(groupId: groupId, state: loaded, plan: plan);
    }
  }
}

class _Flow extends ConsumerWidget {
  const _Flow({
    required this.groupId,
    required this.state,
    required this.plan,
  });

  final String groupId;
  final RidesLoaded state;
  final SettlementPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = MoneyFormat.of(context);
    final key = (groupId: groupId, month: state.month);
    final monthLabel = monthName(context, state.month);
    final order = [for (final m in state.members) m.id];

    Future<void> confirm() async {
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      final period = monthYearName(context, state.month);
      final result = await ref
          .read(monthSettleFlowViewModelProvider(key).notifier)
          .confirm(
            titleOf: (name, _) => l10n.ridesSettleExpenseTitle(period, name),
          );
      switch (result) {
        case Ok(:final value):
          if (!context.mounted) return;
          // The messenger outlives this screen: undo stays on offer.
          showUndoSnackBar(
            context,
            message: l10n.ridesSettleDone(monthLabel),
            undo: value.undo,
          );
          router.pop();
        case Err(error: Conflict()):
          break; // The first tap is already on its way.
        case Err(:final error):
          showErrorSnackBar(messenger, l10n, error);
      }
    }

    return SetupFlowView(
      config: monthSettleFlowFor(key),
      stepBuilder: (context, s) => switch (s.step.id) {
        MonthSettleStep.rides => StepScaffold(
          current: s.current,
          total: s.total,
          title: l10n.monthSettleRidesTitle(monthLabel),
          visual: const StepIconVisual(Icons.directions_car_outlined),
          onNext: () => s.onNext(true),
          onBack: s.onBack,
          result: Text(
            l10n.ridesSettleCardTitle(monthLabel, plan.rideCount),
            style: theme.textTheme.titleMedium,
          ),
          child: Column(
            children: [
              for (final row in state.fairness)
                MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                    child: Row(
                      children: [
                        MemberAvatar(
                          memberId: row.memberId,
                          name: state.member(row.memberId)?.name ?? '',
                          size: Sizes.avatarSmall,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(state.member(row.memberId)?.name ?? ''),
                              Text(
                                l10n.ridesFairnessKm(
                                  formatMilli(
                                    row.metersDriven,
                                    separator: money.decimalSeparator,
                                  ),
                                  formatMilli(
                                    row.metersRidden,
                                    separator: money.decimalSeparator,
                                  ),
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _ => StepScaffold(
          current: s.current,
          total: s.total,
          title: l10n.monthSettleAmountsTitle,
          visual: const StepIconVisual(Icons.payments_outlined),
          onNext: () => s.onNext(true),
          onBack: s.onBack,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final driver in plan.drivers)
                SettleDriverBlock(
                  line: l10n.ridesSettleDriverLine(
                    state.member(driver.driverId)?.name ?? '',
                    money.format(driver.getsCents, state.group.currency),
                    driver.rideCount,
                  ),
                  driverId: driver.driverId,
                  driverName: state.member(driver.driverId)?.name ?? '',
                  state: state,
                  shares: driver.sharesOf(order),
                ),
            ],
          ),
        ),
      },
      finishBuilder: (context, back) => FinishStep(
        title: l10n.ridesSettleTitle(monthLabel),
        celebrate: false,
        summary: [
          l10n.monthSettleSummaryRides(plan.rideCount),
          l10n.monthSettleSummaryExpenses(plan.drivers.length),
        ],
        content: Text(
          l10n.ridesSettleNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actionLabel: l10n.ridesSettleAction,
        onAction: () => unawaited(confirm()),
        onBack: back,
      ),
    );
  }
}
