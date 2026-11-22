import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/recurring/ui/recurring_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../expenses/ui/expenses_fixtures.dart';
import '../../repo_test_support.dart';

RecurrenceRule rule(
  DateTime start, {
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  int interval = 1,
  DateTime? end,
}) => (RecurrenceRule.create(
  start: start,
  frequency: frequency,
  interval: interval,
  end: end,
) as Ok<RecurrenceRule, RecurrenceError>).value;

void main() {
  late ExpensesApp app;
  late ProviderContainer container;

  String id(int i) => app.people[i].id;

  RecurringDraft draft({
    String title = 'Miete',
    int cents = 90000,
    DateTime? start,
    Map<String, int>? payers,
    DateTime? lastGenerated,
  }) => RecurringDraft(
    title: title,
    amountCents: cents,
    payers: payers ?? {id(0): cents},
    split: EqualSplit({for (final p in app.people) p.id}),
    rule: rule(start ?? DateTime.utc(2026, 1, 31)),
    lastGenerated: lastGenerated,
  );

  RecurringViewModel vm() =>
      container.read(recurringViewModelProvider(app.trip.id).notifier);

  RecurringState state() =>
      container.read(recurringViewModelProvider(app.trip.id));

  Future<RecurringViewModel> open() async {
    container.listen(recurringViewModelProvider(app.trip.id), (_, _) {});
    await pumpEventQueue();
    return vm();
  }

  setUp(() async {
    app = ExpensesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedTrip();
  });

  test('starts loading, then shows the rules of the group', () async {
    container.listen(recurringViewModelProvider(app.trip.id), (_, _) {});
    expect(state(), isA<RecurringLoading>());
    await pumpEventQueue();
    final s = state() as RecurringLoaded;
    expect(s.isEmpty, isTrue);
    expect(s.group.id, app.trip.id);
    expect(s.today, DateTime.utc(2026, 3));
  });

  test('create stores the rule and the list follows', () async {
    final model = await open();
    final rule = ok(await model.create(draft()));
    expect(rule.title, 'Miete');
    expect(rule.groupId, app.trip.id);
    final s = state() as RecurringLoaded;
    expect(s.rules.single.id, rule.id);
    expect(model.debugSnapshot(), {
      'status': 'data',
      'groupId': app.trip.id,
      'rules': [
        {
          'id': rule.id,
          'groupId': app.trip.id,
          'title': 'Miete',
          'amountCents': 90000,
          'payers': {id(0): 90000},
          'category': null,
          'frequency': 'monthly',
          'interval': 1,
          'start': '2026-01-31',
          'end': null,
          'lastGenerated': null,
          'next': '2026-03-31',
          'paused': false,
        },
      ],
    });
  });

  group('validation', () {
    test('a blank title is rejected without touching the repository', () async {
      final model = await open();
      final result = await model.create(draft(title: ' '));
      expect(
        (result as Err<RecurringExpense, RepositoryError>).error,
        isA<InvalidData>(),
      );
      expect(app.base.recurring.failWith, isNull);
      expect((state() as RecurringLoaded).isEmpty, isTrue);
    });

    test('payers that do not add up are rejected like an expense', () async {
      final model = await open();
      final result = await model.create(draft(payers: {id(0): 100}));
      expect(
        (result as Err<RecurringExpense, RepositoryError>).error,
        isA<InvalidData>(),
      );
      expect((state() as RecurringLoaded).isEmpty, isTrue);
    });

    test('a person who is not in the group cannot pay', () async {
      final model = await open();
      final result = await model.create(draft(payers: {'ghost': 90000}));
      expect(result, isA<Err<RecurringExpense, RepositoryError>>());
    });

    test('an unknown group is NotFound', () async {
      final model = container.read(
        recurringViewModelProvider('nope').notifier,
      );
      final result = await model.create(draft());
      expect(
        (result as Err<RecurringExpense, RepositoryError>).error,
        isA<NotFound>(),
      );
    });
  });

  test('a repository failure comes back and changes nothing', () async {
    final model = await open();
    app.base.recurring.failWith = const Storage('disk full');
    final result = await model.create(draft());
    expect(
      (result as Err<RecurringExpense, RepositoryError>).error,
      const Storage('disk full'),
    );
    expect(await model.delete('x'), isA<Err<Undo, RepositoryError>>());
    expect(
      await model.setPaused('x', paused: true),
      isA<Err<Undo, RepositoryError>>(),
    );
  });

  test('update replaces what the rule makes', () async {
    final model = await open();
    final rule0 = ok(await model.create(draft()));
    final updated = ok(await model.update(rule0.id, draft(title: 'Miete neu')));
    expect(updated.title, 'Miete neu');
    expect(
      (await model.update(rule0.id, draft(title: '')))
          as Err<RecurringExpense, RepositoryError>,
      isA<Err<RecurringExpense, RepositoryError>>(),
    );
    expect(
      (await model.update(
        'nope',
        draft(),
      ) as Err<RecurringExpense, RepositoryError>).error,
      isA<NotFound>(),
    );
  });

  test('delete can be undone', () async {
    final model = await open();
    final r = ok(await model.create(draft()));
    final undo = ok(await model.delete(r.id));
    await pumpEventQueue();
    expect((state() as RecurringLoaded).isEmpty, isTrue);
    await undo();
    await pumpEventQueue();
    expect((state() as RecurringLoaded).rules.single.id, r.id);
  });

  group('pause', () {
    test('pausing is undoable', () async {
      final model = await open();
      final r = ok(await model.create(draft()));
      final undo = ok(await model.setPaused(r.id, paused: true));
      await pumpEventQueue();
      expect((state() as RecurringLoaded).rules.single.paused, isTrue);
      await undo();
      await pumpEventQueue();
      expect((state() as RecurringLoaded).rules.single.paused, isFalse);
    });

    test('resuming skips the dates that passed while paused', () async {
      final model = await open();
      final r = ok(
        await model.create(draft(lastGenerated: DateTime.utc(2026, 1, 31))),
      );
      ok(await model.setPaused(r.id, paused: true));
      ok(await model.setPaused(r.id, paused: false));
      await pumpEventQueue();
      final resumed = (state() as RecurringLoaded).rules.single;
      // Today is 1 March 2026: 28 Feb passed while paused and is not made up.
      expect(resumed.lastGenerated, DateTime.utc(2026, 2, 28));
      expect(resumed.due(DateTime.utc(2026, 3)), isEmpty);
      expect(
        resumed.nextAfter(DateTime.utc(2026, 3)),
        DateTime.utc(2026, 3, 31),
      );
    });

    test('resuming a rule that is not due yet keeps its progress', () async {
      final model = await open();
      final r = ok(
        await model.create(draft(start: DateTime.utc(2026, 6, 15))),
      );
      ok(await model.setPaused(r.id, paused: true));
      ok(await model.setPaused(r.id, paused: false));
      await pumpEventQueue();
      expect((state() as RecurringLoaded).rules.single.lastGenerated, isNull);
    });

    test('an unknown rule is NotFound', () async {
      final model = await open();
      expect(
        (await model.setPaused(
          'nope',
          paused: false,
        ) as Err<Undo, RepositoryError>).error,
        isA<NotFound>(),
      );
    });
  });
}
