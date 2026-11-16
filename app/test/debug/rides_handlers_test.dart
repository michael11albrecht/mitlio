import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/rides.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';

import '../features/rides/ui/rides_fixtures.dart';

void main() {
  late RidesApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;

  String id(int i) => app.people[i].id;

  setUp(() async {
    app = RidesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedGroup();
    h = ridesDriveHandlers(container);
  });

  Future<DriveResult> createGolf([Map<String, String> extra = const {}]) =>
      h['vehicles.create']!({
        'groupId': app.group.id,
        'name': 'Golf',
        'consumptionMilliPer100km': '6500',
        ...extra,
      });

  Future<DriveResult> createWork([Map<String, String> extra = const {}]) async {
    final golf = await createGolf();
    return h['templates.create']!({
      'groupId': app.group.id,
      'name': 'Arbeit',
      'distanceMeters': '20000',
      'vehicleId': golf['id']! as String,
      'roundTrip': 'true',
      'defaultDriverId': id(0),
      'defaultPassengerIds': jsonEncode([id(1)]),
      ...extra,
    });
  }

  group('vehicles.create', () {
    test('creates a vehicle with defaults', () async {
      final r = await createGolf();
      expect(r, {
        'id': 'rd-1',
        'name': 'Golf',
        'fuelType': 'petrol',
        'consumptionMilliPer100km': 6500,
        'wearMilliPerKm': 0,
        'kmRateMilliPerKm': null,
      });
    });

    test('fuel type, wear and km rate', () async {
      final r = await createGolf({
        'fuelType': 'electric',
        'wearMilliPerKm': '40',
        'kmRateMilliPerKm': '250',
      });
      expect(r['fuelType'], 'electric');
      expect(r['wearMilliPerKm'], 40);
      expect(r['kmRateMilliPerKm'], 250);
    });

    test(
      'reports missing and malformed params and validation errors',
      () async {
        expect((await h['vehicles.create']!({}))['error'], 'invalid_params');
        expect(
          (await createGolf({'fuelType': 'steam'}))['error'],
          'invalid_params',
        );
        expect(
          (await createGolf({'consumptionMilliPer100km': 'x'}))['error'],
          'invalid_params',
        );
        expect((await createGolf({'name': ' '}))['error'], 'invalid_params');
        expect(
          (await createGolf({'groupId': 'nope'}))['error'],
          'not_found',
        );
      },
    );
  });

  group('templates.create', () {
    test('creates a template', () async {
      final r = await createWork({'tollsCents': '200'});
      expect(r['name'], 'Arbeit');
      expect(r['distanceMeters'], 20000);
      expect(r['roundTrip'], isTrue);
      expect(r['defaultDriverId'], id(0));
      expect(r['defaultPassengerIds'], [id(1)]);
      expect(r['tollsCents'], 200);
    });

    test('reports missing params, bad lists and a zero distance', () async {
      expect((await h['templates.create']!({}))['error'], 'invalid_params');
      await createGolf();
      expect(
        (await createWork({'defaultPassengerIds': 'x'}))['error'],
        'invalid_params',
      );
      expect(
        (await createWork({'distanceMeters': '0'}))['error'],
        'invalid_params',
      );
      expect(
        (await createWork({'vehicleId': 'nope'}))['error'],
        'not_found',
      );
    });
  });

  group('rides.log', () {
    test('logs through a template with the smart defaults', () async {
      final work = await createWork();
      final r = await h['rides.log']!({
        'groupId': app.group.id,
        'templateId': work['id']! as String,
        'driverId': id(1),
      });
      expect(r['date'], '2026-03-01');
      expect(r['driverId'], id(1));
      // The carpool swaps seats: Ann rides along.
      expect(r['passengerIds'], [id(0)]);
      expect(r['distanceMeters'], 20000);
      expect(r['roundTrip'], isTrue);
      expect(r['priceMilli'], 1750);
      expect(r['totalCents'], 455);
      expect(r['owes'], [
        {'name': 'Ann', 'cents': 228},
      ]);
      expect(r['locked'], isFalse);
    });

    test('date, passengers and price can be given', () async {
      final work = await createWork();
      final r = await h['rides.log']!({
        'groupId': app.group.id,
        'templateId': work['id']! as String,
        'driverId': id(0),
        'passengerIds': jsonEncode([id(1), id(2)]),
        'date': '2026-02-14',
        'priceMilli': '1799',
      });
      expect(r['date'], '2026-02-14');
      expect(r['passengerIds'], unorderedEquals([id(1), id(2)]));
      expect(r['priceMilli'], 1799);
    });

    test('without a template: vehicle and distance', () async {
      final golf = await createGolf();
      final r = await h['rides.log']!({
        'groupId': app.group.id,
        'vehicleId': golf['id']! as String,
        'distanceMeters': '10000',
        'driverId': id(0),
        'passengerIds': jsonEncode([id(1)]),
        'tollsCents': '100',
        'roundTrip': 'true',
      });
      expect(r['roundTrip'], isTrue);
      expect(r['tollsCents'], 100);
    });

    test('reports usage problems and repository errors', () async {
      final work = await createWork();
      final base = {
        'groupId': app.group.id,
        'templateId': work['id']! as String,
        'driverId': id(0),
      };
      expect((await h['rides.log']!({}))['error'], 'invalid_params');
      expect(
        (await h['rides.log']!({
          'groupId': app.group.id,
          'driverId': id(0),
        }))['error'],
        'invalid_params',
      );
      expect(
        (await h['rides.log']!({...base, 'date': 'gestern'}))['error'],
        'invalid_params',
      );
      expect(
        (await h['rides.log']!({...base, 'passengerIds': '{'}))['error'],
        'invalid_params',
      );
      expect(
        (await h['rides.log']!({...base, 'templateId': 'nope'}))['error'],
        'not_found',
      );
      expect(
        (await h['rides.log']!({
          ...base,
          'passengerIds': jsonEncode([id(0)]),
        }))['error'],
        'invalid_params',
      );
    });
  });

  group('rides.setCanDrive and rides.answerDriverPrompt', () {
    test('marks a member as non-driver and back', () async {
      final params = {
        'groupId': app.group.id,
        'memberId': id(1),
        'canDrive': 'false',
      };
      expect(await h['rides.setCanDrive']!(params), {
        'memberId': id(1),
        'canDrive': false,
      });
      expect(
        (await h['rides.setCanDrive']!({
          ...params,
          'canDrive': 'true',
        }))['canDrive'],
        isTrue,
      );
    });

    test('rejects bad params and unknown members', () async {
      expect((await h['rides.setCanDrive']!({}))['error'], 'invalid_params');
      expect(
        (await h['rides.setCanDrive']!({
          'groupId': app.group.id,
          'memberId': id(1),
          'canDrive': 'maybe',
        }))['error'],
        'invalid_params',
      );
      expect(
        (await h['rides.setCanDrive']!({
          'groupId': app.group.id,
          'memberId': 'nope',
          'canDrive': 'false',
        }))['error'],
        'not_found',
      );
    });

    test('answers the driver question', () async {
      expect(
        await h['rides.answerDriverPrompt']!({
          'groupId': app.group.id,
          'memberId': id(1),
          'canDrive': 'false',
        }),
        {'memberId': id(1), 'canDrive': false, 'undoable': true},
      );
      expect(
        (await h['rides.answerDriverPrompt']!({
          'groupId': app.group.id,
          'memberId': id(2),
          'canDrive': 'true',
        }))['undoable'],
        isFalse,
      );
      expect(
        (await h['rides.answerDriverPrompt']!({}))['error'],
        'invalid_params',
      );
    });
  });

  group('rides.list and rides.delete', () {
    test('lists the rides of a month', () async {
      final work = await createWork();
      Future<void> log(String date) async {
        await h['rides.log']!({
          'groupId': app.group.id,
          'templateId': work['id']! as String,
          'driverId': id(0),
          'date': date,
        });
      }

      await log('2026-02-27');
      await log('2026-03-02');
      await log('2026-03-03');
      final r = await h['rides.list']!({
        'groupId': app.group.id,
        'month': '2026-03',
      });
      expect(
        [
          for (final e in r['rides']! as List<Object?>) (e! as Map)['date'],
        ],
        ['2026-03-02', '2026-03-03'],
      );
    });

    test('reports usage problems', () async {
      expect((await h['rides.list']!({}))['error'], 'invalid_params');
      expect(
        (await h['rides.list']!({
          'groupId': app.group.id,
          'month': '2026',
        }))['error'],
        'invalid_params',
      );
    });

    test('deletes a ride, unknown ids are not found', () async {
      final work = await createWork();
      final logged = await h['rides.log']!({
        'groupId': app.group.id,
        'templateId': work['id']! as String,
        'driverId': id(0),
      });
      final rideId = logged['id']! as String;
      expect(await h['rides.delete']!({'id': rideId}), {'id': rideId});
      expect(
        (await h['rides.list']!({
          'groupId': app.group.id,
          'month': '2026-03',
        }))['rides'],
        isEmpty,
      );
      expect((await h['rides.delete']!({'id': 'nope'}))['error'], 'not_found');
      expect((await h['rides.delete']!({}))['error'], 'invalid_params');
    });
  });

  group('rides.settle and rides.fairness', () {
    Future<void> log(String work, String date, int driver) async {
      await h['rides.log']!({
        'groupId': app.group.id,
        'templateId': work,
        'driverId': id(driver),
        'date': date,
        'priceMilli': '1750',
      });
    }

    test('settles a month, then fairness shows the rides', () async {
      final work = (await createWork())['id']! as String;
      await log(work, '2026-02-02', 0);
      await log(work, '2026-02-03', 1);
      await log(work, '2026-02-04', 0);
      final r = await h['rides.settle']!({
        'groupId': app.group.id,
        'month': '2026-02',
      });
      expect(r['month'], '2026-02');
      expect(r['rideCount'], 3);
      expect(r['expenseIds'], hasLength(2));
      final list = await h['rides.list']!({
        'groupId': app.group.id,
        'month': '2026-02',
      });
      expect(
        [
          for (final e in list['rides']! as List<Object?>)
            (e! as Map)['locked'],
        ],
        [true, true, true],
      );
      final f = await h['rides.fairness']!({
        'groupId': app.group.id,
        'month': '2026-02',
      });
      expect(f['month'], '2026-02');
      expect(
        (f['rows']! as List<Object?>).first,
        containsPair('memberId', id(0)),
      );
      // Nothing left: settling again is an error, not a duplicate.
      final again = await h['rides.settle']!({
        'groupId': app.group.id,
        'month': '2026-02',
      });
      expect(again['error'], 'invalid_params');
    });

    test('report usage problems', () async {
      for (final key in ['rides.settle', 'rides.fairness']) {
        expect((await h[key]!({}))['error'], 'invalid_params');
        expect(
          (await h[key]!({
            'groupId': app.group.id,
            'month': '2026-13',
          }))['error'],
          'invalid_params',
        );
        expect(
          (await h[key]!({
            'groupId': app.group.id,
            'month': '2026-1',
          }))['error'],
          'invalid_params',
        );
      }
    });
  });
  group('vehicles.catalogSearch and catalogPick', () {
    Future<DriveResult> search(String query, [Map<String, String>? extra]) =>
        h['vehicles.catalogSearch']!({
          'groupId': app.group.id,
          'query': query,
          ...?extra,
        });
    Future<DriveResult> pick(String index, [Map<String, String>? extra]) =>
        h['vehicles.catalogPick']!({
          'groupId': app.group.id,
          'index': index,
          ...?extra,
        });

    test('search lists suggestions from the form view model', () async {
      final r = await search('golf');
      expect(r['query'], 'golf');
      expect(r['noMatch'], isFalse);
      expect(r['catalogUnavailable'], isFalse);
      final hits = r['suggestions']! as List;
      expect(hits, hasLength(2));
      expect((hits.first as Map)['name'], 'VW Golf');
      expect((hits.first as Map)['consumptionMilliPer100km'], 5600);
    });

    test('pick fills the form the screen would show', () async {
      await search('golf');
      final r = await pick('1');
      expect(r, {
        'name': 'VW Golf',
        'fuelType': 'diesel',
        'consumptionMilliPer100km': 4500,
        'fromCatalog': 'VW Golf',
        'undoable': false,
      });
      final form = container.read(
        vehicleFormViewModelProvider((
          groupId: app.group.id,
          vehicleId: null,
        )),
      ) as VehicleFormReady;
      expect(form.name, 'VW Golf');
      expect(form.fromCatalog, isNotNull);
    });

    test('a second pick that replaces the consumption is undoable', () async {
      await search('golf');
      await pick('0');
      await search('polo');
      expect((await pick('0'))['undoable'], isTrue);
    });

    test('no match and a catalog that cannot load are reported', () async {
      expect((await search('trabant'))['noMatch'], isTrue);
      app.catalog.failure = const Storage('asset missing');
      final r = await search('golf');
      expect(r['catalogUnavailable'], isTrue);
      expect(r['suggestions'], isEmpty);
    });

    test('works for a stored vehicle too', () async {
      final golf = await createGolf();
      final r = await search('tesla', {'vehicleId': golf['id']! as String});
      expect(
        (r['suggestions']! as List).single,
        containsPair('name', 'Tesla Model 3'),
      );
      final picked = await pick('0', {'vehicleId': golf['id']! as String});
      expect(picked['undoable'], isTrue);
      expect(picked['fuelType'], 'electric');
    });

    test('reports missing params, unknown groups and bad indexes', () async {
      expect(
        (await h['vehicles.catalogSearch']!({}))['error'],
        'invalid_params',
      );
      expect((await h['vehicles.catalogPick']!({}))['error'], 'invalid_params');
      expect(
        (await h['vehicles.catalogSearch']!({
          'groupId': 'nope',
          'query': 'golf',
        }))['error'],
        'not_found',
      );
      expect(
        (await h['vehicles.catalogPick']!({
          'groupId': 'nope',
          'index': '0',
        }))['error'],
        'not_found',
      );
      await search('golf');
      expect((await pick('9'))['error'], 'invalid_params');
      expect((await pick('-1'))['error'], 'invalid_params');
      expect((await pick('x'))['error'], 'invalid_params');
    });
  });
}
