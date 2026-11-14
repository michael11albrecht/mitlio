import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_prices_repository.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_providers.dart';

export 'package:mitlio/features/fuel/data/fuel_price.dart'
    show FuelFailure, FuelGrade, FuelPrice, FuelScope;

/// A price the forms should write into their price field.
final class FuelFill {
  const FuelFill({
    required this.seq,
    required this.priceMilli,
    required this.auto,
  });

  /// Grows with every fill, so listeners can tell a new one from the old.
  final int seq;
  final int priceMilli;

  /// Came without a tap (the pre-selected grade); forms only take it into an
  /// empty field.
  final bool auto;
}

/// State of the price chips: which grade and scope, the current quote (maybe
/// stale) and what went wrong. [available] false means: show nothing.
final class FuelPriceState {
  const FuelPriceState({
    required this.available,
    required this.grade,
    this.scope = FuelScope.national,
    this.loading = false,
    this.price,
    this.stale = false,
    this.age = Duration.zero,
    this.failure,
    this.canLocate = false,
    this.fill,
  });

  /// A backend is configured; otherwise the chips are hidden.
  final bool available;
  final FuelGrade grade;

  /// The scope the user asked for (the quote may be an older one).
  final FuelScope scope;
  final bool loading;
  final FuelPrice? price;

  /// The quote is the last known one because the lookup failed.
  final bool stale;

  /// How old the quote was when it was shown.
  final Duration age;
  final FuelFailure? failure;

  /// "In meiner Nähe" can be offered.
  final bool canLocate;
  final FuelFill? fill;

  FuelPriceState copyWith({
    FuelGrade? grade,
    FuelScope? scope,
    bool? loading,
    FuelPrice? price,
    bool? stale,
    Duration? age,
    FuelFailure? failure,
    bool? canLocate,
    FuelFill? fill,
    bool clearFailure = false,
  }) => FuelPriceState(
    available: available,
    grade: grade ?? this.grade,
    scope: scope ?? this.scope,
    loading: loading ?? this.loading,
    price: price ?? this.price,
    stale: stale ?? this.stale,
    age: age ?? this.age,
    failure: clearFailure ? null : failure ?? this.failure,
    canLocate: canLocate ?? this.canLocate,
    fill: fill ?? this.fill,
  );
}

/// Price chips (E5 / E10 / Diesel) behind the fuel price fields. Starts on
/// the national average of [initialGrade] without any location; a postcode
/// or the position only on the user's explicit command.
class FuelPriceViewModel extends Notifier<FuelPriceState> {
  FuelPriceViewModel(this.initialGrade);

  final FuelGrade initialGrade;

  var _fillSeq = 0;

  /// Drops answers of lookups that were overtaken by a newer one.
  var _generation = 0;

  FuelPricesRepository get _repo => ref.read(fuelPricesRepositoryProvider);

  @override
  FuelPriceState build() {
    final repo = ref.watch(fuelPricesRepositoryProvider);
    if (repo.isAvailable) unawaited(Future.microtask(() => _run(auto: true)));
    return FuelPriceState(
      available: repo.isAvailable,
      grade: initialGrade,
      canLocate: repo.canLocate,
    );
  }

  /// Picks [grade] and fills its price.
  Future<void> selectGrade(FuelGrade grade) async {
    state = state.copyWith(grade: grade);
    await _run(auto: false);
  }

  /// Back to the national average.
  Future<void> useNational() async {
    state = state.copyWith(scope: FuelScope.national);
    _plz = null;
    await _run(auto: false);
  }

  String? _plz;

  /// The average around a typed postcode; a malformed one is
  /// `FuelFailure.invalidParams` and changes nothing else.
  Future<void> usePlz(String plz) async {
    final text = plz.trim();
    if (!PlzArea.isValid(text)) {
      state = state.copyWith(failure: FuelFailure.invalidParams);
      return;
    }
    _plz = text;
    state = state.copyWith(scope: FuelScope.plz);
    await _run(auto: false);
  }

  /// The average around the device position. Asks for the permission now;
  /// denied or failing, the national average stays.
  Future<void> useNearby() async {
    if (!_repo.canLocate) return;
    final generation = ++_generation;
    state = state.copyWith(loading: true, clearFailure: true);
    final outcome = await _repo.nearby(state.grade);
    if (!ref.mounted || generation != _generation) return;
    if (outcome case FuelMissing(:final reason)) {
      // Nothing changes but the hint; nearby may also be gone for good.
      state = state.copyWith(
        loading: false,
        failure: reason,
        canLocate: _repo.canLocate,
      );
      return;
    }
    state = state.copyWith(scope: FuelScope.nearby);
    _apply(outcome, auto: false);
  }

  Future<void> _run({required bool auto}) async {
    final generation = ++_generation;
    state = state.copyWith(loading: true, clearFailure: true);
    final grade = state.grade;
    final outcome = switch (state.scope) {
      FuelScope.plz when _plz != null => await _repo.forPlz(grade, _plz!),
      FuelScope.nearby => await _repo.nearby(grade),
      _ => await _repo.national(grade),
    };
    if (!ref.mounted || generation != _generation) return;
    _apply(outcome, auto: auto);
  }

  void _apply(FuelOutcome outcome, {required bool auto}) {
    switch (outcome) {
      case FuelFound(:final price, :final stale):
        final age = ref.read(clockProvider).now().difference(price.fetchedAt);
        state = state.copyWith(
          loading: false,
          price: price,
          stale: stale,
          age: age.isNegative ? Duration.zero : age,
          clearFailure: true,
          canLocate: _repo.canLocate,
          fill: FuelFill(
            seq: ++_fillSeq,
            priceMilli: price.priceMilli,
            auto: auto,
          ),
        );
      case FuelMissing(:final reason):
        state = state.copyWith(
          loading: false,
          failure: reason,
          canLocate: _repo.canLocate,
        );
    }
  }

  JsonMap debugSnapshot() => {
    'available': state.available,
    'grade': state.grade.name,
    'scope': state.scope.name,
    'priceMilli': state.price?.priceMilli,
    'stale': state.stale,
    'failure': state.failure?.name,
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final fuelPriceViewModelProvider = NotifierProvider.autoDispose
    .family<FuelPriceViewModel, FuelPriceState, FuelGrade>(
      FuelPriceViewModel.new,
    );
