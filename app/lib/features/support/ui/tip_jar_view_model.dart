// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio/features/support/data/support_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

export 'package:mitlio/features/support/data/support_models.dart'
    show TipFailure, TipProduct, TipSize;

sealed class TipJarState {
  const TipJarState();
}

class TipJarLoading extends TipJarState {
  const TipJarLoading();
}

/// The store cannot list the tips; [failure] says why. Retry with `load`.
class TipJarUnavailable extends TipJarState {
  const TipJarUnavailable(this.failure);

  final TipFailure failure;

  @override
  bool operator ==(Object other) =>
      other is TipJarUnavailable && other.failure == failure;

  @override
  int get hashCode => Object.hash(TipJarUnavailable, failure);
}

/// The sizes to pick from. [buying] is the size the store is working on;
/// [error] is why the last purchase failed (a cancel is not an error).
class TipJarReady extends TipJarState {
  const TipJarReady(this.products, {this.buying, this.error});

  final List<TipProduct> products;
  final TipSize? buying;
  final TipFailure? error;
}

/// The thank-you state after a confirmed purchase.
class TipJarThanks extends TipJarState {
  const TipJarThanks();
}

/// The tip jar sheet (ADR-28): three sizes, one tap each, a thank-you.
/// Never part of the settle flow.
class TipJarViewModel extends Notifier<TipJarState> {
  @override
  TipJarState build() => const TipJarLoading();

  /// Asks the store for the sizes and their prices.
  Future<void> load() async {
    state = const TipJarLoading();
    final result = await ref.read(supportRepositoryProvider).tipProducts();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => TipJarReady(value),
      Err(:final error) => TipJarUnavailable(error),
    };
  }

  /// Buys one tip. A second tap while one is running is ignored.
  Future<void> tip(TipSize size) async {
    final current = state;
    if (current is! TipJarReady || current.buying != null) return;
    state = TipJarReady(current.products, buying: size);
    final outcome = await ref.read(supportRepositoryProvider).buyTip(size);
    if (!ref.mounted) return;
    state = switch (outcome) {
      TipThanks() => const TipJarThanks(),
      TipCancelled() => TipJarReady(current.products),
      TipFailed(:final failure) => TipJarReady(
        current.products,
        error: failure,
      ),
    };
  }
}

// ignore: specify_nonobvious_property_types, the autoDispose provider type is not exported
final tipJarViewModelProvider =
    NotifierProvider.autoDispose<TipJarViewModel, TipJarState>(
      TipJarViewModel.new,
    );
