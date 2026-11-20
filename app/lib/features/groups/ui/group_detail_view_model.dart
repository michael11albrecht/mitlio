import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio/features/sync/data/repositories/connections_repository.dart';
import 'package:mitlio/features/sync/data/sync_coordinator.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/ui/join_view_model.dart'
    show JoinProblemConnect;
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A member row: the member and whether expenses or settlements refer to
/// them (then they cannot be removed).
final class MemberItem {
  const MemberItem({
    required this.member,
    required this.inUse,
    this.connected = false,
    this.isMe = false,
    this.canDisconnect = false,
    this.canClaim = false,
  });

  final GroupMember member;
  final bool inUse;

  /// Shared group only: an account is connected to this person ("verbunden").
  /// False at once while a disconnect waits for its undo window.
  final bool connected;

  /// This phone's account is the connected one.
  final bool isMe;

  /// Owner only: "Verbindung trennen" is offered (never for yourself).
  final bool canDisconnect;

  /// "Das bin ich" is offered: you are in the shared group but not connected
  /// to anyone yet, and nobody is connected to this person.
  final bool canClaim;
}

/// A disconnect that failed; [text] says what happened and that nothing
/// changed (plan §2.6 #9).
final class DisconnectProblem {
  const DisconnectProblem(this.error, {this.personName});

  final RemoteError error;
  final String? personName;

  String text(AppLocalizations l10n) {
    final name = personName ?? '';
    return switch (error) {
      Offline() => l10n.memberDisconnectOffline(name),
      ServerDown() => l10n.memberDisconnectServerDown(name),
      _ =>
        '${remoteErrorText(l10n, error, personName: personName)} '
            '${l10n.memberDisconnectNothingChanged}',
    };
  }
}

class _PendingDisconnect {
  _PendingDisconnect(this.name, this.repo);

  final String name;

  /// Kept so the commit still works after the screen is gone.
  final ConnectionsRepository repo;
}

/// Calm inline message: removal was refused because [name] has entries.
final class MemberInUse {
  const MemberInUse({required this.memberId, required this.name});

  final String memberId;
  final String name;
}

sealed class GroupDetailState {
  const GroupDetailState();
}

final class GroupDetailLoading extends GroupDetailState {
  const GroupDetailLoading();
}

/// Also covers a group that does not exist (or was archived): [NotFound].
final class GroupDetailFailure extends GroupDetailState {
  const GroupDetailFailure(this.error);

  final RepositoryError error;
}

final class GroupDetailLoaded extends GroupDetailState {
  const GroupDetailLoaded({
    required this.group,
    required this.members,
    required this.hasEntries,
    this.notice,
  });

  final Group group;

  /// In position order.
  final List<MemberItem> members;

  /// Any expense or settlement exists; the currency is then locked.
  final bool hasEntries;
  final MemberInUse? notice;

  bool get canChangeCurrency => !hasEntries;
}

/// Group detail (members tab): the group, its members, and their commands.
class GroupDetailViewModel extends Notifier<GroupDetailState> {
  GroupDetailViewModel(this.groupId);

  final String groupId;

  Group? _group;
  var _groupKnown = false;
  List<GroupMember>? _members;
  Set<String>? _expenseMemberIds;
  Set<String>? _settlementMemberIds;
  MemberInUse? _notice;
  RepositoryError? _failure;
  GroupConnections _connections = GroupConnections.localOnly;

  /// Disconnects waiting for their undo window, by person.
  final _pending = <String, _PendingDisconnect>{};

  bool get _hasEntries =>
      (_expenseMemberIds?.isNotEmpty ?? false) ||
      (_settlementMemberIds?.isNotEmpty ?? false);

