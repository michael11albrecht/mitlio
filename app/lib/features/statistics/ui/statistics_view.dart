import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/empty_state.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/core/widgets/money_text.dart';
import 'package:mitlio/features/expenses/ui/expenses_view.dart';
import 'package:mitlio/features/statistics/ui/statistics_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Statistics of one group, result first: what the period cost and what it
/// was mostly spent on, then plain bar lists by category, by person and by
/// month. Every bar carries its numbers as a spoken label; the bars
/// themselves are decoration.
class StatisticsView extends ConsumerWidget {
  const StatisticsView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(statisticsViewModelProvider(groupId).notifier);
    final state = ref.watch(statisticsViewModelProvider(groupId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: switch (state) {
        StatisticsLoading() => const Center(child: CircularProgressIndicator()),
        StatisticsFailure() => ErrorState(onRetry: vm.retry),
        final StatisticsLoaded loaded => _Loaded(
          state: loaded,
          onPeriod: vm.setPeriod,
        ),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.onPeriod});

  final StatisticsLoaded state;
  final ValueChanged<StatsPeriod> onPeriod;

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    return ListView(
      padding: Spacing.screen,
      children: [
        _PeriodPicker(selected: state.period, onSelected: onPeriod),
        const SizedBox(height: Spacing.md),
        if (stats.isEmpty)
          const _EmptyPeriod()
        else ...[
          _Headline(state: state),
          const SizedBox(height: Spacing.lg),
          _CategorySection(state: state),
          const SizedBox(height: Spacing.lg),
          _MemberSection(state: state),
        ],
        const SizedBox(height: Spacing.lg),
        _MonthSection(state: state),
        if (stats.hasRides) ...[
          const SizedBox(height: Spacing.lg),
          _RideSection(state: state),
        ],
      ],
    );
  }
}

String _periodLabel(AppLocalizations l10n, StatsPeriod p) => switch (p) {
  StatsPeriod.month => l10n.statsPeriodMonth,
  StatsPeriod.last3Months => l10n.statsPeriod3Months,
  StatsPeriod.year => l10n.statsPeriodYear,
  StatsPeriod.all => l10n.statsPeriodAll,
};

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.selected, required this.onSelected});

  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.statsPeriodLabel,
      child: Wrap(
        spacing: Spacing.sm,
        children: [
          for (final p in StatsPeriod.values)
            ChoiceChip(
              label: Text(_periodLabel(l10n, p)),
              selected: p == selected,
              onSelected: (_) => onSelected(p),
            ),
        ],
      ),
    );
  }
}

class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.bar_chart_outlined,
      title: l10n.statsEmptyTitle,
      message: l10n.statsEmptyMessage,
    );
  }
}

/// "Diesen Monat  412,30 €  ·  meist Sprit (38 %)".
class _Headline extends StatelessWidget {
  const _Headline({required this.state});

  final StatisticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = state.stats;
    final label = switch (state.period) {
      StatsPeriod.month => l10n.statsHeadlineMonth,
      StatsPeriod.last3Months => l10n.statsHeadline3Months,
      StatsPeriod.year => l10n.statsHeadlineYear,
      StatsPeriod.all => l10n.statsHeadlineAll,
    };
    final top = stats.topCategory;
    final detail = [
      l10n.statsExpenseCount(stats.expenseCount),
      if (top case final t?)
        l10n.statsTopCategory(
          categoryLabel(l10n, t.key!),
          t.percent,
        ),
    ].join(' · ');
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: Spacing.allMd,
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              MoneyText(
                cents: stats.totalCents,
                currency: state.currency,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.sm),
    child: Semantics(
      container: true,
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

/// One labelled bar: caption and value on a line, the bar below. Screen
/// readers get [spoken] instead of the pieces; a row without it sits inside
/// a parent that speaks for it.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.caption,
    required this.value,
    required this.fraction,
    this.spoken,
    this.color,
  });

  final String caption;
  final String value;

  /// 0..1 of the track.
  final double fraction;
  final String? spoken;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(caption, style: theme.textTheme.bodyLarge),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                value,
                style: MitlioTypography.tabular(theme.textTheme.bodyLarge),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.barHeight / 2),
            child: SizedBox(
              height: Sizes.barHeight,
              child: ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: fraction.clamp(0, 1),
                    child: ColoredBox(color: color ?? scheme.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final label = spoken;
    return label == null
        ? row
        : Semantics(
            container: true,
            label: label,
            excludeSemantics: true,
            child: row,
          );
  }
}

