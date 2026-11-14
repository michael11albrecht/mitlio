import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Which expense the form works on: a new one in `groupId`, or, with an
/// `expenseId`, the stored one.
typedef ExpenseFormKey = ({String groupId, String? expenseId});

/// How the amount is divided. Persisted as `equal`, `shares`, `percent`,
/// `exact` (see `splitModeOf`).
enum SplitMode { equal, shares, percent, exact }

sealed class ExpenseFormState {
  const ExpenseFormState();
}

final class ExpenseFormLoading extends ExpenseFormState {
  const ExpenseFormLoading();
}

/// Also covers a group or an expense that does not exist ([NotFound]).
final class ExpenseFormFailure extends ExpenseFormState {
  const ExpenseFormFailure(this.error);

  final RepositoryError error;
}

/// The editable form plus everything derived from it by the domain: the
/// per-person [preview] and the [titleMissing] / [amountMissing] /
/// [splitError] / [payerError] findings. Showing them is the View's call
/// (`showErrors` turns on after a save attempt; mismatches show live).
final class ExpenseFormReady extends ExpenseFormState {
  const ExpenseFormReady({
    required this.group,
    required this.members,
    required this.editing,
    required this.title,
    required this.amountCents,
    required this.date,
    required this.today,
    required this.category,
    required this.multiPayer,
    required this.payerId,
    required this.payerCents,
    required this.mode,
    required this.participants,
    required this.weights,
    required this.preview,
    required this.titleMissing,
    required this.amountMissing,
    required this.splitError,
    required this.payerError,
    required this.showErrors,
    required this.saving,
  });

  final Group group;

  /// In position order.
  final List<GroupMember> members;

  /// An existing expense is being edited.
  final bool editing;
  final String title;
  final int? amountCents;

  /// Midnight UTC of the expense day.
  final DateTime date;

  /// Midnight UTC of the current day (from the injected clock).
  final DateTime today;
  final String? category;

  /// "Mehrere haben bezahlt": [payerCents] rules instead of [payerId].
  final bool multiPayer;

  /// The payer while [multiPayer] is off.
  final String payerId;

  /// Member id to paid cents while [multiPayer] is on.
  final Map<String, int> payerCents;
  final SplitMode mode;

  /// Who takes part in the split (weight above zero, or ticked for equal).
  final Set<String> participants;

  /// Entered values of the current [mode]: shares, basis points or cents per
  /// member. Empty for [SplitMode.equal].
  final Map<String, int> weights;

  /// Cents each member bears, live from the domain. Empty while the amount
  /// or the split is invalid; for [SplitMode.exact] it falls back to the
  /// entered amounts so the user sees their own numbers next to the error.
  final Map<String, int> preview;
  final bool titleMissing;
  final bool amountMissing;
  final SplitError? splitError;
  final ExpenseError? payerError;
  final bool showErrors;
  final bool saving;

  bool get hasIssues =>
      titleMissing || amountMissing || splitError != null || payerError != null;

  /// Stored categories first, plus the current one if it is a custom key.
  List<String> get categoryOptions => [
    ...expenseCategories,
    if (category != null && !expenseCategories.contains(category)) category!,
  ];
}

/// Add or edit one expense. Every field is a command; the state is rebuilt
/// from them on each change and validated by the domain, so what the View
/// shows is exactly what `save` would accept.
class ExpenseFormViewModel extends Notifier<ExpenseFormState> {
  ExpenseFormViewModel(this.key);

  final ExpenseFormKey key;

  late Group _group;
  late List<GroupMember> _members;
  var _title = '';
  int? _amount;
  late DateTime _date;
  late DateTime _today;
  String? _category;
  var _multiPayer = false;
  late String _payerId;
  var _payerCents = <String, int>{};
  SplitMode _mode = SplitMode.equal;
  var _participants = <String>{};
  final _shares = <String, int>{};
  final _percent = <String, int>{};
  final _exact = <String, int>{};
  var _showErrors = false;
  var _saving = false;
  var _loaded = false;

