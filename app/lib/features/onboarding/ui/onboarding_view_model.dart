import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The first-run screen has nothing to show but whether a path is running.
final class OnboardingState {
  const OnboardingState({this.busy = false});

  /// A group is being created; further taps are ignored.
  final bool busy;
}

/// First run: the commute path creates the group here; the expense path
/// opens the regular group form and the plain trip calculation opens the trip
/// form without a group, so neither needs a command.
class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  /// Creates the commute group ([groupName] is the localised default, the
  /// user can rename it later). The View continues with car and route.
  Future<RepoResult<Group>> startCommute({required String groupName}) async {
    if (state.busy) return const Err(InvalidData('already creating a group'));
    state = const OnboardingState(busy: true);
    try {
      return await ref
          .read(groupsViewModelProvider.notifier)
          .create(name: groupName, currency: Currency.eur);
    } finally {
      if (ref.mounted) state = const OnboardingState();
    }
  }
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
