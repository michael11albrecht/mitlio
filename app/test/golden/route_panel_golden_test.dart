import '../features/routes/ui/route_fixtures.dart';
import 'golden_matrix.dart';

const _height = 640.0;
const _width = 360.0;

Future<void> main() async {
  for (final (name, state, open) in [
    ('route_panel_collapsed', routeEmpty, false),
    ('route_panel_suggestions', routeSuggesting, true),
    ('route_panel_result', routeResult, true),
    ('route_panel_saved', routeSaved, true),
    ('route_panel_edited', routeEdited, true),
    ('route_panel_rate_limited', routeRateLimited, true),
  ]) {
    await matrixGolden(
      name,
      () => routePanelHost(state, open: open),
      width: _width,
      height: _height,
    );
  }
}
