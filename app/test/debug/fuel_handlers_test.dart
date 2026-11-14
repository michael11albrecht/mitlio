import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/fuel.dart';
import 'package:mitlio/features/fuel/data/fuel_price.dart' show FuelFailure;

import '../helpers/fake_app.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;

  setUp(() {
    app = FakeApp();
    container = app.container(extra: app.fuelBackendOverrides);
    addTearDown(container.dispose);
    h = fuelDriveHandlers(container);
  });

  test('fuel.prices returns the national value from the service', () async {
    final r = await h['fuel.prices']!({'type': 'diesel'});
    expect(r['priceMilli'], 1659);
    expect(r['scope'], 'national');
    expect(r['stale'], false);
    expect(app.fuel.calls.single.area, isNull);
    expect(app.location.asked, 0);
  });

  test('fuel.prices rejects an unknown type', () async {
    expect(
      (await h['fuel.prices']!({'type': 'lpg'}))['error'],
      'invalid_params',
    );
    expect((await h['fuel.prices']!({}))['error'], 'invalid_params');
  });

  test('fuel.prices reports why there is no price', () async {
    app.fuel.failWith = FuelFailure.offline;
    expect((await h['fuel.prices']!({'type': 'e5'}))['error'], 'offline');
  });

  test('without a backend: unavailable', () async {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);
    final r = await fuelDriveHandlers(bare)['fuel.prices']!({'type': 'e5'});
    expect(r['error'], 'unavailable');
  });
}
