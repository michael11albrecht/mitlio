import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/debug/fakes/fake_route_distance_service.dart';
import 'package:mitlio/features/routes/ui/route_distance_panel.dart';
import 'package:mitlio/features/routes/ui/route_distance_view_model.dart';

/// A view model that holds one fixed state, for goldens and a11y tests.
class StubRouteDistanceViewModel extends RouteDistanceViewModel {
  StubRouteDistanceViewModel(this.fixed);

  final RouteDistanceState fixed;

  @override
  RouteDistanceState build() => fixed;
}

List<Override> routeStateOverride(RouteDistanceState state) => [
  routeDistanceViewModelProvider.overrideWith(
    () => StubRouteDistanceViewModel(state),
  ),
];

/// The panel as it sits under a kilometre field.
Widget routePanelHost(RouteDistanceState state, {bool open = true}) =>
    ProviderScope(
      overrides: routeStateOverride(state),
      // Scrollable like the forms it sits in.
      child: SingleChildScrollView(
        padding: Spacing.screen,
        child: RouteDistancePanel(onFill: (_) {}, initiallyOpen: open),
      ),
    );

const PlaceSuggestion _ka = FakeRouteDistanceService.karlsruhe;
const PlaceSuggestion _st = FakeRouteDistanceService.stuttgart;
const String _credit = FakeRouteDistanceService.attribution;

/// Nothing typed yet.
const routeEmpty = RouteDistanceState(available: true);

/// Typing in "Start": suggestions below the field.
const routeSuggesting = RouteDistanceState(
  available: true,
  active: RouteField.start,
  suggestions: [
    _ka,
    PlaceSuggestion(
      label: 'Karlsdorf-Neuthard, Baden-Württemberg, Deutschland',
      lat: 49.2,
      lng: 8.5,
    ),
  ],
  searched: true,
  attribution: _credit,
);

/// Both places picked and the distance known, home not yet saved.
const routeResult = RouteDistanceState(
  available: true,
  start: _ka,
  end: _st,
  meters: 81234,
  calculatedFor: (_ka, _st),
  attribution: _credit,
);

/// A result with saved places offered as quick picks.
const routeSaved = RouteDistanceState(
  available: true,
  start: _ka,
  end: _st,
  meters: 81234,
  calculatedFor: (_ka, _st),
  attribution: _credit,
  saved: [
    SavedPlace(kind: PlaceKind.home, place: _ka),
    SavedPlace(kind: PlaceKind.work, place: _st),
  ],
);

/// The kilometres were typed by hand: "Neu berechnen" is offered.
const routeEdited = RouteDistanceState(
  available: true,
  start: _ka,
  end: _st,
  meters: 81234,
  calculatedFor: (_ka, _st),
  manualOverride: true,
  attribution: _credit,
);

RouteDistanceState _failed(RouteFailure f, {Duration? wait}) =>
    RouteDistanceState(
      available: true,
      start: _ka,
      end: _st,
      failure: f,
      retryAfter: wait,
    );

final RouteDistanceState routeOffline = _failed(RouteFailure.offline);
final RouteDistanceState routeRateLimited = _failed(
  RouteFailure.rateLimited,
  wait: const Duration(minutes: 3),
);
final RouteDistanceState routeNoRoute = _failed(RouteFailure.noRoute);
final RouteDistanceState routeDown = _failed(RouteFailure.provider);
