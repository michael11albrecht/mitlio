import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/statistics/ui/statistics_view.dart';
import 'package:mitlio/features/statistics/ui/statistics_view_model.dart';

import '../features/statistics/ui/statistics_fixtures.dart';
import 'golden_matrix.dart';

const _width = 360.0;

Widget _view(StatisticsState s) => scopedStatistics(
  statisticsStateOverride(s),
  const StatisticsView(groupId: 'g-1'),
);

Future<void> main() async {
  Future<void> golden(
    String name,
    StatisticsState state, {
    double height = 760,
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => _view(state),
    width: _width,
    height: height,
    pumpBeforeTest: pump,
  );

  await golden('statistics_loading', const StatisticsLoading(), pump: pumpOnce);
  await golden('statistics_empty', emptyStatistics);
  await golden('statistics_error', const StatisticsFailure(Storage('x')));
  // Tall enough for the whole list, at text scale 2.0 too.
  await golden('statistics_data', sampleStatistics, height: 3400);
}
