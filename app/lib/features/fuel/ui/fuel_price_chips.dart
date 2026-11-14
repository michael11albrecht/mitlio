import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/fuel/ui/fuel_price_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart' show Currency;

/// E5 / E10 / Diesel chips that fill a fuel price field with the current
/// average, plus the line saying where the number comes from. Renders
/// nothing without a configured backend. Starts on the national average
/// (no location); "in meiner Nähe" and a postcode are explicit choices.
class FuelPriceChips extends ConsumerStatefulWidget {
  const FuelPriceChips({
    required this.grade,
    required this.onFill,
    this.autoFill = false,
    super.key,
  });

  /// The pre-selected grade (the vehicle's fuel).
  final FuelGrade grade;

  /// Receives the price in thousandths per litre; `auto` is true for the
  /// pre-selected grade's price that came without a tap.
  final void Function(int milli, {required bool auto}) onFill;

  /// Also hand over the pre-selected grade's price without a tap (the form
  /// then only takes it into an empty field).
  final bool autoFill;

  @override
  ConsumerState<FuelPriceChips> createState() => _FuelPriceChipsState();
}

class _FuelPriceChipsState extends ConsumerState<FuelPriceChips> {
  final _plz = TextEditingController();
  var _plzOpen = false;
  var _plzInvalid = false;

  @override
  void dispose() {
    _plz.dispose();
    super.dispose();
  }

  FuelPriceViewModel get _vm =>
      ref.read(fuelPriceViewModelProvider(widget.grade).notifier);

  String _gradeLabel(AppLocalizations l10n, FuelGrade g) => switch (g) {
    FuelGrade.e5 => l10n.fuelGradeE5,
    FuelGrade.e10 => l10n.fuelGradeE10,
    FuelGrade.diesel => l10n.fuelGradeDiesel,
  };

  String _scope(AppLocalizations l10n, FuelPrice p) => switch (p.scope) {
    FuelScope.national => l10n.fuelScopeNational,
    FuelScope.plz => l10n.fuelScopePlz(p.scopeKey ?? ''),
    FuelScope.nearby => l10n.fuelScopeNearby,
  };

  /// Relative for fresh data, the date once it is days old (the EU bulletin
  /// is weekly): never pretends to be fresher than it is.
  String _age(AppLocalizations l10n, FuelPriceState s, String locale) {
    final age = s.age;
    if (age.inDays >= 2) {
      final date = DateFormat.Md(locale).format(s.price!.fetchedAt.toLocal());
      return l10n.fuelAgeSince(date);
    }
    if (age.inHours >= 1) return l10n.fuelAgeHours(age.inHours);
    if (age.inMinutes >= 1) return l10n.fuelAgeMinutes(age.inMinutes);
    return l10n.fuelAgeNow;
  }

  /// `1,799 €/l`, with a "≈" when the value stands in for another grade.
  String _price(AppLocalizations l10n, FuelPrice p, String locale) {
    final symbol = MoneyFormat.of(context).currencySymbol(Currency.eur);
    final number = NumberFormat('0.000', locale).format(p.priceMilli / 1000);
    final approx = p.approximation == null ? '' : '≈ ';
    return '$approx$number ${l10n.tripUnitPerLiter(symbol)}';
  }

  String? _line(AppLocalizations l10n, FuelPriceState s, String locale) {
    final p = s.price;
    if (p == null) return null;
    return [
      _price(l10n, p, locale),
      _scope(l10n, p),
      _age(l10n, s, locale),
      if (s.stale) l10n.fuelOfflineNote,
      if (p.attribution.isEmpty)
        l10n.fuelAttributionFallback
      else
        p.attribution,
    ].join(' · ');
  }

  String? _hint(AppLocalizations l10n, FuelPriceState s) {
    if (s.loading) return null;
    return switch (s.failure) {
      FuelFailure.locationDenied => l10n.fuelNearbyDenied,
      FuelFailure.locationUnavailable => l10n.fuelNearbyUnavailable,
      _ when s.price == null && s.failure != null => l10n.fuelNoPrice,
      _ => null,
    };
  }

  void _applyPlz() {
    final text = _plz.text.trim();
    final valid = RegExp(r'^\d{5}$').hasMatch(text);
    setState(() => _plzInvalid = !valid);
    if (valid) {
      setState(() => _plzOpen = false);
      unawaited(_vm.usePlz(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final provider = fuelPriceViewModelProvider(widget.grade);
    ref.listen(provider.select((s) => s.fill), (_, fill) {
      if (fill != null && (widget.autoFill || !fill.auto)) {
        widget.onFill(fill.priceMilli, auto: fill.auto);
      }
    });
    final s = ref.watch(provider);
    if (!s.available) return const SizedBox.shrink();
    final line = _line(l10n, s, locale);
    final hint = _hint(l10n, s);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.fuelChipsLabel,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final g in FuelGrade.values)
                ChoiceChip(
                  label: Text(_gradeLabel(l10n, g)),
                  selected: g == s.grade,
                  showCheckmark: false,
                  onSelected: (_) => unawaited(_vm.selectGrade(g)),
                ),
            ],
          ),
          Wrap(
            spacing: Spacing.sm,
            children: [
              if (s.canLocate)
                ActionChip(
                  avatar: const Icon(Icons.my_location),
                  label: Text(l10n.fuelNearby),
                  onPressed: () => unawaited(_vm.useNearby()),
                ),
              ActionChip(
                avatar: const Icon(Icons.pin_drop_outlined),
                label: Text(l10n.fuelPlzAction),
                onPressed: () => setState(() => _plzOpen = !_plzOpen),
              ),
              if (s.scope != FuelScope.national)
                ActionChip(
                  label: Text(l10n.fuelNationalAction),
                  onPressed: () => unawaited(_vm.useNational()),
                ),
            ],
          ),
          if (_plzOpen)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _plz,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      onSubmitted: (_) => _applyPlz(),
                      decoration: InputDecoration(
                        labelText: l10n.fuelPlzLabel,
                        errorText: _plzInvalid ? l10n.fuelPlzInvalid : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  TextButton(
                    onPressed: _applyPlz,
                    child: Text(l10n.fuelPlzApply),
                  ),
                ],
              ),
            ),
          if (line != null || hint != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  [?line, ?hint].join('\n'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