  @override
  ExpenseFormState build() {
    _loaded = false;
    unawaited(_load());
    return const ExpenseFormLoading();
  }

  void _set(ExpenseFormState next) {
    if (ref.mounted) state = next;
  }

  Future<void> _load() async {
    try {
      final groupResult = await ref
          .read(groupsRepositoryProvider)
          .get(
            key.groupId,
          );
      if (groupResult case Err(:final error)) {
        return _set(ExpenseFormFailure(error));
      }
      final members =
          (await ref.read(membersRepositoryProvider).list(key.groupId))
              .orThrow();
      final entries = await _current(
        ref.read(expensesRepositoryProvider).watchExpenses(key.groupId),
      );
      ExpenseEntry? stored;
      final id = key.expenseId;
      if (id != null) {
        final got = await ref.read(expensesRepositoryProvider).get(id);
        if (got case Err(:final error)) return _set(ExpenseFormFailure(error));
        stored = (got as Ok<ExpenseEntry, RepositoryError>).value;
      }
      if (!ref.mounted) return;
      _group = (groupResult as Ok<Group, RepositoryError>).value;
      _members = members;
      final now = ref.read(clockProvider).now();
      _today = DateTime.utc(now.year, now.month, now.day);
      _date = _today;
      _payerId =
          _lastPayer(entries) ?? (members.isEmpty ? '' : members.first.id);
      _participants = {for (final m in members) m.id};
      if (stored != null) _adopt(stored);
      _loaded = true;
      _emit();
    } on Object catch (e) {
      _set(ExpenseFormFailure(e is RepositoryError ? e : Storage(e)));
    }
  }

  /// The first emission of [stream]. Listens and cancels by hand, so it
  /// settles with plain microtasks (no stream-cancel future to wait for).
  Future<List<ExpenseEntry>> _current(Stream<List<ExpenseEntry>> stream) {
    final done = Completer<List<ExpenseEntry>>();
    final sub = stream.listen(
      (v) => done.isCompleted ? null : done.complete(v),
      onError: (Object e) => done.isCompleted ? null : done.completeError(e),
    );
    return done.future.whenComplete(() => unawaited(sub.cancel()));
  }

  /// Smart default: whoever paid the newest expense (the biggest payer if
  /// several did), as long as they are still a member.
  String? _lastPayer(List<ExpenseEntry> entries) {
    if (entries.isEmpty) return null;
    final payers = entries.first.expense.payers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final id = payers.first.key;
    return _members.any((m) => m.id == id) ? id : null;
  }

  void _adopt(ExpenseEntry stored) {
    final e = stored.expense;
    _title = e.title;
    _amount = e.amountCents;
    _date = DateTime.utc(e.date.year, e.date.month, e.date.day);
    _category = stored.category;
    if (e.payers.length > 1) {
      _multiPayer = true;
      _payerCents = {...e.payers};
    }
    _payerId = e.payers.keys.first;
    switch (stored.split) {
      case EqualSplit(:final participants):
        _participants = {...participants};
      case SharesSplit(:final weights):
        _mode = SplitMode.shares;
        _shares.addAll(weights);
        _participants = {...weights.keys};
      case PercentSplit(:final basisPoints):
        _mode = SplitMode.percent;
        _percent.addAll(basisPoints);
        _participants = {...basisPoints.keys};
      case ExactSplit(:final cents):
        _mode = SplitMode.exact;
        _exact.addAll(cents);
        _participants = {...cents.keys};
    }
  }

  Map<String, int> get _weights => switch (_mode) {
    SplitMode.equal => const {},
    SplitMode.shares => _shares,
    SplitMode.percent => _percent,
    SplitMode.exact => _exact,
  };

  Set<String> _currentParticipants() => switch (_mode) {
    SplitMode.equal => _participants,
    _ => {
      for (final e in _weights.entries)
        if (e.value > 0) e.key,
    },
  };

