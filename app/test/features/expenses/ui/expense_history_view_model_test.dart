import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/ui/expense_history_view.dart';
import 'package:mitlio/features/expenses/ui/expense_history_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/a11y.dart';
import '../../repo_test_support.dart';
import 'expenses_fixtures.dart';

class _StubHistory extends ExpenseHistoryViewModel {
  _StubHistory(super.expenseId, this.fixed);

  final ExpenseHistoryState fixed;

  @override
  ExpenseHistoryState build() => fixed;
}

void main() {
  late ExpensesApp app;
  late ExpenseEntry expense;

  Future<void> edit(ExpenseDraft d) async =>
      ok(await app.expenses.update(expense.expense.id, d));

  ExpenseDraft draft({
    String title = 'Taxi',
    int cents = 900,
    Map<String, int>? payers,
    SplitSpec? split,
  }) => ExpenseDraft(
    title: title,
    amountCents: cents,
    currency: Currency.eur,
    date: DateTime.utc(2026, 2),
    payers: payers ?? {app.people[0].id: cents},
    split: split ?? EqualSplit({for (final p in app.people) p.id}),
  );

  setUp(() async {
    app = ExpensesApp();
    await app.seedTrip();
    expense = await app.add();
  });

  group('ExpenseHistoryViewModel', () {
    late ProviderContainer container;

    ExpenseHistoryViewModel vm() => container.read(
      expenseHistoryViewModelProvider(expense.expense.id).notifier,
    );
    ExpenseHistoryState state() =>
        container.read(expenseHistoryViewModelProvider(expense.expense.id));

    Future<void> open() async {
      container.listen(
        expenseHistoryViewModelProvider(expense.expense.id),
        (_, _) {},
      );
      await pumpEventQueue();
    }

    setUp(() {
      container = app.container();
      addTearDown(container.dispose);
    });

    test('starts loading, then is empty for a never-edited expense', () async {
      expect(state(), isA<ExpenseHistoryLoading>());
      await open();
      expect(state(), isA<ExpenseHistoryLoaded>());
      expect((state() as ExpenseHistoryLoaded).isEmpty, isTrue);
      expect(vm().debugSnapshot()['status'], 'empty');
    });

    test('lists changes newest first, each diffed to what followed', () async {
      await edit(draft(title: 'Taxi 2', cents: 1200));
      await edit(
        draft(
          title: 'Taxi 2',
          cents: 1200,
          split: EqualSplit({app.people[0].id, app.people[1].id}),
        ),
      );
      await open();
      final s = state() as ExpenseHistoryLoaded;
      expect(s.items.map((i) => i.revision), [2, 1]);
      // Cy leaves; Ann's and Ben's shares grow because the total is the same.
      expect(s.items.first.changes.map((c) => c.runtimeType).toSet(), {
        ParticipantRemoved,
        ShareChange,
      });
      expect(
        s.items.first.changes.whereType<ParticipantRemoved>().single.memberId,
        app.people[2].id,
      );
      expect(s.items.last.changes.map((c) => c.runtimeType), [
        TitleChange,
        AmountChange,
        PaidChange,
      ]);
      expect(s.memberNames[app.people[0].id], 'Ann');
      expect(s.currency, Currency.eur);
      expect(vm().debugSnapshot()['status'], 'data');
      expect(vm().debugSnapshot()['revisions']! as List, hasLength(2));
    });

    test('restore applies the old version and can be undone', () async {
      await edit(draft(title: 'Bus', cents: 500));
      await open();
      final first = (state() as ExpenseHistoryLoaded).items.single;
      final undo = ok(await vm().restore(first.revisionId));
      expect(
        ok(await app.expenses.get(expense.expense.id)).expense.title,
        'Taxi',
      );
      ok(await undo());
      expect(
        ok(await app.expenses.get(expense.expense.id)).expense.title,
        'Bus',
      );
    });

    test('restore of an unknown revision fails with NotFound', () async {
      await open();
      expect(err(await vm().restore('nope')), isA<NotFound>());
    });

    test('an unknown expense is a failure, and retry reloads', () async {
      final c = app.container();
      addTearDown(c.dispose);
      final p = expenseHistoryViewModelProvider('nope');
      c.listen(p, (_, _) {});
      await pumpEventQueue();
      expect(c.read(p), isA<ExpenseHistoryFailure>());
      expect(c.read(p.notifier).debugSnapshot()['status'], 'error');
      c.read(p.notifier).retry();
      expect(c.read(p), isA<ExpenseHistoryLoading>());
      expect(c.read(p.notifier).debugSnapshot()['status'], 'loading');
      await pumpEventQueue();
      expect(c.read(p), isA<ExpenseHistoryFailure>());
    });
  });

  group('history sheet', () {
    Future<void> openForm(WidgetTester tester) async {
      await pumpExpenses(
        tester,
        app,
        location: '/groups/${app.trip.id}/expenses/${expense.expense.id}',
      );
    }

    testWidgets('empty history says so', (tester) async {
      await openForm(tester);
      await tester.tap(find.byTooltip('Verlauf'));
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Änderungen'), findsOneWidget);
    });

    testWidgets('shows the diff and restores through an undo snackbar', (
      tester,
    ) async {
      await tester.runAsync(() => edit(draft(title: 'Taxi 2', cents: 1200)));
      await tester.runAsync(
        () => edit(
          draft(
            title: 'Taxi 2',
            cents: 1200,
            split: EqualSplit({app.people[0].id, app.people[1].id}),
          ),
        ),
      );
      await openForm(tester);
      await tester.tap(find.byTooltip('Verlauf'));
      await tester.pumpAndSettle();

      expect(find.text('Cy nicht mehr beteiligt'), findsOneWidget);
      expect(find.text('Betrag 9,00\u00a0€ → 12,00\u00a0€'), findsOneWidget);
      expect(find.text('Titel „Taxi“ → „Taxi 2“'), findsOneWidget);
      expect(find.text('Diese Version wiederherstellen'), findsNWidgets(2));

      await tester.tap(find.text('Diese Version wiederherstellen').last);
      await tester.pumpAndSettle();

      // Sheet and form are gone; the snackbar offers undo.
      expect(find.text('Verlauf'), findsNothing);
      expect(find.text('Version wiederhergestellt'), findsOneWidget);
      final restored = (await tester.runAsync(
        () => app.expenses.get(expense.expense.id),
      ))!;
      expect(ok(restored).expense.title, 'Taxi');
      expect(ok(restored).expense.amountCents, 900);

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      final undone = (await tester.runAsync(
        () => app.expenses.get(expense.expense.id),
      ))!;
      expect(ok(undone).expense.title, 'Taxi 2');
    });

    testWidgets('a failing restore keeps the sheet and shows an error', (
      tester,
    ) async {
      await tester.runAsync(() => edit(draft(title: 'Taxi 2')));
      await tester.runAsync(
        () => app.base.members.softDelete(app.people[2].id),
      );
      await openForm(tester);
      await tester.tap(find.byTooltip('Verlauf'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diese Version wiederherstellen'));
      await tester.pumpAndSettle();
      expect(find.text('Verlauf'), findsWidgets);
      expect(find.text('Version wiederhergestellt'), findsNothing);
    });

    testWidgets('the add form has no history entry', (tester) async {
      await pumpExpenses(
        tester,
        app,
        location: '/groups/${app.trip.id}/expenses/new',
      );
      expect(find.byTooltip('Verlauf'), findsNothing);
    });
  });

  group('history sheet accessibility', () {
    final loaded = ExpenseHistoryLoaded(
      currency: Currency.eur,
      memberNames: const {'m-0': 'Anna Berg', 'm-1': 'Ben'},
      items: [
        ExpenseHistoryItem(
          revisionId: 'r2',
          revision: 2,
          changedAt: DateTime.utc(2026, 3, 2, 10, 30),
          authorName: 'Anna Berg',
          changes: const [
            AmountChange(
              fromCents: 4200,
              fromCurrency: 'EUR',
              toCents: 4550,
              toCurrency: 'EUR',
            ),
            ParticipantRemoved('m-1'),
            ParticipantAdded('m-0'),
            PayerAdded('m-1'),
            PayerRemoved('m-0'),
            PaidChange('m-0', 100, 200),
            ShareChange('m-1', 100, 200),
            TripDetailsChange(),
            RateChange(920000, 910000),
            CategoryChange(null, 'food'),
            SplitModeChange('equal', 'percent'),
            TitleChange('a', 'b'),
          ],
        ),
        ExpenseHistoryItem(
          revisionId: 'r1',
          revision: 1,
          changedAt: DateTime.utc(2026, 3),
          changes: const [],
        ),
      ],
    );
    for (final (name, state) in <(String, ExpenseHistoryState)>[
      ('data', loaded),
      (
        'empty',
        const ExpenseHistoryLoaded(
          items: [],
          currency: Currency.eur,
          memberNames: {},
        ),
      ),
      ('error', const ExpenseHistoryFailure(Storage('x'))),
    ]) {
      forEachMode(
        name,
        () => scopedExpenses([
          expenseHistoryViewModelProvider.overrideWith2(
            (id) => _StubHistory(id, state),
          ),
        ], const ExpenseHistorySheet(expenseId: 'e-1')),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });
}
