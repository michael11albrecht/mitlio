import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/fakes/fake_route_distance_service.dart';
import 'package:mitlio/debug/handlers/routes.dart';
import 'package:mitlio/features/routes/data/route_models.dart';

import '../helpers/fake_app.dart';

const PlaceSuggestion _ka = FakeRouteDistanceService.karlsruhe;
const PlaceSuggestion _st = FakeRouteDistanceService.stuttgart;
const PlaceSuggestion _be = FakeRouteDistanceService.berlin;

Map<String, String> _pair(
  PlaceSuggestion from,
  PlaceSuggestion to,
) => {
  'fromLabel': from.label,
  'fromLat': '${from.lat}',
  'fromLng': '${from.lng}',
  'toLabel': to.label,
  'toLat': '${to.lat}',
  'toLng': '${to.lng}',
};

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;

  setUp(() {
    app = FakeApp();
    container = app.container(extra: app.routeOverrides);
    addTearDown(container.dispose);
    h = routeDriveHandlers(container);
  });

  test('route.suggest returns suggestions and the credit line', () async {
    final r = await h['route.suggest']!({'text': 'Karls', 'field': 'start'});
    expect(r['suggestions'], [
      {'label': _ka.label, 'lat': _ka.lat, 'lng': _ka.lng},
    ]);
    expect(r['failure'], isNull);
    expect(r['attribution'], FakeRouteDistanceService.attribution);
    expect(app.route.calls, ['suggest:Karls']);
  });

  test('route.suggest rejects missing text and an unknown field', () async {
    expect((await h['route.suggest']!({}))['error'], 'invalid_params');
    expect(
      (await h['route.suggest']!({'text': 'abc', 'field': 'middle'}))['error'],
      'invalid_params',
    );
  });

  test('route.suggest reports why there is nothing', () async {
    app.route
      ..failWith = RouteFailure.rateLimited
      ..failRetryAfter = const Duration(minutes: 5);
    final r = await h['route.suggest']!({'text': 'Karls'});
    expect(r['failure'], 'rateLimited');
    expect(r['retryAfterMinutes'], 5);
  });

  test('route.distance runs the ViewModel: picks, calculates, fills', () async {
    final r = await h['route.distance']!(_pair(_ka, _st));
    expect(r['meters'], 81000);
    expect(r['fillMeters'], 81000);
    expect(r['start'], _ka.label);
    expect(r['end'], _st.label);
    expect(r['failure'], isNull);
  });

  test('route.distance validates its params', () async {
    expect((await h['route.distance']!({}))['error'], 'invalid_params');
    final bad = _pair(_ka, _st)..['toLat'] = 'north';
    expect((await h['route.distance']!(bad))['error'], 'invalid_params');
  });

  test('scenario: pick, edit the km, pick again: stays; recalculate', () async {
    await h['route.distance']!(_pair(_ka, _st));
    final edited = await h['route.manualEdit']!({});
    expect(edited['manualOverride'], isTrue);
    final again = await h['route.distance']!(_pair(_ka, _be));
    expect(again['fillMeters'], 81000, reason: 'the hand edit stays');
    expect(again['canRecalculate'], isTrue);
    final redone = await h['route.recalculate']!({});
    expect(redone['fillMeters'], 650400);
    expect(redone['manualOverride'], isFalse);
  });

  test('failures are reported by name', () async {
    app.route.failWith = RouteFailure.offline;
    final r = await h['route.distance']!(_pair(_ka, _st));
    expect(r['failure'], 'offline');
    expect(r['meters'], isNull);
  });

  test('route.reset starts over', () async {
    await h['route.distance']!(_pair(_ka, _st));
    await h['route.reset']!({});
    final r = await h['route.recalculate']!({});
    expect(r['start'], isNull);
  });

  test('without a backend: unavailable', () async {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);
    final r = await routeDriveHandlers(bare)['route.suggest']!({
      'text': 'Karls',
    });
    expect(r['available'], isFalse);
    expect(r['failure'], 'unavailable');
  });
}
