import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Create a group (name, currency, EUR preselected) or, with [groupId],
/// edit its name and currency. Creating continues straight into the new
/// group so its people can be added.
class GroupFormView extends ConsumerStatefulWidget {
  const GroupFormView({this.groupId, super.key});

  final String? groupId;

  @override
  ConsumerState<GroupFormView> createState() => _GroupFormViewState();
}

class _GroupFormViewState extends ConsumerState<GroupFormView> {
  final _name = TextEditingController();
  Currency _currency = Currency.eur;
  String? _nameError;
  var _busy = false;

  bool get _editing => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.groupId;
    if (id == null) return;
    // Fill the fields once with the stored values; later edits are the user's.
    final provider = groupDetailViewModelProvider(id);
    _fill(ref.read(provider));
    ref.listenManual(provider, (_, next) => setState(() => _fill(next)));
  }

  void _fill(GroupDetailState state) {
    if (state is GroupDetailLoaded && _name.text.isEmpty) {
      _name.text = state.group.name;
      _currency = state.group.currency;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = widget.groupId;
    setState(() => _busy = true);
    final result = id == null
        ? await ref
              .read(groupsViewModelProvider.notifier)
              .create(name: _name.text, currency: _currency)
        : await ref
              .read(groupDetailViewModelProvider(id).notifier)
              .updateGroup(name: _name.text, currency: _currency);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        if (id == null) {
          context.pushReplacement('/groups/${value.id}');
        } else {
          context.pop();
        }
      case Err(error: InvalidData()):
        setState(
          () => _nameError = AppLocalizations.of(context).groupNameRequired,
        );
      case Err():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorTitle)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final id = widget.groupId;
    final locked =
        id != null &&
        switch (ref.watch(groupDetailViewModelProvider(id))) {
          GroupDetailLoaded(:final canChangeCurrency) => !canChangeCurrency,
          _ => false,
        };
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l10n.groupEditTitle : l10n.groupNew),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: Spacing.screen,
              children: [
                TextField(
                  controller: _name,
                  autofocus: !_editing,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                  onSubmitted: (_) => unawaited(_submit()),
                  decoration: InputDecoration(
                    labelText: l10n.groupNameLabel,
                    hintText: l10n.groupNameHint,
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                DropdownButtonFormField<Currency>(
                  key: ValueKey(_currency),
                  initialValue: _currency,
                  decoration: InputDecoration(
                    labelText: l10n.groupCurrencyLabel,
                  ),
                  items: [
                    for (final c in Currency.all)
                      DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.code == l10n.currencyName(c.code)
                              ? c.code
                              : '${c.code} · ${l10n.currencyName(c.code)}',
                        ),
                      ),
                  ],
                  onChanged: locked
                      ? null
                      : (c) => setState(() => _currency = c ?? _currency),
                ),
                if (locked) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.groupCurrencyLocked,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: Spacing.screen,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : () => unawaited(_submit()),
                  child: Text(_editing ? l10n.groupSave : l10n.groupCreate),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
