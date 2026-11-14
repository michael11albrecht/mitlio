import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'expenses_fixtures.dart';

void main() {
  late ExpensesApp app;
  late ProviderContainer container;

  ExpensesViewModel vm() =>
      container.read(expensesViewModelProvider(app.trip.id).notifier);
  ExpensesState state() =>
      container.read(expensesViewModelProvider(app.trip.id));
  ExpensesLoaded loaded() => state() as ExpensesLoaded;
  List<String> titles() => [for (final e in loaded().visible) e.expense.title];

  Future<void> open() async {
    container.listen(expensesViewModelProvider(app.trip.id), (_, _) {});
    await pumpEventQueue();
  }

  ExpenseDraft draft({String title = 'Pizza', int cents = 1000}) =>
      ExpenseDraft(
        title: title,
        amountCents: cents,
        currency: Currency.eur,
        date: DateTime.utc(2026, 3),
        payers: {app.people[0].id: cents},
        split: EqualSplit({for (final p in app.people) p.id}),
      );

  setUp(() async {
    app = ExpensesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedTrip();
  });

  group('state', () {
    test('loading, then empty', () async {
      container.listen(expensesViewModelProvider(app.trip.id), (_, _) {});
      expect(state(), isA<ExpensesLoading>());
      await pumpEventQueue();
      expect(loaded().isEmpty, isTrue);
      expect(loaded().days, isEmpty);
      expect(loaded().group.id, app.trip.id);
      expect(loaded().members, hasLength(3));
      expect(loaded().today, DateTime.utc(2026, 3));
    });

    test('groups by day, newest day first, newest entry first', () async {
      await app.add(title: 'Alt', date: DateTime.utc(2026, 2, 20));
      await app.add(title: 'Neu A', date: DateTime.utc(2026, 3));
      await app.add(title: 'Neu B', date: DateTime.utc(2026, 3));
      await app.add(title: 'Mitte', date: DateTime.utc(2026, 2, 27));
      await open();
      final days = loaded().days;
      expect(
        [for (final d in days) d.date],
        [
          DateTime.utc(2026, 3),
          DateTime.utc(2026, 2, 27),
          DateTime.utc(2026, 2, 20),
        ],
      );
      expect(
        [for (final e in days.first.entries) e.expense.title],
        [
          'Neu B',
          'Neu A',
        ],
      );
    });

    test('follows the repository', () async {
      await open();
      ok(await vm().add(draft()));
      await pumpEventQueue();
      expect(titles(), ['Pizza']);
    });

    test('a missing group is a not-found failure', () async {
      const key = 'nope';
      container.listen(expensesViewModelProvider(key), (_, _) {});
      await pumpEventQueue();
      expect(
        container.read(expensesViewModelProvider(key)),
        isA<ExpensesFailure>().having((f) => f.error, 'error', isA<NotFound>()),
      );
    });

    test('a failing store is a failure; retry recovers', () async {
      app.expenses.watchError = const Storage('down');
      await open();
      expect(state(), isA<ExpensesFailure>());
      app.expenses.watchError = null;
      vm().retry();
      await pumpEventQueue();
      expect(state(), isA<ExpensesLoaded>());
    });

    test('a non-repository stream error becomes Storage', () async {
      app.expenses.watchError = StateError('x');
      await open();
      expect((state() as ExpensesFailure).error, isA<Storage>());
    });
  });

  group('filters', () {
    setUp(() async {
      await app.add(
        payers: {app.people[0].id: 900},
        split: EqualSplit({app.people[0].id, app.people[1].id}),
        category: 'transport',
      );
      await app.add(
        title: 'Pizza',
        payers: {app.people[1].id: 900},
        category: 'food',
      );
      await app.add(
        title: 'Kino',
        payers: {app.people[2].id: 900},
        split: EqualSplit({app.people[2].id}),
        category: 'custom',
      );
      await app.add(title: 'Ohne');
      await open();
    });

    test('by member: payer or taking part', () async {
      vm().setMemberFilter(app.people[1].id);
      expect(titles(), unorderedEquals(['Pizza', 'Taxi', 'Ohne']));
      vm().setMemberFilter(app.people[2].id);
      expect(titles(), unorderedEquals(['Pizza', 'Kino', 'Ohne']));
      expect(loaded().hasFilter, isTrue);
    });

    test('by category', () async {
      vm().setCategoryFilter('food');
      expect(titles(), ['Pizza']);
    });

    test('both filters combine', () async {
      vm().setMemberFilter(app.people[0].id);
      vm().setCategoryFilter('transport');
      expect(titles(), ['Taxi']);
      vm().setMemberFilter(app.people[1].id);
      vm().setCategoryFilter('custom');
      expect(titles(), isEmpty);
      expect(loaded().isEmpty, isFalse);
    });

    test('clearing shows everything again', () async {
      vm().setMemberFilter(app.people[1].id);
      vm().setCategoryFilter('food');
      vm().clearFilters();
      expect(loaded().hasFilter, isFalse);
      expect(titles(), hasLength(4));
      vm().setMemberFilter(app.people[1].id);
      vm().setMemberFilter(null);
      expect(titles(), hasLength(4));
    });

    test('categories in use: known order first, custom after', () {
      expect(loaded().categories, ['food', 'transport', 'custom']);
    });

    test('looks members up by id', () {
      expect(loaded().member(app.people[1].id)?.name, 'Ben');
      expect(loaded().member('nope'), isNull);
    });
  });

  group('delete', () {
    test('soft deletes and undo brings it back', () async {
      final e = await app.add();
      await open();
      final undo = ok(await vm().delete(e.expense.id));
      await pumpEventQueue();
      expect(titles(), isEmpty);
      ok(await undo());
      await pumpEventQueue();
      expect(titles(), ['Taxi']);
    });

    test('an unknown id is not found', () async {
      await open();
      expect(err(await vm().delete('nope')), isA<NotFound>());
    });

    test('a failing repository is returned', () async {
      final e = await app.add();
      await open();
      app.expenses.failWith = const Storage('x');
      expect(err(await vm().delete(e.expense.id)), isA<Storage>());
      await pumpEventQueue();
      expect(titles(), ['Taxi']);
    });
  });

  group('add and update', () {
    test('add validates through the domain', () async {
      await open();
      expect(err(await vm().add(draft(title: ' '))), isA<InvalidData>());
      expect(err(await vm().add(draft(cents: 0))), isA<InvalidData>());
    });

    test('add reports a failing repository', () async {
      await open();
      app.expenses.failWith = const Storage('x');
      expect(err(await vm().add(draft())), isA<Storage>());
    });

    test('update replaces the expense', () async {
      final e = await app.add();
      await open();
      final updated = ok(await vm().update(e.expense.id, draft(title: 'Neu')));
      expect(updated.expense.id, e.expense.id);
      await pumpEventQueue();
      expect(titles(), ['Neu']);
    });

    test('update of an unknown expense is not found', () async {
      await open();
      expect(err(await vm().update('nope', draft())), isA<NotFound>());
    });
  });

  group('list', () {
    test('returns the stored expenses', () async {
      await app.add();
      expect(
        [for (final e in ok(await vm().list())) e.expense.title],
        ['Taxi'],
      );
    });

    test('a failing store is an Err', () async {
      app.expenses.watchError = const Storage('x');
      expect(err(await vm().list()), isA<Storage>());
      app.expenses.watchError = StateError('y');
      expect(err(await vm().list()), isA<Storage>());
    });
  });

  group('debugSnapshot', () {
    test('loading, error, empty and data', () async {
      container.listen(expensesViewModelProvider(app.trip.id), (_, _) {});
      expect(vm().debugSnapshot(), {'status': 'loading', 'groupId': 'id-1'});
      await pumpEventQueue();
      expect(vm().debugSnapshot(), {
        'status': 'empty',
        'groupId': 'id-1',
        'currency': 'EUR',
        'filter': {'memberId': null, 'category': null},
        'visible': 0,
        'expenses': <Object?>[],
      });

      final e = await app.add(category: 'transport');
      await pumpEventQueue();
      vm().setCategoryFilter('transport');
      final snap = vm().debugSnapshot();
      expect(snap['status'], 'data');
      expect(snap['filter'], {'memberId': null, 'category': 'transport'});
      expect((snap['expenses']! as List<Object?>).single, {
        'id': e.expense.id,
        'title': 'Taxi',
        'amountCents': 900,
        'currency': 'EUR',
        'date': '2026-02-01',
        'category': 'transport',
        'payers': {app.people[0].id: 900},
        'shares': {for (final p in app.people) p.id: 300},
        'splitMode': 'equal',
      });

      app.expenses.watchError = const Storage('x');
      vm().retry();
      await pumpEventQueue();
      expect(vm().debugSnapshot()['status'], 'error');
    });
  });

  test('isoDay pads and uses the UTC day', () {
    expect(isoDay(DateTime.utc(2026, 3, 5)), '2026-03-05');
    expect(isoDay(DateTime.utc(987, 12, 31)), '0987-12-31');
  });
}
