import '../features/fuel/ui/fuel_fixtures.dart';
import 'golden_matrix.dart';

const _height = 560.0;
const _width = 360.0;

Future<void> main() async {
  for (final (name, state) in [
    ('fuel_chips_fresh', fuelFresh),
    ('fuel_chips_plz', fuelPlz),
    ('fuel_chips_stale', fuelStale),
    ('fuel_chips_bulletin', fuelBulletin),
    ('fuel_chips_location_denied', fuelDenied),
    ('fuel_chips_nothing', fuelNothing),
  ]) {
    await matrixGolden(
      name,
      () => fuelChipsHost(state),
      width: _width,
      height: _height,
    );
  }
}
