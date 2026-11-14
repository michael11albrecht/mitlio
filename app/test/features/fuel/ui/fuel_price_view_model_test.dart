import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/fuel/data/fuel_price.dart';
import 'package:mitlio/features/fuel/data/services/location_service.dart';
import 'package:mitlio/features/fuel/ui/fuel_price_view_model.dart';

import '../../../helpers/fake_app.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;
  late ProviderSubscription<FuelPriceState> sub;
  var grade = FuelGrade.e5;

  FuelPriceState state() => container.read(fuelPriceViewModelProvider(grade));
  FuelPriceViewModel vm() =>
      container.read(fuelPriceViewModelProvider(grade).notifier);

  Future<void> start({bool configured = true}) async {
    app.fuel.configured = configured;
    container = ProviderContainer(
      overrides: [
        ...app.fuelOverrides,
      ],
    );
    addTearDown(container.dispose);
    // Keeps the autoDispose ViewModel alive for the test.
    sub = container.listen(fuelPriceViewModelProvider(grade), (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    app = FakeApp();
    grade = FuelGrade.e5;
  });

  test('no backend: hidden, nothing requested', () async {
    await start(configured: false);
    expect(state().available, isFalse);
    expect(app.fuel.calls, isEmpty);
  });

  test(
    'starts on the national average of the vehicle grade, no location',
    () async {
      grade = FuelGrade.diesel;
      await start();
      expect(state().available, isTrue);
      expect(state().grade, FuelGrade.diesel);
      expect(state().price!.priceMilli, 1659);
      expect(state().scope, FuelScope.national);
      expect(app.fuel.calls.single.area, isNull);
      expect(app.location.asked, 0);
      // The pre-selected price is an automatic fill, not a tap.
      expect(state().fill!.auto, isTrue);
      expect(state().age, const Duration(minutes: 12));
    },
  );

  test('a chip tap selects the grade and fills its price', () async {
    await start();
    await vm().selectGrade(FuelGrade.e10);
    expect(state().grade, FuelGrade.e10);
    expect(state().fill!.priceMilli, 1739);
    expect(state().fill!.auto, isFalse);
  });

  test('every fill has a new sequence number', () async {
    await start();
    final first = state().fill!.seq;
    app.clock.advance(const Duration(minutes: 5));
    await vm().selectGrade(FuelGrade.e5);
    expect(state().fill!.seq, greaterThan(first));
  });

  test(
    'offline: the last known value stays, marked stale, with its age',
    () async {
      await start();
      app.clock.advance(const Duration(hours: 3));
      app.fuel.failWith = FuelFailure.offline;
      await vm().selectGrade(FuelGrade.e5);
      expect(state().stale, isTrue);
      expect(state().price!.priceMilli, 1799);
      expect(state().age, const Duration(hours: 3, minutes: 12));
      expect(state().failure, isNull);
    },
  );

  test('offline without anything known: a failure and no fill', () async {
    app.fuel.failWith = FuelFailure.offline;
    await start();
    expect(state().price, isNull);
    expect(state().failure, FuelFailure.offline);
    expect(state().fill, isNull);
  });

  test('postcode: valid is used, malformed changes nothing', () async {
    await start();
    await vm().usePlz('1011');
    expect(state().failure, FuelFailure.invalidParams);
    expect(state().scope, FuelScope.national);
    await vm().usePlz('10115');
    expect(state().scope, FuelScope.plz);
    expect(state().price!.scopeKey, '10115');
    await vm().useNational();
    expect(state().scope, FuelScope.national);
  });

  group('location opt-in', () {
    test('is offered but never used until the user taps', () async {
      await start();
      expect(state().canLocate, isTrue);
      expect(app.location.asked, 0);
    });

    test('tap: permission asked now, nearby average used', () async {
      await start();
      await vm().useNearby();
      expect(app.location.asked, 1);
      expect(state().scope, FuelScope.nearby);
      expect(state().price!.scope, FuelScope.nearby);
      expect(state().fill!.auto, isFalse);
    });

    test('denied: national stays, calm hint', () async {
      await start();
      app.location.result = const LocationDenied();
      await vm().useNearby();
      expect(state().scope, FuelScope.national);
      expect(state().failure, FuelFailure.locationDenied);
      expect(state().price!.scope, FuelScope.national);
    });

    test('permanently denied: calm hint, no second prompt', () async {
      await start();
      app.location.result = const LocationDeniedForever();
      await vm().useNearby();
      await vm().useNearby();
      expect(state().scope, FuelScope.national);
      expect(state().failure, FuelFailure.locationBlocked);
      expect(app.location.asked, 1);
    });

    test('rounds the position to 2 decimals before the request', () async {
      await start();
      app.location.result = const LocationFound(lat: 48.137154, lng: 11.576124);
      await vm().useNearby();
      final area = app.fuel.calls.last.area! as NearbyArea;
      expect((area.lat, area.lng), (48.14, 11.58));
    });

    test('provider_unconfigured: option disappears', () async {
      await start();
      app.fuel.failWith = FuelFailure.providerUnconfigured;
      await vm().useNearby();
      expect(state().canLocate, isFalse);
    });
  });

  test('debugSnapshot', () async {
    await start();
    expect(vm().debugSnapshot(), {
      'available': true,
      'grade': 'e5',
      'scope': 'national',
      'priceMilli': 1799,
      'stale': false,
      'failure': null,
    });
  });
}
