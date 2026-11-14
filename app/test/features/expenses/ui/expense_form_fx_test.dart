// Justification: one command per line reads as the user's steps.
// ignore_for_file: cascade_invocations

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view_model.dart';
import 'package:mitlio/features/fx/data/repositories/fx_providers.dart';
import 'package:mitlio/features/fx/data/services/fake_fx_rate_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'expenses_fixtures.dart';

/// P7-T02: the ECB rate is suggested for a foreign currency, fills an empty
/// rate, never overrides a typed one, and the rate is frozen as before.
void main() {
  late ExpensesApp app;
  late FakeFxRateService fx;
  late ProviderContainer container;

  ExpenseFormKey newKey() => (groupId: app.trip.id, expenseId: null);

  ExpenseFormViewModel vm() =>
      container.read(expenseFormViewModelProvider(newKey()).notifier);

  ExpenseFormReady ready() =>
      container.read(expenseFormViewModelProvider(newKey()))
          as ExpenseFormReady;

  Future<ExpenseFormViewModel> open() async {
    container.listen(expenseFormViewModelProvider(newKey()), (_, _) {});
    await pumpEventQueue();
    return vm();
  }

  void build({bool configured = true}) {
    fx = FakeFxRateService(configured: configured);
    container = ProviderContainer(
      overrides: [
        ...app.overrides,
        fxRateServiceProvider.overrideWithValue(fx),
      ],
    );
    addTearDown(container.dispose);
  }

  setUp(() async {
    app = ExpensesApp();
    await app.seedTrip();
    build();
  });

  test('a foreign currency fills the empty rate with the ECB rate', () async {
    final f = await open();
    f.setAmount(1000);
    f.setCurrency(Currency.usd);
    expect(ready().rateSuggestion, isNull, reason: 'not yet answered');
    await pumpEventQueue();
    final s = ready();
    expect(s.rateSuggestion?.ppm, 920000);
    expect(s.rateSuggestion?.date, DateTime.utc(2026, 11, 13));
    expect(s.ratePpm, 920000);
    expect(s.groupAmountCents, 920);
    expect(s.rateMissing, isFalse);
    // The question is for 1 USD in EUR, today = latest (no date sent).
    expect(fx.calls.single, (
      base: Currency.usd,
      quote: Currency.eur,
      date: null,
    ));
  });

  test('the user can override; the suggestion stays offered', () async {
    final f = await open();
    f.setAmount(1000);
    f.setCurrency(Currency.usd);
    await pumpEventQueue();
    f.setRate(900000);
    var s = ready();
    expect(s.ratePpm, 900000);
    expect(s.rateSuggestion?.ppm, 920000);
    expect(s.groupAmountCents, 900);
    f.useSuggestedRate();
    s = ready();
    expect(s.ratePpm, 920000);
  });

  test('the typed rate is frozen on the saved expense', () async {
    final f = await open();
    f.setTitle('Taxi');
    f.setAmount(1000);
    f.setCurrency(Currency.usd);
    await pumpEventQueue();
    f.setRate(910000);
    final saved = (await f.save()) as Ok<ExpenseEntry, dynamic>;
    expect(saved.value.foreign?.ratePpm, 910000);
    expect(saved.value.expense.amountCents, 910);
  });

  test('a suggested rate that is saved is frozen too', () async {
    final f = await open();
    f.setTitle('Taxi');
    f.setAmount(1000);
    f.setCurrency(Currency.usd);
    await pumpEventQueue();
    final saved = (await f.save()) as Ok<ExpenseEntry, dynamic>;
    expect(saved.value.foreign?.ratePpm, 920000);
  });

  test(
    'a remembered rate of the group is kept, the offer is separate',
    () async {
      await app.expenses.create(
        app.trip.id,
        ExpenseDraft(
          title: 'Old',
          amountCents: 880,
          currency: Currency.eur,
          date: DateTime.utc(2026, 2),
          payers: {app.people[0].id: 880},
          split: EqualSplit({app.people[0].id}),
          foreign: ForeignAmount(
            currency: Currency.usd,
            amountCents: 1000,
            ratePpm: 880000,
          ),
        ),
      );
      final f = await open();
      f.setCurrency(Currency.usd);
      await pumpEventQueue();
      final s = ready();
      expect(s.ratePpm, 880000);
      expect(s.rateSuggestion?.ppm, 920000);
    },
  );

  test('a new day asks again and replaces a suggested rate', () async {
    final f = await open();
    f.setCurrency(Currency.usd);
    await pumpEventQueue();
    fx.rates[(Currency.usd, Currency.eur)] = 930000;
    f.setDate(DateTime.utc(2026, 2, 27));
    await pumpEventQueue();
    expect(fx.calls.last.date, DateTime.utc(2026, 2, 27));
    expect(ready().ratePpm, 930000);
    expect(ready().rateSuggestion?.ppm, 930000);
  });

  test('a typed rate survives a date change', () async {
    final f = await open();
    f.setCurrency(Currency.usd);
    await pumpEventQueue();
    f.setRate(900000);
    fx.rates[(Currency.usd, Currency.eur)] = 930000;
    f.setDate(DateTime.utc(2026, 2, 27));
    await pumpEventQueue();
    expect(ready().ratePpm, 900000);
    expect(ready().rateSuggestion?.ppm, 930000);
  });

  test('switching back to the group currency drops the offer', () async {
    final f = await open();
    f.setCurrency(Currency.usd);
    await pumpEventQueue();
    f.setCurrency(Currency.eur);
    expect(ready().rateSuggestion, isNull);
    expect(ready().ratePpm, isNull);
  });

  test('a stale answer for the previous currency is dropped', () async {
    final f = await open();
    f.setCurrency(Currency.usd);
    f.setCurrency(Currency.gbp);
    await pumpEventQueue();
    expect(ready().ratePpm, 1150000);
    expect(ready().rateSuggestion?.ppm, 1150000);
  });

  test('no answer: the rate stays required and empty', () async {
    fx.failing = true;
    final f = await open();
    f.setAmount(1000);
    f.setCurrency(Currency.usd);
    await pumpEventQueue();
    final s = ready();
    expect(s.rateSuggestion, isNull);
    expect(s.ratePpm, isNull);
    expect(s.rateMissing, isTrue);
  });

  test('without a backend nothing is asked', () async {
    build(configured: false);
    final f = await open();
    f.setCurrency(Currency.usd);
    await pumpEventQueue();
    expect(fx.calls, isEmpty);
    expect(ready().rateSuggestion, isNull);
    expect(ready().rateMissing, isTrue);
  });

  test('useSuggestedRate without an offer does nothing', () async {
    final f = await open();
    f.useSuggestedRate();
    f.setCurrency(Currency.usd);
    f.setRate(900000);
    await pumpEventQueue();
    expect(ready().ratePpm, 900000);
  });

  test(
    'multi-payer and exact inputs are seeded once the rate arrives',
    () async {
      final f = await open();
      f.setAmount(1000);
      f.setCurrency(Currency.usd);
      f.setMultiplePayers(on: true);
      f.setMode(SplitMode.exact);
      await pumpEventQueue();
      final s = ready();
      expect(s.groupAmountCents, 920);
      int sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);
      expect(sum(s.payerCents), 920, reason: 'payers seeded from the rate');
      expect(sum(s.weights), 920, reason: 'exact amounts seeded too');
      expect(f.debugSnapshot()['fxSuggestionPpm'], 920000);
    },
  );

  test('editing a stored dollar expense keeps its frozen rate', () async {
    final entry = ok(
      await app.expenses.create(
        app.trip.id,
        ExpenseDraft(
          title: 'Taxi NYC',
          amountCents: 880,
          currency: Currency.eur,
          date: DateTime.utc(2026, 2),
          payers: {app.people[0].id: 880},
          split: EqualSplit({app.people[0].id}),
          foreign: ForeignAmount(
            currency: Currency.usd,
            amountCents: 1000,
            ratePpm: 880000,
          ),
        ),
      ),
    );
    final key = (groupId: app.trip.id, expenseId: entry.expense.id);
    container.listen(expenseFormViewModelProvider(key), (_, _) {});
    await pumpEventQueue();
    final s =
        container.read(expenseFormViewModelProvider(key)) as ExpenseFormReady;
    expect(s.ratePpm, 880000);
    expect(s.rateSuggestion?.ppm, 920000);
    expect(fx.calls.single.date, DateTime.utc(2026, 2));
  });
}
