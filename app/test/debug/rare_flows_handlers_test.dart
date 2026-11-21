import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/rare_flows.dart';
import 'package:mitlio/debug/handlers/setup.dart';
import 'package:mitlio/features/onboarding/ui/first_group_view_model.dart';
import 'package:mitlio/features/rides/ui/commute_template_view_model.dart';
import 'package:mitlio/features/rides/ui/month_settle_flow_view_model.dart';

import '../features/repo_test_support.dart' show ok;
import '../features/rides/ui/rides_fixtures.dart';
import '../helpers/fake_app.dart';

/// The finish actions of the rare flows through `ext.mitlio.*` (PU-T12).
void main() {
  late FakeApp app;
  late ProviderContainer c;
  late Map<String, DriveHandler> h;

  setUp(() {
    app = FakeApp();
    c = app.container(
      extra: [
        setupFlowConfigsProvider.overrideWithValue({
          firstGroupFlow.id: firstGroupFlow,
        }),
      ],
    );
    addTearDown(c.dispose);
    h = {...setupDriveHandlers(c), ...rareFlowsDriveHandlers(c)};
  });

  group('onboarding.createGroup', () {
    test('creates the group answered through setup.*', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      await h['setup.next']!({'flowId': 'first_group', 'answer': 'Rom'});
      await h['setup.next']!({'flowId': 'first_group', 'answer': '["Ann"]'});
      await h['setup.next']!({'flowId': 'first_group', 'answer': 'CHF'});
      final r = await h['onboarding.createGroup']!({});
      expect(r, containsPair('name', 'Rom'));
      expect(r, containsPair('currency', 'CHF'));
      final members = ok(await app.members.list(r['id']! as String));
      expect([for (final m in members) m.name], ['Mia', 'Ann']);
      final state = await h['setup.state']!({'flowId': 'first_group'});
      expect(state['answers'], <String, Object?>{}, reason: 'flow cleared');
    });

    test('an unfinished flow is a conflict', () async {
      expect(
        await h['onboarding.createGroup']!({}),
        containsPair('error', 'conflict'),
      );
    });
  });

  group('rides.commute.save', () {
    late RidesApp rides;
    late Map<String, DriveHandler> r;

    setUp(() async {
      rides = RidesApp();
      await rides.seedVehicle();
      final rc = rides.container(
        extra: [
          setupFlowConfigsProvider.overrideWithValue({
            commuteTemplateFlow.id: commuteTemplateFlow,
          }),
        ],
      );
      addTearDown(rc.dispose);
      r = {...setupDriveHandlers(rc), ...rareFlowsDriveHandlers(rc)};
    });

    Future<void> answer(String step, Object? value) async {
      final flowId = 'commute_template:${rides.group.id}';
      final res = await r['setup.next']!({
        'flowId': flowId,
        'answer': jsonEncode(value),
      });
      expect(res['error'], isNull, reason: step);
    }

    test('stores the route answered through setup.*', () async {
      await answer('name', 'Arbeit');
      await answer('route', {'meters': 12500, 'roundTrip': true});
      await answer('vehicle', rides.golf.id);
      await answer('people', {
        'driver': rides.people[0].id,
        'passengers': [rides.people[1].id],
      });
      await answer('tolls', 250);
      final res = await r['rides.commute.save']!({'groupId': rides.group.id});
      expect(res, containsPair('name', 'Arbeit'));
      expect(res, containsPair('distanceMeters', 12500));
      expect(res, containsPair('tollsCents', 250));
      expect(res['defaultPassengerIds'], [rides.people[1].id]);
      final state = await r['setup.state']!({
        'flowId': 'commute_template:${rides.group.id}',
      });
      expect(state['answers'], <String, Object?>{}, reason: 'flow cleared');
    });

    test('needs a group id; an unfinished flow is a conflict', () async {
      expect(
        await r['rides.commute.save']!({}),
        containsPair('error', 'invalid_params'),
      );
      expect(
        await r['rides.commute.save']!({'groupId': rides.group.id}),
        containsPair('error', 'conflict'),
      );
    });
  });

  group('rides.settleFlow.confirm', () {
    late RidesApp rides;
    late Map<String, DriveHandler> r;
    const flow = 'month_settle:%s:2026-03';

    setUp(() async {
      rides = RidesApp();
      await rides.seedCommute();
      await rides.ride(date: '2026-03-05', driver: 0, passengers: [1]);
      final rc = rides.container(
        extra: [
          setupFlowConfigsProvider.overrideWithValue({
            monthSettleFlow.id: monthSettleFlow,
          }),
        ],
      );
      addTearDown(rc.dispose);
      r = {...setupDriveHandlers(rc), ...rareFlowsDriveHandlers(rc)};
    });

    String id() => flow.replaceFirst('%s', rides.group.id);

    test('settles the month once both looks are answered', () async {
      await r['setup.next']!({'flowId': id(), 'answer': 'true'});
      final state = await r['setup.next']!({'flowId': id(), 'answer': 'true'});
      expect(state['finished'], isTrue);
      final res = await r['rides.settleFlow.confirm']!({
        'groupId': rides.group.id,
        'month': '2026-03',
      });
      expect(res, containsPair('month', '2026-03'));
      expect(res, containsPair('rideCount', 1));
      expect(res['expenseIds'], hasLength(1));
      final after = await r['setup.state']!({'flowId': id()});
      expect(after['finished'], isFalse, reason: 'review cleared');
    });

    test('needs groupId and month; the review must be done', () async {
      expect(
        await r['rides.settleFlow.confirm']!({'groupId': rides.group.id}),
        containsPair('error', 'invalid_params'),
      );
      expect(
        await r['rides.settleFlow.confirm']!({
          'groupId': rides.group.id,
          'month': '2026-03',
        }),
        containsPair('error', 'conflict'),
      );
    });
  });
}
