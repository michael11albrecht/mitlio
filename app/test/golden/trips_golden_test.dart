import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/trips/ui/trip_form_view.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart';

import '../features/trips/ui/trips_fixtures.dart';
import 'golden_matrix.dart';

const _height = 720.0;
const _width = 360.0;

Widget _form(TripFormState s) =>
    tripScoped(tripStateOverride(s), const TripFormView(groupId: 'g-1'));

Future<void> main() async {
  Future<void> golden(
    String name,
    TripFormState state, {
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => _form(state),
    width: _width,
    height: _height,
    pumpBeforeTest: pump,
  );

  await golden('trip_form_loading', const TripFormLoading(), pump: pumpOnce);
  await golden('trip_form_error', const TripFormFailure(Storage('x')));
  await golden('trip_form_no_members', tripNoMembers);
  await golden('trip_form_empty', tripEmpty);
  await golden('trip_form_result', tripResult);
  await golden('trip_form_km_rate', tripKmRate);
  await golden('trip_form_invalid', tripInvalid);
  await golden('trip_form_nobody', tripNobody);
}
