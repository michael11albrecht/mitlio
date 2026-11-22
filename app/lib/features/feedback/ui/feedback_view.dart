import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/features/feedback/ui/feedback_error_text.dart';
import 'package:mitlio/features/feedback/ui/feedback_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Settings > Feedback (ADR-29): type chips, one text box, optional
/// screenshots, optional reply address, opt-in app info with a visible
/// preview. One screen, no dialogs; the draft stays when sending fails.
class FeedbackView extends ConsumerStatefulWidget {
  const FeedbackView({super.key});

  @override
  ConsumerState<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends ConsumerState<FeedbackView> {
  late final TextEditingController _message;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(feedbackViewModelProvider);
    _message = TextEditingController(text: draft.message);
    _email = TextEditingController(text: draft.email);
    // Left through "back" after sending: start the next report empty.
    if (draft.status == FeedbackStatus.sent) {
      scheduleMicrotask(() {
        if (mounted) ref.read(feedbackViewModelProvider.notifier).reset();
      });
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  // A failure is kept in the state and shown above the send button (nothing
  // to do here but call the command).
  Future<void> _send() async {
    final locale = Localizations.localeOf(context).languageCode == 'de'
        ? 'de'
        : 'en';
    await ref.read(feedbackViewModelProvider.notifier).submit(locale: locale);
  }

  Future<void> _addScreenshot() async {
    await ref.read(feedbackViewModelProvider.notifier).addScreenshots();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(feedbackViewModelProvider);
    final vm = ref.read(feedbackViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackTitle)),
      body: state.status == FeedbackStatus.sent
          ? _Thanks(
              replyHint: _email.text.trim().isNotEmpty,
              onDone: () {
                vm.reset();
                context.pop();
              },
            )
          : _Form(
              state: state,
              message: _message,
              email: _email,
              onSend: () => unawaited(_send()),
              onAddScreenshot: () => unawaited(_addScreenshot()),
            ),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({
    required this.state,
    required this.message,
    required this.email,
    required this.onSend,
    required this.onAddScreenshot,
  });

  final FeedbackState state;
  final TextEditingController message;
  final TextEditingController email;
  final VoidCallback onSend;
  final VoidCallback onAddScreenshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = ref.read(feedbackViewModelProvider.notifier);
    final editing = state.status == FeedbackStatus.editing;
    final typeLabels = {
      FeedbackType.problem: l10n.feedbackTypeProblem,
      FeedbackType.idea: l10n.feedbackTypeIdea,
      FeedbackType.question: l10n.feedbackTypeQuestion,
    };
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: Spacing.screen,
            children: [
              Wrap(
                spacing: Spacing.sm,
                children: [
                  for (final type in FeedbackType.values)
                    ChoiceChip(
                      label: Text(typeLabels[type]!),
                      selected: state.type == type,
                      onSelected: editing ? (_) => vm.setType(type) : null,
                    ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: message,
                enabled: editing,
                onChanged: vm.setMessage,
                minLines: 4,
                maxLines: 10,
                maxLength: feedbackMessageMax,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: l10n.feedbackMessageLabel,
                  helperText: state.messageValid
                      ? null
                      : l10n.feedbackMessageHelper,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                l10n.feedbackPublicNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Semantics(
                header: true,
                child: Text(
                  l10n.feedbackScreenshotsLabel,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final (i, shot) in state.screenshots.indexed)
                    _Thumbnail(
                      shot: shot,
                      removeLabel: l10n.feedbackRemoveScreenshot,
                      onRemove: editing ? () => vm.removeScreenshot(i) : null,
                    ),
                  if (state.canAddScreenshot)
                    OutlinedButton.icon(
                      onPressed: onAddScreenshot,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(l10n.feedbackAddScreenshot),
                    ),
                ],
              ),
              if (state.screenshots.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.feedbackScreenshotsNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.lg),
              TextField(
                controller: email,
                enabled: editing,
                onChanged: vm.setEmail,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.feedbackEmailLabel,
                  errorText: state.emailValid
                      ? null
                      : l10n.feedbackEmailInvalid,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.feedbackDiagnosticsLabel),
                subtitle: Text(
                  l10n.feedbackDiagnosticsPreview(vm.diagnostics.preview),
                ),
                value: state.includeDiagnostics,
                onChanged: editing
                    ? (v) => vm.setIncludeDiagnostics(include: v)
                    : null,
              ),
            ],
          ),
        ),
        // Pinned: the error and the send button are always in reach, however
        // long the form.
        SafeArea(
          minimum: Spacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    feedbackErrorText(l10n, state.error!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
              ],
              FilledButton(
                onPressed: state.canSubmit ? onSend : null,
                child: Text(
                  state.status == FeedbackStatus.sending
                      ? l10n.feedbackSending
                      : l10n.feedbackSend,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.shot,
    required this.removeLabel,
    required this.onRemove,
  });

  final FeedbackScreenshot shot;
  final String removeLabel;
  final VoidCallback? onRemove;

  static const double _size = 88;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _size,
    height: _size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Spacing.sm),
          child: Image.memory(
            shot.bytes,
            fit: BoxFit.cover,
            // A picture the engine cannot decode still counts as picked: the
            // server decides. Show a plain placeholder instead of an error.
            errorBuilder: (_, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.image_outlined),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            tooltip: removeLabel,
            onPressed: onRemove,
            icon: const Icon(Icons.cancel),
          ),
        ),
      ],
    ),
  );
}

class _Thanks extends StatelessWidget {
  const _Thanks({required this.replyHint, required this.onDone});

  final bool replyHint;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: Spacing.screen,
      children: [
        const SizedBox(height: Spacing.xl),
        Icon(Icons.favorite, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: Spacing.md),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            l10n.feedbackThanksTitle,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        if (replyHint) ...[
          const SizedBox(height: Spacing.sm),
          Text(l10n.feedbackThanksReply, textAlign: TextAlign.center),
        ],
        const SizedBox(height: Spacing.lg),
        FilledButton(onPressed: onDone, child: Text(l10n.feedbackDone)),
      ],
    );
  }
}
