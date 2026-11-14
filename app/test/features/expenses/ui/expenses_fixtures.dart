import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/data/repositories/fake_expenses_repository.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view_model.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

/// Expenses fake whose commands and stream can be made to fail.
class FlakyExpenses extends FakeExpensesRepository {
  FlakyExpenses({
    required super.groups,
    required super.members,
    required super.clock,
    required super.ids,
  });

  /// Fails `create`, `update` and `softDelete` while set.
  RepositoryError? failWith;

  /// Makes `watchExpenses` emit this error while set.
  Object? watchError;

  @override
  Stream<List<ExpenseEntry>> watchExpenses(String groupId) => watchError != null
      ? Stream.error(watchError!)
      : super.watchExpenses(groupId);

  @override
  Future<RepoResult<ExpenseEntry>> create(
    String groupId,
    ExpenseDraft draft,
  ) async => failWith != null ? Err(failWith!) : super.create(groupId, draft);

  @override
  Future<RepoResult<ExpenseEntry>> update(
    String id,
    ExpenseDraft draft,
  ) async => failWith != null ? Err(failWith!) : super.update(id, draft);

  @override
  Future<RepoResult<Undo>> softDelete(String id) async =>
      failWith != null ? Err(failWith!) : super.softDelete(id);
}

/// [FakeApp] plus a failing-capable expenses repository and a group "Trip"
/// with Ann, Ben and Cy.
class ExpensesApp {
  factory ExpensesApp() {
    final base = FakeApp();
    return ExpensesApp._(
      base,
      FlakyExpenses(
        groups: base.groups,
        members: base.members,
        clock: base.clock,
        ids: SequentialIdGenerator(prefix: 'ex'),
      ),
    );
  }

  ExpensesApp._(this.base, this.expenses);

  final FakeApp base;
  final FlakyExpenses expenses;
  late Group trip;
  late List<GroupMember> people;

  List<Override> get overrides => [
    clockProvider.overrideWithValue(base.clock),
    groupsRepositoryProvider.overrideWithValue(base.groups),
    membersRepositoryProvider.overrideWithValue(base.members),
    settlementsRepositoryProvider.overrideWithValue(base.settlements),
    expensesRepositoryProvider.overrideWithValue(expenses),
  ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);

  /// Creates the group with three members.
  Future<void> seedTrip({Currency currency = Currency.eur}) async {
    trip = ok(
      await base.groups.create(
        name: 'Trip',
        currency: currency,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Ann', 'Ben', 'Cy'])
        ok(await base.members.add(trip.id, name: n)),
    ];
  }

  /// Stores an expense directly through the repository.
  Future<ExpenseEntry> add({
    String title = 'Taxi',
    int cents = 900,
    DateTime? date,
    Map<String, int>? payers,
    SplitSpec? split,
    String? category,
  }) async => ok(
    await expenses.create(
      trip.id,
      ExpenseDraft(
        title: title,
        amountCents: cents,
        currency: trip.currency,
        date: date ?? DateTime.utc(2026, 2),
        payers: payers ?? {people[0].id: cents},
        split: split ?? EqualSplit({for (final p in people) p.id}),
        category: category,
      ),
    ),
  );
}

/// Fixed states for goldens and a11y tests: the ViewModels are replaced by
/// stubs that never touch a repository.
class StubExpensesViewModel extends ExpensesViewModel {
  StubExpensesViewModel(super.groupId, this.fixed);

  final ExpensesState fixed;

  @override
  ExpensesState build() => fixed;
}

class StubExpenseFormViewModel extends ExpenseFormViewModel {
  StubExpenseFormViewModel(super.key, this.fixed);

  final ExpenseFormState fixed;

  @override
  ExpenseFormState build() => fixed;

