import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/step_icon_visual.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/core/widgets/amount_field.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/features/rides/ui/commute_template_view_model.dart';
import 'package:mitlio/features/rides/ui/milli_field.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart'
    show formatMilli;
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/features/routes/ui/route_distance_panel.dart';
import 'package:mitlio/features/routes/ui/route_distance_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A new commute route in five steps (PU-T12, ADR-25 §4): name, distance and
/// round trip, car, who usually drives and rides, tolls. The finish screen
/// saves it and ends with just "Strecke speichern", no celebration. Editing
/// a stored route stays the compact `TemplateFormView`.
class CommuteTemplateView extends ConsumerWidget {
  const CommuteTemplateView({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final separator = MoneyFormat.of(context).decimalSeparator;
    final setup = ref.watch(ridesSetupViewModelProvider(groupId));
    final draft = ref.watch(commuteTemplateDraftProvider(groupId));

    Future<void> save() async {
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      final result = await ref
          .read(commuteTemplateViewModelProvider(groupId).notifier)
          .save();
      switch (result) {
        case Ok():
          router.pop();
        case Err(error: Conflict()):
          break; // The first tap is already on its way.
        case Err(:final error):
          showErrorSnackBar(messenger, l10n, error);
      }
    }

    if (setup is RidesSetupFailure) {
      return Scaffold(
        body: ErrorState(
          onRetry: ref
              .read(ridesSetupViewModelProvider(groupId).notifier)
              .retry,
        ),
      );
    }
    if (setup is! RidesSetupLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return SetupFlowView(
      config: commuteTemplateFlowFor(groupId),
      stepBuilder: (context, s) => switch (s.step.id) {
        CommuteStep.name => _NameStep(s),
        CommuteStep.route => _RouteStep(s),
        CommuteStep.vehicle => _VehicleStep(s, groupId: groupId, setup: setup),
        CommuteStep.people => _PeopleStep(s, setup: setup),
        _ => _TollsStep(s, currency: setup.group.currency),
      },
      finishBuilder: (context, back) {
        if (draft == null) return const SizedBox.shrink();
        final money = MoneyFormat.of(context);
        final driver = setup.member(draft.defaultDriverId ?? '');
        final passengers = [
          for (final m in setup.members)
            if (draft.defaultPassengerIds.contains(m.id)) m.name,
        ];
        final km = formatMilli(draft.distanceMeters, separator: separator);
        return FinishStep(
          title: l10n.commuteFinishTitle(draft.name),
          celebrate: false,
          summary: [
            if (draft.roundTrip)
              l10n.commuteSummaryRoundTrip(km)
            else
              l10n.commuteSummaryOneWay(km),
            l10n.commuteSummaryVehicle(
              setup.vehicle(draft.vehicleId)?.name ?? '',
            ),
            if (driver != null) l10n.commuteSummaryDriver(driver.name),
            if (passengers.isNotEmpty)
              l10n.commuteSummaryPassengers(passengers.join(', ')),
            if (draft.tollsCents > 0)
              l10n.commuteSummaryTolls(
                money.format(draft.tollsCents, setup.group.currency),
              ),
          ],
          actionLabel: l10n.commuteSave,
          onAction: () => unawaited(save()),
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
      title: l10n.commuteNameTitle,
      visual: const StepIconVisual(Icons.route_outlined),
      onNext: _next,
      onBack: widget.s.onBack,
      child: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.templateNameLabel,
          hintText: l10n.templateNameHint,
          errorText: _missing ? l10n.templateErrorName : null,
        ),
        onChanged: (_) {
          if (_missing) setState(() => _missing = false);
        },
        onSubmitted: (_) => _next(),
      ),
    );
  }
}

class _RouteStep extends ConsumerStatefulWidget {
  const _RouteStep(this.s);

  final SetupStepContext s;

  @override
  ConsumerState<_RouteStep> createState() => _RouteStepState();
}

class _RouteStepState extends ConsumerState<_RouteStep> {
  late int? _meters = switch (widget.s.answer) {
    {'meters': final int m} => m,
    _ => null,
  };
  late bool _roundTrip = switch (widget.s.answer) {
    {'roundTrip': final bool r} => r,
    _ => true,
  };
  var _missing = false;

  void _next() {
    final meters = _meters;
    if (meters == null || meters <= 0) {
      setState(() => _missing = true);
      return;
    }
    widget.s.onNext(commuteRouteAnswer(meters, roundTrip: _roundTrip));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.commuteRouteTitle,
      visual: const StepIconVisual(Icons.straighten),
      onNext: _next,
      onBack: widget.s.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MilliField(
            label: l10n.templateDistanceLabel,
            suffix: 'km',
            milli: _meters,
            autofocus: true,
            onChanged: (meters) {
              // Typing is the user's: the route lookup stops overwriting it.
              ref
                  .read(routeDistanceViewModelProvider.notifier)
                  .noteManualEdit();
              setState(() {
                _meters = meters;
                _missing = false;
              });
            },
            errorText: _missing ? l10n.templateErrorDistance : null,
          ),
          RouteDistancePanel(
            onFill: (meters) => setState(() {
              _meters = meters;
              _missing = false;
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.templateRoundTrip),
            value: _roundTrip,
            onChanged: (on) => setState(() => _roundTrip = on),
          ),
        ],
      ),
    );
  }
}