  SplitSpec _spec() => switch (_mode) {
    SplitMode.equal => EqualSplit(_participants),
    SplitMode.shares => SharesSplit(_positive(_shares)),
    SplitMode.percent => PercentSplit(_positive(_percent)),
    SplitMode.exact => ExactSplit(_positive(_exact)),
  };

  static Map<String, int> _positive(Map<String, int> m) => {
    for (final e in m.entries)
      if (e.value > 0) e.key: e.value,
  };

  Map<String, int> _payers() {
    final amount = _amount;
    if (amount == null || amount <= 0) return const {};
    return _multiPayer ? _positive(_payerCents) : {_payerId: amount};
  }

  void _emit() {
    if (!_loaded || !ref.mounted) return;
    final amount = _amount;
    final amountMissing = amount == null || amount <= 0;
    final members = [for (final m in _members) m.toDomain()];
    final spec = _spec();
    final payers = _payers();
    SplitError? splitError;
    ExpenseError? payerError;
    var preview = const <String, int>{};
    if (!amountMissing) {
      switch (computeShares(
        amountCents: amount,
        spec: spec,
        members: members,
      )) {
        case Ok(:final value):
          preview = value;
        case Err(:final error):
          splitError = error;
          if (_mode == SplitMode.exact) preview = {..._exact};
      }
      // The title is judged on its own, so a blank one never hides these.
      const probeTitle = 'x';
      final created = Expense.create(
        id: 'preview',
        title: probeTitle,
        amountCents: amount,
        currency: _group.currency,
        date: _date,
        payers: payers,
        split: spec,
        members: members,
      );
      if (created case Err(:final error) when error is! InvalidSplit) {
        payerError = error;
      }
    }
    _set(
      ExpenseFormReady(
        group: _group,
        members: _members,
        editing: key.expenseId != null,
        title: _title,
        amountCents: _amount,
        date: _date,
        today: _today,
        category: _category,
        multiPayer: _multiPayer,
        payerId: _payerId,
        payerCents: Map.unmodifiable(_payerCents),
        mode: _mode,
        participants: Set.unmodifiable(_currentParticipants()),
        weights: Map.unmodifiable(_weights),
        preview: Map.unmodifiable(preview),
        titleMissing: _title.trim().isEmpty,
        amountMissing: amountMissing,
        splitError: splitError,
        payerError: payerError,
        showErrors: _showErrors,
        saving: _saving,
      ),
    );
  }

  /// Starts over after a failed load.
  void retry() {
    state = const ExpenseFormLoading();
    ref.invalidateSelf();
  }

  void setTitle(String value) {
    _title = value;
    _emit();
  }

  /// Integer minor units of the group currency; null while empty or invalid.
  void setAmount(int? cents) {
    _amount = cents;
    _emit();
  }

  /// Only the calendar day counts.
  void setDate(DateTime day) {
    _date = DateTime.utc(day.year, day.month, day.day);
    _emit();
  }

  /// One of [expenseCategories] or any custom key; null clears it.
  void setCategory(String? category) {
    _category = category;
    _emit();
  }

  /// Single-payer mode: [memberId] paid everything.
  void setPayer(String memberId) {
    _payerId = memberId;
    _emit();
  }

  /// Switches between one payer and several. Going to several starts with
  /// the current payer owning the whole amount, so nothing is lost.
  void setMultiplePayers({required bool on}) {
    if (on == _multiPayer) return;
    _multiPayer = on;
    _payerCents = on && _amount != null ? {_payerId: _amount!} : {};
    _emit();
  }

  /// Multi-payer mode: what [memberId] paid; null or 0 removes them.
  void setPayerAmount(String memberId, int? cents) {
    _payerCents = {..._payerCents, memberId: cents ?? 0};
    _emit();
  }

