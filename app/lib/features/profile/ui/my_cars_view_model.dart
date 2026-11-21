import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What "Meine Autos" shows. No cars is [MyCarsLoaded] with an empty list.
sealed class MyCarsState {
  const MyCarsState();
}

final class MyCarsLoading extends MyCarsState {
  const MyCarsLoading();
}

final class MyCarsFailure extends MyCarsState {
  const MyCarsFailure(this.error);

  final RepositoryError error;
}

final class MyCarsLoaded extends MyCarsState {
  const MyCarsLoaded(this.cars);

  final List<Vehicle> cars;
}

/// "Meine Autos": the personal vehicles (ADR-25 §2) and removing one with
/// undo. Adding a car is the car flow (`CarSetupViewModel`).
class MyCarsViewModel extends Notifier<MyCarsState> {
  @override
  MyCarsState build() {
    final sub = ref
        .watch(userVehiclesRepositoryProvider)
        .watchVehicles()
        .listen(
          (cars) => _set(MyCarsLoaded(cars)),
          onError: (Object e) =>
              _set(MyCarsFailure(e is RepositoryError ? e : Storage(e))),
        );
    ref.onDispose(() => unawaited(sub.cancel()));
    return const MyCarsLoading();
  }

  void _set(MyCarsState next) {
    if (ref.mounted) state = next;
  }

  /// Starts over after a failure.
  void retry() {
    state = const MyCarsLoading();
    ref.invalidateSelf();
  }

  /// Removes the car; call the returned [Undo] to bring it back.
  Future<RepoResult<Undo>> remove(String id) =>
      ref.read(userVehiclesRepositoryProvider).softDelete(id);

  /// The cars as of now (for DebugDrive; the UI watches the state).
  List<Vehicle> get cars => switch (state) {
    MyCarsLoaded(:final cars) => cars,
    _ => const [],
  };
}

final myCarsViewModelProvider = NotifierProvider<MyCarsViewModel, MyCarsState>(
  MyCarsViewModel.new,
);