class _VehicleStep extends StatefulWidget {
  const _VehicleStep(this.s, {required this.groupId, required this.setup});

  final SetupStepContext s;
  final String groupId;
  final RidesSetupLoaded setup;

  @override
  State<_VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends State<_VehicleStep> {
  // Smart default: the only car (or the first one).
  late String? _vehicleId =
      widget.s.answer is String &&
          widget.setup.vehicle(widget.s.answer! as String) != null
      ? widget.s.answer! as String
      : widget.setup.vehicles.firstOrNull?.id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicles = widget.setup.vehicles;
    final id = _vehicleId;
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.commuteVehicleTitle,
      visual: const StepIconVisual(Icons.directions_car_outlined),
      onNext: id == null ? null : () => widget.s.onNext(id),
      onBack: widget.s.onBack,
      child: vehicles.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.templateNoVehicle),
                TextButton(
                  onPressed: () => unawaited(
                    context.push(
                      '/groups/${widget.groupId}/rides/vehicles/new',
                    ),
                  ),
                  child: Text(l10n.templateNoVehicleAction),
                ),
              ],
            )
          : Wrap(
              spacing: Spacing.sm,
              children: [
                for (final v in vehicles)
                  ChoiceChip(
                    label: Text(v.name),
                    selected: id == v.id,
                    onSelected: (_) => setState(() => _vehicleId = v.id),
                  ),
              ],
            ),
    );
  }
}

class _PeopleStep extends StatefulWidget {
  const _PeopleStep(this.s, {required this.setup});

  final SetupStepContext s;
  final RidesSetupLoaded setup;

  @override
  State<_PeopleStep> createState() => _PeopleStepState();
}

class _PeopleStepState extends State<_PeopleStep> {
  late String? _driver = switch (widget.s.answer) {
    {'driver': final String d} => d,
    _ => null,
  };
  late final Set<String> _passengers = switch (widget.s.answer) {
    {'passengers': final List<Object?> p} => {
      for (final id in p)
        if (id is String) id,
    },
    _ => <String>{},
  };

  void _next() => widget.s.onNext(
    commutePeopleAnswer(
      driverId: _driver,
      passengerIds: [
        for (final m in widget.setup.members)
          if (_passengers.contains(m.id) && m.id != _driver) m.id,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final members = widget.setup.members;
    Widget avatar(String id, String name) => ExcludeSemantics(
      child: MemberAvatar(memberId: id, name: name, size: Sizes.avatarSmall),
    );
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.commutePeopleTitle,
      visual: const StepIconVisual(Icons.people_outline),
      onNext: _next,
      onSkip: widget.s.onSkip,
      onBack: widget.s.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(l10n.templateDriverSection),
          Wrap(
            spacing: Spacing.sm,
            children: [
              ChoiceChip(
                label: Text(l10n.templateDriverNone),
                selected: _driver == null,
                onSelected: (_) => setState(() => _driver = null),
              ),
              for (final m in members)
                ChoiceChip(
                  avatar: avatar(m.id, m.name),
                  label: Text(m.name),
                  selected: _driver == m.id,
                  onSelected: (_) => setState(() {
                    _driver = m.id;
                    _passengers.remove(m.id);
                  }),
                ),
            ],
          ),
          heading(l10n.templatePassengersSection),
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final m in members)
                if (m.id != _driver)
                  FilterChip(
                    avatar: avatar(m.id, m.name),
                    label: Text(m.name),
                    selected: _passengers.contains(m.id),
                    onSelected: (on) => setState(
                      () =>
                          on ? _passengers.add(m.id) : _passengers.remove(m.id),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TollsStep extends StatefulWidget {
  const _TollsStep(this.s, {required this.currency});

  final SetupStepContext s;
  final Currency currency;

  @override
  State<_TollsStep> createState() => _TollsStepState();
}

class _TollsStepState extends State<_TollsStep> {
  late int? _cents = widget.s.answer is int ? widget.s.answer! as int : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cents = _cents;
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.commuteTollsTitle,
      visual: const StepIconVisual(Icons.toll_outlined),
      onNext: () => cents == null || cents <= 0
          ? widget.s.onSkip?.call()
          : widget.s.onNext(cents),
      onSkip: widget.s.onSkip,
      onBack: widget.s.onBack,
      child: AmountField(
        currency: widget.currency,
        cents: _cents,
        autofocus: true,
        label: l10n.templateTollsLabel,
        onChanged: (c) => setState(() => _cents = c),
      ),
    );
  }
}
