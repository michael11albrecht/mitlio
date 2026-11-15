import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/fakes/fake_route_distance_service.dart';
import 'package:mitlio/features/routes/data/repositories/fake_places_repository.dart';
import 'package:mitlio/features/routes/data/repositories/route_providers.dart';
import 'package:mitlio/features/routes/data/route_models.dart';
import 'package:mitlio/features/routes/data/services/route_distance_service.dart';
import 'package:mitlio/features/routes/ui/route_distance_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

const PlaceSuggestion _ka = FakeRouteDistanceService.karlsruhe;
const PlaceSuggestion _st = FakeRouteDistanceService.stuttgart;
const PlaceSuggestion _be = FakeRouteDistanceService.berlin;

/// A service whose answers the test releases by hand, to build races.
class _GatedService extends FakeRouteDistanceService {
  final suggestGates = <Completer<void>>[];
  final distanceGates = <Completer<void>>[];

  @override
  Future<RouteResult<List<PlaceSuggestion>>> suggest(
    String text, {
    required String lang,
  }) async {
    final gate = Completer<void>();
    suggestGates.add(gate);
    await gate.future;
    return super.suggest(text, lang: lang);
  }

  @override
  Future<RouteResult<int>> distance(
    PlaceSuggestion from,
    PlaceSuggestion to,
  ) async {
    final gate = Completer<void>();
    distanceGates.add(gate);
    await gate.future;
    return super.distance(from, to);
  }
}