double _fraction(int part, int whole) => whole <= 0 ? 0 : part / whole;

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.state});

  final StatisticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat.of(context);
    final stats = state.stats;
    final biggest = stats.categories.first.cents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.statsByCategory),
        for (final c in stats.categories)
          _BarRow(
            caption: c.key == null
                ? l10n.statsCategoryNone
                : categoryLabel(l10n, c.key!),
            value:
                '${money.format(c.cents, state.currency)} · '
                '${l10n.statsPercent(c.percent)}',
            fraction: _fraction(c.cents, biggest),
            spoken: l10n.statsCategorySpoken(
              c.key == null
                  ? l10n.statsCategoryNone
                  : categoryLabel(l10n, c.key!),
              spokenMoney(l10n, c.cents, state.currency),
              c.percent,
            ),
          ),
      ],
    );
  }
}

class _MemberSection extends StatelessWidget {
  const _MemberSection({required this.state});

  final StatisticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = MoneyFormat.of(context);
    final members = state.stats.members;
    final biggest = members.fold<int>(
      0,
      (a, m) => [a, m.paidCents, m.shareCents].reduce((x, y) => x > y ? x : y),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.statsByMember),
        for (final m in members)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Card(
              child: Padding(
                padding: Spacing.allMd,
                child: Semantics(
                  container: true,
                  label: l10n.statsMemberSpoken(
                    state.nameOf(m.memberId),
                    spokenMoney(l10n, m.paidCents, state.currency),
                    spokenMoney(l10n, m.shareCents, state.currency),
                  ),
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MemberAvatar(
                            memberId: m.memberId,
                            name: state.nameOf(m.memberId),
                            size: Sizes.avatarSmall,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              state.nameOf(m.memberId),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      _BarRow(
                        caption: l10n.statsPaid,
                        value: money.format(m.paidCents, state.currency),
                        fraction: _fraction(m.paidCents, biggest),
                      ),
                      _BarRow(
                        caption: l10n.statsConsumed,
                        value: money.format(m.shareCents, state.currency),
                        fraction: _fraction(m.shareCents, biggest),
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _monthLabel(BuildContext context, MonthStat m) =>
    MaterialLocalizations.of(
      context,
    ).formatMonthYear(DateTime.utc(m.year, m.month));

class _MonthSection extends StatelessWidget {
  const _MonthSection({required this.state});

  final StatisticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat.of(context);
    final months = state.stats.months;
    final biggest = months.fold<int>(
      0,
      (a, m) => m.expenseCents > a ? m.expenseCents : a,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.statsOverTime),
        for (final m in months)
          _BarRow(
            caption: _monthLabel(context, m),
            value: money.format(m.expenseCents, state.currency),
            fraction: _fraction(m.expenseCents, biggest),
            spoken: l10n.statsMonthSpoken(
              _monthLabel(context, m),
              spokenMoney(l10n, m.expenseCents, state.currency),
            ),
          ),
      ],
    );
  }
}

class _RideSection extends StatelessWidget {
  const _RideSection({required this.state});

  final StatisticsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat.of(context);
    final km = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final months = [
      for (final m in state.stats.months)
        if (m.rideMeters > 0) m,
    ];
    final biggest = months.fold<int>(
      0,
      (a, m) => m.rideMeters > a ? m.rideMeters : a,
    );
    String kmOf(MonthStat m) => km.format((m.rideMeters + 500) ~/ 1000);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.statsRides),
        for (final m in months)
          _BarRow(
            caption: _monthLabel(context, m),
            value:
                '${l10n.statsKm(kmOf(m))} · '
                '${money.format(m.rideCents, state.currency)}',
            fraction: _fraction(m.rideMeters, biggest),
            spoken: l10n.statsRideSpoken(
              _monthLabel(context, m),
              kmOf(m),
              spokenMoney(l10n, m.rideCents, state.currency),
            ),
          ),
      ],
    );
  }
}
