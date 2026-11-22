import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/ui/driver_prompt_sheet.dart';
import 'package:mitlio/features/rides/ui/month_settle_view.dart';
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
import '../../../helpers/themed_app.dart';
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
      ('settlement due', settleDueRides),
      ('a non-driver in the fairness card', nonDriverRides),
      ('month settled', settledMonthRides),
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

  testWidgets('calendar days announce who drove', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      themedApp(
        RideCalendar(
          state: dataRides,
          onPreviousMonth: () {},
          onNextMonth: () {},
          onDay: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Mo\., 2\. März, Anna Berg ist gefahren$'),
      ),
      findsWidgets,
    );
    semantics.dispose();
  });

  group('month settlement flow', () {
    final month = settleDueRides.month;
    for (final (name, state, progress)
        in <(String, RidesLoaded, List<Override>)>[
          ('rides', settleDueRides, monthSettleProgress(month)),
          ('amounts', settleDueRides, monthSettleProgress(month, step: 1)),
          (
            'confirm',
            settleDueRides,
            monthSettleProgress(month, finished: true),
          ),
          ('nothing to settle', settledMonthRides, monthSettleProgress(month)),
        ]) {
      forEachMode(
        name,
        () => scopedRides([
          ...ridesStateOverride(state),
          ...progress,
        ], const MonthSettleView(groupId: 'g-1')),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });

  group('cars and routes', () {
    for (final (name, state) in <(String, RidesSetupState)>[
      ('data', setupData),
      ('with a non-driver', setupNonDriver),
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

  forEachMode(
    'driver prompt sheet',
    () => const DriverPromptSheet(name: 'Chiara Rossi', rides: 5),
    (tester, _, _) => expectAccessible(tester),
  );

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
      (
        'with car suggestions',
        vehicleFormReady(
          name: 'Golf',
          suggestions: sampleCatalogEntries.take(3).toList(),
        ),
      ),
      (
        'after a catalog pick',
        vehicleFormReady(
          name: 'VW Golf',
          consumption: 5600,
          fromCatalog: sampleCatalogEntries.first,
        ),
      ),
      (
        'after taking the realistic value',
        vehicleFormReady(
          name: 'VW Golf',
          consumption: 6720,
          fromCatalog: sampleCatalogEntries.first,
          realisticApplied: true,
        ),
      ),
      (
        'electric catalog pick',
        vehicleFormReady(
          name: 'Tesla Model 3',
          fuel: FuelType.electric,
          consumption: 14900,
          fromCatalog: sampleCatalogEntries.last,
        ),
      ),
      ('no catalog match', vehicleFormReady(name: 'Trabant', noMatch: true)),
      (
        'catalog unavailable',
        vehicleFormReady(name: 'Golf', catalogUnavailable: true),
      ),
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
