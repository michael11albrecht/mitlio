import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/core/ui/setup_flow/yes_no_step.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/features/profile/ui/iban_input.dart';
import 'package:mitlio/features/profile/ui/profile_card.dart';
import 'package:mitlio/features/profile/ui/profile_photo_view_model.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The profile flow (PU-T07, ADR-25 §4): name, avatar, PayPal yes/no and
/// PayPal.Me, bank transfer yes/no and IBAN, then the profile card. Reached
/// from Settings "Mein Profil". Every step but the name can be skipped.
class ProfileSetupView extends ConsumerWidget {
  const ProfileSetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SetupFlowView(
      config: profileSetupFlow,
      stepBuilder: (context, s) => switch (s.step.id) {
        profileStepName => _NameStep(s),
        profileStepAvatar => _AvatarStep(s),
        profileStepPaypalWanted => YesNoStep(
          current: s.current,
          total: s.total,
          title: l10n.profilePaypalAskTitle,
          visual: const _VisualSlot(Icons.account_balance_wallet_outlined),
          selected: s.answer as bool?,
          onAnswer: s.onNext,
          onSkip: s.onSkip,
          onBack: s.onBack,
        ),
        profileStepPaypalMe => _PaypalMeStep(s),
        profileStepBankWanted => YesNoStep(
          current: s.current,
          total: s.total,
          title: l10n.profileBankAskTitle,
          visual: const _VisualSlot(Icons.qr_code_2),
          selected: s.answer as bool?,
          onAnswer: s.onNext,
          onSkip: s.onSkip,
          onBack: s.onBack,
        ),
        _ => _IbanStep(s),
      },
      finishBuilder: (context, back) => _Finish(onBack: back),
    );
  }
}

/// A calm placeholder where the illustration of the step goes (PU-T06).
class _VisualSlot extends StatelessWidget {
  const _VisualSlot(this.icon, {this.height = Sizes.stepVisual});

  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: Radii.lgAll,
        ),
        child: Icon(icon, size: height / 2, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _NameStep extends ConsumerStatefulWidget {
  const _NameStep(this.s);

  final SetupStepContext s;

  @override
  ConsumerState<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<_NameStep> {
  late final _name = TextEditingController(
    text: widget.s.answer is String ? widget.s.answer! as String : '',
  );
  bool _missing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_name.text.trim().isEmpty || _name.text.trim().length > 60) {
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
      title: l10n.profileNameTitle,
      visual: ValueListenableBuilder(
        valueListenable: _name,
        builder: (context, value, _) => ProfileAvatar(
          name: value.text,
          photo: ref.watch(profilePhotoViewModelProvider).photo,
          size: Sizes.profileAvatar,
        ),
      ),
      onNext: _next,
      onSkip: widget.s.onSkip,
      onBack: widget.s.onBack,
      child: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        maxLength: 60,
        decoration: InputDecoration(
          labelText: l10n.profileNameLabel,
          errorText: _missing ? l10n.profileNameRequired : null,
        ),
        onChanged: (_) {
          if (_missing) setState(() => _missing = false);
        },
        onSubmitted: (_) => _next(),
      ),
    );
  }
}

const _avatarEmojis = [
  '🚗',
  '🚲',
  '🚌',
  '🌻',
  '🐶',
  '🐱',
  '🦊',
  '🎸',
  '⚽',
  '☕',
  '🌈',
  '⭐',
];

class _AvatarStep extends ConsumerStatefulWidget {
  const _AvatarStep(this.s);

  final SetupStepContext s;

  @override
  ConsumerState<_AvatarStep> createState() => _AvatarStepState();
}

class _AvatarStepState extends ConsumerState<_AvatarStep> {
  int? _color;
  String? _emoji;

  @override
  void initState() {
    super.initState();
    if (widget.s.answer case final Map<Object?, Object?> saved) {
      _color = saved[profileAnswerColor] as int?;
      _emoji = saved[profileAnswerEmoji] as String?;
    }
  }

