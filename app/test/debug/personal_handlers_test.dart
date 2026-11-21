import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/groups.dart';
import 'package:mitlio/debug/handlers/payment.dart';
import 'package:mitlio/debug/handlers/personal.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart' show eur, ok;
import '../helpers/fake_app.dart';

const _iban = 'DE89370400440532013000';

/// The personal cars, cards and own member through `ext.mitlio.*` (PU-T10,
/// PU-T11): the commands the screens use.
void main() {
  late FakeApp app;
  late ProviderContainer c;
  late Map<String, DriveHandler> h;
  late String gA;
  late String gB;
  late String golfId;

  setUp(() async {
    app = FakeApp();
    c = app.container();
    addTearDown(c.dispose);
    h = {
      ...personalDriveHandlers(c),
      ...groupsDriveHandlers(c),
      ...paymentDriveHandlers(c),
    };
    gA = ok(
      await app.groups.create(name: 'A', currency: eur, createdBy: 'dev'),
    ).id;
    gB = ok(
      await app.groups.create(name: 'B', currency: eur, createdBy: 'dev'),
    ).id;
    golfId = ok(
      await app.userVehicles.add(
        name: 'Golf',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: 6500,
        wearMilliPerKm: 80,
      ),
    ).id;
  });

  test('cars.list shows the personal cars', () async {
    final r = await h['cars.list']!({});
    expect((r['cars']! as List).single, containsPair('name', 'Golf'));
  });

  test('cars.add saves the car of the finished flow', () async {
    expect(
      await h['cars.add']!({}),
      containsPair('error', 'conflict'),
      reason: 'nothing answered yet',
    );
  });

  test('use, edit in two groups, undo', () async {
    final a = await h['cars.use']!({'groupId': gA, 'carId': golfId});
    final b = await h['cars.use']!({'groupId': gB, 'carId': golfId});
    expect(a['name'], 'Golf');
    expect(
      await h['cars.linked']!({'vehicleId': a['id']! as String}),
      containsPair('linked', true),
    );

    final edit = await h['cars.edit']!({
      'id': golfId,
      'name': 'Golf GTI',
      'consumptionMilli': '7200',
    });
    expect(edit['groups'], 2);
    expect(
      (edit['car']! as Map)['consumptionMilliPer100km'],
      7200,
    );
    expect(ok(await app.vehicles.get(b['id']! as String)).name, 'Golf GTI');

    expect(await h['cars.undoEdit']!({}), {'ok': true});
    expect(ok(await app.vehicles.get(b['id']! as String)).name, 'Golf');
    expect(await h['cars.undoEdit']!({}), containsPair('error', 'conflict'));
  });

  test('unlink ends the link; errors are plain', () async {
    final a = await h['cars.use']!({'groupId': gA, 'carId': golfId});
    final id = a['id']! as String;
    expect(
      await h['cars.unlink']!({'vehicleId': id}),
      containsPair('linked', false),
    );
    expect(
      await h['cars.linked']!({'vehicleId': id}),
      containsPair('linked', false),
    );
    expect(
      await h['cars.unlink']!({'vehicleId': 'nope'}),
      containsPair('error', 'not_found'),
    );
    expect(await h['cars.edit']!({}), containsPair('error', 'invalid_params'));
    expect(
      await h['cars.edit']!({'id': 'nope'}),
      containsPair('error', 'not_found'),
    );
    expect(
      await h['cars.edit']!({'id': golfId, 'name': ' '}),
      containsPair('error', 'invalid_params'),
    );
    expect(
      await h['cars.use']!({'groupId': gA, 'carId': 'nope'}),
      containsPair('error', 'not_found'),
    );
    expect(await h['cars.use']!({}), containsPair('error', 'invalid_params'));
  });

  test('cards: visible until dismissed or no longer needed', () async {
    expect(
      await h['cards.state']!({'card': 'settlePayment'}),
      containsPair('visible', true),
    );
    expect(
      await h['cards.dismiss']!({'card': 'settlePayment'}),
      containsPair('visible', false),
    );
    expect(
      await h['cards.state']!({'card': 'settlePayment'}),
      containsPair('visible', false),
    );
    expect(
      await h['cards.state']!({'card': 'groupCar'}),
      containsPair('visible', false),
      reason: 'a personal car exists',
    );
    expect(
      await h['cards.state']!({'card': 'x'}),
      containsPair('error', 'invalid_params'),
    );
  });

  test('profile summary, own member and payout links', () async {
    expect(await h['profile.summary']!({}), {'summary': 'none'});
    ok(await app.profile.save(displayName: 'Mia', paypalMe: 'mia'));
    ok(await app.profileBank.save(iban: _iban));
    expect(await h['profile.summary']!({}), {'summary': 'both'});

    final g = await h['groups.create']!({
      'name': 'Ski',
      'members': jsonEncode(['Ben']),
      'withProfile': 'true',
    });
    final members = ok(await app.members.list(g['id']! as String));
    expect([for (final m in members) m.name], ['Mia', 'Ben']);
    expect(
      await h['members.isOwn']!({'memberId': members[0].id}),
      containsPair('own', true),
    );
    expect(
      await h['members.isOwn']!({'memberId': members[1].id}),
      containsPair('own', false),
    );
    final links = await h['payment.links']!({
      'fromId': members[1].id,
      'toId': members[0].id,
      'amountCents': '1000',
    });
    expect(links['paypalUrl'], contains('mia'));
    expect(links['epcPayload'], isNotNull);
  });
}
