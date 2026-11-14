import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio/features/trips/data/trip_meta.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../support/trip_examples.dart';
import '../../repo_test_support.dart';

/// Expenses fake whose `create` and stream can be made to fail.
class _FlakyExpenses implements ExpensesRepository {
  _FlakyExpenses(this._inner);

  final ExpensesRepository _inner;
  RepositoryError? createFails;
  Object? watchError;

  @override
  Stream<List<ExpenseEntry>> watchExpenses(String groupId) => watchError != null
      ? Stream.error(watchError!)
      : _inner.watchExpenses(groupId);

  @override
  Future<RepoResult<ExpenseEntry>> create(
    String groupId,
    ExpenseDraft draft,
  ) async =>
      createFails != null ? Err(createFails!) : _inner.create(groupId, draft);

  @override
  Future<RepoResult<ExpenseEntry>> get(String id) => _inner.get(id);

  @override
  Future<RepoResult<ExpenseEntry>> update(String id, ExpenseDraft draft) =>
      _inner.update(id, draft);

  @override
  Future<RepoResult<Undo>> softDelete(String id) => _inner.softDelete(id);

  @override
  Future<RepoResult<void>> restore(String id) => _inner.restore(id);
}

void main() {
  late FakeApp app;
  late _FlakyExpenses expenses;
  late ProviderContainer container;
  late Group grp;
  late List<GroupMember> people;

  List<Override> overrides() => [
    clockProvider.overrideWithValue(app.clock),
    groupsRepositoryProvider.overrideWithValue(app.groups),
    membersRepositoryProvider.overrideWithValue(app.members),
    expensesRepositoryProvider.overrideWithValue(expenses),
    settlementsRepositoryProvider.overrideWithValue(app.settlements),
    paymentDetailsRepositoryProvider.overrideWithValue(app.payments),
    linkLauncherProvider.overrideWithValue(app.launcher),
    shareServiceProvider.overrideWithValue(app.share),
  ];

  TripFormViewModel vm([String? id]) =>
      container.read(tripFormViewModelProvider(id ?? grp.id).notifier);
  TripFormState state([String? id]) =>
      container.read(tripFormViewModelProvider(id ?? grp.id));
  TripFormLoaded loaded() => state() as TripFormLoaded;
  TripEvaluation eval() => loaded().evaluation;
  TripFormLoaded loaded0(String id) => state(id) as TripFormLoaded;

  Future<void> open([String? id]) async {
    container.listen(tripFormViewModelProvider(id ?? grp.id), (_, _) {});
    await pumpEventQueue();
  }

  /// The "250 km, 6.5 l, 1.799" example from docs/domain-rules.md.
  void fillExample() {
    vm()
      ..setDistance('250')
      ..setConsumption('6,5')
      ..setPrice('1.799');
  }

  Future<List<ExpenseEntry>> stored() => expenses.watchExpenses(grp.id).first;

  setUp(() async {
    app = FakeApp();
    expenses = _FlakyExpenses(app.expenses);
    container = ProviderContainer(
      overrides: overrides(),
    );
    addTearDown(container.dispose);
    grp = ok(
      await app.groups.create(
        name: 'Pendeln',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Anna', 'Ben', 'Chiara'])
        ok(await app.members.add(grp.id, name: n)),
    ];
  });

  group('loading', () {
    test('starts loading, then asks for the numbers', () async {
      container.listen(tripFormViewModelProvider(grp.id), (_, _) {});
      expect(state(), isA<TripFormLoading>());
      await pumpEventQueue();
      expect(loaded().group, grp);
      expect(eval().cost, isNull);
      expect(eval().blocker, TripBlocker.needsInput);
      expect(vm().debugSnapshot()['status'], 'incomplete');
    });

    test('first member drives, the others ride along', () async {
      await open();
      expect(loaded().inputs.driverId, people[0].id);
      expect(loaded().inputs.passengerIds, {people[1].id, people[2].id});
      expect(loaded().inputs.driverCounts, isTrue);
      expect(loaded().canSave, isFalse);
    });

    test('a group without members has nobody to drive', () async {
      final empty = ok(
        await app.groups.create(
          name: 'Leer',
          currency: Currency.eur,
          createdBy: 'dev',
        ),
      );
      await open(empty.id);
      final s = state(empty.id) as TripFormLoaded;
      expect(s.members, isEmpty);
      expect(s.inputs.driverId, isNull);
      expect(s.evaluation.blocker, TripBlocker.needsInput);
    });

    test('unknown group is a failure; retry starts over', () async {
      await open('nope');
      expect(
        (state('nope') as TripFormFailure).error,
        const NotFound('group', 'nope'),
      );
      expect(vm('nope').debugSnapshot()['status'], 'error');
      vm('nope').retry();
      expect(state('nope'), isA<TripFormLoading>());
      await pumpEventQueue();
      expect(state('nope'), isA<TripFormFailure>());
    });

    test('a failing store is a failure', () async {
      expenses.watchError = StateError('down');
      await open();
      expect((state() as TripFormFailure).error, isA<Storage>());
    });

    test('starts from the last trip: driver, passengers, vehicle', () async {
      await open();
      vm()
        ..setDriver(people[1].id)
        ..togglePassenger(people[2].id)
        ..setDriverCounts(value: false)
        ..setRoundTrip(value: true)
        ..setEnergy(TripEnergy.electric)
        ..setDistance('10')
        ..setConsumption('18,5')
        ..setPrice('0,32')
        ..setWear('0,05');
      ok(await vm().save(fallbackTitle: 'Fahrt'));

      final next = ProviderContainer(
        overrides: overrides(),
      );
      addTearDown(next.dispose);
      next.listen(tripFormViewModelProvider(grp.id), (_, _) {});
      await pumpEventQueue();
      final s = next.read(tripFormViewModelProvider(grp.id)) as TripFormLoaded;
      expect(s.inputs.driverId, people[1].id);
      expect(s.inputs.passengerIds, {people[0].id});
      expect(s.inputs.driverCounts, isFalse);
      expect(s.inputs.roundTrip, isTrue);
      expect(s.inputs.energy, TripEnergy.electric);
      expect(s.inputs.consumption, '18.5');
      expect(s.inputs.price, '0.32');
      expect(s.inputs.wear, '0.05');
      expect(s.inputs.distance, isEmpty);
      expect(s.inputs.tolls, isEmpty);
    });

    test('a remembered km rate is restored without wear', () async {
      await open();
      vm()
        ..setUseKmRate(value: true)
        ..setDistance('100')
        ..setKmRate('0,3');
      ok(await vm().save(fallbackTitle: 'Fahrt'));
      final next = ProviderContainer(
        overrides: overrides(),
      );
      addTearDown(next.dispose);
      next.listen(tripFormViewModelProvider(grp.id), (_, _) {});
      await pumpEventQueue();
      final s = next.read(tripFormViewModelProvider(grp.id)) as TripFormLoaded;
      expect(s.inputs.useKmRate, isTrue);
      expect(s.inputs.kmRate, '0.3');
    });

    test('forgets people who left the group', () async {
      await open();
      vm()
        ..setDriver(people[2].id)
        ..setDistance('10')
        ..setConsumption('6')
        ..setPrice('1.5');
      ok(await vm().save(fallbackTitle: 'Fahrt'));
      ok(await app.members.softDelete(people[2].id));
      final next = ProviderContainer(
        overrides: overrides(),
      );
      addTearDown(next.dispose);
      next.listen(tripFormViewModelProvider(grp.id), (_, _) {});
      await pumpEventQueue();
      final s = next.read(tripFormViewModelProvider(grp.id)) as TripFormLoaded;
      expect(s.inputs.driverId, people[0].id);
      expect(s.inputs.passengerIds, {people[1].id});
    });
  });

  group('result', () {
    setUp(() async => open());

    test('consumption: the documented example', () {
      fillExample();
      final e = eval();
      expect(e.cost!.fuelCents, 2923);
      expect(e.cost!.totalCents, 2923);
      expect(e.perPersonCents, 975);
      expect(e.sharesEqual, isFalse);
      expect(e.driverGetsCents, 2923 - 975);
      expect(e.participantShares, {
        people[0].id: 975,
        people[1].id: 974,
        people[2].id: 974,
      });
      expect(loaded().canSave, isTrue);
    });

    test('equal shares are reported as equal', () {
      vm()
        ..setUseKmRate(value: true)
        ..setDistance('250')
        ..setKmRate('0.30')
        ..setDriverCounts(value: false);
      expect(eval().cost!.kmRateCents, 7500);
      expect(eval().perPersonCents, 3750);
      expect(eval().sharesEqual, isTrue);
      expect(eval().driverGetsCents, 7500);
    });

    test('round trip doubles the distance once', () {
      fillExample();
      vm()
        ..setRoundTrip(value: true)
        ..togglePassenger(people[2].id);
      expect(eval().cost!.totalCents, 5847);
    });

    test('wear, tolls and ferry are added; blank means none', () {
      fillExample();
      vm()
        ..setWear('0,05')
        ..setTolls('11,50')
        ..setFerry('2');
      expect(eval().cost!.wearCents, 1250);
      expect(eval().cost!.tollsCents, 1150);
      expect(eval().cost!.ferryCents, 200);
      expect(eval().cost!.totalCents, 2923 + 1250 + 1150 + 200);
    });

    test('a km rate ignores consumption and price', () {
      vm()
        ..setDistance('250')
        ..setConsumption('abc')
        ..setUseKmRate(value: true)
        ..setKmRate('0,3');
      expect(eval().cost!.totalCents, 7500);
      expect(eval().invalid, isEmpty);
    });

    test('an electric vehicle computes the same way', () {
      fillExample();
      vm().setEnergy(TripEnergy.electric);
      expect(loaded().inputs.energy, TripEnergy.electric);
      expect(eval().cost!.totalCents, 2923);
    });

    test('missing numbers: no result, nothing flagged', () {
      vm().setDistance('250');
      expect(eval().cost, isNull);
      expect(eval().blocker, TripBlocker.needsInput);
      expect(eval().invalid, isEmpty);
      expect(eval().perPersonCents, isNull);
      expect(eval().sharesEqual, isFalse);
      expect(eval().driverGetsCents, isNull);
      expect(eval().participantShares, isNull);
      vm()
        ..setConsumption('6,5')
        ..setPrice('');
      expect(eval().cost, isNull);
      vm()
        ..setUseKmRate(value: true)
        ..setKmRate('');
      expect(eval().cost, isNull);
    });

    test('unreadable numbers are flagged per field', () {
      vm()
        ..setDistance('1.2.3')
        ..setConsumption('x')
        ..setPrice('-1')
        ..setWear('1e3')
        ..setTolls('12,345')
        ..setFerry('abc');
      expect(eval().cost, isNull);
      expect(eval().invalid, {
        TripField.distance,
        TripField.consumption,
        TripField.price,
        TripField.wear,
        TripField.tolls,
        TripField.ferry,
      });
      vm()
        ..setUseKmRate(value: true)
        ..setKmRate('..');
      expect(eval().invalid, contains(TripField.kmRate));
    });

    test('zero distance gives no result', () {
      fillExample();
      vm().setDistance('0');
      expect(eval().cost, isNull);
      expect(eval().blocker, TripBlocker.needsInput);
    });

    test('nobody sharing the cost is its own message', () {
      fillExample();
      vm()
        ..togglePassenger(people[1].id)
        ..togglePassenger(people[2].id)
        ..setDriverCounts(value: false);
      expect(eval().blocker, TripBlocker.noParticipants);
      expect(loaded().canSave, isFalse);
    });

    test('a huge trip is too large instead of crashing', () {
      vm()
        ..setDistance('999999999')
        ..setConsumption('999999999')
        ..setPrice('999999999');
      expect(eval().blocker, TripBlocker.tooLarge);
    });

    test('driver and passenger commands keep the sets consistent', () {
      vm().togglePassenger(people[0].id);
      expect(loaded().inputs.passengerIds, {people[1].id, people[2].id});
      vm().setDriver(people[0].id);
      expect(loaded().inputs.passengerIds, {people[1].id, people[2].id});
      vm().setDriver(people[1].id);
      expect(loaded().inputs.driverId, people[1].id);
      expect(loaded().inputs.passengerIds, {people[0].id, people[2].id});
      vm().togglePassenger(people[0].id);
      expect(loaded().inputs.passengerIds, {people[2].id});
      vm().togglePassenger(people[0].id);
      expect(loaded().inputs.passengerIds, {people[0].id, people[2].id});
    });

    test('edits before loading are ignored', () {
      final other = ProviderContainer(overrides: overrides());
      addTearDown(other.dispose);
      other.read(tripFormViewModelProvider(grp.id).notifier)
        ..setDistance('1')
        ..setTitle('x');
      expect(
        other.read(tripFormViewModelProvider(grp.id)),
        isA<TripFormLoading>(),
      );
    });

    test('debugSnapshot shows inputs and result', () {
      fillExample();
      vm().setTitle('Büro');
      final snap = vm().debugSnapshot();
      expect(snap['status'], 'result');
      expect(snap['currency'], 'EUR');
      expect((snap['inputs']! as Map)['title'], 'Büro');
      expect((snap['inputs']! as Map)['distance'], '250');
      expect((snap['result']! as Map)['totalCents'], 2923);
      expect((snap['result']! as Map)['perPersonCents'], 975);
      expect((snap['result']! as Map)['driverGetsCents'], 1948);
      expect(snap['blocker'], isNull);
      vm().setDistance('x');
      expect(vm().debugSnapshot()['invalid'], ['distance']);
      expect(vm().debugSnapshot()['blocker'], 'needsInput');
    });
  });

  group('docs/domain-rules.md examples:trip', () {
    for (final ex in tripExamples()) {
      test('${ex.name}: shares and saved expense', () async {
        final ids = {'A': people[0].id, 'B': people[1].id, 'C': people[2].id};
        final saved = ok(
          await vm().add(ex.inputs(ids), fallbackTitle: 'Fahrt'),
        );
        expect(saved.entry.expense.amountCents, ex.total);
        expect(saved.entry.expense.shares, {
          for (final e in ids.entries) e.value: ex.shares[e.key] ?? 0,
        });
        expect(saved.entry.expense.payers, {ids[ex.letters.first]!: ex.total});
      });
    }
  });

  group('save', () {
    setUp(() async => open());

    test('stores a trip expense with its inputs for re-editing', () async {
      fillExample();
      vm().setTitle('  Büro  ');
      final saved = ok(await vm().save(fallbackTitle: 'Fahrt'));
      final e = saved.entry;
      expect(e.expense.title, 'Büro');
      expect(e.expense.amountCents, 2923);
      expect(e.expense.date, DateTime.utc(2026, 3, 1, 12));
      expect(e.expense.payers, {people[0].id: 2923});
      expect(e.expense.shares, {
        people[0].id: 975,
        people[1].id: 974,
        people[2].id: 974,
      });
      final meta = TripMeta.tryParse(e.tripMeta)!;
      expect(meta.distanceMeters, 250000);
      expect(meta.driverId, people[0].id);
      expect(meta.passengerIds, {people[1].id, people[2].id});
      expect(
        meta.mode,
        isA<Consumption>()
            .having((m) => m.consumptionMilliPer100km, 'consumption', 6500)
            .having((m) => m.pricePerUnitMilli, 'price', 1799),
      );
      expect(loaded().saving, isFalse);
    });

    test('uses the fallback title when none is typed', () async {
      fillExample();
      final saved = ok(await vm().save(fallbackTitle: 'Fahrt'));
      expect(saved.entry.expense.title, 'Fahrt');
    });

    test('a driver who rides free pays nothing', () async {
      fillExample();
      vm().setDriverCounts(value: false);
      final saved = ok(await vm().save(fallbackTitle: 'Fahrt'));
      expect(saved.entry.expense.shares, {
        people[0].id: 0,
        people[1].id: 1462,
        people[2].id: 1461,
      });
    });

    test('undo takes the trip back', () async {
      fillExample();
      final saved = ok(await vm().save(fallbackTitle: 'Fahrt'));
      expect(await stored(), hasLength(1));
      ok(await saved.undo());
      expect(await stored(), isEmpty);
    });

    test('undo reports a repository failure', () async {
      fillExample();
      final saved = ok(await vm().save(fallbackTitle: 'Fahrt'));
      ok(await app.expenses.softDelete(saved.entry.expense.id));
      expect(err(await saved.undo()), isA<NotFound>());
    });

    test('refuses while the inputs give no result', () async {
      vm().setDistance('250');
      expect(err(await vm().save(fallbackTitle: 'Fahrt')), isA<InvalidData>());
      expect(await stored(), isEmpty);
    });

    test('a zero total is invalid data', () async {
      vm()
        ..setDistance('250')
        ..setConsumption('0')
        ..setPrice('1.5');
      expect(eval().cost!.totalCents, 0);
      expect(err(await vm().save(fallbackTitle: 'Fahrt')), isA<InvalidData>());
    });

    test('reports a repository failure and stays editable', () async {
      fillExample();
      expenses.createFails = const Storage('disk full');
      expect(
        err(await vm().save(fallbackTitle: 'Fahrt')),
        const Storage('disk full'),
      );
      expect(loaded().saving, isFalse);
      expect(loaded().canSave, isTrue);
      expect(await stored(), isEmpty);
    });

    test('reports a failing group lookup', () async {
      fillExample();
      ok(await app.groups.softDelete(grp.id));
      expect(err(await vm().save(fallbackTitle: 'Fahrt')), isA<NotFound>());
    });

    test('save before loading is not found', () async {
      final other = ProviderContainer(overrides: overrides());
      addTearDown(other.dispose);
      expect(
        err(
          await other
              .read(tripFormViewModelProvider(grp.id).notifier)
              .save(fallbackTitle: 'Fahrt'),
        ),
        isA<NotFound>(),
      );
    });

    test('add fails for an unknown group', () async {
      expect(
        err(
          await vm('nope').add(
            const TripInputs(driverId: 'x'),
            fallbackTitle: 'Fahrt',
          ),
        ),
        isA<NotFound>(),
      );
    });
  });

  group('standalone (no group)', () {
    const id = standaloneTripGroupId;

    test('opens with five anonymous seats, two of them taking part', () async {
      await open(id);
      final s = state(id) as TripFormLoaded;
      expect(s.members, hasLength(5));
      expect(s.inputs.driverId, s.members.first.id);
      expect(s.inputs.passengerIds, {s.members[1].id});
      expect(s.group.currency, Currency.eur);
      expect(vm(id).isStandalone, isTrue);
      expect(vm().isStandalone, isFalse);
    });

    test('shows the result like in a group', () async {
      await open(id);
      vm(id)
        ..setDistance('250')
        ..setConsumption('6,5')
        ..setPrice('1.799');
      final s = state(id) as TripFormLoaded;
      expect(s.evaluation.cost, isNotNull);
      expect(s.evaluation.cost!.totalCents, 2923);
      expect(s.evaluation.perPersonCents, 1462);
    });

    test('nothing is stored: no group, no expense', () async {
      await open(id);
      vm(id)
        ..setDistance('250')
        ..setConsumption('6,5')
        ..setPrice('1.799');
      final result = await vm(id).add(
        loaded0(id).inputs,
        fallbackTitle: 'Fahrt',
      );
      expect(result, isA<Err<TripSaved, RepositoryError>>());
      expect(await app.groups.watchGroups().first, [grp]);
    });

    test('shares the result through the share sheet', () async {
      await open(id);
      vm(id)
        ..setDistance('250')
        ..setConsumption('6,5')
        ..setPrice('1.799');
      final result = await vm(id).shareResult((perPerson) => 'pp $perPerson');
      expect(result, isA<Ok<void, RepositoryError>>());
      expect(app.share.shared, ['pp 1462']);
    });

    test('there is nothing to share without a result', () async {
      await open(id);
      expect(await vm(id).shareResult((_) => 'x'), isNull);
      expect(app.share.shared, isEmpty);
    });
  });

  group('TripMeta', () {
    test('round-trips both modes', () {
      for (final mode in <TripCostMode>[
        const Consumption(
          consumptionMilliPer100km: 6500,
          pricePerUnitMilli: 1799,
          wearMilliPerKm: 50,
        ),
        const KmRate(300),
      ]) {
        final meta = TripMeta(
          distanceMeters: 1000,
          roundTrip: true,
          energy: TripEnergy.electric,
          mode: mode,
          tollsCents: 5,
          ferryCents: 6,
          driverId: 'a',
          passengerIds: const {'c', 'b'},
          driverCounts: false,
        );
        final back = TripMeta.tryParse(meta.toJson())!;
        expect(back.toJson(), meta.toJson());
        expect(back.energy, TripEnergy.electric);
        expect(back.passengerIds, {'b', 'c'});
      }
    });

    test('rejects anything that is not a version 1 document', () {
      expect(TripMeta.tryParse(null), isNull);
      expect(TripMeta.tryParse('nope'), isNull);
      expect(TripMeta.tryParse('[]'), isNull);
      expect(TripMeta.tryParse('{"v":2}'), isNull);
      expect(TripMeta.tryParse('{"v":1,"mode":"x"}'), isNull);
      expect(TripMeta.tryParse('{"v":1,"mode":"kmRate"}'), isNull);
    });
  });
}
