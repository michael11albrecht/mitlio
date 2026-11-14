import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/expenses/ui/expenses_view.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Number of tabs of the group detail (members, expenses).
const groupTabCount = 2;

enum _MenuAction { edit, archive }

/// Group detail: tabs for the members and the expenses. Members tab: add by
/// name (the field stays focused for the next one), tap a name to rename, drag
/// to reorder, remove with undo.
class GroupDetailView extends ConsumerWidget {
  const GroupDetailView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(groupDetailViewModelProvider(groupId).notifier);
    return switch (ref.watch(groupDetailViewModelProvider(groupId))) {
      GroupDetailLoading() => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      GroupDetailFailure() => Scaffold(
        appBar: AppBar(),
        body: ErrorState(onRetry: vm.retry),
      ),
      GroupDetailLoaded(
        :final group,
        :final members,
        :final notice,
      ) =>
        DefaultTabController(
          length: groupTabCount,
          child: Scaffold(
            appBar: AppBar(
              title: Text(group.name),
              actions: [
                IconButton(
                  tooltip: l10n.tripAdd,
                  icon: const Icon(Icons.directions_car_outlined),
                  onPressed: () =>
                      unawaited(context.push('/groups/$groupId/trip')),
                ),
                IconButton(
                  tooltip: l10n.balancesOpen,
                  icon: const Icon(Icons.balance_outlined),
                  onPressed: () =>
                      unawaited(context.push('/groups/$groupId/balances')),
                ),
                PopupMenuButton<_MenuAction>(
                  tooltip: l10n.groupMenu,
                  onSelected: (action) async {
                    switch (action) {
                      case _MenuAction.edit:
                        unawaited(context.push('/groups/$groupId/edit'));
                      case _MenuAction.archive:
                        final result = await vm.archive();
                        if (!context.mounted) return;
                        if (result case Ok(:final value)) {
                          showUndoSnackBar(
                            context,
                            message: l10n.groupArchived(group.name),
                            undo: value,
                          );
                          context.go('/');
                        }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _MenuAction.edit,
                      child: Text(l10n.groupEditTitle),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.archive,
                      child: Text(l10n.groupArchive),
                    ),
                  ],
                ),
              ],
              // One entry per tab; keep in step with `groupTabCount` and the
              // children of the TabBarView below.
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.tabMembers),
                  Tab(text: l10n.tabExpenses),
                ],
              ),
            ),
            // Swipes belong to the rows (swipe to delete); tabs switch by tap.
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Column(
                  children: [
                    Expanded(
                      child: members.isEmpty
                          ? EmptyState(
                              icon: Icons.person_add_alt_outlined,
                              title: l10n.membersEmptyTitle,
                              message: l10n.membersEmptyMessage,
                            )
                          : ReorderableListView.builder(
                              padding: Spacing.screen,
                              buildDefaultDragHandles: false,
                              itemCount: members.length,
                              onReorderItem: (from, to) => unawaited(
                                vm.reorder(from, to),
                              ),
                              header: notice == null
                                  ? null
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: Spacing.sm,
                                      ),
                                      child: _InlineNotice(
                                        message: l10n.memberInUse(notice.name),
                                        onDismiss: vm.dismissNotice,
                                      ),
                                    ),
                              footer: members.length < 2
                                  ? null
                                  : Padding(
                                      padding: Spacing.allSm,
                                      child: Text(
                                        l10n.memberOrderHint,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                              itemBuilder: (context, index) {
                                final item = members[index];
                                return _MemberTile(
                                  key: ValueKey(item.member.id),
                                  item: item,
                                  index: index,
                                  onRename: (name) => unawaited(
                                    vm.renameMember(item.member.id, name),
                                  ),
                                  onRemove: () async {
                                    final result = await vm.removeMember(
                                      item.member.id,
                                    );
                                    if (!context.mounted) return;
                                    if (result case Ok(:final value)) {
                                      showUndoSnackBar(
                                        context,
                                        message: l10n.memberRemoved(
                                          item.member.name,
                                        ),
                                        undo: value,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                    _AddMemberField(
                      autofocus: members.isEmpty,
                      onAdd: vm.addMember,
                    ),
                  ],
                ),
                ExpensesView(groupId: groupId),
              ],
            ),
          ),
        ),
    };
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: Radii.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: Spacing.md),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
              IconButton(
                tooltip: AppLocalizations.of(context).dismiss,
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatefulWidget {
  const _MemberTile({
    required this.item,
    required this.index,
    required this.onRename,
    required this.onRemove,
    super.key,
  });

  final MemberItem item;
  final int index;
  final ValueChanged<String> onRename;
  final VoidCallback onRemove;

  @override
  State<_MemberTile> createState() => _MemberTileState();
}

class _MemberTileState extends State<_MemberTile> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    _controller.text = widget.item.member.name;
    setState(() => _editing = true);
  }

  /// Saves a changed, non-empty name; anything else keeps the old one.
  void _commit() {
    final name = _controller.text.trim();
    setState(() => _editing = false);
    if (name.isNotEmpty && name != widget.item.member.name) {
      widget.onRename(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final member = widget.item.member;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: Spacing.md),
          child: Row(
            children: [
              MemberAvatar(memberId: member.id, name: member.name),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _editing
                    ? TextField(
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _commit(),
                        decoration: InputDecoration(
                          labelText: l10n.memberNameLabel,
                        ),
                      )
                    : InkWell(
                        onTap: _startEditing,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: Sizes.tapTarget,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(member.name),
                          ),
                        ),
                      ),
              ),
              IconButton(
                tooltip: l10n.memberRemove(member.name),
                icon: const Icon(Icons.close),
                onPressed: widget.onRemove,
              ),
              ExcludeSemantics(
                child: ReorderableDragStartListener(
                  index: widget.index,
                  child: const SizedBox.square(
                    dimension: Sizes.tapTarget,
                    child: Icon(Icons.drag_indicator),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Persistent "add a name" row at the thumb: submit adds the member and keeps
/// the field focused for the next name.
class _AddMemberField extends StatefulWidget {
  const _AddMemberField({required this.onAdd, required this.autofocus});

  final Future<RepoResult<Object>> Function(String name) onAdd;
  final bool autofocus;

  @override
  State<_AddMemberField> createState() => _AddMemberFieldState();
}

class _AddMemberFieldState extends State<_AddMemberField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final result = await widget.onAdd(_controller.text);
    if (result is Ok) _controller.clear();
    if (mounted) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: Spacing.screen,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => unawaited(_add()),
                decoration: InputDecoration(labelText: l10n.memberAddLabel),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            IconButton.filled(
              tooltip: l10n.memberAdd,
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(_add()),
            ),
          ],
        ),
      ),
    );
  }
}
