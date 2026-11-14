import 'package:mitlio/features/fuel/data/fuel_price.dart';
import 'package:mitlio/features/fuel/data/services/fuel_price_service.dart';

/// In-memory price API for tests and DebugDrive: fixed prices per grade, a
/// switch for failures, and a log of what was asked.
class FakeFuelPriceService implements FuelPriceService {
  FakeFuelPriceService({
    required this.now,
    this.prices = const {
      FuelGrade.e5: 1799,
      FuelGrade.e10: 1739,
      FuelGrade.diesel: 1659,
    },
    this.configured = true,
    this.age = const Duration(minutes: 12),
  });

  /// Clock of the fake backend (`fetchedAt` is `now() - age`).
  final DateTime Function() now;
  final Map<FuelGrade, int> prices;
  final Duration age;

  /// Whether a backend "is configured".
  bool configured;

  /// Makes every call fail with this reason while set.
  FuelFailure? failWith;

  /// Every request in order; `area` is null for the national average.
  final List<({FuelGrade grade, FuelArea? area})> calls = [];

  @override
  bool get isConfigured => configured;

  @override
  Future<FuelServiceResult> fetch(FuelGrade grade, {FuelArea? area}) async {
    calls.add((grade: grade, area: area));
    if (!configured) return const FuelServiceFailure(FuelFailure.unavailable);
    final failure = failWith;
    if (failure != null) return FuelServiceFailure(failure);
    final milli = prices[grade];
    if (milli == null) return const FuelServiceFailure(FuelFailure.provider);
    return FuelServiceOk(
      FuelPrice(
        grade: grade,
        priceMilli: milli,
        scope: switch (area) {
          null => FuelScope.national,
          PlzArea() => FuelScope.plz,
          NearbyArea() => FuelScope.nearby,
        },
        scopeKey: area is PlzArea ? area.plz : null,
        fetchedAt: now().subtract(age),
        stations: area == null ? 14000 : 12,
        source: 'tankerkoenig',
        attribution: 'Daten: MTS-K via Tankerkönig (CC BY 4.0)',
      ),
    );
  }
}