  Future<void> _pick(
    Future<RepoResult<PhotoOutcome>> Function(ProfilePhotoViewModel vm) ask,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final result = await ask(ref.read(profilePhotoViewModelProvider.notifier));
    final message = switch (result) {
      Err(:final error) => repositoryErrorMessage(l10n, error),
      Ok(value: PhotoOutcome.denied) => l10n.profilePhotoDenied,
      Ok(value: PhotoOutcome.unusable) => l10n.profilePhotoUnusable,
      Ok() => null,
    };
    if (message == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _removePhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(profilePhotoViewModelProvider.notifier)
        .remove();
    if (result case Err(:final error)) {
      showErrorSnackBar(messenger, l10n, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    ref.listen(profilePhotoViewModelProvider.select((s) => s.loadError), (
      _,
      error,
    ) {
      if (error != null) {
        showErrorSnackBar(ScaffoldMessenger.of(context), l10n, error);
      }
    });
    final photo = ref.watch(profilePhotoViewModelProvider);
    final name =
        ref
                .watch(setupFlowViewModelProvider(profileSetupFlow))
                .answerOf(profileStepName)
            as String? ??
        '';
    final palette = MitlioColors.of(context).avatars;
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.profileAvatarTitle,
      visual: ProfileAvatar(
        name: name,
        color: _color,
        emoji: _emoji,
        photo: photo.photo,
        size: Sizes.profileAvatar,
      ),
      onNext: () => widget.s.onNext({
        profileAnswerColor: _color,
        profileAnswerEmoji: _emoji,
      }),
      onSkip: widget.s.onSkip,
      onBack: widget.s.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo.canPick || photo.photo != null) ...[
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                if (photo.canPick) ...[
                  OutlinedButton.icon(
                    onPressed: () => _pick((vm) => vm.takePhoto()),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.profilePhotoCamera),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pick((vm) => vm.chooseFromGallery()),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.profilePhotoGallery),
                  ),
                ],
                if (photo.photo != null)
                  TextButton(
                    onPressed: _removePhoto,
                    child: Text(l10n.profilePhotoRemove),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.profilePhotoLocalOnly,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (var i = 0; i < palette.length; i++)
                _Choice(
                  label: l10n.profileAvatarColor(i + 1),
                  selected: _color == palette[i].background.toARGB32(),
                  onTap: () => setState(
                    () => _color = palette[i].background.toARGB32(),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette[i].background,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: Sizes.avatar),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              _Choice(
                label: l10n.profileAvatarInitials,
                selected: _emoji == null,
                onTap: () => setState(() => _emoji = null),
                child: SizedBox.square(
                  dimension: Sizes.avatar,
                  child: Center(
                    child: Text(
                      MemberAvatar.initials(name),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              for (final emoji in _avatarEmojis)
                _Choice(
                  label: l10n.profileAvatarEmoji(emoji),
                  selected: _emoji == emoji,
                  onTap: () => setState(() => _emoji = emoji),
                  child: SizedBox.square(
                    dimension: Sizes.avatar,
                    child: Center(
                      child: Text(
                        emoji,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A round pick with a ring when selected; at least a tap target big.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: Sizes.tapTarget / 2,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(
            width: Sizes.tapTarget,
            height: Sizes.tapTarget,
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipOval(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaypalMeStep extends ConsumerStatefulWidget {
  const _PaypalMeStep(this.s);

  final SetupStepContext s;

  @override
  ConsumerState<_PaypalMeStep> createState() => _PaypalMeStepState();
}

class _PaypalMeStepState extends ConsumerState<_PaypalMeStep> {
  late final _handle = TextEditingController(
    text: widget.s.answer is String ? 'paypal.me/${widget.s.answer}' : '',
  );
  bool _showInvalid = false;

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  PaypalMeHandle? get _parsed => switch (PaypalMeHandle.parse(_handle.text)) {
    Ok(:final value) => value,
    Err() => null,
  };

  void _next() {
    if (_parsed == null) {
      setState(() => _showInvalid = true);
      return;
    }
    widget.s.onNext(_handle.text);
  }

  Future<void> _test() async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = AppLocalizations.of(context).profilePaypalLinkCopied;
    final outcome = await ref
        .read(profileSetupViewModelProvider)
        .openPaypalLink(_handle.text);
    if (!mounted) return;
    switch (outcome) {
      case PaypalLinkOutcome.opened:
        break;
      case PaypalLinkOutcome.invalid:
        setState(() => _showInvalid = true);
      case PaypalLinkOutcome.copied:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(copied)));
    }
  }

  Future<void> _create() async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = AppLocalizations.of(context).profilePaypalLinkCopied;
    final opened = await ref
        .read(profileSetupViewModelProvider)
        .openCreatePaypalMe();
    if (!mounted || opened) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final parsed = _parsed;
    final invalid = _handle.text.trim().isNotEmpty && parsed == null;
    final helps = [
      l10n.profilePaypalHelp1,
      l10n.profilePaypalHelp2,
      l10n.profilePaypalHelp3,
      l10n.profilePaypalHelp4,
    ];
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.profilePaypalTitle,
      visual: const _VisualSlot(Icons.link),
      onNext: _next,
      onSkip: widget.s.onSkip,
      onBack: widget.s.onBack,
      result: parsed == null
          ? null
          : Text(
              l10n.profilePaypalResult(parsed.format()),
              style: theme.textTheme.titleMedium,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _handle,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.profilePaypalLabel,
              hintText: l10n.profilePaypalHint,
              errorText: invalid || _showInvalid && parsed == null
                  ? l10n.profilePaypalInvalid
                  : null,
              errorMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _next(),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: parsed == null ? null : () => unawaited(_test()),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.profilePaypalTest),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => unawaited(_create()),
              child: Text(l10n.profilePaypalCreate),
            ),
          ),
          ExpansionTile(
            title: Text(l10n.profilePaypalHelpTitle),
            children: [
              for (var i = 0; i < helps.length; i++)
                ListTile(
                  leading: const _VisualSlot(
                    Icons.phone_android,
                    height: Sizes.avatar,
                  ),
                  title: Text('${i + 1}. ${helps[i]}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IbanStep extends ConsumerStatefulWidget {
  const _IbanStep(this.s);

  final SetupStepContext s;

  @override
  ConsumerState<_IbanStep> createState() => _IbanStepState();
}

class _IbanStepState extends ConsumerState<_IbanStep> {
  final _iban = TextEditingController();
  late final _holder = TextEditingController(
    text:
        ref
                .read(setupFlowViewModelProvider(profileSetupFlow))
                .answerOf(profileStepName)
            as String? ??
        '',
  );
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Coming back to the step: show what is stored. The IBAN is not in the
    // flow's answers, only here.
    if (widget.s.answer != null) unawaited(_prefill());
  }

  Future<void> _prefill() async {
    final stored = await ref.read(profileSetupViewModelProvider).storedBank();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    switch (stored) {
      case Ok(value: final bank?):
        setState(() {
          _iban.text = formatIban(bank.iban);
          _holder.text = bank.accountName ?? _holder.text;
        });
      case Ok():
        break;
      case Err(:final error):
        showErrorSnackBar(messenger, l10n, error);
    }
  }

  @override
  void dispose() {
    _iban.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final messenger = ScaffoldMessenger.of(context);
    final empty = AppLocalizations.of(context).profileIbanPasteEmpty;
    final text = await ref.read(profileSetupViewModelProvider).paste();
    if (!mounted) return;
    if (text == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(empty)));
      return;
    }
    setState(() => _iban.text = formatIban(text));
  }

  void _next() {
    final valid =
        checkIban(_iban.text) == IbanCheck.valid &&
        _holder.text.trim().isNotEmpty;
    if (!valid) {
      setState(() => _submitted = true);
      return;
    }
    widget.s.onNext({
      profileAnswerIban: cleanIban(_iban.text),
      profileAnswerHolder: _holder.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final check = checkIban(_iban.text);
    final shownCheck = check == IbanCheck.empty && _submitted
        ? IbanCheck.badFormat
        : check;
    final (message, isError) = switch (shownCheck) {
      IbanCheck.empty => (null, false),
      IbanCheck.typing => (l10n.profileIbanTyping, false),
      IbanCheck.valid => (l10n.profileIbanValid, false),
      IbanCheck.badFormat => (l10n.profileIbanBadFormat, true),
      IbanCheck.badChecksum => (l10n.profileIbanBadChecksum, true),
    };
    final holderMissing = _submitted && _holder.text.trim().isEmpty;
    final qr = check == IbanCheck.valid && _holder.text.trim().isNotEmpty
        ? buildEpcQrPayload(
            name: _holder.text,
            iban: cleanIban(_iban.text),
            amount: Money(1000, Currency.eur),
          )
        : null;
    return StepScaffold(
      current: widget.s.current,
      total: widget.s.total,
      title: l10n.profileIbanTitle,
      visual: const _VisualSlot(Icons.account_balance),
      onNext: _next,
      onSkip: widget.s.onSkip,
      onBack: widget.s.onBack,
      result: message == null
          ? null
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    size: Sizes.avatarSmall - Spacing.sm,
                    color: isError ? scheme.error : scheme.primary,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isError ? scheme.error : null,
                    ),
                  ),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _iban,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            inputFormatters: const [IbanInputFormatter()],
            decoration: InputDecoration(
              labelText: l10n.profileIbanLabel,
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste),
                tooltip: l10n.profileIbanPaste,
                onPressed: () => unawaited(_paste()),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _holder,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.profileIbanHolderLabel,
              errorText: holderMissing ? l10n.profileIbanHolderRequired : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _next(),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.lock_outline,
                  size: Sizes.avatarSmall - Spacing.sm,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  l10n.profileIbanLocalOnly,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (check == IbanCheck.valid && _holder.text.trim().isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            switch (qr) {
              Ok(:final value) => _QrPreview(data: value),
              _ => Text(
                l10n.profileIbanQrFailed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            },
          ],
        ],
      ),
    );
  }
}

/// The QR code a friend scans to pay, with a sample amount. Black on white
/// in both themes: what banking apps scan reliably.
class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n.profileIbanQrPreview,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.sm),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: Radii.mdAll,
          ),
          child: QrImageView(
            data: data,
            size: Sizes.qrCode,
            padding: Spacing.allMd,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
            semanticsLabel: l10n.profileIbanQrSemantics,
          ),
        ),
      ],
    );
  }
}

class _Finish extends ConsumerWidget {
  const _Finish({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final card = ref.watch(profileCardProvider);
    final preview = switch (card) {
      AsyncData(value: Ok(value: final data?)) => ProfileCard(data: data),
      AsyncData(value: Err(:final error)) => _CardError(error: error),
      AsyncData() => null,
      AsyncError() => ErrorState(
        onRetry: () => ref.invalidate(profileCardProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
    return FinishStep(
      title: l10n.profileFinishTitle,
      preview: preview,
      actionLabel: l10n.setupFinishDone,
      onAction: () => context.canPop() ? context.pop() : context.go('/'),
      onBack: onBack,
    );
  }
}

class _CardError extends ConsumerWidget {
  const _CardError({required this.error});

  final RepositoryError error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ErrorState(
    message: repositoryErrorMessage(AppLocalizations.of(context), error),
    onRetry: () => ref.invalidate(profileCardProvider),
  );
}
