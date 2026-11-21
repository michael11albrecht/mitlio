import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Whether a group vehicle is a linked copy of a personal car (ADR-25 §2),
/// and the command that ends the link so the copy can diverge. Loading is the
/// first value; a failure is an [AsyncError] the view shows.
class VehicleLinkViewModel extends Notifier<AsyncValue<bool>> {
  VehicleLinkViewModel(this.vehicleId);

  final String vehicleId;

  @override
  AsyncValue<bool> build() {
    unawaited(_load());
    return const AsyncLoading();
  }

  Future<void> _load() async {
    final source = await ref
        .read(vehiclesRepositoryProvider)
        .sourceOf(vehicleId);
    if (!ref.mounted) return;
    state = switch (source) {
      Ok(:final value) => AsyncData(value != null),
      Err(:final error) => AsyncError(error, StackTrace.empty),
    };
  }

  /// Starts over after a failure.
  void retry() {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }

  /// The copy keeps its values and no longer follows the personal car.
  Future<RepoResult<void>> unlink() async {
    final result = await ref.read(vehiclesRepositoryProvider).unlink(vehicleId);
    if (result is Ok && ref.mounted) state = const AsyncData(false);
    return result;
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final vehicleLinkViewModelProvider = NotifierProvider.autoDispose
    .family<VehicleLinkViewModel, AsyncValue<bool>, String>(
      VehicleLinkViewModel.new,
    );
