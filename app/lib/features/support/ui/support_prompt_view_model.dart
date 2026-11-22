import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio/features/support/data/support_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The one quiet line on the "all settled" screen (ADR-28 §2). The state is
/// whether it is visible. It appears at most once per
/// [supportPromptEverySettlements] settled screens and never twice within
/// [supportPromptMinGap]; "Nicht mehr zeigen" is permanent. The line never
/// shows while the remote flag is off, and nothing is counted then.
class SupportPromptViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  /// Call once when the "all settled" screen is reached. Decides whether the
  /// line shows. A passive hint: when the local state cannot be read or
  /// saved nothing is shown, because no user action failed.
  Future<void> settledScreenReached() async {
    final repo = ref.read(supportRepositoryProvider);
    if (!await repo.tipsEnabled()) return;
    final read = await repo.promptState();
    final prompt = switch (read) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (prompt == null || prompt.dismissed) return;
    final now = ref.read(clockProvider).now();
    final count = prompt.settledSinceShown + 1;
    final last = prompt.lastShown;
    final age = last == null ? null : now.difference(last);
    // A clock set back leaves the stamp in the future: not yet.
    final gapOver =
        age == null || (!age.isNegative && age >= supportPromptMinGap);
    final show = count >= supportPromptEverySettlements && gapOver;
    final saved = await repo.savePromptState(
      show
          ? SupportPromptState(lastShown: now)
          : prompt.copyWith(settledSinceShown: count),
    );
    if (!ref.mounted) return;
    state = show && saved is Ok;
  }

  /// "Nicht mehr zeigen". An `Err` means the choice was not saved: the line
  /// stays and the view says so.
  Future<RepoResult<void>> dismissForever() async {
    final repo = ref.read(supportRepositoryProvider);
    final read = await repo.promptState();
    final result = switch (read) {
      Ok(:final value) => await repo.savePromptState(
        value.copyWith(dismissed: true),
      ),
      Err(:final error) => Err<void, RepositoryError>(error),
    };
    if (ref.mounted && result is Ok) state = false;
    return result;
  }
}

// ignore: specify_nonobvious_property_types, the autoDispose provider type is not exported
final supportPromptViewModelProvider =
    NotifierProvider.autoDispose<SupportPromptViewModel, bool>(
      SupportPromptViewModel.new,
    );
