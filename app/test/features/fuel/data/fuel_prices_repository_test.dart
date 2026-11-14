import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_prices_repository.dart';
import 'package:mitlio/features/fuel/data/services/fake_fuel_price_service.dart';
import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart';
import 'package:mitlio/features/fuel/data/services/location_service.dart';

void main() {
  late FixedClock clock;
  late FakeFuelPriceService service;
  late FakeLocationService location;
  late FuelPricesRepository repo;

  FuelPricesRepository build({
    FuelPriceService? svc,
    LocationService? loc,
  }) => FuelPricesRepository(
    service: svc ?? service,
    location: loc ?? location,
    clock: clock,
  );

  setUp(() {
    clock = FixedClock(DateTime.utc(2026, 11, 14, 12));
    service = FakeFuelPriceService(now: clock.now);
    location = FakeLocationService();
    repo = build();
  });

  test('national average asks without any area and never locates', () async {
    final outcome = await repo.national(FuelGrade.e5);
    expect(outcome, isA<FuelFound>());
    final price = (outcome as FuelFound).price;
    expect(price.priceMilli, 1799);
    expect(price.scope, FuelScope.national);
    expect(service.calls.single.area, isNull);
    expect(location.asked, 0);
  });

  test('no backend: unavailable, nothing is requested', () async {
    final off = build(svc: const UnavailableFuelPriceService());
    expect(off.isAvailable, isFalse);
    expect(off.canLocate, isFalse);
    expect(
      (await off.national(FuelGrade.e5) as FuelMissing).reason,
      FuelFailure.unavailable,
    );
  });

  test('a fresh price is reused, an old one asked again', () async {
    await repo.national(FuelGrade.e5);
    await repo.national(FuelGrade.e5);
    expect(service.calls, hasLength(1));
    clock.advance(const Duration(minutes: 2));
    await repo.national(FuelGrade.e5);
    expect(service.calls, hasLength(2));
  });

  test('offline falls back to the last known value, marked stale', () async {
    await repo.national(FuelGrade.diesel);
    clock.advance(const Duration(minutes: 5));
    service.failWith = FuelFailure.offline;
    final outcome = await repo.national(FuelGrade.diesel) as FuelFound;
    expect(outcome.stale, isTrue);
    expect(outcome.price.priceMilli, 1659);
  });

  test('offline without a last known value reports why', () async {
    service.failWith = FuelFailure.offline;
    final outcome = await repo.national(FuelGrade.e10) as FuelMissing;
    expect(outcome.reason, FuelFailure.offline);
  });

  test('a postcode must have five digits', () async {
    expect(
      (await repo.forPlz(FuelGrade.e5, '1011') as FuelMissing).reason,
      FuelFailure.invalidParams,
    );
    expect(service.calls, isEmpty);
    final ok = await repo.forPlz(FuelGrade.e5, '10115') as FuelFound;
    expect(ok.price.scope, FuelScope.plz);
    expect((service.calls.single.area! as PlzArea).plz, '10115');
  });

  group('location opt-in', () {
    test('only nearby() asks for the position, then looks around it', () async {
      final outcome = await repo.nearby(FuelGrade.e5) as FuelFound;
      expect(location.asked, 1);
      expect(outcome.price.scope, FuelScope.nearby);
      final area = service.calls.single.area! as NearbyArea;
      expect(area.lat, 52.52);
    });

    test('denied: no request to the backend', () async {
      location.result = const LocationDenied();
      final outcome = await repo.nearby(FuelGrade.e5) as FuelMissing;
      expect(outcome.reason, FuelFailure.locationDenied);
      expect(service.calls, isEmpty);
    });

    test('position not found', () async {
      location.result = const LocationUnavailable();
      expect(
        (await repo.nearby(FuelGrade.e5) as FuelMissing).reason,
        FuelFailure.locationUnavailable,
      );
    });

    test('not offered without a location plugin', () async {
      final noLoc = build(loc: const NoLocationService());
      expect(noLoc.canLocate, isFalse);
      expect(
        (await noLoc.nearby(FuelGrade.e5) as FuelMissing).reason,
        FuelFailure.locationUnavailable,
      );
    });

    test('503 from the backend switches the option off', () async {
      expect(repo.canLocate, isTrue);
      service.failWith = FuelFailure.provider;
      await repo.nearby(FuelGrade.e5);
      expect(repo.canLocate, isFalse);
    });

    test(
      'the cache holds no coordinates: a second spot is asked anew',
      () async {
        await repo.nearby(FuelGrade.e5);
        location.result = const LocationFound(lat: 48.1, lng: 11.5);
        clock.advance(const Duration(seconds: 10));
        await repo.nearby(FuelGrade.e5);
        // Reused within the minute, by scope only.
        expect(service.calls, hasLength(1));
      },
    );
  });
}
