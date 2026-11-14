import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Fixed states for goldens and a11y tests: the ViewModels are replaced by
/// stubs that never touch a repository.
class StubGroupsViewModel extends GroupsViewModel {
  StubGroupsViewModel(this.fixed);

  final GroupsState fixed;

  @override
  GroupsState build() => fixed;
}

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

Widget scoped(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: child);

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

final emptyDetail = GroupDetailLoaded(
  group: sampleGroups.first,
  hasEntries: false,
  members: const [],
);
