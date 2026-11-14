import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/amount_field.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/core/widgets/rate_field.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view_model.dart';
import 'package:mitlio/features/expenses/ui/expense_history_view.dart';
import 'package:mitlio/features/expenses/ui/expenses_view.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Add an expense to [groupId], or with [expenseId] edit the stored one.
///
/// Amount first (focused), then what for; payer and split are pre-set to the
/// smart defaults, so a plain equal split is amount, title, save. Every
/// person shows what they bear, live, and problems are explained inline.
class ExpenseFormView extends ConsumerStatefulWidget {
  const ExpenseFormView({required this.groupId, this.expenseId, super.key});

  final String groupId;
  final String? expenseId;

  @override
  ConsumerState<ExpenseFormView> createState() => _ExpenseFormViewState();
}

class _ExpenseFormViewState extends ConsumerState<ExpenseFormView> {
  final _title = TextEditingController();

  ExpenseFormKey get _key =>
      (groupId: widget.groupId, expenseId: widget.expenseId);

  @override
  void initState() {
    super.initState();
    // Fill the title once with the stored value; later edits are the user's.
    ref.listenManual(expenseFormViewModelProvider(_key), (prev, next) {
      if (prev is! ExpenseFormReady && next is ExpenseFormReady) {
        _title.text = next.title;
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = ref.read(expenseFormViewModelProvider(_key).notifier);
    final result = await vm.save();
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.pop();
      case Err(error: InvalidData()):
        break; // Explained inline.
      case Err():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorTitle)),
        );
    }
  }

  /// A restored version replaced the stored expense, so this form is stale:
  /// leave it (the undo snackbar outlives the route).
  Future<void> _openHistory(String expenseId) async {
    final restored = await showExpenseHistorySheet(context, expenseId);
    if (restored ?? false) {
      if (mounted) context.pop();
    }
  }

  Future<void> _pickDate(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    ref.read(expenseFormViewModelProvider(_key).notifier).setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(expenseFormViewModelProvider(_key).notifier);
    final state = ref.watch(expenseFormViewModelProvider(_key));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expenseId == null ? l10n.expenseFormNew : l10n.expenseFormEdit,
        ),
        actions: [
          if (widget.expenseId case final id?)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l10n.expenseHistory,
              onPressed: () => unawaited(_openHistory(id)),
            ),
        ],
      ),
      body: switch (state) {
        ExpenseFormLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        ExpenseFormFailure() => ErrorState(onRetry: vm.retry),
        final ExpenseFormReady form => Column(
          children: [
            Expanded(
              child: _FormBody(
                form: form,
                vm: vm,
                title: _title,
                onPickDate: () => unawaited(_pickDate(form.date)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: Spacing.screen,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: form.saving ? null : () => unawaited(_save()),
                    child: Text(l10n.expenseSave),
                  ),
                ),
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.form,
    required this.vm,
    required this.title,
    required this.onPickDate,
  });

  final ExpenseFormReady form;
  final ExpenseFormViewModel vm;
  final TextEditingController title;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: Spacing.screen,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AmountField(
                currency: form.currency,
                cents: form.amountCents,
                label: l10n.expenseAmountLabel,
                autofocus: !form.editing,
                onChanged: vm.setAmount,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            SizedBox(
              width: Sizes.currencyPicker,
              child: DropdownButtonFormField<Currency>(
                key: ValueKey('currency-${form.currency.code}'),
                initialValue: form.currency,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.expenseCurrencyLabel,
                ),
                items: [
                  for (final c in form.currencyOptions)
                    DropdownMenuItem(value: c, child: Text(c.code)),
                ],
                onChanged: (c) {
                  if (c != null) vm.setCurrency(c);
                },
              ),
            ),
          ],
        ),
        if (form.showErrors && form.amountMissing)
          _ErrorLine(l10n.expenseErrorAmount),
        if (form.isForeign) ...[
          const SizedBox(height: Spacing.md),
          RateField(
            fromCode: form.currency.code,
            toSymbol: MoneyFormat.of(
              context,
            ).currencySymbol(form.group.currency),
            label: l10n.expenseRateLabel,
            ppm: form.ratePpm,
            errorText: form.showErrors && form.rateMissing
                ? l10n.expenseErrorRate
                : null,
            onChanged: vm.setRate,
          ),
          if (form.groupAmountCents case final converted?)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.expenseConverted(
                    MoneyFormat.of(context).format(
                      converted,
                      form.group.currency,
                    ),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
        const SizedBox(height: Spacing.md),
        TextField(
          controller: title,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          onChanged: vm.setTitle,
          decoration: InputDecoration(
            labelText: l10n.expenseTitleLabel,
            hintText: l10n.expenseTitleHint,
            errorText: form.showErrors && form.titleMissing
                ? l10n.expenseErrorTitle
                : null,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionChip(
            avatar: const Icon(Icons.event_outlined),
            tooltip: l10n.expenseDateChange,
            label: Text(_dateLabel(context)),
            onPressed: onPickDate,
          ),
        ),
        _Section(l10n.expensePayerSection),
        if (form.multiPayer) ..._multiPayers(context) else _singlePayer(),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => vm.setMultiplePayers(on: !form.multiPayer),
            child: Text(
              form.multiPayer
                  ? l10n.expensePayerSingle
                  : l10n.expensePayerMulti,
            ),
          ),
        ),
        _Section(l10n.expenseSplitSection),
        Wrap(
          spacing: Spacing.sm,
          children: [
            for (final mode in SplitMode.values)
              ChoiceChip(
                label: Text(_modeLabel(l10n, mode)),
                selected: form.mode == mode,
                onSelected: (_) => vm.setMode(mode),
              ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        for (final m in form.members)
          _PersonRow(
            key: ValueKey('${form.mode.name}-${m.id}'),
            form: form,
            vm: vm,
            memberId: m.id,
            name: m.name,
          ),
        if (_splitMessage(context) case final message?) _ErrorLine(message),
        _Section(l10n.expenseCategorySection),
        Wrap(
          spacing: Spacing.sm,
          children: [
            for (final c in form.categoryOptions)
              ChoiceChip(
                label: Text(categoryLabel(l10n, c)),
                selected: form.category == c,
                onSelected: (on) => vm.setCategory(on ? c : null),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
      ],
    );
  }

  Widget _singlePayer() => Wrap(
    spacing: Spacing.sm,
    children: [
      for (final m in form.members)
        ChoiceChip(
          avatar: ExcludeSemantics(
            child: MemberAvatar(
              memberId: m.id,
              name: m.name,
              size: Sizes.avatarSmall,
            ),
          ),
          label: Text(m.name),
          selected: form.payerId == m.id,
          onSelected: (_) => vm.setPayer(m.id),
        ),
    ],
  );

  List<Widget> _multiPayers(BuildContext context) {
    final message = _payerMessage(context);
    return [
      for (final m in form.members)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Row(
            children: [
              ExcludeSemantics(
                child: MemberAvatar(memberId: m.id, name: m.name),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: AmountField(
                  currency: form.group.currency,
                  cents: form.payerCents[m.id],
                  label: m.name,
                  onChanged: (cents) => vm.setPayerAmount(m.id, cents),
                ),
              ),
            ],
          ),
        ),
      if (message != null) _ErrorLine(message),
    ];
  }

  String _dateLabel(BuildContext context) => form.date == form.today
      ? AppLocalizations.of(context).expenseToday
      : MaterialLocalizations.of(context).formatMediumDate(form.date);

  String? _payerMessage(BuildContext context) {
    final error = form.payerError;
    if (error == null || !(form.multiPayer || form.showErrors)) return null;
    final l10n = AppLocalizations.of(context);
    return switch (error) {
      NoPayer() => l10n.expenseErrorNoPayer,
      PayersMismatch(:final sum, :final expected) => _difference(
        context,
        expected - sum,
      ),
      _ => l10n.expenseErrorGeneric,
    };
  }

  String? _splitMessage(BuildContext context) {
    final error = form.splitError;
    if (error == null) return null;
    final l10n = AppLocalizations.of(context);
    return switch (error) {
      NoParticipants() => l10n.expenseErrorNoParticipants,
      ExactMismatch(:final sum, :final expected) => _difference(
        context,
        expected - sum,
      ),
      PercentNotFull(:final sum) => l10n.expensePercentSum(
        // Basis points print like a two-decimal amount.
        '${MoneyFormat.of(context).formatPlain(sum, Currency.eur)} %',
      ),
      _ => l10n.expenseErrorGeneric,
    };
  }

  /// "Noch 5,00 € offen" (missing, positive) or "5,00 € zu viel".
  String _difference(BuildContext context, int missing) {
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat.of(context);
    return missing > 0
        ? l10n.expenseLeftOver(money.format(missing, form.group.currency))
        : l10n.expenseOver(money.format(-missing, form.group.currency));
  }
}

String _modeLabel(AppLocalizations l10n, SplitMode mode) => switch (mode) {
  SplitMode.equal => l10n.expenseSplitEqual,
  SplitMode.shares => l10n.expenseSplitShares,
  SplitMode.percent => l10n.expenseSplitPercent,
  SplitMode.exact => l10n.expenseSplitExact,
};

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.sm),
      child: Semantics(
        header: true,
        child: Text(title, style: theme.textTheme.titleMedium),
      ),
    );
  }
}

