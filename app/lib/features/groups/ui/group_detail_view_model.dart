import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_snapshots.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A member row: the member and whether expenses or settlements refer to
/// them (then they cannot be removed).
final class MemberItem {
  const MemberItem({required this.member, required this.inUse});

  final GroupMember member;
  final bool inUse;
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

  String get _screen => 'group';

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
    final registry = ref.watch(debugSnapshotRegistryProvider)
      ..register(_screen, debugSnapshot);
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
      registry.unregister(_screen);
    });
    return const GroupDetailLoading();
  }

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
          for (final m in members)
            MemberItem(
              member: m,
              inUse: expenseIds.contains(m.id) || settlementIds.contains(m.id),
            ),
        ],
        hasEntries: _hasEntries,
        notice: _notice,
      );
    }
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
    return _clearNotice(
      await ref.read(membersRepositoryProvider).add(groupId, name: name),
    );
  }

  Future<RepoResult<GroupMember>> renameMember(String id, String name) async {
    if (name.trim().isEmpty) {
      return const Err(InvalidData('name must not be empty'));
    }
    final current = _members?.where((m) => m.id == id).firstOrNull;
    if (current == null) return Err(NotFound('member', id));
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

  DriveResult debugSnapshot() => switch (state) {
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
