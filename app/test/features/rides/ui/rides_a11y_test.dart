import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/ride_calendar.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_view.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/features/rides/ui/template_form_view.dart';
import 'package:mitlio/features/rides/ui/template_form_view_model.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/a11y.dart';
import 'rides_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  group('rides tab', () {
    for (final (name, state) in <(String, RidesState)>[
      ('data', dataRides),
      ('several routes', severalTemplatesRides),
      ('route not picked', pickRouteRides),
      ('done today with a locked ride', doneTodayRides),
      ('first run', onboardingRides),
      ('no members', noMembersRides),
      ('error', const RidesFailure(Storage('x'))),
    ]) {
      forEachMode(
        name,
        () => scopedRides(
          ridesStateOverride(state),
          const RidesView(groupId: 'g-1'),
        ),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });

  forEachMode(
    'calendar',
    () => RideCalendar(
      state: dataRides,
      onPreviousMonth: () {},
      onNextMonth: () {},
      onDay: (_) {},
    ),
    (tester, _, _) => expectAccessible(tester),
  );

  group('cars and routes', () {
    for (final (name, state) in <(String, RidesSetupState)>[
      ('data', setupData),
      ('empty', setupEmpty),
      ('error', const RidesSetupFailure(Storage('x'))),
    ]) {
      forEachMode(
        name,
        () => scopedRides(
          setupStateOverride(state),
          const RidesSetupView(groupId: 'g-1'),
        ),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });

  group('vehicle form', () {
    for (final (name, state) in <(String, VehicleFormState)>[
      ('empty', vehicleFormReady()),
      (
        'filled',
        vehicleFormReady(
          name: 'Golf',
          fuel: FuelType.electric,
          consumption: 16500,
          wear: 80,
          kmRate: 300,
        ),
      ),
      ('with errors', vehicleFormReady(showErrors: true)),
    ]) {
      forEachMode(
        name,
        () => scopedRides(
          vehicleFormOverride(state),
          const VehicleFormView(groupId: 'g-1'),
        ),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });

  group('template form', () {
    for (final (name, state) in <(String, TemplateFormState)>[
      ('empty', templateFormReady()),
      (
        'filled',
        templateFormReady(
          name: 'Arbeit',
          distance: 20000,
          driver: 'm-0',
          passengers: {'m-1'},
          tolls: 250,
        ),
      ),
      ('with errors', templateFormReady(showErrors: true)),
      ('without a car', templateFormReady(vehicleId: null, vehicles: [])),
    ]) {
      forEachMode(
        name,
        () => scopedRides(
          templateFormOverride(state),
          const TemplateFormView(groupId: 'g-1'),
        ),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });
}
