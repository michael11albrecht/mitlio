import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Month grid: who drove each day, as the driver's avatar. Tap a day to see
/// or log its rides. Arrows move by month.
class RideCalendar extends StatelessWidget {
  const RideCalendar({
    required this.state,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDay,
    this.onSettle,
    super.key,
  });

  final RidesLoaded state;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDay;

  /// "Monat abrechnen" in the month menu; null while there is nothing to
  /// settle (the menu entry is then disabled).
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final month = state.month;
    final first = DateTime.utc(month.year, month.month);
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    // Column of the first day, counted from the locale's first weekday.
    final offset = (first.weekday % 7 - material.firstDayOfWeekIndex + 7) % 7;
    final weeks = (offset + daysInMonth + 6) ~/ 7;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.ridesMonthPrev,
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousMonth,
            ),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  material.formatMonthYear(first),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.ridesMonthNext,
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
            ),
            PopupMenuButton<void>(
              tooltip: l10n.ridesMonthMenu,
              itemBuilder: (_) => [
                PopupMenuItem<void>(
                  enabled: onSettle != null,
                  onTap: onSettle,
                  child: Text(l10n.ridesSettleMenu),
                ),
              ],
            ),
          ],
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      material.narrowWeekdays[(material.firstDayOfWeekIndex +
                              i) %
                          7],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var w = 0; w < weeks; w++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(context, w * 7 + c - offset + 1)),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int dayOfMonth) {
    final daysInMonth = DateTime.utc(
      state.month.year,
      state.month.month + 1,
      0,
    ).day;
    if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
      return const SizedBox(height: Sizes.calendarCell);
    }
    final day = DateTime.utc(state.month.year, state.month.month, dayOfMonth);
    return _DayCell(
      day: day,
      isToday: day == state.today,
      drivers: [
        for (final id in state.driversOn(day)) ?state.member(id),
      ],
      locked: state.entriesOn(day).any((e) => e.isSettled),
      onTap: () => onDay(day),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.drivers,
    required this.locked,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final List<GroupMember> drivers;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = MaterialLocalizations.of(context).formatMediumDate(day);
    final label = drivers.isEmpty
        ? date
        : l10n.ridesDayDrivers(date, drivers.map((m) => m.name).join(', '));
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: Radii.smAll,
        onTap: onTap,
        child: SizedBox(
          height: Sizes.calendarCell,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: Spacing.allXs,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.day}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isToday ? scheme.primary : null,
                      fontWeight: isToday ? FontWeight.w700 : null,
                      decoration: isToday ? TextDecoration.underline : null,
                    ),
                  ),
                  if (drivers.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MemberAvatar(
                          memberId: drivers.first.id,
                          name: drivers.first.name,
                          size: Sizes.avatarSmall,
                        ),
                        if (drivers.length > 1)
                          Text(
                            '+${drivers.length - 1}',
                            style: theme.textTheme.labelSmall,
                          ),
                        if (locked)
                          Icon(
                            Icons.lock_outline,
                            size: Spacing.md,
                            color: scheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
