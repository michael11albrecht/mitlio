import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/debug/debug_snapshots.dart';

import '../features/rides/ui/rides_fixtures.dart';

void main() {
  late RidesApp app;

  setUp(() => app = RidesApp());

  testWidgets('the rides screens follow the open route', (tester) async {
    app.tester = tester;
    await app.seedCommute();
    final c = await pumpRides(tester, app);
    final live = buildSnapshotRegistry(c);
    final g = app.group.id;
    for (final screen in [
      'rides',
      'rides_setup',
      'vehicle_form',
      'template_form',
    ]) {
      expect(live.snapshot(screen), {'status': 'not_open'}, reason: screen);
    }

    c.read(routerProvider).go('/groups/$g?tab=rides');
    await tester.pumpAndSettle();
    final rides = live.snapshot('rides')!;
    expect(rides['status'], 'data');
    expect(rides['groupId'], g);
    expect(rides['templates'], 1);
    expect(live.snapshot('vehicle_form'), {'status': 'not_open'});

    c.read(routerProvider).go('/groups/$g/rides/settings');
    await tester.pumpAndSettle();
    final setup = live.snapshot('rides_setup')!;
    expect(setup['status'], 'data');
    expect((setup['vehicles']! as List).single, containsPair('name', 'Golf'));

    c.read(routerProvider).go('/groups/$g/rides/vehicles/${app.golf.id}');
    await tester.pumpAndSettle();
    expect(live.snapshot('vehicle_form'), containsPair('name', 'Golf'));
    expect(live.snapshot('template_form'), {'status': 'not_open'});

    c.read(routerProvider).go('/groups/$g/rides/templates/new');
    await tester.pumpAndSettle();
    expect(live.snapshot('template_form'), containsPair('editing', false));
    expect(live.snapshot('vehicle_form'), {'status': 'not_open'});

    c.read(routerProvider).go('/groups/$g/rides/templates/${app.work.id}');
    await tester.pumpAndSettle();
    expect(live.snapshot('template_form'), containsPair('name', 'Arbeit'));
  });
}
