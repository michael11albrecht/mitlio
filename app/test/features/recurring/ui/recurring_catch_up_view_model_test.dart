import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/recurring/ui/recurring_catch_up_view_model.dart';
import 'package:mitlio/features/recurring/ui/recurring_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../expenses/ui/expenses_fixtures.dart';
import '../../repo_test_support.dart';
import 'recurring_view_model_test.dart' show rule;

void main() {
  late ExpensesApp app;
  late ProviderContainer container;

  String id(int i) => app.people[i].id;

  RecurringCatchUpViewModel vm() =>
      container.read(recurringCatchUpViewModelProvider.notifier);

  Future<RecurringExpense> addRule({
    String title = 'Miete',
    int cents = 90000,
    RecurrenceRule? r,
    DateTime? lastGenerated,
    String? groupId,
  }) async => ok(
    await app.base.recurring.create(
      groupId ?? app.trip.id,
      RecurringDraft(
        title: title,
        amountCents: cents,
        payers: {id(0): cents},
        split: EqualSplit({for (final p in app.people) p.id}),
        rule: r ?? rule(DateTime.utc(2026, 1, 31)),
        lastGenerated: lastGenerated,
        category: 'other',
      ),
    ),
  );

  Future<List<ExpenseEntry>> expenses() =>
      app.expenses.watchExpenses(app.trip.id).first;

  Future<List<String>> days() async => [
    for (final e in await expenses())
      e.expense.date.toIso8601String().substring(0, 10),
  ]..sort();

  setUp(() async {
    app = ExpensesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedTrip();
    // 1 April 2026.
    app.base.clock.value = DateTime.utc(2026, 4, 1, 8);
  });

  test('makes every due expense, month ends clamped', () async {
    await addRule();
    final notice = await vm().run();
    expect(notice.created, 3);
    expect(notice.skipped, 0);
    expect(notice.failures, isEmpty);
    expect(await days(), ['2026-01-31', '2026-02-28', '2026-03-31']);
    final entry = (await expenses()).first;
    expect(entry.expense.title, 'Miete');
    expect(entry.expense.amountCents, 90000);
    expect(entry.expense.payers, {id(0): 90000});
    expect(entry.category, 'other');
    expect(entry.split, EqualSplit({id(0), id(1), id(2)}));
    final stored =
        (await app.base.recurring.all()
                as Ok<List<RecurringExpense>, RepositoryError>)
            .value
            .single;
    expect(stored.lastGenerated, DateTime.utc(2026, 3, 31));
    expect(stored.nextAfter(DateTime.utc(2026, 4)), DateTime.utc(2026, 4, 30));
  });

  test('a second run makes nothing again', () async {
    await addRule();
    await vm().run();
    final second = await vm().run();
    expect(second.isEmpty, isTrue);
    expect(await days(), hasLength(3));
  });

  test('later days follow once their date is reached', () async {
    await addRule();
    await vm().run();
    app.base.clock.value = DateTime.utc(2026, 4, 30, 23);
    final notice = await vm().run();
    expect(notice.created, 1);
    expect(await days(), contains('2026-04-30'));
  });

  test('a date that is already covered is not made again', () async {
    await addRule(lastGenerated: DateTime.utc(2026, 2, 28));
    final notice = await vm().run();
    expect(notice.created, 1);
    expect(await days(), ['2026-03-31']);
  });

  test('a long absence makes only the newest ones and says so', () async {
    await addRule(
      r: rule(DateTime.utc(2026), frequency: RecurrenceFrequency.daily),
    );
    final notice = await vm().run();
    // 1 Jan .. 1 Apr 2026 is 91 days.
    expect(notice.created, 12);
    expect(notice.skipped, 91 - 12);
    final made = await days();
    expect(made, hasLength(12));
    expect(made.first, '2026-03-21');
    expect(made.last, '2026-04-01');
    // The skipped ones are not made up in a later run.
    expect((await vm().run()).isEmpty, isTrue);
    expect(await days(), hasLength(12));
  });

  test('paused rules, future starts and ended rules make nothing', () async {
    final paused = await addRule(title: 'Paused');
    await app.base.recurring.setPaused(paused.id, paused: true);
    await addRule(title: 'Later', r: rule(DateTime.utc(2026, 5)));
    await addRule(
      title: 'Ended',
      r: rule(DateTime.utc(2025), end: DateTime.utc(2025, 1, 31)),
      lastGenerated: DateTime.utc(2025, 1, 31),
    );
    final notice = await vm().run();
    expect(notice.isEmpty, isTrue);
    expect(await expenses(), isEmpty);
  });

  test('the notice is published and can be consumed', () async {
    container.listen(recurringCatchUpViewModelProvider, (_, _) {});
    expect(container.read(recurringCatchUpViewModelProvider), isNull);
    await vm().run();
    expect(container.read(recurringCatchUpViewModelProvider), isNull);
    await addRule();
    await vm().run();
    expect(container.read(recurringCatchUpViewModelProvider)?.created, 3);
    expect(vm().debugSnapshot()['pending'], {
      'created': 3,
      'skipped': 0,
      'failures': <Object>[],
    });
    vm().consume();
    expect(container.read(recurringCatchUpViewModelProvider), isNull);
  });

  group('failures are reported, never swallowed', () {
    test('an expense that cannot be made stops that rule only', () async {
      await addRule(title: 'Broken');
      await addRule(title: 'Other', r: rule(DateTime.utc(2026, 3)));
      app.expenses.failWith = const Storage('disk full');
      final notice = await vm().run();
      expect(notice.created, 0);
      expect([for (final f in notice.failures) f.title], ['Broken', 'Other']);
      expect(notice.failures.first.error, const Storage('disk full'));
      // Nothing was marked: the next run, with the disk back, catches up.
      app.expenses.failWith = null;
      final retry = await vm().run();
      expect(retry.created, 5);
      expect(retry.failures, isEmpty);
    });

    test('a person who left makes the rule fail with a reason', () async {
      final r = await addRule();
      await app.base.recurring.update(
        r.id,
        RecurringDraft(
          title: r.title,
          amountCents: r.amountCents,
          payers: {'ghost': r.amountCents},
          split: r.split,
          rule: r.rule,
        ),
      );
      final notice = await vm().run();
      expect(notice.created, 0);
      expect(notice.failures.single.title, 'Miete');
      expect(notice.failures.single.error, isA<InvalidData>());
    });

    test('a failed bookkeeping takes the expense back (no double)', () async {
      await addRule();
      app.base.recurring.failMarkWith = const Storage('locked');
      final notice = await vm().run();
      expect(notice.created, 0);
      expect(notice.failures.single.error, const Storage('locked'));
      expect(await expenses(), isEmpty);
      app.base.recurring.failMarkWith = null;
      expect((await vm().run()).created, 3);
      expect(await expenses(), hasLength(3));
    });

    test('a rule list that cannot be read is reported', () async {
      app.base.recurring.failWith = const Storage('broken');
      final notice = await vm().run();
      expect(notice.failures.single.error, const Storage('broken'));
      expect(container.read(recurringCatchUpViewModelProvider), isNotNull);
    });

    test('a group that is gone is skipped without an error', () async {
      await addRule(groupId: 'deleted-group');
      final notice = await vm().run();
      expect(notice.isEmpty, isTrue);
    });
  });
}
