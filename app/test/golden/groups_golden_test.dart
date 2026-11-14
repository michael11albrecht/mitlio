import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/ui/group_detail_view.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/groups/ui/group_form_view.dart';
import 'package:mitlio/features/groups/ui/groups_view.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';

import '../features/groups/ui/groups_fixtures.dart';
import 'golden_matrix.dart';

const _height = 640.0;
const _width = 360.0;

Widget _list(GroupsState s) =>
    scoped(groupsStateOverride(s), const GroupsView());

Widget _detail(GroupDetailState s) =>
    scoped(detailStateOverride(s), const GroupDetailView(groupId: 'g-1'));

Widget _form({GroupDetailState? stored}) => stored == null
    ? scoped(const [], const GroupFormView())
    : scoped(detailStateOverride(stored), const GroupFormView(groupId: 'g-1'));

Future<void> main() async {
  Future<void> golden(
    String name,
    Widget Function() child, {
    PumpAction pump = onlyPumpAndSettle,
  }) => matrixGolden(
    name,
    child,
    width: _width,
    height: _height,
    pumpBeforeTest: pump,
  );

  await golden(
    'groups_loading',
    () => _list(const GroupsLoading()),
    pump: pumpOnce,
  );
  await golden('groups_empty', () => _list(const GroupsLoaded([])));
  await golden(
    'groups_error',
    () => _list(const GroupsFailure(Storage('x'))),
  );
  await golden('groups_data', () => _list(GroupsLoaded(sampleGroups)));

  await golden(
    'group_detail_loading',
    () => _detail(const GroupDetailLoading()),
    pump: pumpOnce,
  );
  await golden('group_detail_empty', () => _detail(emptyDetail));
  await golden(
    'group_detail_error',
    () => _detail(const GroupDetailFailure(Storage('x'))),
  );
  await golden('group_detail_data', () => _detail(sampleDetail));
  await golden(
    'group_detail_notice',
    () => _detail(sampleDetailWithNotice),
  );

  await golden('group_form_create', _form);
  await golden(
    'group_form_edit_locked',
    () => _form(stored: sampleDetail),
  );
}
