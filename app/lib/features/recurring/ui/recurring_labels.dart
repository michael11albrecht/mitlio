import 'package:mitlio/features/recurring/ui/recurring_catch_up_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Monatlich", "Alle 2 Wochen", ...
String recurrenceLabel(
  AppLocalizations l10n,
  RecurrenceFrequency frequency,
  int interval,
) => switch (frequency) {
  RecurrenceFrequency.daily => l10n.recurringEveryDays(interval),
  RecurrenceFrequency.weekly => l10n.recurringEveryWeeks(interval),
  RecurrenceFrequency.monthly => l10n.recurringEveryMonths(interval),
  RecurrenceFrequency.yearly => l10n.recurringEveryYears(interval),
};

/// The sentence for a catch-up run that has news: what was made, what was
/// left out, what failed and why (`reason` is the plain-words error).
String recurringNoticeText(
  AppLocalizations l10n,
  RecurringCatchUpNotice notice,
  String Function(RecurringFailureNote) reason,
) {
  final parts = <String>[
    if (notice.created > 0) l10n.recurringCreated(notice.created),
    if (notice.skipped > 0) l10n.recurringSkipped(notice.skipped),
    if (notice.failures.isNotEmpty) _failure(l10n, notice.failures, reason),
  ];
  return parts.join(' ');
}

String _failure(
  AppLocalizations l10n,
  List<RecurringFailureNote> failures,
  String Function(RecurringFailureNote) reason,
) {
  final first = failures.first;
  if (first.title.isEmpty) return l10n.recurringCheckFailed(reason(first));
  return failures.length == 1
      ? l10n.recurringFailed(first.title, reason(first))
      : l10n.recurringFailedMore(
          first.title,
          failures.length - 1,
          reason(first),
        );
}
