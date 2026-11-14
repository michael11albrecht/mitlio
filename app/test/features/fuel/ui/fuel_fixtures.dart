import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/fuel/ui/fuel_price_chips.dart';
import 'package:mitlio/features/fuel/ui/fuel_price_view_model.dart';

/// A view model that holds one fixed state, for goldens and a11y tests.
class StubFuelPriceViewModel extends FuelPriceViewModel {
  StubFuelPriceViewModel(super.initialGrade, this.fixed);

  final FuelPriceState fixed;

  @override
  FuelPriceState build() => fixed;
}

List<Override> fuelStateOverride(FuelPriceState state) => [
  fuelPriceViewModelProvider.overrideWith2(
    (g) => StubFuelPriceViewModel(g, state),
  ),
];

/// The chips as they sit under a price field.
Widget fuelChipsHost(FuelPriceState state) => ProviderScope(
  overrides: fuelStateOverride(state),
  child: Padding(
    padding: Spacing.screen,
    child: FuelPriceChips(grade: FuelGrade.e5, onFill: (_, {required auto}) {}),
  ),
);

FuelPrice _price({
  FuelScope scope = FuelScope.national,
  String source = 'tankerkoenig',
  String attribution = 'Daten: MTS-K via Tankerkönig (CC BY 4.0)',
  FuelGrade? approximation,
  DateTime? fetchedAt,
  int milli = 1799,
}) => FuelPrice(
  grade: FuelGrade.e5,
  priceMilli: milli,
  scope: scope,
  scopeKey: scope == FuelScope.plz ? '10115' : null,
  fetchedAt: fetchedAt ?? DateTime.utc(2026, 11, 14, 11, 48),
  source: source,
  attribution: attribution,
  approximation: approximation,
);

/// Fresh national average, "in meiner Nähe" offered.
final fuelFresh = FuelPriceState(
  available: true,
  grade: FuelGrade.e5,
  price: _price(),
  age: const Duration(minutes: 12),
  canLocate: true,
);

/// Postcode average, no location plugin.
final fuelPlz = FuelPriceState(
  available: true,
  grade: FuelGrade.diesel,
  scope: FuelScope.plz,
  price: _price(scope: FuelScope.plz, milli: 1659),
  age: const Duration(hours: 1),
);

/// Offline: the last known value with its age.
final fuelStale = FuelPriceState(
  available: true,
  grade: FuelGrade.e5,
  price: _price(),
  stale: true,
  age: const Duration(hours: 5),
);

/// EU Weekly Oil Bulletin: days old, E10 shown as an E5 approximation.
final fuelBulletin = FuelPriceState(
  available: true,
  grade: FuelGrade.e10,
  price: _price(
    source: 'eu-oil-bulletin',
    attribution: 'Quelle: EU Weekly Oil Bulletin',
    approximation: FuelGrade.e5,
    fetchedAt: DateTime.utc(2026, 11, 10),
    milli: 1741,
  ),
  age: const Duration(days: 4),
);

/// Location said no: the national average stays, with a calm hint.
final fuelDenied = FuelPriceState(
  available: true,
  grade: FuelGrade.e5,
  price: _price(),
  age: const Duration(minutes: 3),
  failure: FuelFailure.locationDenied,
  canLocate: true,
);

/// Nothing known and no connection.
const fuelNothing = FuelPriceState(
  available: true,
  grade: FuelGrade.e5,
  failure: FuelFailure.offline,
);