  /// Switches the split mode, carrying over who takes part and starting with
  /// sensible values (1 share each, an even percentage, an even cent split)
  /// so the form stays valid.
  void setMode(SplitMode mode) {
    if (mode == _mode) return;
    final taking = _currentParticipants();
    if (taking.isNotEmpty) _participants = {...taking};
    _mode = mode;
    final members = [for (final m in _members) m.toDomain()];
    Map<String, int> evenly(int total) => switch (computeShares(
      amountCents: total,
      spec: EqualSplit(_participants),
      members: members,
    )) {
      Ok(:final value) => _positive(value),
      Err() => {},
    };
    switch (mode) {
      case SplitMode.equal:
        break;
      case SplitMode.shares:
        if (_shares.isEmpty) {
          _shares.addAll({for (final p in _participants) p: 1});
        }
      case SplitMode.percent:
        if (_percent.isEmpty) _percent.addAll(evenly(10000));
      case SplitMode.exact:
        final amount = _amount;
        if (_exact.isEmpty && amount != null && amount > 0) {
          _exact.addAll(evenly(amount));
        }
    }
    _emit();
  }

  /// Equal mode: ticks or unticks [memberId].
  void toggleParticipant(String memberId) {
    _participants = _participants.contains(memberId)
        ? ({..._participants}..remove(memberId))
        : {..._participants, memberId};
    _emit();
  }

  /// Shares, percent or exact mode: the value of [memberId] in the unit of
  /// the mode (shares, basis points, cents). Null or 0 excludes them.
  void setWeight(String memberId, int? value) {
    if (_mode == SplitMode.equal) return;
    _weights[memberId] = value ?? 0;
    _emit();
  }

  /// Validates and stores. Local findings are returned as
  /// `Err(InvalidData)` without touching the repository and become visible
  /// in the state; the repository then validates once more.
  Future<RepoResult<ExpenseEntry>> save() async {
    if (!_loaded || _saving) return const Err(Conflict('form is not ready'));
    _showErrors = true;
    _emit();
    final ready = state;
    if (ready is! ExpenseFormReady || ready.hasIssues) {
      return const Err(InvalidData('the form has errors'));
    }
    final draft = ExpenseDraft(
      title: _title,
      amountCents: _amount!,
      currency: _group.currency,
      date: _date,
      payers: _payers(),
      split: _spec(),
      category: _category,
    );
    _saving = true;
    _emit();
    final list = ref.read(expensesViewModelProvider(key.groupId).notifier);
    final id = key.expenseId;
    final result = await (id == null
        ? list.add(draft)
        : list.update(id, draft));
    _saving = false;
    _emit();
    return result;
  }

  JsonMap debugSnapshot() => switch (state) {
    ExpenseFormLoading() => {'status': 'loading', 'groupId': key.groupId},
    ExpenseFormFailure(:final error) => {
      'status': 'error',
      'groupId': key.groupId,
      'error': error.toString(),
    },
    ExpenseFormReady() => _readySnapshot(state as ExpenseFormReady),
  };

  JsonMap _readySnapshot(ExpenseFormReady s) => {
    'status': 'ready',
    'groupId': key.groupId,
    'expenseId': key.expenseId,
    'title': s.title,
    'amountCents': s.amountCents,
    'currency': s.group.currency.code,
    'date': isoDay(s.date),
    'category': s.category,
    'multiPayer': s.multiPayer,
    'payers': _payers(),
    'mode': s.mode.name,
    'participants': s.participants.toList()..sort(),
    'weights': s.weights,
    'preview': s.preview,
    'issues': [
      if (s.titleMissing) 'title',
      if (s.amountMissing) 'amount',
      if (s.splitError != null) 'split: ${s.splitError}',
      if (s.payerError != null) 'payers: ${s.payerError}',
    ],
    'showErrors': s.showErrors,
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final expenseFormViewModelProvider =
    NotifierProvider.family<
      ExpenseFormViewModel,
      ExpenseFormState,
      ExpenseFormKey
    >(
      ExpenseFormViewModel.new,
    );
