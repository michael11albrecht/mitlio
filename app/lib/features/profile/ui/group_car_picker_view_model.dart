import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Mein Auto" in the vehicle list of a group (ADR-25 §2): the personal cars
/// that have no copy in this group yet, and the command that makes the copy.
/// Loading is the first value; a failure is an [AsyncError] the view shows.
class GroupCarPickerViewModel extends Notifier<AsyncValue<List<Vehicle>>> {
  GroupCarPickerViewModel(this.groupId);

  final String groupId;

  @override
  AsyncValue<List<Vehicle>> build() {
    final personal = ref.watch(userVehiclesRepositoryProvider);
    final group = ref.watch(vehiclesRepositoryProvider);
    final subs = [
      personal.watchVehicles().listen(
        (_) => unawaited(_refresh()),
        onError: _fail,
      ),
      group
          .watchVehicles(groupId)
          .listen(
            (_) => unawaited(_refresh()),
            onError: _fail,
          ),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    return const AsyncLoading();
  }

  void _fail(Object error) {
    if (!ref.mounted) return;
    state = AsyncError(
      error is RepositoryError ? error : Storage(error),
      StackTrace.empty,
    );
  }

  Future<void> _refresh() async {
    final personal = ref.read(userVehiclesRepositoryProvider);
    final group = ref.read(vehiclesRepositoryProvider);
    final List<Vehicle> cars;
    try {
      cars = await personal.watchVehicles().first;
    } on Object catch (e) {
      return _fail(e);
    }
    final free = <Vehicle>[];
    for (final car in cars) {
      switch (await group.linkedCopies(car.id)) {
        case Err(:final error):
          return _fail(error);
        case Ok(:final value):
          if (value.every((c) => c.groupId != groupId)) free.add(car);
      }
    }
    if (ref.mounted) state = AsyncData(List.unmodifiable(free));
  }

  /// Starts over after a failure.
  void retry() {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }

  /// Uses the personal car in this group: creates the linked copy.
  Future<RepoResult<Vehicle>> use(String personalCarId) => ref
      .read(personalCarLinksRepositoryProvider)
      .useInGroup(groupId, personalCarId);
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final groupCarPickerViewModelProvider = NotifierProvider.autoDispose
    .family<GroupCarPickerViewModel, AsyncValue<List<Vehicle>>, String>(
      GroupCarPickerViewModel.new,
    );
