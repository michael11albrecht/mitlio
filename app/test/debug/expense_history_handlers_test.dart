import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/expense_history.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/expenses/ui/expenses_fixtures.dart';
import '../features/repo_test_support.dart';

void main() {
  late ExpensesApp app;
  late ProviderContainer container;
  late Map<String, DriveHandler> h;
  late ExpenseEntry expense;

  setUp(() async {
    app = ExpensesApp();
    container = app.container();
    addTearDown(container.dispose);
    await app.seedTrip();
    expense = await app.add();
    h = expenseHistoryDriveHandlers(container);
  });

  Future<void> rename(String title) async => ok(
    await app.expenses.update(
      expense.expense.id,
      ExpenseDraft(
        title: title,
        amountCents: 900,
        currency: Currency.eur,
        date: DateTime.utc(2026, 2),
        payers: {app.people[0].id: 900},
        split: EqualSplit({for (final p in app.people) p.id}),
      ),
    ),
  );

  test('history lists revisions newest first', () async {
    expect(await h['expenses.history']!({'id': expense.expense.id}), {
      'revisions': <Object>[],
    });
    await rename('Bus');
    await rename('Train');
    final r = await h['expenses.history']!({'id': expense.expense.id});
    final revisions = (r['revisions']! as List).cast<Map<String, Object?>>();
    expect(revisions.map((e) => e['revision']), [2, 1]);
    expect(revisions.map((e) => e['title']), ['Bus', 'Taxi']);
    expect(revisions.first['amountCents'], 900);
    expect(revisions.first['changedAt'], '2026-03-01T12:00:00.000Z');
  });

  test('restoreRevision goes through the ViewModel command', () async {
    await rename('Bus');
    final history = await h['expenses.history']!({'id': expense.expense.id});
    final rev =
        ((history['revisions']! as List).single as Map)['id']! as String;
    final r = await h['expenses.restoreRevision']!({
      'id': expense.expense.id,
      'revisionId': rev,
    });
    expect(r, {'id': expense.expense.id, 'revisionId': rev});
    expect(
      ok(await app.expenses.get(expense.expense.id)).expense.title,
      'Taxi',
    );
  });

  test('missing params and unknown ids are reported', () async {
    expect((await h['expenses.history']!({}))['error'], 'invalid_params');
    expect(
      (await h['expenses.restoreRevision']!({'id': 'x'}))['error'],
      'invalid_params',
    );
    expect(
      (await h['expenses.history']!({'id': 'nope'}))['error'],
      'not_found',
    );
    expect(
      (await h['expenses.restoreRevision']!({
        'id': expense.expense.id,
        'revisionId': 'nope',
      }))['error'],
      'not_found',
    );
  });
}
