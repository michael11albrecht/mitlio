import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
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
  const GroupsLoaded(this.groups, {this.archivedCount = 0});

  final List<Group> groups;

  /// How many archived groups exist; the list shows an entry when above 0.
  final int archivedCount;

  bool get isEmpty => groups.isEmpty;
}

/// Creator id until accounts exist (P6); replaced by the account id then.
const localOwnerId = 'local';

/// Home screen: the groups of this device, plus create and archive.
class GroupsViewModel extends Notifier<GroupsState> {
  @override
  GroupsState build() {
    final repo = ref.watch(groupsRepositoryProvider);
    List<Group>? live;
    var archived = 0;
    void emit() {
      if (live != null) _set(GroupsLoaded(live!, archivedCount: archived));
    }

    void fail(Object e) =>
        _set(GroupsFailure(e is RepositoryError ? e : Storage(e)));
    final subs = [
      repo.watchGroups().listen((groups) {
        live = groups;
        emit();
      }, onError: fail),
      repo.watchArchivedGroups().listen((groups) {
        archived = groups.length;
        emit();
      }, onError: fail),
    ];
    ref.onDispose(() {
      for (final sub in subs) {
        unawaited(sub.cancel());
      }
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

  /// Pull-to-refresh: syncs every shared group now (local-only groups never
  /// touch the network). Returns the first failure so the list can say so
  /// (`remoteErrorText`); each group's status line shows its own.
  Future<SyncError?> refresh() async {
    final stats = await ref.read(syncCoordinatorProvider).refreshAll();
    for (final s in stats) {
      final status = s.status;
      if (status is SyncError) return status;
    }
    return null;
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

  JsonMap debugSnapshot() => switch (state) {
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

/// The archived groups, with "restore" (no confirm; the screen offers undo).
class ArchivedGroupsViewModel extends Notifier<GroupsState> {
  @override
  GroupsState build() {
    final sub = ref
        .watch(groupsRepositoryProvider)
        .watchArchivedGroups()
        .listen(
          (groups) => _set(GroupsLoaded(groups)),
          onError: (Object e) =>
              _set(GroupsFailure(e is RepositoryError ? e : Storage(e))),
        );
    ref.onDispose(() => unawaited(sub.cancel()));
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

  /// The archived groups as of now (for DebugDrive).
  Future<RepoResult<List<Group>>> list() async {
    try {
      return Ok(
        await ref.read(groupsRepositoryProvider).watchArchivedGroups().first,
      );
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  /// Brings the group back to the list; the returned [Undo] archives it
  /// again.
  Future<RepoResult<Undo>> restore(String id) async {
    final repo = ref.read(groupsRepositoryProvider);
    final restored = await repo.restore(id);
    return switch (restored) {
      Ok() => Ok(
        Undo(() async {
          final r = await repo.softDelete(id);
          return switch (r) {
            Ok() => const Ok(null),
            Err(:final error) => Err(error),
          };
        }),
      ),
      Err(:final error) => Err(error),
    };
  }

  JsonMap debugSnapshot() => switch (state) {
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

final archivedGroupsViewModelProvider =
    NotifierProvider<ArchivedGroupsViewModel, GroupsState>(
      ArchivedGroupsViewModel.new,
    );