  @override
  GroupDetailState build() {
    _group = null;
    _groupKnown = false;
    _members = null;
    _expenseMemberIds = null;
    _settlementMemberIds = null;
    _notice = null;
    _failure = null;
    _connections = GroupConnections.localOnly;
    _pending.clear();
    final subs = [
      _listen(ref.watch(groupsRepositoryProvider).watchGroups(), (groups) {
        _group = groups.where((g) => g.id == groupId).firstOrNull;
        _groupKnown = true;
      }),
      _listen(
        ref.watch(membersRepositoryProvider).watchMembers(groupId),
        (members) => _members = members,
      ),
      _listen(
        ref.watch(expensesRepositoryProvider).watchExpenses(groupId),
        (entries) => _expenseMemberIds = {
          for (final e in entries) ...e.expense.payers.keys,
          for (final e in entries) ...e.expense.shares.keys,
        },
      ),
      _listen(ref.watch(connectionsRepositoryProvider).watch(groupId), (c) {
        _connections = c;
        // A finished disconnect is done once the person is not connected.
        _pending.removeWhere((id, _) => !c.connectedIds.contains(id));
      }),
      _listen(
        ref.watch(settlementsRepositoryProvider).watchSettlements(groupId),
        (entries) => _settlementMemberIds = {
          for (final e in entries) e.settlement.fromId,
          for (final e in entries) e.settlement.toId,
        },
      ),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    // Opening a shared group syncs it; a local-only group stays offline.
    ref.read(syncCoordinatorProvider).groupOpened(groupId);
    return const GroupDetailLoading();
  }

  /// Pull-to-refresh: push and pull a shared group now. The outcome shows in
  /// the status line; a local-only group is a no-op.
  Future<SyncStats> refresh() =>
      ref.read(syncCoordinatorProvider).syncNow(groupId, force: true);

  StreamSubscription<T> _listen<T>(Stream<T> stream, void Function(T) onData) =>
      stream.listen(
        (data) {
          onData(data);
          _emit();
        },
        onError: (Object e) {
          _failure = e is RepositoryError ? e : Storage(e);
          _emit();
        },
      );

  void _emit() {
    if (!ref.mounted) return;
    final failure = _failure;
    final members = _members;
    final expenseIds = _expenseMemberIds;
    final settlementIds = _settlementMemberIds;
    if (failure != null) {
      state = GroupDetailFailure(failure);
    } else if (!_groupKnown ||
        members == null ||
        expenseIds == null ||
        settlementIds == null) {
      state = const GroupDetailLoading();
    } else if (_group == null) {
      state = GroupDetailFailure(NotFound('group', groupId));
    } else {
      state = GroupDetailLoaded(
        group: _group!,
        members: [
          for (final m in members) _item(m, expenseIds, settlementIds),
        ],
        hasEntries: _hasEntries,
        notice: _notice,
      );
    }
  }

  MemberItem _item(
    GroupMember m,
    Set<String> expenseIds,
    Set<String> settlementIds,
  ) {
    final c = _connections;
    final connected =
        c.shared &&
        c.connectedIds.contains(m.id) &&
        !_pending.containsKey(m.id);
    final isMe = c.shared && c.myMemberId == m.id;
    return MemberItem(
      member: m,
      inUse: expenseIds.contains(m.id) || settlementIds.contains(m.id),
      connected: connected,
      isMe: isMe,
      canDisconnect: connected && c.isOwner && !isMe,
      canClaim: c.canClaimSelf && !c.connectedIds.contains(m.id),
    );
  }

  void retry() {
    state = const GroupDetailLoading();
    ref.invalidateSelf();
  }

  void dismissNotice() {
    _notice = null;
    _emit();
  }

  /// Appends a member. The name is trimmed and must not be empty.
  Future<RepoResult<GroupMember>> addMember(String name) async {
    if (name.trim().isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    if (_nameTaken(name)) return const Err(Conflict('name already in group'));
    return _clearNotice(
      await ref.read(membersRepositoryProvider).add(groupId, name: name),
    );
  }

  /// Whether another member already has [name] (trimmed, case-insensitive).
  bool _nameTaken(String name, {String? exceptId}) {
    final wanted = name.trim().toLowerCase();
    return (_members ?? const <GroupMember>[]).any(
      (m) => m.id != exceptId && m.name.trim().toLowerCase() == wanted,
    );
  }

  Future<RepoResult<GroupMember>> renameMember(String id, String name) async {
    if (name.trim().isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    final current = _members?.where((m) => m.id == id).firstOrNull;
    if (current == null) return Err(NotFound('member', id));
    if (_nameTaken(name, exceptId: id)) {
      return const Err(Conflict('name already in group'));
    }
    return _clearNotice(
      await ref
          .read(membersRepositoryProvider)
          .update(
            id,
            name: name,
            paypalMe: current.paypalMe,
            ibanHint: current.ibanHint,
          ),
    );
  }

  /// Moves the member at [oldIndex] to [newIndex], the position it ends up at
  /// (`ReorderableListView.onReorderItem` semantics). The list updates at
  /// once and rolls back if the repository refuses.
  Future<RepoResult<void>> reorder(int oldIndex, int newIndex) async {
    final before = _members;
    if (before == null ||
        oldIndex < 0 ||
        oldIndex >= before.length ||
        newIndex < 0 ||
        newIndex >= before.length) {
      return const Err(InvalidData('index out of range'));
    }
    if (newIndex == oldIndex) return const Ok(null);
    final after = [...before];
    after.insert(newIndex, after.removeAt(oldIndex));
    _members = after;
    _emit();
    final result = await ref.read(membersRepositoryProvider).reorder(groupId, [
      for (final m in after) m.id,
    ]);
    if (result is Err) {
      _members = before;
      _emit();
    }
    return result;
  }

  /// Soft delete unless entries refer to the member; then nothing changes and
  /// `notice` explains why (`Err(Conflict)`).
  Future<RepoResult<Undo>> removeMember(String id) async {
    final loaded = state;
    final item = loaded is GroupDetailLoaded
        ? loaded.members.where((m) => m.member.id == id).firstOrNull
        : null;
    if (item == null) return Err(NotFound('member', id));
    if (item.inUse) {
      _notice = MemberInUse(memberId: id, name: item.member.name);
      _emit();
      return const Err(Conflict('member has expenses or settlements'));
    }
    return _clearNotice(
      await ref.read(membersRepositoryProvider).softDelete(id),
    );
  }

  /// Owner: starts "Verbindung trennen". The person shows as not connected
  /// at once; nothing is sent until [commitDisconnect]. Returns the person's
  /// name for the snack bar, or null when this is not allowed (not the
  /// owner, not connected, yourself). [undoDisconnect] takes it back.
  String? beginDisconnect(String memberId) {
    final loaded = state;
    final item = loaded is GroupDetailLoaded
        ? loaded.members.where((m) => m.member.id == memberId).firstOrNull
        : null;
    if (item == null || !item.canDisconnect) return null;
    _pending[memberId] = _PendingDisconnect(
      item.member.name,
      ref.read(connectionsRepositoryProvider),
    );
    _emit();
    return item.member.name;
  }

  /// "Rückgängig": no call was made, the badge is back.
  void undoDisconnect(String memberId) {
    if (_pending.remove(memberId) != null) _emit();
  }

  /// The undo window closed without undo: ends the connection on the server.
  /// Null: done. A problem brings the badge back; nothing changed. Works
  /// after the screen is closed (the repository is kept by
  /// `beginDisconnect`).
  Future<DisconnectProblem?> commitDisconnect(String memberId) async {
    final p = _pending[memberId];
    if (p == null) return null;
    return _disconnect(p.repo, memberId, p.name);
  }

  /// The same command without the undo window (DebugDrive, scripts).
  Future<DisconnectProblem?> disconnectNow(String memberId) {
    final name = _members?.where((m) => m.id == memberId).firstOrNull?.name;
    return _disconnect(
      ref.read(connectionsRepositoryProvider),
      memberId,
      name,
    );
  }

  Future<DisconnectProblem?> _disconnect(
    ConnectionsRepository repo,
    String memberId,
    String? name,
  ) async {
    final result = await repo.disconnect(groupId, memberId);
    switch (result) {
      case Ok():
        // The pending mark goes when the connections stream shows the
        // person as not connected, so the badge does not flash back.
        return null;
      case Err(:final error):
        _pending.remove(memberId);
        _emit();
        return DisconnectProblem(error, personName: name);
    }
  }

  /// "Das bin ich": connects this account to [memberId] with the same
  /// command and the same error texts as the join flow. Null: connected (or
  /// not offered).
  Future<JoinProblemConnect?> connectMe(String memberId) async {
    final loaded = state;
    final item = loaded is GroupDetailLoaded
        ? loaded.members.where((m) => m.member.id == memberId).firstOrNull
        : null;
    if (item == null || !item.canClaim) return null;
    final repo = ref.read(connectionsRepositoryProvider);
    final result = await repo.connectMe(groupId, memberId);
    switch (result) {
      case Ok():
        return null;
      case Err(:final error):
        var name = item.member.name;
        if (error is MemberAlreadyClaimed ||
            error is MemberGone ||
            error is AlreadyConnected) {
          // The list was stale: pull so it shows what the server says.
          final mine = await repo.refresh(groupId);
          if (error is AlreadyConnected) name = mine ?? '';
        }
        return JoinProblemConnect(
          error,
          personName: name.isEmpty ? null : name,
        );
    }
  }

  /// Renames and/or changes the currency. The currency is locked once the
  /// group has expenses or settlements (`Err(Conflict)`).
  Future<RepoResult<Group>> updateGroup({
    required String name,
    required Currency currency,
  }) async {
    final group = _group;
    if (name.trim().isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    if (group == null) return Err(NotFound('group', groupId));
    if (currency != group.currency && _hasEntries) {
      return const Err(Conflict('currency is locked once entries exist'));
    }
    return _clearNotice(
      await ref
          .read(groupsRepositoryProvider)
          .update(groupId, name: name, currency: currency),
    );
  }

  /// Soft delete; the returned [Undo] brings the group back.
  Future<RepoResult<Undo>> archive() =>
      ref.read(groupsRepositoryProvider).softDelete(groupId);

  RepoResult<T> _clearNotice<T>(RepoResult<T> result) {
    if (result is Ok && _notice != null) {
      _notice = null;
      _emit();
    }
    return result;
  }

  JsonMap debugSnapshot() => switch (state) {
    GroupDetailLoading() => {'status': 'loading', 'groupId': groupId},
    GroupDetailFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    GroupDetailLoaded(
      :final group,
      :final members,
      :final hasEntries,
      :final notice,
    ) =>
      {
        'status': members.isEmpty ? 'empty' : 'data',
        'groupId': group.id,
        'name': group.name,
        'currency': group.currency.code,
        'hasEntries': hasEntries,
        'members': [
          for (final m in members)
            {
              'id': m.member.id,
              'name': m.member.name,
              'position': m.member.position,
              'inUse': m.inUse,
              if (_connections.shared) ...{
                'connected': m.connected,
                'isMe': m.isMe,
                'canDisconnect': m.canDisconnect,
                'canClaim': m.canClaim,
              },
            },
        ],
        'notice': notice == null ? null : {'memberInUse': notice.name},
      },
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final groupDetailViewModelProvider =
    NotifierProvider.family<GroupDetailViewModel, GroupDetailState, String>(
      GroupDetailViewModel.new,
    );
