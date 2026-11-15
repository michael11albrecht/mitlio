import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/repository_error.dart' show Undo;
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio/features/routes/ui/route_distance_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Start und Ziel eingeben, Strecke berechnen": a collapsed row under a
/// kilometre field. Open, it has two typeahead fields, the saved places
/// (Zuhause, Arbeit) and the result line. The one-way distance goes to
/// [onFill] in metres; the form keeps its own field editable and tells the
/// panel about hand edits with [RouteDistanceViewModel.noteManualEdit].
///
/// Renders nothing without a configured backend: the form then has only
/// its manual kilometre field and no dead button.
class RouteDistancePanel extends ConsumerStatefulWidget {
  const RouteDistancePanel({
    required this.onFill,
    this.initiallyOpen = false,
    super.key,
  });

  /// Receives the one-way distance in metres (rounded to 100 m).
  final ValueChanged<int> onFill;

  /// Starts expanded (tests and goldens; the forms start collapsed).
  final bool initiallyOpen;

  @override
  ConsumerState<RouteDistancePanel> createState() => _RouteDistancePanelState();
}

class _RouteDistancePanelState extends ConsumerState<RouteDistancePanel> {
  final _start = TextEditingController();
  final _end = TextEditingController();
  late bool _open = widget.initiallyOpen;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  RouteDistanceViewModel get _vm =>
      ref.read(routeDistanceViewModelProvider.notifier);

  String get _lang => Localizations.localeOf(context).languageCode;

  TextEditingController _controller(RouteField f) =>
      f == RouteField.start ? _start : _end;

  void _picked(RouteField field, PlaceSuggestion place) {
    _controller(field).text = place.label;
    unawaited(_vm.pick(field, place));
  }

  void _pickSaved(PlaceKind kind) {
    final picked = _vm.pickSaved(kind);
    if (picked != null) _controller(picked.field).text = picked.place.label;
  }

  Future<void> _save(RouteField field, PlaceKind kind) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _vm.savePlace(field, kind);
    if (!mounted || result == null) return;
    switch (result) {
      case Ok(:final value):
        showUndoSnackBar(
          context,
          message: kind == PlaceKind.home
              ? l10n.routeSavedAsHome
              : l10n.routeSavedAsWork,
          undo: Undo(() async {
            final undone = await value();
            if (mounted) unawaited(_vm.refreshSaved());
            return undone;
          }),
        );
      case Err(:final error):
        showErrorSnackBar(messenger, l10n, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(routeDistanceViewModelProvider.select((s) => s.fill), (_, fill) {
      if (fill != null) widget.onFill(fill.meters);
    });
    final s = ref.watch(routeDistanceViewModelProvider);
    if (!s.available) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(_open ? Icons.expand_less : Icons.alt_route),
            label: Text(l10n.routeToggle),
          ),
        ),
        if (_open) ...[
          _field(context, s, RouteField.start, l10n.routeStartLabel),
          const SizedBox(height: Spacing.sm),
          _field(context, s, RouteField.end, l10n.routeEndLabel),
          _savedChips(context, s),
          _status(context, s),
        ],
      ],
    );
  }

  Widget _field(
    BuildContext context,
    RouteDistanceState s,
    RouteField field,
    String label,
  ) {
    final place = field == RouteField.start ? s.start : s.end;
    final showSuggestions = s.active == field && s.suggestions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller(field),
          textInputAction: field == RouteField.start
              ? TextInputAction.next
              : TextInputAction.done,
          onTap: () => _vm.onTextChanged(
            field,
            _controller(field).text,
            lang: _lang,
          ),
          onChanged: (text) => _vm.onTextChanged(field, text, lang: _lang),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: place == null
                ? null
                : const ExcludeSemantics(child: Icon(Icons.check)),
          ),
        ),
        if (showSuggestions)
          for (final p in s.suggestions)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: Spacing.sm,
              leading: const ExcludeSemantics(
                child: Icon(Icons.place_outlined),
              ),
              title: Text(p.label),
              onTap: () => _picked(field, p),
            ),
        if (s.active == field && s.searching)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: Text(
                AppLocalizations.of(context).routeSearching,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        if (place != null && s.meters != null && !s.canRecalculate)
          _saveButtons(context, s, field, place),
      ],
    );
  }

  Widget _saveButtons(
    BuildContext context,
    RouteDistanceState s,
    RouteField field,
    PlaceSuggestion place,
  ) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: Spacing.sm,
      children: [
        if (s.savedOf(PlaceKind.home)?.place != place)
          TextButton(
            onPressed: () => unawaited(_save(field, PlaceKind.home)),
            child: Text(l10n.routeSaveAsHome),
          ),
        if (s.savedOf(PlaceKind.work)?.place != place)
          TextButton(
            onPressed: () => unawaited(_save(field, PlaceKind.work)),
            child: Text(l10n.routeSaveAsWork),
          ),
      ],
    );
  }

  Widget _savedChips(BuildContext context, RouteDistanceState s) {
    if (s.saved.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Wrap(
        spacing: Spacing.sm,
        children: [
          for (final kind in PlaceKind.values)
            if (s.savedOf(kind) != null)
              ActionChip(
                avatar: Icon(
                  kind == PlaceKind.home
                      ? Icons.home_outlined
                      : Icons.work_outline,
                ),
                label: Text(
                  kind == PlaceKind.home
                      ? l10n.routeSavedHome
                      : l10n.routeSavedWork,
                ),
                onPressed: () => _pickSaved(kind),
              ),
        ],
      ),
    );
  }

  String? _failureText(AppLocalizations l10n, RouteDistanceState s) {
    final minutes = s.retryAfter?.inMinutes;
    return switch (s.failure) {
      null => null,
      RouteFailure.offline => l10n.routeOffline,
      RouteFailure.rateLimited =>
        minutes == null
            ? l10n.routeRateLimited
            : l10n.routeRateLimitedIn(minutes < 1 ? 1 : minutes),
      RouteFailure.noRoute => l10n.routeNoRoute,
      RouteFailure.invalidParams => l10n.routeInvalid,
      RouteFailure.provider || RouteFailure.unavailable => l10n.routeServerDown,
    };
  }

  Widget _status(BuildContext context, RouteDistanceState s) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final failure = _failureText(l10n, s);
    final noMatches =
        s.searched &&
        s.suggestions.isEmpty &&
        s.failure == null &&
        s.active != null;
    final meters = s.meters;
    final line =
        failure ??
        (s.calculating
            ? l10n.routeCalculating
            : noMatches
            ? l10n.routeNoMatches
            : meters != null && !s.canRecalculate
            ? l10n.routeResult(
                formatMilli(
                  roundRouteMeters(meters),
                  separator: MoneyFormat.of(context).decimalSeparator,
                ),
              )
            : null);
    final showCredit = s.suggestions.isNotEmpty || meters != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (line != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Text(
                line,
                style: failure != null
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      )
                    : theme.textTheme.bodyMedium,
              ),
            ),
          ),
        if (s.canRecalculate)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => unawaited(_vm.recalculate()),
              child: Text(l10n.routeRecalculate),
            ),
          ),
        if (showCredit)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Text(
              s.attribution.isEmpty
                  ? l10n.routeAttributionFallback
                  : s.attribution,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
