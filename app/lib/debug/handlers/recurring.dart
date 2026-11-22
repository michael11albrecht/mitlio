import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/recurring/data/repositories/recurring_providers.dart';
import 'package:mitlio/features/recurring/ui/recurring_catch_up_view_model.dart';
import 'package:mitlio/features/recurring/ui/recurring_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

const _usage =
    'need groupId, title, amountCents (group currency), frequency (daily, '
    'weekly, monthly or yearly); optional interval (default 1), start '
    '(YYYY-MM-DD, default today), end (YYYY-MM-DD), payers (JSON '
    '{memberId: cents}, default: the first member pays), split (JSON, default '
    'equal among everyone: {"mode": "equal", "participants": [ids]} or '
    '{"mode": "shares" | "percent" | "exact", "weights": {id: n}}), category, '
    'lastGenerated (YYYY-MM-DD, an expense for that day exists already)';

Object? _json(String? raw) {
  if (raw == null) return null;
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

Map<String, int>? _intMap(Object? raw) =>
    raw is Map && raw.values.every((v) => v is int)
    ? raw.map((k, v) => MapEntry(k as String, v as int))
    : null;

SplitSpec? _split(String? raw, List<String> everyone) {
  if (raw == null) return EqualSplit(everyone.toSet());
  final json = _json(raw);
  if (json is! Map) return null;
  final participants = json['participants'];
  if (json['mode'] == 'equal' && participants is List) {
    return participants.every((e) => e is String)
        ? EqualSplit(participants.cast<String>().toSet())
        : null;
  }
  final weights = _intMap(json['weights']);
  final mode = json['mode'];
  return mode is String && weights != null
      ? splitFromWeights(mode, weights)
      : null;
}

DateTime? _day(String? raw, DateTime? fallback) {
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

/// `ext.mitlio.recurring.*`: thin wrappers over the same ViewModel commands
/// the UI calls (keys without the `ext.mitlio.` prefix).
Map<String, DriveHandler> recurringDriveHandlers(ProviderContainer c) {
  DateTime today() {
    final now = c.read(clockProvider).now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  RecurringViewModel rules(String groupId) =>
      c.read(recurringViewModelProvider(groupId).notifier);

  /// The draft described by the params, or an error result.
  Future<(RecurringDraft?, DriveResult?)> draft(
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
    final cents = int.tryParse(p['amountCents'] ?? '');
    final frequency = RecurrenceFrequency.values.asNameMap()[p['frequency']];
    final start = _day(p['start'], today());
    final end = _day(p['end'], null);
    final last = _day(p['lastGenerated'], null);
    final payers = p.containsKey('payers')
        ? _intMap(_json(p['payers']))
        : (members.isEmpty || cents == null ? null : {members.first.id: cents});
    final split = _split(p['split'], [for (final m in members) m.id]);
    final interval = int.tryParse(p['interval'] ?? '1');
    if (title == null ||
        cents == null ||
        frequency == null ||
        start == null ||
        (p.containsKey('end') && end == null) ||
        (p.containsKey('lastGenerated') && last == null) ||
        payers == null ||
        split == null ||
        interval == null) {
      return (null, invalidParams(_usage));
    }
    final rule = RecurrenceRule.create(
      start: start,
      frequency: frequency,
      interval: interval,
      end: end,
    );
    if (rule case Err(:final error)) {
      return (null, invalidParams('invalid rule: $error'));
    }
    return (
      RecurringDraft(
        title: title,
        amountCents: cents,
        payers: payers,
        split: split,
        category: p['category'],
        rule: (rule as Ok<RecurrenceRule, RecurrenceError>).value,
        lastGenerated: last,
      ),
      null,
    );
  }

  Future<RepoResult<RecurringExpense>> find(String id) async {
    final all = await c.read(recurringRepositoryProvider).all();
    if (all case Err(:final error)) return Err(error);
    final found = (all as Ok<List<RecurringExpense>, RepositoryError>).value
        .where((r) => r.id == id)
        .firstOrNull;
    return found == null ? Err(NotFound('recurring', id)) : Ok(found);
  }

  DriveResult json(RecurringExpense r) => recurringJson(r, today());

  return {
    'recurring.create': (p) async {
      final groupId = p['groupId'];
      if (groupId == null) return invalidParams(_usage);
      final (d, error) = await draft(groupId, p);
      return error ?? _result(await rules(groupId).create(d!), json);
    },
    'recurring.update': (p) async {
      final id = p['id'];
      if (id == null) return invalidParams('need id, and $_usage');
      final found = await find(id);
      if (found case Err(:final error)) return driveError(error);
      final groupId =
          (found as Ok<RecurringExpense, RepositoryError>).value.groupId;
      final (d, error) = await draft(groupId, {...p, 'groupId': groupId});
      return error ?? _result(await rules(groupId).update(id, d!), json);
    },
    'recurring.list': (p) async {
      final groupId = p['groupId'];
      if (groupId == null) return invalidParams('need groupId');
      final all = await c.read(recurringRepositoryProvider).all();
      return _result(
        all,
        (list) => {
          'rules': [
            for (final r in list)
              if (r.groupId == groupId) json(r),
          ],
        },
      );
    },
    'recurring.pause': (p) async {
      final id = p['id'];
      final paused = p['paused'] ?? 'true';
      if (id == null || (paused != 'true' && paused != 'false')) {
        return invalidParams('need id; optional paused (true or false)');
      }
      final found = await find(id);
      if (found case Err(:final error)) return driveError(error);
      final groupId =
          (found as Ok<RecurringExpense, RepositoryError>).value.groupId;
      final done = await rules(groupId).setPaused(id, paused: paused == 'true');
      if (done case Err(:final error)) return driveError(error);
      return _result(await find(id), json);
    },
    'recurring.delete': (p) async {
      final id = p['id'];
      if (id == null) return invalidParams('need id');
      final found = await find(id);
      if (found case Err(:final error)) return driveError(error);
      final groupId =
          (found as Ok<RecurringExpense, RepositoryError>).value.groupId;
      return _result(await rules(groupId).delete(id), (_) => {'id': id});
    },
    'recurring.catchUp': (_) async {
      final notice = await c
          .read(recurringCatchUpViewModelProvider.notifier)
          .run();
      return {
        'created': notice.created,
        'skipped': notice.skipped,
        'failures': [
          for (final f in notice.failures)
            {'title': f.title, 'error': f.error.toString()},
        ],
      };
    },
  };
}