void main() {
  late FakeRouteDistanceService service;
  late FakePlacesRepository places;
  late ProviderContainer container;

  ProviderContainer make(
    RouteDistanceService s, {
    Duration debounce = Duration.zero,
  }) {
    final c = ProviderContainer(
      overrides: [
        routeDistanceServiceProvider.overrideWithValue(s),
        placesRepositoryProvider.overrideWithValue(places),
        routeSearchDebounceProvider.overrideWithValue(debounce),
      ],
    );
    addTearDown(c.dispose);
    c.listen(routeDistanceViewModelProvider, (_, _) {});
    return c;
  }

  setUp(() {
    service = FakeRouteDistanceService();
    places = FakePlacesRepository();
    container = make(service);
  });

  RouteDistanceViewModel vm() =>
      container.read(routeDistanceViewModelProvider.notifier);
  RouteDistanceState state() => container.read(routeDistanceViewModelProvider);

  test('hidden without a backend, nothing is ever asked', () async {
    service.configured = false;
    final c = make(service);
    expect(c.read(routeDistanceViewModelProvider).available, isFalse);
    final model = c.read(routeDistanceViewModelProvider.notifier);
    await model.search(RouteField.start, 'Karls');
    await model.pick(RouteField.start, _ka);
    await model.pick(RouteField.end, _st);
    expect(service.calls, isEmpty);
    expect(c.read(routeDistanceViewModelProvider).canRecalculate, isFalse);
  });

  group('searchPlaces', () {
    test('success: suggestions and the credit line', () async {
      await vm().search(RouteField.start, 'Karls');
      expect(state().suggestions, [_ka]);
      expect(state().active, RouteField.start);
      expect(state().searched, isTrue);
      expect(state().searching, isFalse);
      expect(state().attribution, FakeRouteDistanceService.attribution);
    });

    test('no match is told apart from not asked yet', () async {
      await vm().search(RouteField.end, 'Nirgendwo');
      expect(state().suggestions, isEmpty);
      expect(state().searched, isTrue);
      expect(state().failure, isNull);
    });

    test('validation: under three characters never asks', () async {
      vm().onTextChanged(RouteField.start, 'Ka');
      await pumpEventQueue();
      expect(service.calls, isEmpty);
      expect(state().suggestions, isEmpty);
    });

    test('each failure is kept with its reason and wait', () async {
      for (final reason in RouteFailure.values) {
        service
          ..failWith = reason
          ..failRetryAfter = const Duration(minutes: 4);
        await vm().search(RouteField.start, 'Karls');
        expect(state().failure, reason);
        expect(state().retryAfter, const Duration(minutes: 4));
        expect(state().suggestions, isEmpty);
        expect(state().searching, isFalse);
      }
    });

    test('a new search clears the old failure', () async {
      service.failWith = RouteFailure.offline;
      await vm().search(RouteField.start, 'Karls');
      service.failWith = null;
      await vm().search(RouteField.start, 'Karls');
      expect(state().failure, isNull);
    });

    test('an answer that was overtaken is ignored', () async {
      final gated = _GatedService();
      final c = make(gated);
      final model = c.read(routeDistanceViewModelProvider.notifier);
      final first = model.search(RouteField.start, 'Karls');
      final second = model.search(RouteField.start, 'Stutt');
      await pumpEventQueue();
      // The newer answer arrives first, the older one after it.
      gated.suggestGates[1].complete();
      await second;
      gated.suggestGates[0].complete();
      await first;
      expect(c.read(routeDistanceViewModelProvider).suggestions, [_st]);
    });

    test('typing again drops a pending answer', () async {
      final gated = _GatedService();
      final c = make(gated);
      final model = c.read(routeDistanceViewModelProvider.notifier);
      final pending = model.search(RouteField.start, 'Karls');
      await pumpEventQueue();
      model.onTextChanged(RouteField.start, 'K');
      gated.suggestGates.single.complete();
      await pending;
      expect(c.read(routeDistanceViewModelProvider).suggestions, isEmpty);
    });

    test('debounce: only the last keystroke asks, after the pause', () async {
      final c = make(service, debounce: const Duration(milliseconds: 60));
      final model = c.read(routeDistanceViewModelProvider.notifier)
        ..onTextChanged(RouteField.start, 'Kar');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      model.onTextChanged(RouteField.start, 'Karl');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(service.calls, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(service.calls, ['suggest:Karl']);
    });

    test('the language goes along', () async {
      final seen = <String>[];
      final spy = _LangSpy(seen);
      final c = make(spy);
      c
          .read(routeDistanceViewModelProvider.notifier)
          .onTextChanged(RouteField.end, 'Berlin', lang: 'en');
      await pumpEventQueue();
      expect(seen, ['en']);
    });
  });

  group('pickPlace', () {
    test('both places fill the distance (rounded to 100 m)', () async {
      service.distances[(a: _ka.label, b: _st.label)] = 81234;
      await vm().pick(RouteField.start, _ka);
      expect(service.calls, isEmpty, reason: 'one place is not a route');
      expect(state().fill, isNull);
      await vm().pick(RouteField.end, _st);
      expect(state().meters, 81234);
      expect(state().fill?.meters, 81200);
      expect(state().canRecalculate, isFalse);
      expect(state().suggestions, isEmpty);
    });

    test('a distance never fills zero', () {
      expect(roundRouteMeters(0), 100);
      expect(roundRouteMeters(49), 100);
      expect(roundRouteMeters(149), 100);
      expect(roundRouteMeters(150), 200);
      expect(roundRouteMeters(81249), 81200);
    });

    test('failure leaves the field alone and offers a retry', () async {
      service.failWith = RouteFailure.offline;
      await vm().pick(RouteField.start, _ka);
      await vm().pick(RouteField.end, _st);
      expect(state().failure, RouteFailure.offline);
      expect(state().fill, isNull);
      expect(state().meters, isNull);
      expect(state().canRecalculate, isTrue);
      service.failWith = null;
      await vm().recalculate();
      expect(state().failure, isNull);
      expect(state().fill?.meters, 81000);
    });

    test('each failure of the distance call surfaces', () async {
      for (final reason in RouteFailure.values) {
        service
          ..failWith = reason
          ..failRetryAfter = reason == RouteFailure.rateLimited
              ? const Duration(minutes: 3)
              : null;
        await vm().pick(RouteField.start, _ka);
        await vm().pick(RouteField.end, _st);
        expect(state().failure, reason);
        expect(state().fill, isNull);
        expect(state().calculating, isFalse);
      }
    });

    test('no route between the places is its own failure', () async {
      await vm().pick(RouteField.start, _st);
      await vm().pick(RouteField.end, _be);
      expect(state().failure, RouteFailure.noRoute);
    });

    test('the same place twice is invalid', () async {
      await vm().pick(RouteField.start, _ka);
      await vm().pick(RouteField.end, _ka);
      expect(state().failure, RouteFailure.invalidParams);
      expect(service.calls, isEmpty);
    });

    test('changing a place recalculates while the km are untouched', () async {
      await vm().pick(RouteField.start, _ka);
      await vm().pick(RouteField.end, _st);
      await vm().pick(RouteField.end, _be);
      expect(state().fill?.meters, 650400);
      expect(state().fill?.seq, 2);
    });

    test('a stale distance answer is dropped', () async {
      final gated = _GatedService();
      final c = make(gated);
      final model = c.read(routeDistanceViewModelProvider.notifier);
      unawaited(model.pick(RouteField.start, _ka));
      final first = model.pick(RouteField.end, _st);
      await pumpEventQueue();
      final second = model.pick(RouteField.end, _be);
      await pumpEventQueue();
      gated.distanceGates[1].complete();
      await second;
      gated.distanceGates[0].complete();
      await first;
      final s = c.read(routeDistanceViewModelProvider);
      expect(s.meters, 650400);
      expect(s.fill?.meters, 650400);
      expect(s.end, _be);
    });

    test('an answer for places that changed meanwhile is dropped', () async {
      final gated = _GatedService();
      final c = make(gated);
      final model = c.read(routeDistanceViewModelProvider.notifier);
      await model.pick(RouteField.start, _ka);
      final pending = model.pick(RouteField.end, _st);
      await pumpEventQueue();
      model.onTextChanged(RouteField.end, 'Ber'); // drops the destination
      gated.distanceGates.single.complete();
      await pending;
      final s = c.read(routeDistanceViewModelProvider);
      expect(s.fill, isNull);
      expect(s.calculating, isFalse);
    });
  });

  group('manual override', () {
    test(
      'after a hand edit, picking another place does not overwrite',
      () async {
        await vm().pick(RouteField.start, _ka);
        await vm().pick(RouteField.end, _st);
        expect(state().fill?.meters, 81000);
        vm().noteManualEdit();
        await vm().pick(RouteField.end, _be);
        expect(state().fill?.meters, 81000, reason: 'unchanged');
        expect(state().fill?.seq, 1);
        expect(service.calls, hasLength(1));
        expect(state().canRecalculate, isTrue);
      },
    );

    test('"Neu berechnen" overwrites a hand edit', () async {
      await vm().pick(RouteField.start, _ka);
      await vm().pick(RouteField.end, _st);
      vm().noteManualEdit();
      expect(state().canRecalculate, isTrue);
      await vm().recalculate();
      expect(state().fill?.seq, 2);
      expect(state().manualOverride, isFalse);
      expect(state().canRecalculate, isFalse);
    });

    test(
      'a hand edit before any places: the first route is not filled',
      () async {
        vm().noteManualEdit();
        await vm().pick(RouteField.start, _ka);
        await vm().pick(RouteField.end, _st);
        expect(state().fill, isNull);
        expect(state().canRecalculate, isTrue);
      },
    );

    test('recalculate without two places does nothing', () async {
      await vm().recalculate();
      await vm().pick(RouteField.start, _ka);
      await vm().recalculate();
      expect(service.calls, isEmpty);
    });
  });

  group('typing into a field', () {
    test('changing a picked place drops the pick, keeping the other', () async {
      await vm().pick(RouteField.start, _ka);
      await vm().pick(RouteField.end, _st);
      vm().onTextChanged(RouteField.end, 'Stuttg');
      expect(state().end, isNull);
      expect(state().start, _ka);
      expect(state().canRecalculate, isFalse);
    });

    test('the unchanged label keeps the pick and asks nothing', () async {
      await vm().pick(RouteField.start, _ka);
      service.calls.clear();
      vm().onTextChanged(RouteField.start, _ka.label);
      await pumpEventQueue();
      expect(state().start, _ka);
      expect(service.calls, isEmpty);
    });
  });

  group('saved places', () {
    test('loaded on start, offered as quick picks', () async {
      await places.save(PlaceKind.home, _ka);
      final c = make(service);
      await pumpEventQueue();
      final s = c.read(routeDistanceViewModelProvider);
      expect(s.savedOf(PlaceKind.home)?.place, _ka);
      expect(s.savedOf(PlaceKind.work), isNull);
    });

    test('a failing load leaves typing working', () async {
      places.failWith = const Storage('x');
      final c = make(service);
      await pumpEventQueue();
      expect(c.read(routeDistanceViewModelProvider).saved, isEmpty);
      await c
          .read(routeDistanceViewModelProvider.notifier)
          .search(RouteField.start, 'Karls');
      expect(c.read(routeDistanceViewModelProvider).suggestions, [_ka]);
    });

    test('pickSaved fills the first empty field, no request for one', () async {
      await places.save(PlaceKind.home, _ka);
      await places.save(PlaceKind.work, _st);
      await vm().loadSaved();
      final first = vm().pickSaved(PlaceKind.home)!;
      expect(first.field, RouteField.start);
      expect(first.place, _ka);
      await pumpEventQueue();
      vm().onTextChanged(RouteField.end, '');
      final second = vm().pickSaved(PlaceKind.work)!;
      expect(second.field, RouteField.end);
      await pumpEventQueue();
      expect(state().fill?.meters, 81000);
    });

    test('pickSaved without a saved place does nothing', () async {
      expect(vm().pickSaved(PlaceKind.home), isNull);
      expect(state().start, isNull);
    });

    test('savePlace stores the place and reloads', () async {
      await vm().pick(RouteField.start, _ka);
      final r = await vm().savePlace(RouteField.start, PlaceKind.home);
      expect(r, isA<Ok<Undo, RepositoryError>>());
      expect(state().savedOf(PlaceKind.home)?.place, _ka);
      // Undo, then reload: gone again.
      await (r! as Ok<Undo, RepositoryError>).value();
      await vm().refreshSaved();
      expect(state().savedOf(PlaceKind.home), isNull);
    });

    test('savePlace without a picked place is a no-op', () async {
      expect(await vm().savePlace(RouteField.end, PlaceKind.work), isNull);
    });

    test('savePlace failure is returned, not swallowed', () async {
      await vm().pick(RouteField.start, _ka);
      places.failWith = const Storage('disk full');
      final r = await vm().savePlace(RouteField.start, PlaceKind.home);
      expect(r, isA<Err<Undo, RepositoryError>>());
      expect(state().savedOf(PlaceKind.home), isNull);
    });
  });

  test('debugSnapshot mirrors the state', () async {
    await vm().pick(RouteField.start, _ka);
    await vm().pick(RouteField.end, _st);
    expect(vm().debugSnapshot(), {
      'available': true,
      'start': _ka.label,
      'end': _st.label,
      'meters': 81000,
      'manualOverride': false,
      'canRecalculate': false,
      'failure': null,
      'attribution': FakeRouteDistanceService.attribution,
    });
  });
}

class _LangSpy extends FakeRouteDistanceService {
  _LangSpy(this.langs);

  final List<String> langs;

  @override
  Future<RouteResult<List<PlaceSuggestion>>> suggest(
    String text, {
    required String lang,
  }) {
    langs.add(lang);
    return super.suggest(text, lang: lang);
  }
}
