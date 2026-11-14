import '../../../helpers/a11y.dart';
import 'fuel_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  for (final (name, state) in [
    ('fresh', fuelFresh),
    ('postcode', fuelPlz),
    ('offline last known', fuelStale),
    ('EU bulletin approximation', fuelBulletin),
    ('location denied', fuelDenied),
    ('nothing known', fuelNothing),
  ]) {
    forEachMode(
      'fuel chips: $name',
      () => fuelChipsHost(state),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
