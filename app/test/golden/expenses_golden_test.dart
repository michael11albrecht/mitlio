import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view_model.dart';
import 'package:mitlio/features/expenses/ui/expenses_view.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';

import '../features/expenses/ui/expenses_fixtures.dart';
import 'golden_matrix.dart';

const _width = 360.0;
const _listHeight = 640.0;
const _formHeight = 960.0;

Widget _list(ExpensesState s) => scopedExpenses(
  expensesStateOverride(s),
  const ExpensesView(groupId: 'g-1'),
);

Widget _form(ExpenseFormState s) =>
    scopedExpenses(formStateOverride(s), const ExpenseFormView(groupId: 'g-1'));

Future<void> main() async {
  Future<void> list(
    String name,
    ExpensesState state, {
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => _list(state),
    width: _width,
    height: _listHeight,
    pumpBeforeTest: pump,
  );

  Future<void> form(
    String name,
    ExpenseFormState state, {
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    () => _form(state),
    width: _width,
    height: _formHeight,
    pumpBeforeTest: pump,
  );

  await list('expenses_loading', const ExpensesLoading(), pump: pumpOnce);
  await list('expenses_empty', emptyExpenses);
  await list('expenses_no_members', noMembersExpenses);
  await list('expenses_error', const ExpensesFailure(Storage('x')));
  await list('expenses_data', sampleExpenses);
  await list('expenses_filtered_empty', filteredExpenses);
  await list('expenses_foreign', foreignExpenses);

  await form(
    'expense_form_loading',
    const ExpenseFormLoading(),
    pump: pumpOnce,
  );
  await form('expense_form_error', const ExpenseFormFailure(Storage('x')));
  await form('expense_form_empty', emptyForm);
  await form('expense_form_equal', equalForm);
  await form('expense_form_exact_error', exactErrorForm);
  await form('expense_form_foreign', foreignForm);
}
