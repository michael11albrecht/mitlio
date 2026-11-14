import 'package:alchemist/alchemist.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/ride_calendar.dart';
import 'package:mitlio/features/rides/ui/ride_settle_widgets.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_view.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/features/rides/ui/template_form_view.dart';
import 'package:mitlio/features/rides/ui/template_form_view_model.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';

import '../features/rides/ui/rides_fixtures.dart';
import 'golden_matrix.dart';

const _width = 360.0;
const _tabHeight = 1100.0;
const _formHeight = 900.0;

Future<void> main() async {
  Future<void> tab(
    String name,
    RidesState state, {
    double height = _tabHeight,
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => scopedRides(
      ridesStateOverride(state),
      const RidesView(groupId: 'g-1'),
    ),
    width: _width,
    height: height,
    pumpBeforeTest: pump,
  );

  Future<void> setup(String name, RidesSetupState state) => matrixGolden(
    name,
    () => scopedRides(
      setupStateOverride(state),
      const RidesSetupView(groupId: 'g-1'),
    ),
    width: _width,
    height: 640,
  );

  Future<void> vehicleForm(String name, VehicleFormState state) => matrixGolden(
    name,
    () => scopedRides(
      vehicleFormOverride(state),
      const VehicleFormView(groupId: 'g-1'),
    ),
    width: _width,
    height: _formHeight,
  );

  Future<void> templateForm(String name, TemplateFormState state) =>
      matrixGolden(
        name,
        () => scopedRides(
          templateFormOverride(state),
          const TemplateFormView(groupId: 'g-1'),
        ),
        width: _width,
        height: _formHeight + 300,
      );

  await tab('rides_loading', const RidesLoading(), pump: pumpOnce);
  await tab(
    'rides_error',
    const RidesFailure(Storage('x')),
    height: 480,
  );
  await tab('rides_onboarding', onboardingRides, height: 480);
  await tab('rides_no_members', noMembersRides, height: 480);
  // The quick log card in its states, with the calendar and list below.
  await tab('rides_data', dataRides);
  await tab('rides_pick_route', pickRouteRides);
  await tab('rides_done_today', doneTodayRides);
  // Period settlement (P3r-T06) and the fairness view (P3r-T07).
  await tab('rides_settle_due', settleDueRides, height: 1500);
  await tab('rides_settled_month', settledMonthRides);
  for (final (name, state) in [
    ('ride_settle_sheet', settleDueRides),
    ('ride_settle_sheet_nothing', settledMonthRides),
  ]) {
    await matrixGolden(
      name,
      () => scopedRides(
        ridesStateOverride(state),
        const RideSettleSheet(groupId: 'g-1'),
      ),
      width: _width,
      height: 820,
    );
  }

  await matrixGolden(
    'ride_calendar',
    () => RideCalendar(
      state: dataRides,
      onPreviousMonth: () {},
      onNextMonth: () {},
      onDay: (_) {},
    ),
    width: _width,
    height: 520,
  );

  await setup('rides_setup_data', setupData);
  await setup('rides_setup_empty', setupEmpty);

  await vehicleForm('vehicle_form_empty', vehicleFormReady());
  await vehicleForm(
    'vehicle_form_filled',
    vehicleFormReady(
      name: 'Golf',
      consumption: 6500,
      wear: 80,
      kmRate: 300,
    ),
  );
  await vehicleForm(
    'vehicle_form_error',
    vehicleFormReady(showErrors: true),
  );

  await templateForm('template_form_empty', templateFormReady());
  await templateForm(
    'template_form_filled',
    templateFormReady(
      name: 'Arbeit',
      distance: 20000,
      driver: 'm-0',
      passengers: {'m-1'},
      tolls: 250,
    ),
  );
  await templateForm(
    'template_form_error',
    templateFormReady(showErrors: true),
  );
}
