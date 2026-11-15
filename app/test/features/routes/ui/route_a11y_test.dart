import '../../../helpers/a11y.dart';
import 'route_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  forEachMode(
    'route panel: collapsed',
    () => routePanelHost(routeEmpty, open: false),
    (tester, _, _) => expectAccessible(tester),
  );
  for (final (name, state) in [
    ('empty', routeEmpty),
    ('suggestions', routeSuggesting),
    ('result', routeResult),
    ('saved places', routeSaved),
    ('hand edited', routeEdited),
    ('offline', routeOffline),
    ('rate limited', routeRateLimited),
    ('no route', routeNoRoute),
    ('service down', routeDown),
  ]) {
    forEachMode(
      'route panel: $name',
      () => routePanelHost(state),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
