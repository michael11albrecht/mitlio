import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/step_icon_visual.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/features/onboarding/ui/first_group_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The first group with people in three steps (PU-T12, ADR-25 §4): name,
/// who is in, currency. The finish screen creates the group and opens it.
/// Reached from the first-run screen's "Gruppe für Ausgaben anlegen".
class FirstGroupView extends ConsumerWidget {
  const FirstGroupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final answers = ref.watch(firstGroupAnswersProvider);

    Future<void> create() async {
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      final result = await ref
          .read(firstGroupViewModelProvider.notifier)
          .create();
      switch (result) {
        case Ok(:final value):
          router.go('/groups/${value.id}');
        case Err(error: Conflict()):
          break; // The first tap is already on its way.
        case Err(:final error):
          showErrorSnackBar(messenger, l10n, error);
      }
    }

    return SetupFlowView(
      config: firstGroupFlow,
      stepBuilder: (context, s) => switch (s.step.id) {
        FirstGroupStep.name => _NameStep(s),
        FirstGroupStep.people => _PeopleStep(s),
        _ => _CurrencyStep(s),
      },
      finishBuilder: (context, back) {
        if (answers == null) return const SizedBox.shrink();
        return FinishStep(
          title: l10n.firstGroupFinishTitle(answers.name),
          summary: [
            if (answers.people.isEmpty)
              l10n.firstGroupSummaryAlone
            else
              l10n.firstGroupSummaryPeople(answers.people.join(', ')),
            l10n.firstGroupSummaryCurrency(
              answers.currency.code == l10n.currencyName(answers.currency.code)
                  ? answers.currency.code
                  : '${answers.currency.code} · '
                        '${l10n.currencyName(answers.currency.code)}',
            ),
          ],
          actionLabel: l10n.firstGroupCreate,
          onAction: () => unawaited(create()),
          onBack: back,
        );
      },
    );
  }
}

class _NameStep extends StatefulWidget {
  const _NameStep(this.s);

  final SetupStepContext s;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  late final _name = TextEditingController(
    text: widget.s.answer is String ? widget.s.answer! as String : '',
  );
  var _missing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_name.text.trim().isEmpty) {
      setState(() => _missing = true);
      return;
    }
    widget.s.onNext(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.firstGroupNameTitle,
      visual: const StepIconVisual(Icons.groups_outlined),
      onNext: _next,
      onBack: widget.s.onBack,
      child: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.groupNameLabel,
          hintText: l10n.groupNameHint,
          errorText: _missing ? l10n.groupNameRequired : null,
        ),
        onChanged: (_) {
          if (_missing) setState(() => _missing = false);
        },
        onSubmitted: (_) => _next(),
      ),
    );
  }
}

class _PeopleStep extends StatefulWidget {
  const _PeopleStep(this.s);

  final SetupStepContext s;

  @override
  State<_PeopleStep> createState() => _PeopleStepState();
}

class _PeopleStepState extends State<_PeopleStep> {
  final _name = TextEditingController();
  late final List<String> _people = [
    if (widget.s.answer is List)
      for (final n in widget.s.answer! as List<Object?>)
        if (n is String) n,
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Moves the typed name into the list; false if there was none.
  bool _add() {
    final typed = _name.text.trim();
    if (typed.isEmpty) return false;
    setState(() => _people.add(typed));
    _name.clear();
    widget.s.onAnswer(List<String>.of(_people));
    return true;
  }

  void _next() {
    _add();
    // Nobody typed: the same as skipping, "just me".
    if (_people.isEmpty) {
      widget.s.onSkip?.call();
      return;
    }
    widget.s.onNext(List<String>.of(_people));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.firstGroupPeopleTitle,
      visual: const StepIconVisual(Icons.group_add_outlined),
      onNext: _next,
      onSkip: widget.s.onSkip,
      onBack: widget.s.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.firstGroupPeopleLabel,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.firstGroupPeopleAdd,
                onPressed: _add,
              ),
            ),
            onSubmitted: (_) => _add(),
          ),
          if (_people.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              children: [
                for (final (i, person) in _people.indexed)
                  InputChip(
                    label: Text(person),
                    deleteButtonTooltipMessage: l10n.firstGroupPeopleRemove(
                      person,
                    ),
                    onDeleted: () {
                      setState(() => _people.removeAt(i));
                      widget.s.onAnswer(
                        _people.isEmpty ? null : List<String>.of(_people),
                      );
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: Spacing.md),
          Text(
            l10n.firstGroupPeopleHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyStep extends StatefulWidget {
  const _CurrencyStep(this.s);

  final SetupStepContext s;

  @override
  State<_CurrencyStep> createState() => _CurrencyStepState();
}

class _CurrencyStepState extends State<_CurrencyStep> {
  late String _code = widget.s.answer is String
      ? widget.s.answer! as String
      : Currency.eur.code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.firstGroupCurrencyTitle,
      visual: const StepIconVisual(Icons.euro),
      onNext: () => widget.s.onNext(_code),
      onSkip: widget.s.onSkip,
      onBack: widget.s.onBack,
      child: DropdownButtonFormField<String>(
        key: ValueKey(_code),
        initialValue: _code,
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.groupCurrencyLabel),
        items: [
          for (final c in Currency.all)
            DropdownMenuItem(
              value: c.code,
              child: Text(
                c.code == l10n.currencyName(c.code)
                    ? c.code
                    : '${c.code} · ${l10n.currencyName(c.code)}',
              ),
            ),
        ],
        onChanged: (code) => setState(() => _code = code ?? _code),
      ),
    );
  }
}
