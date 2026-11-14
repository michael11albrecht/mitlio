// Justification: one command per line reads as the user's steps.
// ignore_for_file: cascade_invocations

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'expenses_fixtures.dart';

void main() {
  late ExpensesApp app;
  late ProviderContainer container;

  ExpenseFormKey newKey() => (groupId: app.trip.id, expenseId: null);

  ExpenseFormViewModel vm([ExpenseFormKey? key]) => container.read(
    expenseFormViewModelProvider(key ?? newKey()).notifier,
  );

  ExpenseFormReady ready([ExpenseFormKey? key]) =>
      container.read(expenseFormViewModelProvider(key ?? newKey()))
          as ExpenseFormReady;

  Future<ExpenseFormViewModel> open([ExpenseFormKey? key]) async {
    container.listen(
      expenseFormViewModelProvider(key ?? newKey()),
      (_, _) {},
    );
    await pumpEventQueue();
    return vm(key);
  }

  String id(int i) => app.people[i].id;

  setUp(() async {
    app = ExpensesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedTrip();
  });

  group('loading', () {
    test('starts loading, then offers a valid-looking empty form', () async {
      container.listen(expenseFormViewModelProvider(newKey()), (_, _) {});
      expect(
        container.read(expenseFormViewModelProvider(newKey())),
        isA<ExpenseFormLoading>(),
      );
      await pumpEventQueue();
      final s = ready();
      expect(s.group.id, app.trip.id);
      expect(s.editing, isFalse);
      expect(s.mode, SplitMode.equal);
      expect(s.participants, {id(0), id(1), id(2)});
      expect(s.payerId, id(0));
      expect(s.multiPayer, isFalse);
      expect(s.date, DateTime.utc(2026, 3));
      expect(s.amountMissing, isTrue);
      expect(s.titleMissing, isTrue);
      expect(s.preview, isEmpty);
      expect(s.showErrors, isFalse);
    });

    test('the date comes from the injected clock', () async {
      app.base.clock.value = DateTime.utc(2027, 12, 31, 23);
      await open();
      expect(ready().date, DateTime.utc(2027, 12, 31));
    });

    test('the newest expense decides the default payer', () async {
      await app.add(payers: {id(2): 900});
      await open();
      expect(ready().payerId, id(2));
    });

    test('with several payers the biggest one is the default', () async {
      await app.add(payers: {id(1): 300, id(2): 600});
      await open();
      expect(ready().payerId, id(2));
    });

    test('an unknown group is reported as not found', () async {
      const key = (groupId: 'nope', expenseId: null);
      await open(key);
      expect(
        container.read(expenseFormViewModelProvider(key)),
        isA<ExpenseFormFailure>().having(
          (f) => f.error,
          'error',
          isA<NotFound>(),
        ),
      );
    });

    test('an unknown expense is reported as not found', () async {
      final key = (groupId: app.trip.id, expenseId: 'nope');
      await open(key);
      expect(
        container.read(expenseFormViewModelProvider(key)),
        isA<ExpenseFormFailure>(),
      );
    });

    test('a failing store is reported; retry recovers', () async {
      app.expenses.watchError = const Storage('down');
      await open();
      expect(
        container.read(expenseFormViewModelProvider(newKey())),
        isA<ExpenseFormFailure>(),
      );
      expect(vm().debugSnapshot()['status'], 'error');

      app.expenses.watchError = null;
      vm().retry();
      await pumpEventQueue();
      expect(ready().group.id, app.trip.id);
    });
  });

  group('equal split', () {
    test('previews each share with the largest remainder', () async {
      final f = await open();
      f.setAmount(1000);
      expect(ready().preview, {id(0): 334, id(1): 333, id(2): 333});
      expect(ready().splitError, isNull);
      expect(ready().amountMissing, isFalse);
    });

    test('excluding a person re-divides among the rest', () async {
      final f = await open();
      f.setAmount(1000);
      f.toggleParticipant(id(1));
      expect(ready().participants, {id(0), id(2)});
      expect(ready().preview, {id(0): 500, id(1): 0, id(2): 500});
      f.toggleParticipant(id(1));
      expect(ready().participants, {id(0), id(1), id(2)});
    });

    test('nobody taking part is an error', () async {
      final f = await open();
      f.setAmount(1000);
      for (var i = 0; i < 3; i++) {
        f.toggleParticipant(id(i));
      }
      expect(ready().splitError, const NoParticipants());
      expect(ready().preview, isEmpty);
    });

    test('a zero amount counts as missing', () async {
      final f = await open();
      f.setAmount(0);
      expect(ready().amountMissing, isTrue);
      f.setAmount(null);
      expect(ready().amountMissing, isTrue);
    });
  });

  group('shares', () {
    test('start at 1 each and weigh the preview', () async {
      final f = await open();
      f.setAmount(1200);
      f.setMode(SplitMode.shares);
      expect(ready().weights, {id(0): 1, id(1): 1, id(2): 1});
      f.setWeight(id(0), 2);
      expect(ready().preview, {id(0): 600, id(1): 300, id(2): 300});
    });

    test('weight 0 or null excludes a person', () async {
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.shares);
      f.setWeight(id(1), 0);
      f.setWeight(id(2), null);
      expect(ready().participants, {id(0)});
      expect(ready().preview[id(0)], 1000);
    });

    test('all weights 0 is an error', () async {
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.shares);
      for (var i = 0; i < 3; i++) {
        f.setWeight(id(i), 0);
      }
      expect(ready().splitError, const NoParticipants());
    });
  });

  group('percent', () {
    test('starts evenly summing to 100 %', () async {
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.percent);
      expect(ready().weights.values.fold<int>(0, (a, b) => a + b), 10000);
      expect(ready().splitError, isNull);
      expect(ready().preview.values.fold<int>(0, (a, b) => a + b), 1000);
    });

    test('a sum other than 100 % is reported, not hidden', () async {
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.percent);
      f.setWeight(id(0), 5000);
      f.setWeight(id(1), 2000);
      f.setWeight(id(2), 2000);
      expect(ready().splitError, const PercentNotFull(9000));
      expect(ready().preview, isEmpty);
      f.setWeight(id(2), 3000);
      expect(ready().splitError, isNull);
      expect(ready().preview, {id(0): 500, id(1): 200, id(2): 300});
    });
  });

  group('exact', () {
    test('starts with an even split of the amount', () async {
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.exact);
      expect(ready().weights, {id(0): 334, id(1): 333, id(2): 333});
      expect(ready().splitError, isNull);
    });

    test(
      'a mismatch is reported and the entered amounts stay visible',
      () async {
        final f = await open();
        f.setAmount(1000);
        f.setMode(SplitMode.exact);
        f.setWeight(id(0), 500);
        expect(ready().splitError, const ExactMismatch(1166, 1000));
        expect(ready().preview[id(0)], 500);
        f.setWeight(id(0), 334);
        f.setWeight(id(1), 333);
        f.setWeight(id(2), 333);
        expect(ready().splitError, isNull);
      },
    );

    test('without an amount the start is empty until one is entered', () async {
      final f = await open();
      f.setMode(SplitMode.exact);
      expect(ready().weights, isEmpty);
      expect(ready().amountMissing, isTrue);
    });

    test('negative values are rejected by the domain', () async {
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.exact);
      f.setWeight(id(0), -5);
      // Non-positive entries are dropped from the spec, so the rest must add
      // up; here it does not.
      expect(ready().splitError, isA<ExactMismatch>());
    });
  });

  group('switching modes', () {
    test('keeps who takes part', () async {
      final f = await open();
      f.setAmount(1000);
      f.toggleParticipant(id(1));
      f.setMode(SplitMode.shares);
      expect(ready().participants, {id(0), id(2)});
      f.setMode(SplitMode.equal);
      expect(ready().participants, {id(0), id(2)});
    });

    test('switching to the same mode changes nothing', () async {
      final f = await open();
      f.setAmount(1000);
      final before = ready().preview;
      f.setMode(SplitMode.equal);
      expect(ready().preview, before);
    });

    test('keeps the entered values when coming back', () async {
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.shares);
      f.setWeight(id(0), 3);
      f.setMode(SplitMode.equal);
      f.setMode(SplitMode.shares);
      expect(ready().weights[id(0)], 3);
    });

    test('setWeight is ignored in equal mode', () async {
      final f = await open();
      f.setAmount(1000);
      f.setWeight(id(0), 5);
      expect(ready().weights, isEmpty);
    });
  });

  group('payers', () {
    test('single payer by default; pick another', () async {
      final f = await open();
      f.setAmount(900);
      f.setPayer(id(2));
      expect(f.debugSnapshot()['payers'], {id(2): 900});
      expect(ready().payerError, isNull);
    });

    test(
      'several payers start with the current one owning the amount',
      () async {
        final f = await open();
        f.setAmount(900);
        f.setMultiplePayers(on: true);
        expect(ready().payerCents, {id(0): 900});
        f.setPayerAmount(id(0), 500);
        expect(ready().payerError, const PayersMismatch(500, 900));
        f.setPayerAmount(id(1), 400);
        expect(ready().payerError, isNull);
        expect(f.debugSnapshot()['payers'], {id(0): 500, id(1): 400});
      },
    );

    test('a payer amount of 0 or null removes the payer', () async {
      final f = await open();
      f.setAmount(900);
      f.setMultiplePayers(on: true);
      f.setPayerAmount(id(1), 900);
      f.setPayerAmount(id(0), 0);
      expect(f.debugSnapshot()['payers'], {id(1): 900});
      f.setPayerAmount(id(1), null);
      expect(ready().payerError, const NoPayer());
    });

    test('going back to a single payer drops the amounts', () async {
      final f = await open();
      f.setAmount(900);
      f.setMultiplePayers(on: true);
      f.setPayerAmount(id(1), 300);
      f.setMultiplePayers(on: false);
      expect(ready().multiPayer, isFalse);
      expect(ready().payerCents, isEmpty);
      // Idempotent.
      f.setMultiplePayers(on: false);
      expect(ready().multiPayer, isFalse);
    });

    test('multi payers without an amount yet start empty', () async {
      final f = await open();
      f.setMultiplePayers(on: true);
      expect(ready().payerCents, isEmpty);
    });
  });

  group('save', () {
    test('stores a valid equal expense and the list sees it', () async {
      final f = await open();
      f.setTitle('  Pizza ');
      f.setAmount(1000);
      f.setCategory('food');
      f.setDate(DateTime(2026, 2, 20, 18));
      final result = ok(await f.save());
      expect(result.expense.title, 'Pizza');
      expect(result.expense.amountCents, 1000);
      expect(result.expense.date, DateTime.utc(2026, 2, 20));
      expect(result.expense.payers, {id(0): 1000});
      expect(result.expense.shares, {id(0): 334, id(1): 333, id(2): 333});
      expect(result.category, 'food');
      expect(result.split, isA<EqualSplit>());
      final stored = ok(await app.expenses.get(result.expense.id));
      expect(stored, result);
    });

    for (final mode in [
      SplitMode.shares,
      SplitMode.percent,
      SplitMode.exact,
    ]) {
      test('stores a ${mode.name} expense with its weights', () async {
        final f = await open();
        f.setTitle('Essen');
        f.setAmount(1000);
        f.setMode(mode);
        final entered = switch (mode) {
          SplitMode.shares => {id(0): 2, id(1): 1, id(2): 1},
          SplitMode.percent => {id(0): 5000, id(1): 2500, id(2): 2500},
          _ => {id(0): 500, id(1): 250, id(2): 250},
        };
        entered.forEach(f.setWeight);
        final result = ok(await f.save());
        expect(result.expense.shares, {id(0): 500, id(1): 250, id(2): 250});
        expect(splitModeOf(result.split), mode.name);
      });
    }

    test('a multi-payer expense is stored with every payer', () async {
      final f = await open();
      f.setTitle('Hotel');
      f.setAmount(900);
      f.setMultiplePayers(on: true);
      f.setPayerAmount(id(0), 600);
      f.setPayerAmount(id(1), 300);
      final result = ok(await f.save());
      expect(result.expense.payers, {id(0): 600, id(1): 300});
    });

    test('a blank title and amount are reported, nothing is stored', () async {
      final f = await open();
      final result = await f.save();
      expect(err(result), isA<InvalidData>());
      expect(ready().showErrors, isTrue);
      expect(ready().titleMissing, isTrue);
      expect(ready().amountMissing, isTrue);
      expect(await app.expenses.watchExpenses(app.trip.id).first, isEmpty);
    });

    test('a split that does not add up is not stored', () async {
      final f = await open();
      f.setTitle('x');
      f.setAmount(1000);
      f.setMode(SplitMode.exact);
      f.setWeight(id(0), 1);
      expect(err(await f.save()), isA<InvalidData>());
      expect(ready().splitError, isA<ExactMismatch>());
    });

    test('payers that do not add up are not stored', () async {
      final f = await open();
      f.setTitle('x');
      f.setAmount(1000);
      f.setMultiplePayers(on: true);
      f.setPayerAmount(id(0), 1);
      expect(err(await f.save()), isA<InvalidData>());
      expect(ready().payerError, isA<PayersMismatch>());
    });

    test('a failing repository is returned and the form stays', () async {
      final f = await open();
      f.setTitle('Pizza');
      f.setAmount(1000);
      app.expenses.failWith = const Storage('disk');
      expect(err(await f.save()), const Storage('disk'));
      expect(ready().saving, isFalse);
      expect(ready().title, 'Pizza');
      app.expenses.failWith = null;
      ok(await f.save());
    });

    test('a foreign currency group cannot be tricked into EUR', () async {
      // The form always uses the group currency.
      final chf = ExpensesApp();
      final c = chf.container();
      addTearDown(c.dispose);
      await chf.seedTrip(currency: Currency.chf);
      final key = (groupId: chf.trip.id, expenseId: null);
      c.listen(expenseFormViewModelProvider(key), (_, _) {});
      await pumpEventQueue();
      final f = c.read(expenseFormViewModelProvider(key).notifier)
        ..setTitle('Käse')
        ..setAmount(2000);
      expect(ok(await f.save()).expense.currency, Currency.chf);
    });

    test('saving before the form loaded is refused', () async {
      container.listen(expenseFormViewModelProvider(newKey()), (_, _) {});
      expect(err(await vm().save()), isA<Conflict>());
    });
  });

  group('edit', () {
    Future<ExpenseFormKey> store(ExpensesApp a, {SplitSpec? split}) async {
      final entry = await a.add(
        cents: 1200,
        date: DateTime.utc(2026, 2, 14),
        payers: {a.people[1].id: 700, a.people[2].id: 500},
        split: split,
        category: 'transport',
      );
      return (groupId: a.trip.id, expenseId: entry.expense.id);
    }

    test('shows the stored values', () async {
      final key = await store(app);
      await open(key);
      final s = ready(key);
      expect(s.editing, isTrue);
      expect(s.title, 'Taxi');
      expect(s.amountCents, 1200);
      expect(s.date, DateTime.utc(2026, 2, 14));
      expect(s.category, 'transport');
      expect(s.multiPayer, isTrue);
      expect(s.payerCents, {id(1): 700, id(2): 500});
      expect(s.mode, SplitMode.equal);
      expect(s.preview, {id(0): 400, id(1): 400, id(2): 400});
    });

    for (final (spec, mode, weights) in [
      (SharesSplit({'a': 3, 'b': 1}), SplitMode.shares, {'a': 3, 'b': 1}),
      (
        PercentSplit({'a': 7500, 'b': 2500}),
        SplitMode.percent,
        {'a': 7500, 'b': 2500},
      ),
      (ExactSplit({'a': 900, 'b': 300}), SplitMode.exact, {'a': 900, 'b': 300}),
    ]) {
      test('round-trips a ${mode.name} split with its weights', () async {
        // Replace the placeholder ids by real members.
        final ids = [id(0), id(1)];
        Map<String, int> real(Map<String, int> m) => {
          ids[0]: m['a']!,
          ids[1]: m['b']!,
        };
        final split = switch (spec) {
          SharesSplit() => SharesSplit(real(weights)),
          PercentSplit() => PercentSplit(real(weights)),
          _ => ExactSplit(real(weights)),
        };
        final key = await store(app, split: split);
        final f = await open(key);
        expect(ready(key).mode, mode);
        expect(ready(key).weights, real(weights));
        expect(ready(key).participants, {id(0), id(1)});
        expect(ready(key).splitError, isNull);

        // Saving unchanged keeps the expense identical.
        final before = ok(await app.expenses.get(key.expenseId!));
        final saved = ok(await f.save());
        expect(saved.expense, before.expense);
        expect(saved.split, before.split);
      });
    }

    test('saves changes onto the same expense', () async {
      final key = await store(app);
      final f = await open(key);
      f.setTitle('Taxi heim');
      f.setMultiplePayers(on: false);
      f.setPayer(id(1));
      final saved = ok(await f.save());
      expect(saved.expense.id, key.expenseId);
      expect(saved.expense.title, 'Taxi heim');
      expect(saved.expense.payers, {id(1): 1200});
      expect(await app.expenses.watchExpenses(app.trip.id).first, hasLength(1));
    });

    test('a failing update is reported', () async {
      final key = await store(app);
      final f = await open(key);
      app.expenses.failWith = const Storage('x');
      expect(err(await f.save()), isA<Storage>());
    });
  });

  test('debugSnapshot describes loading, error and the filled form', () async {
    container.listen(expenseFormViewModelProvider(newKey()), (_, _) {});
    expect(vm().debugSnapshot()['status'], 'loading');
    await pumpEventQueue();
    final f = vm()
      ..setTitle('Pizza')
      ..setAmount(1000)
      ..setCategory('food');
    expect(f.debugSnapshot(), {
      'status': 'ready',
      'groupId': app.trip.id,
      'expenseId': null,
      'title': 'Pizza',
      'amountCents': 1000,
      'currency': 'EUR',
      'date': '2026-03-01',
      'category': 'food',
      'multiPayer': false,
      'payers': {id(0): 1000},
      'mode': 'equal',
      'participants': [id(0), id(1), id(2)],
      'weights': <String, int>{},
      'preview': {id(0): 334, id(1): 333, id(2): 333},
      'issues': <String>[],
      'showErrors': false,
    });
    f.setAmount(null);
    expect(f.debugSnapshot()['issues'], ['amount']);
    f.setAmount(1000);
    f.setMode(SplitMode.exact);
    f.setWeight(id(0), 1);
    expect(f.debugSnapshot()['issues'], [startsWith('split: ExactMismatch')]);
    f.setMode(SplitMode.equal);
    f.setMultiplePayers(on: true);
    f.setPayerAmount(id(0), 1);
    expect(f.debugSnapshot()['issues'], [startsWith('payers: PayersMismatch')]);
  });
}
