import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/keyboard.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/expenses/ui/expenses_view.dart';
import 'package:mitlio/features/export/ui/export_sheet.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/members/ui/member_payment_view.dart';
import 'package:mitlio/features/rides/ui/rides_view.dart';
import 'package:mitlio/features/sync/ui/share_sheet.dart';
import 'package:mitlio/features/sync/ui/share_view_model.dart'
    show shareAvailableProvider;
import 'package:mitlio/features/sync/ui/sync_status_line.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Number of tabs of the group detail (members, expenses, rides).
const groupTabCount = 3;

enum _MenuAction { edit, statistics, notifications, export, archive }

/// Group detail: tabs for the members and the expenses. Members tab: add by
/// name (the field stays focused for the next one), tap a name to rename, drag
/// to reorder, remove with undo.
class GroupDetailView extends ConsumerWidget {
  const GroupDetailView({required this.groupId, this.initialTab, super.key});

  final String groupId;

  /// `rides` or `expenses` opens that tab first (deep link, home shortcut);
  /// anything else opens the members tab.
  final String? initialTab;

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
          initialIndex: switch (initialTab) {
            'expenses' => 1,
            'rides' => 2,
            _ => 0,
          },
          child: DismissKeyboardOnTabChange(
            child: Scaffold(
              appBar: AppBar(
                title: Text(group.name),
                actions: [
                  // One tap to the link and QR; not offered without a backend.
                  if (ref.watch(shareAvailableProvider))
                    IconButton(
                      tooltip: l10n.shareMenu,
                      icon: const Icon(Icons.group_add_outlined),
                      onPressed: () =>
                          unawaited(showShareSheet(context, groupId)),
                    ),
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
                        case _MenuAction.statistics:
                          unawaited(
                            context.push('/groups/$groupId/statistics'),
                          );
                        case _MenuAction.notifications:
                          unawaited(
                            context.push('/groups/$groupId/notifications'),
                          );
                        case _MenuAction.export:
                          unawaited(showExportSheet(context, groupId));
                        case _MenuAction.archive:
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await vm.archive();
                          if (!context.mounted) return;
                          switch (result) {
                            case Ok(:final value):
                              showUndoSnackBar(
                                context,
                                message: l10n.groupArchived(group.name),
                                undo: value,
                              );
                              context.go('/');
                            case Err(:final error):
                              showErrorSnackBar(messenger, l10n, error);
                          }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _MenuAction.edit,
                        child: Text(l10n.groupEditTitle),
                      ),
                      PopupMenuItem(
                        value: _MenuAction.statistics,
                        child: Text(l10n.statsMenu),
                      ),
                      // Notifications need a backend, like sharing.
                      if (ref.watch(shareAvailableProvider))
                        PopupMenuItem(
                          value: _MenuAction.notifications,
                          child: Text(l10n.notifSettingsTitle),
                        ),
                      PopupMenuItem(
                        value: _MenuAction.export,
                        child: Text(l10n.exportMenu),
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
                    Tab(text: l10n.tabRides),
                  ],
                ),
              ),
              // Swipes belong to the rows (swipe to delete); tabs switch by
              // tap.
              body: Column(
                children: [
                  SyncStatusLine(groupId: groupId),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _MembersTab(
                          groupId: groupId,
                          members: members,
                          notice: notice,
                          vm: vm,
                        ),
                        ExpensesView(groupId: groupId),
                        RidesView(groupId: groupId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    };
  }
}

/// The members tab: list (pull to refresh), notice and the add field.
class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.groupId,
    required this.members,
    required this.notice,
    required this.vm,
  });

  final String groupId;
  final List<MemberItem> members;
  final MemberInUse? notice;
  final GroupDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notice = this.notice;
    return Column(
      children: [
        Expanded(
          child: members.isEmpty
              ? EmptyState(
                  icon: Icons.person_add_alt_outlined,
                  title: l10n.membersEmptyTitle,
                  message: l10n.membersEmptyMessage,
                )
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ReorderableListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: Spacing.screen,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    buildDefaultDragHandles: false,
                    itemCount: members.length,
                    onReorderItem: (from, to) async {
                      final messenger = ScaffoldMessenger.of(
                        context,
                      );
                      final result = await vm.reorder(
                        from,
                        to,
                      );
                      if (result case Err(:final error)) {
                        showErrorSnackBar(
                          messenger,
                          l10n,
                          error,
                        );
                      }
                    },
                    header: notice == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(
                              bottom: Spacing.sm,
                            ),
                            child: _InlineNotice(
                              message: l10n.memberInUse(
                                notice.name,
                              ),
                              onDismiss: vm.dismissNotice,
                            ),
                          ),
                    footer: members.length < 2
                        ? null
                        : Padding(
                            padding: Spacing.allSm,
                            child: Text(
                              l10n.memberOrderHint,
                              style: Theme.of(context).textTheme.bodySmall
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
                        onRename: (name) async {
                          final messenger = ScaffoldMessenger.of(
                            context,
                          );
                          final result = await vm.renameMember(
                            item.member.id,
                            name,
                          );
                          if (result case Err(
                            error: Conflict(),
                          )) {
                            _showText(
                              messenger,
                              l10n.memberNameTaken(name.trim()),
                            );
                          } else if (result case Err(
                            :final error,
                          )) {
                            showErrorSnackBar(
                              messenger,
                              l10n,
                              error,
                            );
                          }
                        },
                        onDisconnect: () {
                          // Nothing is sent until the bar closes without
                          // undo; the app-level messenger keeps the bar (and
                          // the commit) alive when the screen is left.
                          final messenger = ScaffoldMessenger.of(context);
                          final id = item.member.id;
                          final name = vm.beginDisconnect(id);
                          if (name == null) return;
                          showDeferredUndoSnackBar(
                            context,
                            message: l10n.memberDisconnected(name),
                            onUndo: () => vm.undoDisconnect(id),
                            onCommit: () async {
                              final problem = await vm.commitDisconnect(id);
                              if (problem != null) {
                                _showText(messenger, problem.text(l10n));
                              }
                            },
                          );
                        },
                        onClaim: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final problem = await vm.connectMe(item.member.id);
                          if (problem != null) {
                            _showText(messenger, problem.text(l10n));
                          }
                        },
                        onRemove: () async {
                          final messenger = ScaffoldMessenger.of(
                            context,
                          );
                          final result = await vm.removeMember(
                            item.member.id,
                          );
                          if (!context.mounted) return;
                          switch (result) {
                            case Ok(:final value):
                              showUndoSnackBar(
                                context,
                                message: l10n.memberRemoved(
                                  item.member.name,
                                ),
                                undo: value,
                              );
                            // "In use" is explained by the inline
                            // notice above the list.
                            case Err(error: Conflict()):
                              break;
                            case Err(:final error):
                              showErrorSnackBar(
                                messenger,
                                l10n,
                                error,
                              );
                          }
                        },
                      );
                    },
                  ),
                ),
        ),
        _AddMemberField(
          autofocus: members.isEmpty,
          onAdd: vm.addMember,
        ),
      ],
    );
  }
}

