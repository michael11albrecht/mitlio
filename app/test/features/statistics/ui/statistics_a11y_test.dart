import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/statistics/ui/statistics_view.dart';
import 'package:mitlio/features/statistics/ui/statistics_view_model.dart';

import '../../../helpers/a11y.dart';
import 'statistics_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6). That every bar is read out with its
/// numbers is checked in `statistics_flow_test.dart`.
void main() {
  const view = StatisticsView(groupId: 'g-1');
  final states = <String, StatisticsState>{
    'data': sampleStatistics,
    'empty': emptyStatistics,
    'error': const StatisticsFailure(Storage('x')),
  };
  for (final MapEntry(:key, :value) in states.entries) {
    forEachMode(
      key,
      () => scopedStatistics(statisticsStateOverride(value), view),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
