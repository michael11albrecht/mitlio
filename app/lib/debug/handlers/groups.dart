import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

DriveResult _group(Group g) => {
  'id': g.id,
  'name': g.name,
  'currency': g.currency.code,
};

/// `members` param: a JSON list of names. Absent means none, malformed null.
List<String>? _names(String? raw) {
  if (raw == null) return const [];
  try {
    final decoded = jsonDecode(raw);
    return decoded is List && decoded.every((e) => e is String)
        ? decoded.cast<String>()
        : null;
  } on FormatException {
    return null;
  }
}

DriveResult _result<T>(RepoResult<T> r, DriveResult Function(T) ok) =>
    switch (r) {
      Ok(:final value) => ok(value),
      Err(:final error) => driveError(error),
    };

/// `ext.mitlio.groups.*` and `ext.mitlio.members.*`: thin wrappers over the
/// same ViewModel commands the UI calls (keys without the `ext.mitlio.`
/// prefix).
Map<String, DriveHandler> groupsDriveHandlers(ProviderContainer c) {
  GroupsViewModel groups() => c.read(groupsViewModelProvider.notifier);
  return {
    'groups.create': (p) async {
      final currency = Currency.tryParse(p['currency'] ?? 'EUR');
      final members = _names(p['members']);
      final name = p['name'];
      if (name == null || currency == null || members == null) {
        return invalidParams('need name, currency (ISO), members (JSON list)');
      }
      final created = await groups().create(
        name: name,
        currency: currency,
        memberNames: members,
      );
      return _result(created, _group);
    },
    'groups.list': (_) async => _result(
      await groups().list(),
      (gs) => {'groups': gs.map(_group).toList()},
    ),
    'members.add': (p) async {
      final (groupId, name) = (p['groupId'], p['name']);
      if (groupId == null || name == null) {
        return invalidParams('need groupId, name');
      }
      final vm = c.read(groupDetailViewModelProvider(groupId).notifier);
      return _result(
        await vm.addMember(name),
        (m) => {'id': m.id, 'name': m.name, 'position': m.position},
      );
    },
  };
}
