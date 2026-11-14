import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

Object? _json(String? raw) {
  if (raw == null) return null;
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

/// `{"memberId": 1200, ...}`, or null if [raw] is not such an object.
Map<String, int>? _intMap(Object? raw) =>
    raw is Map && raw.values.every((v) => v is int)
    ? raw.map((k, v) => MapEntry(k as String, v as int))
    : null;

/// The `split` param: `{"mode": "equal", "participants": [ids]}` or
/// `{"mode": "shares" | "percent" | "exact", "weights": {id: n}}` (basis
/// points for percent, cents for exact). Absent means equal among everyone.
SplitSpec? _split(String? raw, List<String> everyone) {
  if (raw == null) return EqualSplit(everyone.toSet());
  final json = _json(raw);
  if (json is! Map) return null;
  final mode = json['mode'];
  final participants = json['participants'];
  if (mode == 'equal' && participants is List) {
    return participants.every((e) => e is String)
        ? EqualSplit(participants.cast<String>().toSet())
        : null;
  }
  final weights = _intMap(json['weights']);
  return mode is String && weights != null
      ? splitFromWeights(mode, weights)
      : null;
}

DateTime? _day(String? raw, DateTime fallback) {
  if (raw == null) return fallback;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  return m == null
      ? null
      : DateTime.utc(
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
        );
}

DriveResult _result<T>(RepoResult<T> r, DriveResult Function(T) ok) =>
    switch (r) {
      Ok(:final value) => ok(value),
      Err(:final error) => driveError(error),
    };

const _addUsage =
    'need groupId, title, amountCents, payers (JSON {memberId: cents in the '
    'group currency}); optional currency (default: the group currency; '
    'amountCents is in it) with fxRatePpm (required for a foreign currency: '
    'group currency per 1 unit x 1e6), date (YYYY-MM-DD, default today), '
    'split (JSON, default equal among everyone), category';

/// The draft described by the `expenses.add` params; null if any is missing
/// or malformed.
Future<ExpenseDraft?> _draft(
  ProviderContainer c,
  String groupId,
  Map<String, String> p,
) async {
  final members = switch (await c
      .read(membersRepositoryProvider)
      .list(groupId)) {
    Ok(:final value) => value,
    Err() => const <GroupMember>[],
  };
  final title = p['title'];
  final entered = int.tryParse(p['amountCents'] ?? '');
  final groupCurrency = switch (await c
      .read(groupsRepositoryProvider)
      .get(groupId)) {
    Ok(:final value) => value.currency,
    Err() => null,
  };
  final currency = Currency.tryParse(
    p['currency'] ?? groupCurrency?.code ?? 'EUR',
  );
  final payers = _intMap(_json(p['payers']));
  final split = _split(p['split'], [for (final m in members) m.id]);
  final date = _day(p['date'], c.read(clockProvider).now());
  if (title == null ||
      entered == null ||
      currency == null ||
      payers == null ||
      split == null ||
      date == null) {
    return null;
  }
  ForeignAmount? foreign;
  var cents = entered;
  // An unknown group stays the repository's NotFound.
  final group = groupCurrency ?? currency;
  if (currency != group) {
    final ppm = int.tryParse(p['fxRatePpm'] ?? '');
    if (ppm == null || ppm <= 0 || entered <= 0) return null;
    foreign = ForeignAmount(
      currency: currency,
      amountCents: entered,
      ratePpm: ppm,
    );
    try {
      cents = foreign.toGroup(group).cents;
    } on MoneyOverflow {
      return null;
    }
  }
  return ExpenseDraft(
    title: title,
    amountCents: cents,
    currency: group,
    foreign: foreign,
    date: date,
    payers: payers,
    split: split,
    category: p['category'],
  );
}

/// `ext.mitlio.expenses.*`: thin wrappers over the same ViewModel commands
/// the UI calls (keys without the `ext.mitlio.` prefix).
Map<String, DriveHandler> expensesDriveHandlers(ProviderContainer c) {
  ExpensesViewModel expenses(String groupId) =>
      c.read(expensesViewModelProvider(groupId).notifier);
  return {
    'expenses.add': (p) async {
      final groupId = p['groupId'];
      final draft = groupId == null ? null : await _draft(c, groupId, p);
      return draft == null
          ? invalidParams(_addUsage)
          : _result(await expenses(groupId!).add(draft), expenseJson);
    },
    'expenses.list': (p) async {
      final groupId = p['groupId'];
      if (groupId == null) return invalidParams('need groupId');
      return _result(
        await expenses(groupId).list(),
        (list) => {'expenses': list.map(expenseJson).toList()},
      );
    },
    'expenses.delete': (p) async {
      final id = p['id'];
      if (id == null) return invalidParams('need id');
      final entry = await c.read(expensesRepositoryProvider).get(id);
      if (entry case Err(:final error)) return driveError(error);
      final groupId =
          (entry as Ok<ExpenseEntry, RepositoryError>).value.groupId;
      return _result(await expenses(groupId).delete(id), (_) => {'id': id});
    },
  };
}
