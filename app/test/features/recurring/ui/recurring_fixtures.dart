import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/recurring/ui/recurring_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../expenses/ui/expenses_fixtures.dart';
import 'recurring_view_model_test.dart' show rule;

/// A fixed state for goldens and a11y tests: the ViewModel is replaced by a
/// stub that never touches a repository.
class StubRecurringViewModel extends RecurringViewModel {
  StubRecurringViewModel(super.groupId, this.fixed);

  final RecurringState fixed;

  @override
  RecurringState build() => fixed;
}

List<Override> recurringStateOverride(RecurringState state) => [
  recurringViewModelProvider.overrideWith2(
    (id) => StubRecurringViewModel(id, state),
  ),
];

Widget scopedRecurring(RecurringState state, Widget child) =>
    scopedExpenses(recurringStateOverride(state), child);

RecurringExpense _rule(
  String id,
  String title,
  int cents,
  RecurrenceRule r, {
  bool paused = false,
  DateTime? lastGenerated,
}) => RecurringExpense(
  id: id,
  groupId: 'g-1',
  title: title,
  amountCents: cents,
  payers: {'m-0': cents},
  split: EqualSplit({for (final m in sampleMembers) m.id}),
  rule: r,
  paused: paused,
  lastGenerated: lastGenerated,
  createdAt: DateTime.utc(2026),
);

final RecurringState emptyRecurring = RecurringLoaded(
  group: sampleGroup,
  rules: const [],
  today: DateTime.utc(2026, 3),
);

final RecurringState sampleRecurring = RecurringLoaded(
  group: sampleGroup,
  today: DateTime.utc(2026, 3),
  rules: [
    _rule(
      'r-1',
      'Miete',
      90000,
      rule(DateTime.utc(2026, 1, 31)),
      lastGenerated: DateTime.utc(2026, 2, 28),
    ),
    _rule(
      'r-2',
      'Zeitung',
      1250,
      rule(DateTime.utc(2026, 2, 4), frequency: RecurrenceFrequency.weekly),
      paused: true,
    ),
    _rule(
      'r-3',
      'Versicherung',
      48000,
      rule(
        DateTime.utc(2025, 4),
        frequency: RecurrenceFrequency.yearly,
        end: DateTime.utc(2025, 4),
      ),
    ),
  ],
);
