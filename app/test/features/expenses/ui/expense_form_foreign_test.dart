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

/// P7-T01: a foreign currency on the expense form. The amount is entered in
/// the picked currency, the rate is frozen, and the split, payers and shares
/// work on the converted group-currency amount.
void main() {
  late ExpensesApp app;
  late ProviderContainer container;

  ExpenseFormKey newKey() => (groupId: app.trip.id, expenseId: null);

  ExpenseFormViewModel vm([ExpenseFormKey? key]) =>
      container.read(expenseFormViewModelProvider(key ?? newKey()).notifier);

  ExpenseFormReady ready([ExpenseFormKey? key]) =>
      container.read(expenseFormViewModelProvider(key ?? newKey()))
          as ExpenseFormReady;

  Future<ExpenseFormViewModel> open([ExpenseFormKey? key]) async {
    container.listen(expenseFormViewModelProvider(key ?? newKey()), (_, _) {});
    await pumpEventQueue();
    return vm(key);
  }

  String id(int i) => app.people[i].id;

  /// A stored dollar expense: 10,00 $ at 0,92 = 9,20 €.
  Future<ExpenseEntry> addUsd({
    int cents = 1000,
    int ppm = 920000,
    DateTime? date,
  }) async => ok(
    await app.expenses.create(
      app.trip.id,
      ExpenseDraft(
        title: 'Taxi NYC',
        amountCents: convert(
          Money(cents, Currency.usd),
          Currency.eur,
          FxRate(ppm),
        ).cents,
        currency: Currency.eur,
        date: date ?? DateTime.utc(2026, 2),
        payers: {
          id(0): convert(
            Money(cents, Currency.usd),
            Currency.eur,
            FxRate(ppm),
          ).cents,
        },
        split: EqualSplit({id(0), id(1), id(2)}),
        foreign: ForeignAmount(
          currency: Currency.usd,
          amountCents: cents,
          ratePpm: ppm,
        ),
      ),
    ),
  );

  setUp(() async {
    app = ExpensesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedTrip();
  });

  group('currency picker', () {
    test('defaults to the group currency, group first, no rate', () async {
      final f = await open();
      f.setAmount(1000);
      final s = ready();
      expect(s.currency, Currency.eur);
      expect(s.isForeign, isFalse);
      expect(s.rateMissing, isFalse);
      expect(s.ratePpm, isNull);
      expect(s.groupAmountCents, 1000);
      expect(s.currencyOptions.first, Currency.eur);
      expect(s.currencyOptions.toSet(), Currency.all.toSet());
      expect(s.currencyOptions.length, Currency.all.length);
    });

    test('a foreign currency needs a rate and blocks saving', () async {
      final f = await open();
      f.setTitle('Taxi');
      f.setAmount(1000);
      f.setCurrency(Currency.usd);
      var s = ready();
      expect(s.isForeign, isTrue);
      expect(s.rateMissing, isTrue);
      expect(s.groupAmountCents, isNull);
      expect(s.amountMissing, isFalse, reason: 'the rate is its own finding');
      expect(s.preview, isEmpty);
      expect(s.hasIssues, isTrue);
      expect(await f.save(), isA<Err<ExpenseEntry, RepositoryError>>());
      s = ready();
      expect(s.showErrors, isTrue);
      expect(f.debugSnapshot()['issues'], ['rate']);
    });

    test('rate converts half-even and drives the split', () async {
      final f = await open();
      f.setAmount(1234);
      f.setCurrency(Currency.usd);
      f.setRate(920000);
      final s = ready();
      expect(s.groupAmountCents, 1135); // 11.3528 -> 11,35
      expect(s.preview, {id(0): 379, id(1): 378, id(2): 378});
      expect(s.preview.values.fold<int>(0, (a, b) => a + b), 1135);

      // The examples:fx half-even cases (16.5 -> 16, 27.5 -> 28, 5.5 -> 6).
      for (final (cents, expected) in [(15, 16), (25, 28), (5, 6)]) {
        f.setAmount(cents);
        f.setRate(1100000);
        expect(ready().groupAmountCents, expected, reason: '$cents');
      }
    });

    test('a conversion that rounds to zero is not an amount', () async {
      final f = await open();
      f.setCurrency(Currency.jpy);
      f.setAmount(1);
      f.setRate(1); // 1 yen at 0,000001 EUR = 0 cents
      final s = ready();
      expect(s.groupAmountCents, isNull);
      expect(s.amountMissing, isTrue);
      expect(s.rateMissing, isFalse);
    });

    test('a huge conversion overflows into a missing amount', () async {
      final f = await open();
      f.setCurrency(Currency.usd);
      f.setAmount(Money.maxAbsCents);
      f.setRate(999999999999);
      expect(ready().groupAmountCents, isNull);
      expect(ready().amountMissing, isTrue);
    });

    test(
      'rate clears with null and is ignored for the group currency',
      () async {
        final f = await open();
        f.setRate(500000);
        expect(ready().ratePpm, isNull);
        f.setCurrency(Currency.usd);
        f.setRate(500000);
        f.setRate(null);
        expect(ready().ratePpm, isNull);
        expect(ready().rateMissing, isTrue);
      },
    );

    test('back to the group currency drops the rate', () async {
      final f = await open();
      f.setAmount(1000);
      f.setCurrency(Currency.usd);
      f.setRate(920000);
      f.setCurrency(Currency.eur);
      f.setCurrency(Currency.eur); // no-op
      final s = ready();
      expect(s.isForeign, isFalse);
      expect(s.ratePpm, isNull);
      expect(s.groupAmountCents, 1000);
    });

    test('minor units that differ clear the amount', () async {
      final f = await open();
      f.setAmount(1000);
      f.setCurrency(Currency.jpy);
      expect(ready().amountCents, isNull);
      f.setAmount(500);
      f.setCurrency(Currency.usd); // 0 -> 2 decimals
      expect(ready().amountCents, isNull);
      f.setAmount(500);
      f.setCurrency(Currency.gbp); // 2 -> 2 decimals: kept
      expect(ready().amountCents, 500);
    });

    test('remembers the last foreign currency and rate of the group', () async {
      await addUsd(date: DateTime.utc(2026, 2), ppm: 900000);
      await addUsd(date: DateTime.utc(2026, 2, 5));
      final f = await open();
      var s = ready();
      expect(s.currency, Currency.eur, reason: 'default is the group currency');
      expect(s.currencyOptions.take(2), [Currency.eur, Currency.usd]);
      f.setCurrency(Currency.usd);
      s = ready();
      expect(s.ratePpm, 920000, reason: 'newest expense wins');
      expect(s.rateMissing, isFalse);
      f.setCurrency(Currency.gbp);
      expect(ready().ratePpm, isNull, reason: 'no GBP expense yet');
    });
  });

  group('switching currency with amounts already split', () {
    test(
      'multi-payer restarts with the payer owning the converted total',
      () async {
        final f = await open();
        f.setAmount(1000);
        f.setMultiplePayers(on: true);
        expect(ready().payerCents, {id(0): 1000});
        f.setCurrency(Currency.usd);
        expect(ready().payerCents, isEmpty);
        f.setRate(920000);
        f.setMultiplePayers(on: false);
        f.setMultiplePayers(on: true);
        expect(ready().payerCents, {id(0): 920});
        expect(ready().payerError, isNull);
      },
    );

    test('exact amounts are re-seeded on the converted total', () async {
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.exact);
      f.setCurrency(Currency.usd);
      f.setRate(1500000); // 15,00 EUR
      f.setCurrency(Currency.gbp);
      f.setRate(1500000);
      f.setCurrency(Currency.usd);
      f.setRate(1500000);
      final s = ready();
      expect(s.mode, SplitMode.exact);
      expect(s.groupAmountCents, 1500);
      expect(s.splitError, isA<ExactMismatch>());
      f.setMode(SplitMode.equal);
      f.setMode(SplitMode.exact);
      expect(ready().weights.values.fold<int>(0, (a, b) => a + b), 1500);
      expect(ready().splitError, isNull);
    });

    test('switching with a known total re-seeds exact straight away', () async {
      await addUsd(ppm: 1000000);
      final f = await open();
      f.setAmount(1000);
      f.setMode(SplitMode.exact);
      f.setCurrency(Currency.usd); // rate remembered: 1,00
      final s = ready();
      expect(s.groupAmountCents, 1000);
      expect(s.weights.values.fold<int>(0, (a, b) => a + b), 1000);
      expect(s.splitError, isNull);
    });

    test('exact and multi-payer amounts stay in the group currency', () async {
      final f = await open();
      f.setAmount(1000);
      f.setCurrency(Currency.usd);
      f.setRate(920000); // 9,20 EUR
      f.setMode(SplitMode.exact);
      expect(ready().weights.values.fold<int>(0, (a, b) => a + b), 920);
      f.setWeight(id(0), 500);
      expect(ready().splitError, isA<ExactMismatch>());
      f.setWeight(id(1), 420);
      f.setWeight(id(2), 0);
      expect(ready().splitError, isNull);
    });
  });

  group('save', () {
    test(
      'stores the frozen rate, the original and the converted amount',
      () async {
        final f = await open();
        f.setTitle('Taxi');
        f.setAmount(1000);
        f.setCurrency(Currency.usd);
        f.setRate(920000);
        final entry = ok(await f.save());
        expect(entry.expense.amountCents, 920);
        expect(entry.expense.currency, Currency.eur);
        expect(entry.expense.payers, {id(0): 920});
        expect(entry.expense.shares, {id(0): 307, id(1): 307, id(2): 306});
        expect(
          entry.foreign,
          const ForeignAmount(
            currency: Currency.usd,
            amountCents: 1000,
            ratePpm: 920000,
          ),
        );
      },
    );

    test('a group-currency expense carries no foreign part', () async {
      final f = await open();
      f.setTitle('Taxi');
      f.setAmount(1000);
      expect(ok(await f.save()).foreign, isNull);
    });

    test('later rate changes never touch a stored expense', () async {
      final f = await open();
      f.setTitle('Taxi');
      f.setAmount(1000);
      f.setCurrency(Currency.usd);
      f.setRate(920000);
      final stored = ok(await f.save());
      final again = await open((groupId: app.trip.id, expenseId: null));
      again.setCurrency(Currency.usd);
      again.setRate(1500000);
      final fetched = ok(await app.expenses.get(stored.expense.id));
      expect(fetched.expense.amountCents, 920);
      expect(fetched.foreign!.ratePpm, 920000);
    });
  });

  group('edit round trip', () {
    test('a foreign expense reopens with currency, rate and amount', () async {
      final stored = await addUsd(cents: 1234);
      final key = (groupId: app.trip.id, expenseId: stored.expense.id);
      final f = await open(key);
      final s = ready(key);
      expect(s.editing, isTrue);
      expect(s.currency, Currency.usd);
      expect(s.amountCents, 1234);
      expect(s.ratePpm, 920000);
      expect(s.groupAmountCents, stored.expense.amountCents);
      expect(s.hasIssues, isFalse);

      // Change the rate: the converted amount, shares and payers follow.
      f.setRate(1000000);
      expect(ready(key).groupAmountCents, 1234);
      final updated = ok(await f.save());
      expect(updated.expense.amountCents, 1234);
      expect(updated.expense.shares.values.fold<int>(0, (a, b) => a + b), 1234);
      expect(updated.foreign!.ratePpm, 1000000);
      expect(updated.foreign!.amountCents, 1234);
    });

    test('switching an edited foreign expense to the group currency', () async {
      final stored = await addUsd();
      final key = (groupId: app.trip.id, expenseId: stored.expense.id);
      final f = await open(key);
      f.setCurrency(Currency.eur);
      f.setAmount(777);
      final updated = ok(await f.save());
      expect(updated.foreign, isNull);
      expect(updated.expense.amountCents, 777);
    });

    test('a group-currency expense still reopens as before', () async {
      final stored = await app.add();
      final key = (groupId: app.trip.id, expenseId: stored.expense.id);
      await open(key);
      expect(ready(key).currency, Currency.eur);
      expect(ready(key).amountCents, 900);
      expect(ready(key).isForeign, isFalse);
    });
  });

  test('debugSnapshot reports currency, rate and converted amount', () async {
    final f = await open();
    f.setAmount(1000);
    f.setCurrency(Currency.usd);
    f.setRate(920000);
    final snap = f.debugSnapshot();
    expect(snap['currency'], 'USD');
    expect(snap['groupCurrency'], 'EUR');
    expect(snap['fxRatePpm'], 920000);
    expect(snap['groupAmountCents'], 920);
    expect(snap['amountCents'], 1000);
  });

  group('mixed-currency groups balance to zero', () {
    test('stored aggregates carry group-currency shares and payers', () async {
      final usd = await addUsd(cents: 1234);
      final jpy = ok(
        await app.expenses.create(
          app.trip.id,
          ExpenseDraft(
            title: 'Ramen',
            amountCents: 1974,
            currency: Currency.eur,
            date: DateTime.utc(2026, 2, 2),
            payers: {id(1): 1974},
            split: EqualSplit({id(0), id(1), id(2)}),
            foreign: const ForeignAmount(
              currency: Currency.jpy,
              amountCents: 12340,
              ratePpm: 1600,
            ),
          ),
        ),
      );
      final eur = await app.add(cents: 1000, payers: {id(2): 1000});
      for (final e in [usd, jpy, eur]) {
        expect(e.expense.currency, Currency.eur);
        expect(
          e.expense.shares.values.fold<int>(0, (a, b) => a + b),
          e.expense.amountCents,
        );
        expect(
          e.expense.payers.values.fold<int>(0, (a, b) => a + b),
          e.expense.amountCents,
        );
      }
      final balances = computeBalances(
        members: [for (final m in app.people) m.toDomain()],
        expenses: [usd.expense, jpy.expense, eur.expense],
        settlements: const [],
      );
      expect(balances.values.fold<int>(0, (a, b) => a + b), 0);
    });
  });
}
