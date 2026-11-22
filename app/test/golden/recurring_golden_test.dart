import 'package:alchemist/alchemist.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/recurring/ui/recurring_view.dart';
import 'package:mitlio/features/recurring/ui/recurring_view_model.dart';

import '../features/recurring/ui/recurring_fixtures.dart';
import 'golden_matrix.dart';

const _width = 360.0;
const _height = 640.0;

Future<void> main() async {
  Future<void> list(
    String name,
    RecurringState state, {
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => scopedRecurring(state, const RecurringView(groupId: 'g-1')),
    width: _width,
    height: _height,
    pumpBeforeTest: pump,
  );

  await list('recurring_loading', const RecurringLoading(), pump: pumpOnce);
  await list('recurring_error', const RecurringFailure(Storage('x')));
  await list('recurring_empty', emptyRecurring);
  await list('recurring_rules', sampleRecurring);
}
