import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/amount_field.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/features/rides/ui/milli_field.dart';
import 'package:mitlio/features/rides/ui/template_form_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Add a ride template to [groupId], or with [templateId] edit the stored
/// one: name, one-way distance, round trip, car, usual driver and
/// passengers, tolls. The usual driver and passengers are what the quick
/// log pre-selects.
class TemplateFormView extends ConsumerStatefulWidget {
  const TemplateFormView({required this.groupId, this.templateId, super.key});

  final String groupId;
  final String? templateId;

  @override
  ConsumerState<TemplateFormView> createState() => _TemplateFormViewState();
}

class _TemplateFormViewState extends ConsumerState<TemplateFormView> {
  final _name = TextEditingController();

  TemplateFormKey get _key =>
      (groupId: widget.groupId, templateId: widget.templateId);

  @override
  void initState() {
    super.initState();
    // Fill the name once with the stored value; later edits are the user's.
    ref.listenManual(templateFormViewModelProvider(_key), (prev, next) {
      if (prev is! TemplateFormReady && next is TemplateFormReady) {
        _name.text = next.name;
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final result = await ref
        .read(templateFormViewModelProvider(_key).notifier)
        .save();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(templateFormViewModelProvider(_key).notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.templateId == null
              ? l10n.templateFormNew
              : l10n.templateFormEdit,
        ),
      ),
      body: switch (ref.watch(templateFormViewModelProvider(_key))) {
        TemplateFormLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        TemplateFormFailure() => ErrorState(onRetry: vm.retry),
        final TemplateFormReady form => Column(
          children: [
            Expanded(
              child: _FormBody(
                groupId: widget.groupId,
                form: form,
                vm: vm,
                name: _name,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: Spacing.screen,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: form.saving ? null : () => unawaited(_save()),
                    child: Text(l10n.templateSave),
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
    required this.groupId,
    required this.form,
    required this.vm,
    required this.name,
  });

  final String groupId;
  final TemplateFormReady form;
  final TemplateFormViewModel vm;
  final TextEditingController name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: Spacing.screen,
      children: [
        TextField(
          controller: name,
          autofocus: !form.editing,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          onChanged: vm.setName,
          decoration: InputDecoration(
            labelText: l10n.templateNameLabel,
            hintText: l10n.templateNameHint,
            errorText: form.showErrors && form.nameMissing
                ? l10n.templateErrorName
                : null,
          ),
        ),
        const SizedBox(height: Spacing.md),
        MilliField(
          label: l10n.templateDistanceLabel,
          suffix: 'km',
          milli: form.distanceMeters,
          onChanged: vm.setDistance,
          errorText: form.showErrors && form.distanceMissing
              ? l10n.templateErrorDistance
              : null,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.templateRoundTrip),
          value: form.roundTrip,
          onChanged: (on) => vm.setRoundTrip(on: on),
        ),
        _Section(l10n.templateVehicleSection),
        if (form.vehicles.isEmpty) ...[
          Text(l10n.templateNoVehicle),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => unawaited(
                context.push('/groups/$groupId/rides/vehicles/new'),
              ),
              child: Text(l10n.templateNoVehicleAction),
            ),
          ),
        ] else
          Wrap(
            spacing: Spacing.sm,
            children: [
              for (final v in form.vehicles)
                ChoiceChip(
                  label: Text(v.name),
                  selected: form.vehicleId == v.id,
                  onSelected: (_) => vm.setVehicle(v.id),
                ),
            ],
          ),
        _Section(l10n.templateDriverSection),
        Wrap(
          spacing: Spacing.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.templateDriverNone),
              selected: form.defaultDriverId == null,
              onSelected: (_) => vm.setDefaultDriver(null),
            ),
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
                selected: form.defaultDriverId == m.id,
                onSelected: (_) => vm.setDefaultDriver(m.id),
              ),
          ],
        ),
        _Section(l10n.templatePassengersSection),
        Wrap(
          spacing: Spacing.sm,
          children: [
            for (final m in form.members)
              if (m.id != form.defaultDriverId)
                FilterChip(
                  avatar: ExcludeSemantics(
                    child: MemberAvatar(
                      memberId: m.id,
                      name: m.name,
                      size: Sizes.avatarSmall,
                    ),
                  ),
                  label: Text(m.name),
                  selected: form.defaultPassengerIds.contains(m.id),
                  onSelected: (_) => vm.togglePassenger(m.id),
                ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        AmountField(
          currency: form.group.currency,
          cents: form.tollsCents,
          label: l10n.templateTollsLabel,
          onChanged: vm.setTolls,
        ),
        const SizedBox(height: Spacing.md),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