  @override
  Future<RepoResult<ExpenseEntry>> save() async =>
      const Err(InvalidData('stub'));
}

List<Override> expensesStateOverride(ExpensesState state) => [
  expensesViewModelProvider.overrideWith2(
    (id) => StubExpensesViewModel(id, state),
  ),
];

List<Override> formStateOverride(ExpenseFormState state) => [
  expenseFormViewModelProvider.overrideWith2(
    (key) => StubExpenseFormViewModel(key, state),
  ),
];

Widget scopedExpenses(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: child);

const _names = ['Anna Berg', 'Ben', 'Chiara Rossi', 'Dino Kovač'];

final sampleGroup = Group(
  id: 'g-1',
  name: 'Wochenende in den Bergen',
  currency: Currency.eur,
  createdBy: 'local',
  createdAt: DateTime.utc(2026),
);

final List<GroupMember> sampleMembers = [
  for (var i = 0; i < _names.length; i++)
    GroupMember(id: 'm-$i', groupId: 'g-1', name: _names[i], position: i),
];

final Set<String> _everyone = {for (final m in sampleMembers) m.id};

ExpenseEntry _entry(
  String id,
  String title,
  int cents,
  DateTime date,
  String payer, {
  String? category,
}) {
  final split = EqualSplit(_everyone);
  final expense = (Expense.create(
    id: id,
    title: title,
    amountCents: cents,
    currency: Currency.eur,
    date: date,
    payers: {payer: cents},
    split: split,
    members: [for (final m in sampleMembers) m.toDomain()],
  ) as Ok<Expense, ExpenseError>).value;
  return ExpenseEntry(
    groupId: 'g-1',
    expense: expense,
    split: split,
    category: category,
    createdAt: date,
  );
}

final List<ExpenseEntry> sampleEntries = [
  _entry(
    'e-1',
    'Pizza am See',
    4860,
    DateTime.utc(2026, 3),
    'm-1',
    category: 'food',
  ),
  _entry(
    'e-2',
    'Taxi',
    2350,
    DateTime.utc(2026, 3),
    'm-0',
    category: 'transport',
  ),
  _entry(
    'e-3',
    'Hütte, 2 Nächte',
    26000,
    DateTime.utc(2026, 2, 27),
    'm-2',
    category: 'stay',
  ),
];

final sampleExpenses = ExpensesLoaded(
  group: sampleGroup,
  members: sampleMembers,
  entries: sampleEntries,
  today: DateTime.utc(2026, 3),
);

/// One expense paid in dollars (12,00 $ at 0,92 = 11,04 €) and one in euros.
final foreignExpenses = ExpensesLoaded(
  group: sampleGroup,
  members: sampleMembers,
  entries: [
    ExpenseEntry(
      groupId: 'g-1',
      expense: (Expense.create(
        id: 'e-4',
        title: 'Eis in New York',
        amountCents: 1104,
        currency: Currency.eur,
        date: DateTime.utc(2026, 3),
        payers: {'m-1': 1104},
        split: EqualSplit(_everyone),
        members: [for (final m in sampleMembers) m.toDomain()],
      ) as Ok<Expense, ExpenseError>).value,
      split: EqualSplit(_everyone),
      category: 'food',
      foreign: const ForeignAmount(
        currency: Currency.usd,
        amountCents: 1200,
        ratePpm: 920000,
      ),
      createdAt: DateTime.utc(2026, 3),
    ),
    sampleEntries.first,
  ],
  today: DateTime.utc(2026, 3),
);

final emptyExpenses = ExpensesLoaded(
  group: sampleGroup,
  members: sampleMembers,
  entries: const [],
  today: DateTime.utc(2026, 3),
);

final noMembersExpenses = ExpensesLoaded(
  group: sampleGroup,
  members: const [],
  entries: const [],
  today: DateTime.utc(2026, 3),
);

final filteredExpenses = ExpensesLoaded(
  group: sampleGroup,
  members: sampleMembers,
  entries: sampleEntries,
  today: DateTime.utc(2026, 3),
  categoryFilter: 'other',
);

ExpenseFormReady formReady({
  String title = '',
  int? amountCents,
  SplitMode mode = SplitMode.equal,
  Set<String>? participants,
  Map<String, int> weights = const {},
  Map<String, int> preview = const {},
  SplitError? splitError,
  ExpenseError? payerError,
  bool multiPayer = false,
  Map<String, int> payerCents = const {},
  bool showErrors = false,
  String? category,
  bool editing = false,
  Currency currency = Currency.eur,
  int? ratePpm,
  int? groupAmountCents,
}) => ExpenseFormReady(
  group: sampleGroup,
  members: sampleMembers,
  editing: editing,
  title: title,
  amountCents: amountCents,
  date: DateTime.utc(2026, 3),
  today: DateTime.utc(2026, 3),
  currency: currency,
  ratePpm: ratePpm,
  groupAmountCents: groupAmountCents ?? amountCents,
  currencyOptions: [
    Currency.eur,
    for (final c in Currency.all)
      if (c != Currency.eur) c,
  ],
  category: category,
  multiPayer: multiPayer,
  payerId: 'm-0',
  payerCents: payerCents,
  mode: mode,
  participants: participants ?? _everyone,
  weights: weights,
  preview: preview,
  titleMissing: title.trim().isEmpty,
  amountMissing: amountCents == null,
  splitError: splitError,
  payerError: payerError,
  showErrors: showErrors,
  saving: false,
);

/// 120,00 € between four people, empty title: the typical state mid-entry.
final ExpenseFormReady equalForm = formReady(
  title: 'Abendessen',
  amountCents: 12000,
  preview: {'m-0': 3000, 'm-1': 3000, 'm-2': 3000, 'm-3': 3000},
  category: 'food',
);

/// Exact amounts that miss the total by 10,00 €.
final ExpenseFormReady exactErrorForm = formReady(
  title: 'Abendessen',
  amountCents: 12000,
  mode: SplitMode.exact,
  weights: {'m-0': 5000, 'm-1': 3000, 'm-2': 2000, 'm-3': 2000},
  preview: {'m-0': 5000, 'm-1': 3000, 'm-2': 2000, 'm-3': 2000},
  splitError: const ExactMismatch(11000, 12000),
  showErrors: true,
);

final ExpenseFormReady emptyForm = formReady();

/// 120,00 $ at 0,92: converted to 110,40 € which the split works on.
final ExpenseFormReady foreignForm = formReady(
  title: 'Abendessen',
  amountCents: 12000,
  currency: Currency.usd,
  ratePpm: 920000,
  groupAmountCents: 11040,
  preview: {'m-0': 2760, 'm-1': 2760, 'm-2': 2760, 'm-3': 2760},
  category: 'food',
);

/// Starts the real app on the repositories of [app] and optionally jumps to
/// [location]; German unless [locale] says otherwise.
Future<ProviderContainer> pumpExpenses(
  WidgetTester tester,
  ExpensesApp app, {
  String? location,
  Locale locale = const Locale('de'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  // Tall enough that the whole form is built (lists build lazily).
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = app.container();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MitlioApp()),
  );
  if (location != null) container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return container;
}
