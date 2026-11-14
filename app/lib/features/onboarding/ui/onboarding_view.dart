import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/brand_mark.dart';
import 'package:mitlio/features/onboarding/ui/onboarding_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// First run as its own route (`/welcome`, DebugDrive navigate, goldens).
/// Home shows the same [OnboardingBody] while no group exists.
class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).appName)),
    body: const OnboardingBody(),
  );
}

/// One calm screen: what mitlio is in a line, two ways to begin, and a quiet
/// link for just one trip. No carousel, no sign-up, no permission prompts.
class OnboardingBody extends ConsumerWidget {
  const OnboardingBody({super.key});

  Future<void> _startCommute(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final result = await ref
        .read(onboardingViewModelProvider.notifier)
        .startCommute(groupName: l10n.onboardingCommuteGroupName);
    switch (result) {
      case Ok(:final value):
        // Rides tab: it asks for the people first, then car and route.
        unawaited(router.push('/groups/${value.id}?tab=rides'));
      case Err(error: InvalidData()):
        break; // Busy: the first tap is already on its way.
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorTitle)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final busy = ref.watch(onboardingViewModelProvider).busy;
    return Center(
      child: SingleChildScrollView(
        padding: Spacing.allLg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Sizes.contentMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(child: BrandMark()),
              const SizedBox(height: Spacing.lg),
              Semantics(
                header: true,
                child: Text(
                  l10n.onboardingTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                l10n.onboardingValue,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: muted),
              ),
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => unawaited(_startCommute(context, ref)),
                child: Text(l10n.onboardingCommute),
              ),
              _Hint(l10n.onboardingCommuteHint),
              const SizedBox(height: Spacing.md),
              FilledButton.tonal(
                onPressed: () => unawaited(context.push('/groups/new')),
                child: Text(l10n.onboardingGroup),
              ),
              _Hint(l10n.onboardingGroupHint),
              const SizedBox(height: Spacing.md),
              TextButton(
                onPressed: () => unawaited(context.push('/trip')),
                child: Text(l10n.onboardingTripOnly),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
