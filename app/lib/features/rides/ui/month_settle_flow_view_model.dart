import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/rides/ui/ride_settle_view_model.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Step ids of the month settlement flow (PU-T12). Never rename after
/// release.
abstract final class MonthSettleStep {
  static const rides = 'rides';
  static const amounts = 'amounts';
}

String? _seen(Object answer) => answer == true ? null : 'answer must be true';

/// "Abrechnen für Oktober" as a short step flow (ADR-25 §4: monthly): look
/// at the rides of the month, look at who gets and owes what, then confirm
/// on the finish screen. The steps ask for nothing but "seen".
const monthSettleFlow = SetupFlowConfig(
  id: 'month_settle',
  steps: [
    SetupStepSpec(MonthSettleStep.rides, skippable: false, validate: _seen),
    SetupStepSpec(MonthSettleStep.amounts, skippable: false, validate: _seen),
  ],
);

/// Which month of which group is being settled.
typedef MonthSettleKey = ({String groupId, Month month});

/// The flow of one month of one group: the rides and amounts to look at
/// change with them, so progress is never shared.
SetupFlowConfig monthSettleFlowFor(MonthSettleKey key) =>
    monthSettleFlow.scopedTo('${key.groupId}:${monthKey(key.month)}');

/// Confirms the month: the one command behind the finish screen's
/// "Abrechnen" and `ext.mitlio.rides.settleFlow.confirm`. The settlement
/// itself is `RideSettleViewModel.settle`; this adds the review and clears it.
class MonthSettleFlowViewModel extends Notifier<bool> {
  MonthSettleFlowViewModel(this.key);

  final MonthSettleKey key;

  /// True while [confirm] runs, so a double tap cannot settle twice.
  @override
  bool build() => false;

  /// Settles the month, then clears the review. [Conflict] while the review
  /// is not done; [InvalidData] if there is nothing to settle; storage errors
  /// come from the repository. On a failure the review stays.
  Future<RepoResult<SettledMonth>> confirm({
    required SettlementTitle titleOf,
  }) async {
    final flow = monthSettleFlowFor(key);
    if (!ref.read(setupFlowViewModelProvider(flow)).finished) {
      return const Err(Conflict('the review is not done'));
    }
    if (state) return const Err(Conflict('already settling'));
    state = true;
    try {
      final done = await ref
          .read(rideSettleViewModelProvider(key.groupId).notifier)
          .settle(key.month, titleOf: titleOf);
      if (done is Ok) {
        // Documented reason for ignoring a failure: the month is settled
        // already; old progress only shows the finish screen again, and an
        // error would suggest the settlement was lost.
        await ref
            .read(setupStateRepositoryProvider)
            .save(flow.id, const SetupProgress());
        ref.invalidate(setupFlowViewModelProvider(flow));
      }
      return done;
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final monthSettleFlowViewModelProvider =
    NotifierProvider.family<MonthSettleFlowViewModel, bool, MonthSettleKey>(
      MonthSettleFlowViewModel.new,
    );