/// Calm inline explanation under a field group.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

/// One member of the split: avatar, name, the control of the current mode
/// and what they bear.
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.form,
    required this.vm,
    required this.memberId,
    required this.name,
    super.key,
  });

  final ExpenseFormReady form;
  final ExpenseFormViewModel vm;
  final String memberId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final taking = form.participants.contains(memberId);
    final share = form.preview[memberId];
    final isEqual = form.mode == SplitMode.equal;
    final result = switch (share) {
      _ when !taking => Text(
        l10n.expenseExcluded,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      final int cents when form.mode != SplitMode.exact => MoneyText(
        cents: cents,
        currency: form.group.currency,
        style: theme.textTheme.titleMedium,
      ),
      _ => const SizedBox.shrink(),
    };
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEqual)
            ExcludeSemantics(
              child: Checkbox(
                value: taking,
                onChanged: (_) => vm.toggleParticipant(memberId),
              ),
            ),
          ExcludeSemantics(
            child: MemberAvatar(memberId: memberId, name: name),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: Sizes.avatar),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(name),
                  ),
                ),
                if (!isEqual) _control(context),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.avatar),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: result,
            ),
          ),
        ],
      ),
    );
    if (!isEqual) return row;
    return MergeSemantics(
      child: Semantics(
        checked: taking,
        child: InkWell(
          borderRadius: Radii.smAll,
          onTap: () => vm.toggleParticipant(memberId),
          child: row,
        ),
      ),
    );
  }

  Widget _control(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = form.weights[memberId] ?? 0;
    return switch (form.mode) {
      SplitMode.shares => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.expenseSharesFewer(name),
            icon: const Icon(Icons.remove),
            onPressed: value > 0
                ? () => vm.setWeight(memberId, value - 1)
                : null,
          ),
          Semantics(
            label: l10n.expenseSplitShares,
            value: '$value',
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: Spacing.lg),
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: MitlioTypography.tabular(
                  Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.expenseSharesMore(name),
            icon: const Icon(Icons.add),
            onPressed: () => vm.setWeight(memberId, value + 1),
          ),
        ],
      ),
      SplitMode.percent => AmountField(
        // Basis points are edited as a percentage with two decimals, which
        // is what a two-decimal currency amount parses and prints as.
        currency: Currency.eur,
        suffix: '%',
        cents: value == 0 ? null : value,
        label: l10n.expenseSplitPercent,
        onChanged: (bp) => vm.setWeight(memberId, bp),
      ),
      SplitMode.exact => AmountField(
        currency: form.group.currency,
        cents: value == 0 ? null : value,
        label: l10n.expenseAmountLabel,
        onChanged: (cents) => vm.setWeight(memberId, cents),
      ),
      SplitMode.equal => const SizedBox.shrink(),
    };
  }
}
