import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/debug/fakes/fake_route_distance_service.dart';
import 'package:mitlio/features/routes/data/repositories/drift_places_repository.dart';
import 'package:mitlio/features/routes/data/repositories/fake_places_repository.dart';
import 'package:mitlio/features/routes/data/repositories/places_repository.dart';
import 'package:mitlio/features/routes/data/repositories/route_distance_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

const PlaceSuggestion _ka = FakeRouteDistanceService.karlsruhe;
const PlaceSuggestion _st = FakeRouteDistanceService.stuttgart;

void main() {
  group('RouteDistanceRepository', () {
    late FakeRouteDistanceService service;
    late RouteDistanceRepository repo;

    setUp(() {
      service = FakeRouteDistanceService();
      repo = RouteDistanceRepository(service);
    });

    test('suggest passes trimmed text through', () async {
      final r = await repo.suggest('  Karls  ', lang: 'de');
      expect(r, isA<RouteOk<List<PlaceSuggestion>>>());
      expect(service.calls, ['suggest:Karls']);
    });

    test('suggest below three characters never asks', () async {
      final r = await repo.suggest(' ab ', lang: 'de');
      expect((r as RouteFail).reason, RouteFailure.invalidParams);
      expect(service.calls, isEmpty);
    });

    test('three umlauts are three characters', () async {
      expect(await repo.suggest('äöü', lang: 'de'), isA<RouteOk<Object?>>());
    });

    test('distance passes through', () async {
      final r = await repo.distance(_ka, _st) as RouteOk<int>;
      expect(r.value, 81000);
      expect(r.attribution, isNotEmpty);
    });

    test('the same spot is invalid and never asked', () async {
      final r = await repo.distance(_ka, _ka) as RouteFail<int>;
      expect(r.reason, RouteFailure.invalidParams);
      expect(service.calls, isEmpty);
    });

    test('every failure of the service is passed on, with the wait', () async {
      for (final reason in RouteFailure.values.where(
        (r) => r != RouteFailure.providerUnconfigured,
      )) {
        service
          ..failWith = reason
          ..failRetryAfter = const Duration(minutes: 7);
        final r = await repo.distance(_ka, _st) as RouteFail<int>;
        expect(r.reason, reason);
        expect(r.retryAfter, const Duration(minutes: 7));
        final s = await repo.suggest('Karls', lang: 'de') as RouteFail;
        expect(s.reason, reason);
      }
    });

    test(
      'provider_unconfigured switches the feature off for the session',
      () async {
        service.failWith = RouteFailure.providerUnconfigured;
        expect(repo.isAvailable, isTrue);
        final first = await repo.suggest('Karls', lang: 'de') as RouteFail;
        expect(first.reason, RouteFailure.providerUnconfigured);
        expect(repo.isAvailable, isFalse);
        service.calls.clear();
        expect(
          (await repo.distance(_ka, _st) as RouteFail).reason,
          RouteFailure.unavailable,
        );
        expect(service.calls, isEmpty);
      },
    );

    test('no route is a failure, not zero', () async {
      final r = await repo.distance(_ka, _kaOther) as RouteFail<int>;
      expect(r.reason, RouteFailure.noRoute);
    });

    test('without a backend: unavailable and no request', () async {
      service.configured = false;
      expect(repo.isAvailable, isFalse);
      expect(
        (await repo.suggest('Karls', lang: 'de') as RouteFail).reason,
        RouteFailure.unavailable,
      );
      expect(
        (await repo.distance(_ka, _st) as RouteFail<int>).reason,
        RouteFailure.unavailable,
      );
    });
  });

  group('places', () {
    late AppDatabase db;
    late FixedClock clock;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      clock = FixedClock(DateTime.utc(2026, 11, 15, 10));
    });
    tearDown(() => db.close());

    final repos = <(String, PlacesRepository Function())>[
      ('drift', () => DriftPlacesRepository(db: db, clock: clock)),
      ('fake', FakePlacesRepository.new),
    ];

    for (final (name, make) in repos) {
      group(name, () {
        late PlacesRepository repo;
        setUp(() => repo = make());

        Future<List<SavedPlace>> all() async =>
            ((await repo.all()) as Ok<List<SavedPlace>, RepositoryError>).value;

        test('starts empty', () async => expect(await all(), isEmpty));

        test('saves, replaces and keeps one place per kind', () async {
          await repo.save(PlaceKind.home, _ka);
          await repo.save(PlaceKind.work, _st);
          await repo.save(PlaceKind.home, _kaOther);
          expect(
            await all(),
            unorderedEquals([
              const SavedPlace(kind: PlaceKind.home, place: _kaOther),
              const SavedPlace(kind: PlaceKind.work, place: _st),
            ]),
          );
        });

        test('undo of a replace brings the old place back', () async {
          await repo.save(PlaceKind.home, _ka);
          final undo = ((await repo.save(
            PlaceKind.home,
            _st,
          )) as Ok<Undo, RepositoryError>).value;
          await undo();
          expect(await all(), [
            const SavedPlace(kind: PlaceKind.home, place: _ka),
          ]);
        });

        test('undo of a first save removes it', () async {
          final undo = ((await repo.save(
            PlaceKind.work,
            _st,
          )) as Ok<Undo, RepositoryError>).value;
          expect(await all(), hasLength(1));
          await undo();
          expect(await all(), isEmpty);
        });

        test('remove forgets, undo restores', () async {
          await repo.save(PlaceKind.home, _ka);
          final undo = ((await repo.remove(
            PlaceKind.home,
          )) as Ok<Undo, RepositoryError>).value;
          expect(await all(), isEmpty);
          await undo();
          expect(await all(), hasLength(1));
        });

        test('removing nothing is fine and undoable', () async {
          final undo = ((await repo.remove(
            PlaceKind.work,
          )) as Ok<Undo, RepositoryError>).value;
          await undo();
          expect(await all(), isEmpty);
        });
      });
    }

    test('drift: a storage failure is an error result, not a throw', () async {
      final repo = DriftPlacesRepository(db: db, clock: clock);
      await db.customStatement('DROP TABLE local_places');
      for (final r in [
        await repo.all(),
        await repo.save(PlaceKind.home, _ka),
        await repo.remove(PlaceKind.home),
      ]) {
        expect((r as Err).error, isA<Storage>());
      }
    });

    test(
      'drift: the table is wiped by "delete my data" like the rest',
      () async {
        final repo = DriftPlacesRepository(db: db, clock: clock);
        await repo.save(PlaceKind.home, _ka);
        expect(
          db.allTables.map((t) => t.actualTableName),
          contains('local_places'),
        );
        for (final table in db.allTables.toList().reversed) {
          await db.delete(table).go();
        }
        expect(
          (await repo.all() as Ok<List<SavedPlace>, RepositoryError>).value,
          isEmpty,
        );
      },
    );

    test('fake: failures are returned', () async {
      final fake = FakePlacesRepository()..failWith = const Storage('x');
      expect(await fake.all(), isA<Err<List<SavedPlace>, RepositoryError>>());
      expect(
        await fake.save(PlaceKind.home, _ka),
        isA<Err<Undo, RepositoryError>>(),
      );
      expect(
        await fake.remove(PlaceKind.home),
        isA<Err<Undo, RepositoryError>>(),
      );
    });
  });
}

const _kaOther = PlaceSuggestion(label: 'Elsewhere', lat: 50, lng: 9);