void _showText(ScaffoldMessengerState messenger, String text) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
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
    required this.onDisconnect,
    required this.onClaim,
    super.key,
  });

  final MemberItem item;
  final int index;
  final ValueChanged<String> onRename;
  final VoidCallback onRemove;
  final VoidCallback onDisconnect;
  final VoidCallback onClaim;

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
    // `autofocus` is ignored while another field (the add field) has focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_editing) return;
      _focus.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
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
    final item = widget.item;
    final member = item.member;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(memberId: member.id, name: member.name),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _editing
                        ? TextField(
                            controller: _controller,
                            focusNode: _focus,
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
                    tooltip: l10n.paymentOpen(member.name),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    onPressed: () => unawaited(
                      showMemberPaymentSheet(
                        context,
                        memberId: member.id,
                        memberName: member.name,
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
              if (item.connected || item.canDisconnect || item.canClaim)
                Padding(
                  padding: const EdgeInsets.only(
                    left: Sizes.avatar + Spacing.md,
                    bottom: Spacing.sm,
                  ),
                  child: _ConnectionRow(
                    item: item,
                    onDisconnect: widget.onDisconnect,
                    onClaim: widget.onClaim,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared groups only: the "verbunden" badge, and the owner's "Verbindung
/// trennen" or the "Das bin ich" of a member not connected to anyone yet.
class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({
    required this.item,
    required this.onDisconnect,
    required this.onClaim,
  });

  final MemberItem item;
  final VoidCallback onDisconnect;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = item.member.name;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.sm,
      children: [
        if (item.connected)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.link,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                l10n.joinConnected,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        if (item.canDisconnect)
          Semantics(
            label: l10n.memberDisconnectFor(name),
            excludeSemantics: true,
            button: true,
            child: TextButton(
              onPressed: onDisconnect,
              child: Text(l10n.memberDisconnect),
            ),
          ),
        if (item.canClaim)
          Semantics(
            label: l10n.memberThatsMeFor(name),
            excludeSemantics: true,
            button: true,
            child: TextButton(
              onPressed: onClaim,
              child: Text(l10n.memberThatsMe),
            ),
          ),
      ],
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
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final name = _controller.text;
    final result = await widget.onAdd(name);
    switch (result) {
      case Ok():
        _controller.clear();
      // An empty name is a no-op: the field simply stays focused.
      case Err(error: InvalidData()):
        break;
      case Err(error: Conflict()):
        _showText(messenger, l10n.memberNameTaken(name.trim()));
      case Err(:final error):
        showErrorSnackBar(messenger, l10n, error);
    }
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
