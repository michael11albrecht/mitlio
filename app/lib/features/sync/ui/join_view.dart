import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/features/sync/ui/join_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Opening an invite link: joins the group, then asks once "Wer bist du?".
/// Route `/join/:token`; deep links (#166) and DebugDrive open it.
class JoinView extends ConsumerStatefulWidget {
  const JoinView({required this.token, super.key});

  final String token;

  @override
  ConsumerState<JoinView> createState() => _JoinViewState();
}

class _JoinViewState extends ConsumerState<JoinView> {
  @override
  void initState() {
    super.initState();
    // Not during build: the command changes provider state.
    unawaited(
      Future.microtask(
        () => ref.read(joinViewModelProvider(widget.token).notifier).start(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = joinViewModelProvider(widget.token);
    ref.listen(provider, (_, next) {
      if (next is JoinDone) context.go('/groups/${next.groupId}');
    });
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Spacing.screen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Sizes.contentMaxWidth,
              ),
              child: switch (state) {
                JoinJoining() || JoinDone() => _Joining(text: l10n.joinJoining),
                final JoinChoosePerson s => JoinPicker(state: s, vm: vm),
                final JoinFailed s => _Failed(state: s, vm: vm),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Joining extends StatelessWidget {
  const _Joining({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: Spacing.allLg,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: Spacing.md),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.state, required this.vm});

  final JoinFailed state;
  final JoinViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupId = state.groupId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(liveRegion: true, child: Text(state.problem.text(l10n))),
        const SizedBox(height: Spacing.md),
        if (groupId != null)
          FilledButton(
            onPressed: () => context.go('/groups/$groupId'),
            child: Text(l10n.joinOpenGroup),
          )
        else ...[
          if (state.problem.canRetry)
            FilledButton(
              onPressed: () => unawaited(vm.start()),
              child: Text(l10n.retry),
            ),
          TextButton(
            onPressed: () => context.go('/'),
            child: Text(l10n.joinClose),
          ),
        ],
      ],
    );
  }
}

/// "Wer bist du?": tap your name and you are in (one tap), or say you are new.
class JoinPicker extends StatefulWidget {
  const JoinPicker({required this.state, required this.vm, super.key});

  final JoinChoosePerson state;
  final JoinViewModel vm;

  @override
  State<JoinPicker> createState() => _JoinPickerState();
}

class _JoinPickerState extends State<JoinPicker> {
  final _name = TextEditingController();
  var _creating = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = widget.state;
    final notice = s.notice;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.groupName, style: theme.textTheme.titleLarge),
        const SizedBox(height: Spacing.sm),
        if (notice != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              notice.text(l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
        ],
        for (final person in s.people)
          ListTile(
            key: ValueKey(person.id),
            enabled: !person.connected && !s.busy,
            leading: MemberAvatar(memberId: person.id, name: person.name),
            title: Text(person.name),
            trailing: person.connected ? Text(l10n.joinConnected) : null,
            onTap: () => unawaited(widget.vm.choose(person.id)),
          ),
        if (_creating) ...[
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: _name,
            enabled: !s.busy,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l10n.joinNameLabel),
            onSubmitted: (v) => unawaited(widget.vm.createPerson(v)),
          ),
          const SizedBox(height: Spacing.sm),
          FilledButton(
            onPressed: s.busy
                ? null
                : () => unawaited(widget.vm.createPerson(_name.text)),
            child: Text(s.busy ? l10n.joinConnecting : l10n.joinNameConfirm),
          ),
        ] else
          ListTile(
            enabled: !s.busy,
            leading: const Icon(Icons.add),
            title: Text(l10n.joinNewHere),
            onTap: () => setState(() => _creating = true),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: s.busy ? null : widget.vm.skip,
            child: Text(l10n.joinSkip),
          ),
        ),
      ],
    );
  }
}
