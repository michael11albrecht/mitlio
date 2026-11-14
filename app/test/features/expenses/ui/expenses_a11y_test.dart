import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view_model.dart';
import 'package:mitlio/features/expenses/ui/expenses_view.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/a11y.dart';
import 'expenses_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  group('expense list', () {
    for (final (name, state) in <(String, ExpensesState)>[
      ('empty', emptyExpenses),
      ('data', sampleExpenses),
      ('no members', noMembersExpenses),
      ('filter finds nothing', filteredExpenses),
      ('error', const ExpensesFailure(Storage('x'))),
    ]) {
      forEachMode(
        name,
        () => scopedExpenses(
          expensesStateOverride(state),
          const ExpensesView(groupId: 'g-1'),
        ),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });

  group('expense form', () {
    for (final (name, state) in <(String, ExpenseFormState)>[
      ('empty', emptyForm),
      ('equal', equalForm),
      ('exact with error', exactErrorForm),
      (
        'shares',
        formReady(
          title: 'Essen',
          amountCents: 1200,
          mode: SplitMode.shares,
          weights: {'m-0': 2, 'm-1': 1, 'm-2': 1, 'm-3': 0},
          preview: {'m-0': 600, 'm-1': 300, 'm-2': 300, 'm-3': 0},
          participants: {'m-0', 'm-1', 'm-2'},
        ),
      ),
      (
        'percent with error',
        formReady(
          title: 'Essen',
          amountCents: 1200,
          mode: SplitMode.percent,
          weights: {'m-0': 5000, 'm-1': 4500},
          splitError: const PercentNotFull(9500),
          participants: {'m-0', 'm-1'},
        ),
      ),
      (
        'several payers',
        formReady(
          title: 'Hotel',
          amountCents: 1200,
          multiPayer: true,
          payerCents: {'m-0': 800},
          preview: {'m-0': 300, 'm-1': 300, 'm-2': 300, 'm-3': 300},
          payerError: const PayersMismatch(800, 1200),
        ),
      ),
      ('error', const ExpenseFormFailure(Storage('x'))),
    ]) {
      forEachMode(
        name,
        () => scopedExpenses(
          formStateOverride(state),
          const ExpenseFormView(groupId: 'g-1'),
        ),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });
}
