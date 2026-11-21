import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/amount_parser.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart';
import 'package:mitlio/features/profile/ui/car_flow_calculator.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Placeholder slot for a step's illustration. PU-T06 draws the real art and
/// replaces the body of this widget; the steps already place it.
class CarVisualSlot extends StatelessWidget {
  const CarVisualSlot(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: Sizes.illustration,
      height: Sizes.illustration,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: Radii.lgAll,
      ),
      child: Icon(
        icon,
        size: Sizes.illustration / 2,
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}

/// A big tappable card with a label, an optional hint and an optional icon;
/// the answer of a choice step (one tap answers and moves on).
class CarChoiceCard extends StatelessWidget {
  const CarChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
    this.icon,
    super.key,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = selected ? scheme.onPrimaryContainer : null;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: Card(
          color: selected ? scheme.primaryContainer : null,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sizes.choiceCard),
              child: Padding(
                padding: Spacing.allMd,
                child: Row(
                  children: [
                    if (icon != null) ...[
                      ExcludeSemantics(child: Icon(icon, color: on)),
                      const SizedBox(width: Spacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: on,
                            ),
                          ),
                          if (hint != null)
                            Text(
                              hint!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: on ?? scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selected) Icon(Icons.check, color: on),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An inline note that never blocks anything: the PBefG hint and the
/// "Bitte prüfen" typo hint (PU-T15, ADR-25 §3). Read aloud when it appears.
class CarHint extends StatelessWidget {
  const CarHint(this.text, {super.key});

  final String text;

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
          padding: Spacing.allMd,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.info_outline,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The hints of [check], each in its own non-blocking note, with space
/// above.
List<Widget> carHints(AppLocalizations l10n, OperatingCostCheck check) => [
  if (check.exceedsOperatingCost) ...[
    const SizedBox(height: Spacing.md),
    CarHint(l10n.carHintOperatingCost),
  ],
  if (check.plausibility.isNotEmpty) ...[
    const SizedBox(height: Spacing.md),
    CarHint(l10n.carHintCheck),
  ],
];

/// A whole-number step (annual kilometres, years kept): a field, optional
/// quick-pick chips and slider, the live [result]. "Weiter" only moves on
/// with a valid number; an optional step with an empty field is skipped.
class CarIntStep extends StatefulWidget {
  const CarIntStep({
    required this.step,
    required this.title,
    required this.label,
    required this.invalidText,
    required this.max,
    required this.visual,
    this.initial,
    this.presets = const [],
    this.presetLabel,
    this.sliderStep,
    this.result,
    super.key,
  });

  final SetupStepContext step;
  final String title;
  final String label;
  final String invalidText;
  final int max;
  final IconData visual;

  /// Shown when the step has no answer yet; "Weiter" accepts it.
  final int? initial;
  final List<int> presets;
  final String Function(int value)? presetLabel;

  /// With a step, a slider from [sliderStep] to [max] sits under the field.
  final int? sliderStep;
  final Widget? result;

  @override
  State<CarIntStep> createState() => _CarIntStepState();
}

class _CarIntStepState extends State<CarIntStep> {
  late final TextEditingController _controller = TextEditingController(
    text: '${(widget.step.answer as int?) ?? widget.initial ?? ''}',
  );
  bool _showError = false;

  int? get _value {
    final n = int.tryParse(_controller.text.trim());
    return n != null && n > 0 && n <= widget.max ? n : null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String text) {
    setState(() {
      _controller.text = text;
      _showError = false;
    });
    widget.step.onAnswer(_value);
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final blank = _controller.text.trim().isEmpty;
    final slider = widget.sliderStep;
    return StepScaffold(
      current: widget.step.current,
      total: widget.step.total,
      title: widget.title,
      visual: CarVisualSlot(widget.visual),
      result: widget.result,
      onBack: widget.step.onBack,
      onSkip: widget.step.onSkip,
      onNext: () {
        final current = _value;
        if (current != null) {
          widget.step.onNext(current);
        } else if (_controller.text.trim().isEmpty &&
            widget.step.onSkip != null) {
          widget.step.onSkip!();
        } else {
          setState(() => _showError = true);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: (_showError || (!blank && value == null))
                  ? widget.invalidText
                  : null,
            ),
            onChanged: (text) {
              setState(() => _showError = false);
              widget.step.onAnswer(_value);
            },
          ),
          if (widget.presets.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              children: [
                for (final p in widget.presets)
                  ChoiceChip(
                    label: Text(widget.presetLabel!(p)),
                    selected: value == p,
                    onSelected: (_) => _set('$p'),
                  ),
              ],
            ),
          ],
          if (slider != null)
            Slider(
              value: (value ?? slider).clamp(slider, widget.max).toDouble(),
              min: slider.toDouble(),
              max: widget.max.toDouble(),
              divisions: (widget.max - slider) ~/ slider,
              onChanged: (v) => _set('${v.round()}'),
            ),
        ],
      ),
    );
  }
}

/// An amount step of the cost calculator: the amount, per month or per
/// year. "Überspringen" means "no such cost".
class CarAmountStep extends StatefulWidget {
  const CarAmountStep({
    required this.step,
    required this.title,
    required this.visual,
    this.result,
    this.perPeriod = true,
    super.key,
  });

  final SetupStepContext step;
  final String title;
  final IconData visual;
  final Widget? result;

  /// Offer the month/year toggle; without it the amount is a whole sum.
  final bool perPeriod;

  @override
  State<CarAmountStep> createState() => _CarAmountStepState();
}

class _CarAmountStepState extends State<CarAmountStep> {
  late final TextEditingController _controller = TextEditingController();
  late CostPeriod _period = widget.perPeriod
      ? CostPeriod.month
      : CostPeriod.year;
  bool _showError = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final answer = widget.step.answer;
    if (answer is Map) {
      final cents = answer['cents'];
      final period = CostPeriod.values.asNameMap()[answer['period']];
      if (cents is int) {
        _controller.text = MoneyFormat.of(context)
            .formatPlain(cents, carCurrency);
      }
      if (period != null) _period = period;
    } else if (answer is int) {
      _controller.text = MoneyFormat.of(context)
          .formatPlain(answer, carCurrency);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _cents {
    final cents = parseAmountCents(_controller.text, carCurrency);
    return cents != null && cents <= maxCostCents ? cents : null;
  }

  Object? get _answer {
    final cents = _cents;
    if (cents == null) return null;
    return widget.perPeriod ? costEntryAnswer(cents, _period) : cents;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cents = _cents;
    final blank = _controller.text.trim().isEmpty;
    return StepScaffold(
      current: widget.step.current,
      total: widget.step.total,
      title: widget.title,
      visual: CarVisualSlot(widget.visual),
      result: widget.result,
      onBack: widget.step.onBack,
      onSkip: widget.step.onSkip,
      onNext: () {
        if (_cents != null) {
          widget.step.onNext(_answer);
        } else if (_controller.text.trim().isEmpty &&
            widget.step.onSkip != null) {
          widget.step.onSkip!();
        } else {
          setState(() => _showError = true);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.carCostAmountLabel,
              suffixText: MoneyFormat.of(context).currencySymbol(carCurrency),
              errorText: (_showError || (!blank && cents == null))
                  ? l10n.carCostAmountInvalid
                  : null,
            ),
            onChanged: (_) {
              setState(() => _showError = false);
              widget.step.onAnswer(_answer);
            },
          ),
          if (widget.perPeriod) ...[
            const SizedBox(height: Spacing.md),
            SegmentedButton<CostPeriod>(
              segments: [
                ButtonSegment(
                  value: CostPeriod.month,
                  label: Text(l10n.carCostMonth),
                ),
                ButtonSegment(
                  value: CostPeriod.year,
                  label: Text(l10n.carCostYear),
                ),
              ],
              selected: {_period},
              onSelectionChanged: (s) {
                setState(() => _period = s.first);
                widget.step.onAnswer(_answer);
              },
            ),
          ],
        ],
      ),
    );
  }
}
