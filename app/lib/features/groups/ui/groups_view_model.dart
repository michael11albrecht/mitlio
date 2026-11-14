import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_snapshots.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What the group list shows. Empty is `GroupsLoaded` with no groups.
sealed class GroupsState {
  const GroupsState();
}

final class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

final class GroupsFailure extends GroupsState {
  const GroupsFailure(this.error);

  final RepositoryError error;
}

final class GroupsLoaded extends GroupsState {
  const GroupsLoaded(this.groups);

  final List<Group> groups;

  bool get isEmpty => groups.isEmpty;
}

/// Creator id until accounts exist (P6); replaced by the account id then.
const localOwnerId = 'local';

/// Home screen: the groups of this device, plus create and archive.
class GroupsViewModel extends Notifier<GroupsState> {
  @override
  GroupsState build() {
    final registry = ref.watch(debugSnapshotRegistryProvider)
      ..register('groups', debugSnapshot);
    final sub = ref
        .watch(groupsRepositoryProvider)
        .watchGroups()
        .listen(
          (groups) => _set(GroupsLoaded(groups)),
          onError: (Object e) =>
              _set(GroupsFailure(e is RepositoryError ? e : Storage(e))),
        );
    ref.onDispose(() {
      unawaited(sub.cancel());
      registry.unregister('groups');
    });
    return const GroupsLoading();
  }

  void _set(GroupsState next) {
    if (ref.mounted) state = next;
  }

  /// Starts over after a failure.
  void retry() {
    state = const GroupsLoading();
    ref.invalidateSelf();
  }

  /// Creates the group and appends [memberNames] in order (blank names are
  /// skipped). If adding a member fails the group stays and the error is
  /// returned.
  Future<RepoResult<Group>> create({
    required String name,
    required Currency currency,
    List<String> memberNames = const [],
  }) async {
    if (name.trim().isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    final created = await ref
        .read(groupsRepositoryProvider)
        .create(name: name, currency: currency, createdBy: localOwnerId);
    if (created case Ok(:final value)) {
      final members = ref.read(membersRepositoryProvider);
      for (final memberName in memberNames) {
        if (memberName.trim().isEmpty) continue;
        final added = await members.add(value.id, name: memberName);
        if (added case Err(:final error)) return Err(error);
      }
    }
    return created;
  }

  /// The groups as of now (for DebugDrive; the UI watches the state).
  Future<RepoResult<List<Group>>> list() async {
    try {
      return Ok(await ref.read(groupsRepositoryProvider).watchGroups().first);
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  /// Soft delete; the returned [Undo] brings the group back.
  Future<RepoResult<Undo>> archive(String id) =>
      ref.read(groupsRepositoryProvider).softDelete(id);

  DriveResult debugSnapshot() => switch (state) {
    GroupsLoading() => {'status': 'loading'},
    GroupsFailure(:final error) => {
      'status': 'error',
      'error': error.toString(),
    },
    GroupsLoaded(:final groups) => {
      'status': groups.isEmpty ? 'empty' : 'data',
      'groups': [
        for (final g in groups)
          {'id': g.id, 'name': g.name, 'currency': g.currency.code},
      ],
    },
  };
}

final groupsViewModelProvider = NotifierProvider<GroupsViewModel, GroupsState>(
  GroupsViewModel.new,
);
