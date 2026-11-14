import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/ui/group_detail_view.dart';
import 'package:mitlio/features/groups/ui/group_form_view.dart';
import 'package:mitlio/features/groups/ui/groups_view.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';

import '../../../helpers/a11y.dart';
import 'groups_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  group('groups list', () {
    forEachMode(
      'empty',
      () => scoped(
        groupsStateOverride(const GroupsLoaded([])),
        const GroupsView(),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
    forEachMode(
      'data',
      () => scoped(
        groupsStateOverride(GroupsLoaded(sampleGroups)),
        const GroupsView(),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
    forEachMode(
      'error',
      () => scoped(
        groupsStateOverride(const GroupsFailure(Storage('x'))),
        const GroupsView(),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  });

  group('group detail', () {
    GroupDetailView view() => const GroupDetailView(groupId: 'g-1');
    forEachMode(
      'members',
      () => scoped(detailStateOverride(sampleDetail), view()),
      (tester, _, _) => expectAccessible(tester),
    );
    forEachMode(
      'members with notice',
      () => scoped(detailStateOverride(sampleDetailWithNotice), view()),
      (tester, _, _) => expectAccessible(tester),
    );
    forEachMode(
      'no members yet',
      () => scoped(detailStateOverride(emptyDetail), view()),
      (tester, _, _) => expectAccessible(tester),
    );
  });

  group('group form', () {
    forEachMode(
      'create',
      () => scoped(const [], const GroupFormView()),
      (tester, _, _) => expectAccessible(tester),
    );
    forEachMode(
      'edit with locked currency',
      () => scoped(
        detailStateOverride(sampleDetail),
        const GroupFormView(groupId: 'g-1'),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  });
}
