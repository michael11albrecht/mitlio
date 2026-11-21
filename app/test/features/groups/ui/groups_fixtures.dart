import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/sync/data/repositories/fake_connections_repository.dart';
import 'package:mitlio/features/sync/data/sync_coordinator.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/entry_card_stub.dart';

/// Fixed states for goldens and a11y tests: the ViewModels are replaced by
/// stubs that never touch a repository.
class StubGroupsViewModel extends GroupsViewModel {
  StubGroupsViewModel(this.fixed);

  final GroupsState fixed;

  @override
  GroupsState build() => fixed;
}

class StubArchivedGroupsViewModel extends ArchivedGroupsViewModel {
  StubArchivedGroupsViewModel(this.fixed);

  final GroupsState fixed;

  @override
  GroupsState build() => fixed;
}

List<Override> archivedStateOverride(GroupsState state) => [
  archivedGroupsViewModelProvider.overrideWith(
    () => StubArchivedGroupsViewModel(state),
  ),
];

class StubGroupDetailViewModel extends GroupDetailViewModel {
  StubGroupDetailViewModel(super.groupId, this.fixed);

  final GroupDetailState fixed;

  @override
  GroupDetailState build() => fixed;
}

List<Override> groupsStateOverride(GroupsState state) => [
  groupsViewModelProvider.overrideWith(() => StubGroupsViewModel(state)),
];

List<Override> detailStateOverride(GroupDetailState state) => [
  groupDetailViewModelProvider.overrideWith2(
    (id) => StubGroupDetailViewModel(id, state),
  ),
];

/// Without a database: nothing is shared, so no status line and no sync.
Widget scoped(List<Override> overrides, Widget child) => ProviderScope(
  overrides: [
    syncCoordinatorProvider.overrideWithValue(const NoSyncCoordinator()),
    connectionsRepositoryProvider.overrideWithValue(
      FakeConnectionsRepository(),
    ),
    ...noEntryCards,
    ...overrides,
  ],
  child: child,
);

final sampleGroups = [
  Group(
    id: 'g-1',
    name: 'Wochenende in den Bergen',
    currency: Currency.eur,
    createdBy: 'local',
    createdAt: DateTime.utc(2026),
  ),
  Group(
    id: 'g-2',
    name: 'WG',
    currency: Currency.chf,
    createdBy: 'local',
    createdAt: DateTime.utc(2026, 1, 2),
  ),
];

const _names = ['Anna Berg', 'Ben', 'Chiara Rossi', 'Dino Kovač'];

final sampleDetail = GroupDetailLoaded(
  group: sampleGroups.first,
  hasEntries: true,
  members: [
    for (var i = 0; i < _names.length; i++)
      MemberItem(
        member: GroupMember(
          id: 'm-$i',
          groupId: 'g-1',
          name: _names[i],
          position: i,
        ),
        inUse: i < 2,
      ),
  ],
);

final sampleDetailWithNotice = GroupDetailLoaded(
  group: sampleDetail.group,
  hasEntries: true,
  members: sampleDetail.members,
  notice: const MemberInUse(memberId: 'm-0', name: 'Anna Berg'),
);

/// A shared group, seen by its owner: Anna is the owner's own person, Ben has
/// a phone the owner can disconnect.
final sampleDetailOwner = GroupDetailLoaded(
  group: sampleGroups.first,
  hasEntries: true,
  members: [
    for (var i = 0; i < _names.length; i++)
      MemberItem(
        member: sampleDetail.members[i].member,
        inUse: i < 2,
        connected: i < 2,
        isMe: i == 0,
        canDisconnect: i == 1,
      ),
  ],
);

/// A shared group, seen by a member not connected to anyone yet.
final sampleDetailClaim = GroupDetailLoaded(
  group: sampleGroups.first,
  hasEntries: true,
  members: [
    for (var i = 0; i < _names.length; i++)
      MemberItem(
        member: sampleDetail.members[i].member,
        inUse: i < 2,
        connected: i == 1,
        canClaim: i != 1,
      ),
  ],
);

final emptyDetail = GroupDetailLoaded(
  group: sampleGroups.first,
  hasEntries: false,
  members: const [],
);
