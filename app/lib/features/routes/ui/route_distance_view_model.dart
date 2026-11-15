import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/routes/data/repositories/places_repository.dart';
import 'package:mitlio/features/routes/data/repositories/route_distance_repository.dart';
import 'package:mitlio/features/routes/data/repositories/route_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

export 'package:mitlio/features/routes/data/route_models.dart'
    show PlaceKind, PlaceSuggestion, RouteFailure, SavedPlace;

/// Start or destination.
enum RouteField { start, end }

/// A one-way distance the form should write into its kilometre field.
final class RouteFill {
  const RouteFill({required this.seq, required this.meters});

  /// Grows with every fill, so listeners can tell a new one from the old.
  final int seq;
  final int meters;
}

/// State of the "Strecke berechnen" panel. [available] false means: show
/// nothing, the form has only its manual kilometre field.
final class RouteDistanceState {
  const RouteDistanceState({
    required this.available,
    this.start,
    this.end,
    this.active,
    this.suggestions = const [],
    this.searching = false,
    this.searched = false,
    this.calculating = false,
    this.meters,
    this.calculatedFor,
    this.attribution = '',
    this.failure,
    this.retryAfter,
    this.manualOverride = false,
    this.saved = const [],
    this.fill,
  });

  final bool available;
  final PlaceSuggestion? start;
  final PlaceSuggestion? end;

  /// The field the suggestions belong to.
  final RouteField? active;
  final List<PlaceSuggestion> suggestions;
  final bool searching;

  /// A search for the current text finished (so an empty list means "no
  /// match", not "not asked yet").
  final bool searched;
  final bool calculating;

  /// The last calculated one-way distance in metres.
  final int? meters;

  /// Which pair [meters] belongs to.
  final (PlaceSuggestion, PlaceSuggestion)? calculatedFor;

  /// Credit line of the provider data shown, from the server.
  final String attribution;
  final RouteFailure? failure;

  /// The wait the server asked for after a rate limit.
  final Duration? retryAfter;

  /// The user typed into the kilometre field after the last fill: changing
  /// places never overwrites it, only "Neu berechnen" does.
  final bool manualOverride;
  final List<SavedPlace> saved;
  final RouteFill? fill;

  bool get bothPicked => start != null && end != null;

  /// "Neu berechnen" is offered: both places are chosen, but the kilometre
  /// field does not hold their distance (edited by hand, places changed, or
  /// the last lookup failed).
  bool get canRecalculate {
    final from = start;
    final to = end;
    if (!available || calculating || from == null || to == null) return false;
    return manualOverride || calculatedFor != (from, to);
  }

  SavedPlace? savedOf(PlaceKind kind) {
    for (final s in saved) {
      if (s.kind == kind) return s;
    }
    return null;
  }

  RouteDistanceState copyWith({
    PlaceSuggestion? start,
    PlaceSuggestion? end,
    RouteField? active,
    List<PlaceSuggestion>? suggestions,
    bool? searching,
    bool? searched,
    bool? calculating,
    int? meters,
    (PlaceSuggestion, PlaceSuggestion)? calculatedFor,
    String? attribution,
    RouteFailure? failure,
    Duration? retryAfter,
    bool? manualOverride,
    List<SavedPlace>? saved,
    RouteFill? fill,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearFailure = false,
  }) => RouteDistanceState(
    available: available,
    start: clearStart ? null : start ?? this.start,
    end: clearEnd ? null : end ?? this.end,
    active: active ?? this.active,
    suggestions: suggestions ?? this.suggestions,
    searching: searching ?? this.searching,
    searched: searched ?? this.searched,
    calculating: calculating ?? this.calculating,
    meters: meters ?? this.meters,
    calculatedFor: calculatedFor ?? this.calculatedFor,
    attribution: attribution ?? this.attribution,
    failure: clearFailure ? null : failure ?? this.failure,
    retryAfter: clearFailure ? null : retryAfter ?? this.retryAfter,
    manualOverride: manualOverride ?? this.manualOverride,
    saved: saved ?? this.saved,
    fill: fill ?? this.fill,
  );
}

/// A route distance as the kilometre field gets it: rounded to 100 m, never
/// zero (a lookup that found a route must not fill "0").
int roundRouteMeters(int meters) {
  final rounded = ((meters + 50) ~/ 100) * 100;
  return rounded < 100 ? 100 : rounded;
}

/// How long the user must stop typing before a lookup goes out. Overridden
/// with zero in tests.
final routeSearchDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 300),
);

/// "Strecke berechnen" for the forms that ask for a distance: type start and
/// destination, pick suggestions, the one-way distance fills the kilometre
/// field. The manual field always works and always wins: a hand edit stops
/// any further overwrite until the user taps "Neu berechnen".
class RouteDistanceViewModel extends Notifier<RouteDistanceState> {
  var _fillSeq = 0;

  /// Drop answers of lookups that were overtaken by a newer one.
  var _searchGeneration = 0;
  var _calcGeneration = 0;
  Timer? _debounce;

  RouteDistanceRepository get _routes =>
      ref.read(routeDistanceRepositoryProvider);
  PlacesRepository get _places => ref.read(placesRepositoryProvider);

  @override
  RouteDistanceState build() {
    ref.onDispose(() => _debounce?.cancel());
    final available = ref.watch(routeDistanceRepositoryProvider).isAvailable;
    if (available) unawaited(Future.microtask(loadSaved));
    return RouteDistanceState(available: available);
  }

  /// Reads the saved places from the device.
  Future<void> loadSaved() async {
    final result = await _places.all();
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(saved: value);
      case Err():
        // Saved places are a convenience: typing still works. The commands
        // that change them report their own errors.
        state = state.copyWith(saved: const []);
    }
  }

  /// The current state, for DebugDrive handlers (which are not subclasses).
  RouteDistanceState get current => state;

  PlaceSuggestion? _pick(RouteField field) =>
      field == RouteField.start ? state.start : state.end;

  /// The user typed [text] into [field]. A changed text drops that field's
  /// pick; after the debounce (and from three characters) suggestions load.
  void onTextChanged(RouteField field, String text, {String lang = 'de'}) {
    _debounce?.cancel();
    _searchGeneration++;
    final picked = _pick(field);
    final dropPick = picked != null && picked.label != text;
    state = state.copyWith(
      active: field,
      clearStart: dropPick && field == RouteField.start,
      clearEnd: dropPick && field == RouteField.end,
      suggestions: const [],
      searching: false,
      searched: false,
      clearFailure: true,
    );
    if (text.trim().runes.length < minPlaceTextLength ||
        picked?.label == text) {
      return;
    }
    _debounce = Timer(
      ref.read(routeSearchDebounceProvider),
      () => unawaited(search(field, text, lang: lang)),
    );
  }

  /// Looks suggestions up for [text] now (no debounce). A newer lookup makes
  /// this one's answer obsolete.
  Future<void> search(
    RouteField field,
    String text, {
    String lang = 'de',
  }) async {
    final generation = ++_searchGeneration;
    state = state.copyWith(
      active: field,
      searching: true,
      searched: false,
      clearFailure: true,
    );
    final result = await _routes.suggest(text, lang: lang);
    if (!ref.mounted || generation != _searchGeneration) return;
    switch (result) {
      case RouteOk(:final value, :final attribution):
        state = state.copyWith(
          suggestions: value,
          searching: false,
          searched: true,
          attribution: attribution.isEmpty ? null : attribution,
        );
      case RouteFail(:final reason, :final retryAfter):
        state = state.copyWith(
          suggestions: const [],
          searching: false,
          failure: reason,
          retryAfter: retryAfter,
        );
    }
  }

  /// The user chose [place] for [field]. With both places set and no manual
  /// edit of the kilometre field, the distance is calculated and filled.
  Future<void> pick(RouteField field, PlaceSuggestion place) async {
    _debounce?.cancel();
    _searchGeneration++;
    state = state.copyWith(
      start: field == RouteField.start ? place : null,
      end: field == RouteField.end ? place : null,
      suggestions: const [],
      searching: false,
      searched: false,
      clearFailure: true,
    );
    if (state.bothPicked && !state.manualOverride) await _calculate();
  }

  /// Takes the saved place of [kind] into the active field (the first empty
  /// one without an active field). Returns what was picked so the view can
  /// show the label; null when [kind] is not saved.
  ({RouteField field, PlaceSuggestion place})? pickSaved(PlaceKind kind) {
    final saved = state.savedOf(kind);
    if (saved == null) return null;
    final field =
        state.active ??
        (state.start == null ? RouteField.start : RouteField.end);
    unawaited(pick(field, saved.place));
    return (field: field, place: saved.place);
  }

  /// "Neu berechnen": the user asked for it, so it overwrites a hand edit.
  Future<void> recalculate() async {
    if (!state.bothPicked) return;
    state = state.copyWith(manualOverride: false);
    await _calculate();
  }

  /// The user typed into the kilometre field: stop auto-filling.
  void noteManualEdit() {
    if (!state.manualOverride) state = state.copyWith(manualOverride: true);
  }

  Future<void> _calculate() async {
    final from = state.start;
    final to = state.end;
    if (from == null || to == null) return;
    final generation = ++_calcGeneration;
    state = state.copyWith(calculating: true, clearFailure: true);
    final result = await _routes.distance(from, to);
    if (!ref.mounted || generation != _calcGeneration) return;
    // A place changed while waiting: this answer is for another route.
    if (state.start != from || state.end != to) {
      state = state.copyWith(calculating: false);
      return;
    }
    switch (result) {
      case RouteOk(:final value, :final attribution):
        state = state.copyWith(
          calculating: false,
          meters: value,
          calculatedFor: (from, to),
          attribution: attribution.isEmpty ? null : attribution,
          manualOverride: false,
          fill: RouteFill(seq: ++_fillSeq, meters: roundRouteMeters(value)),
        );
      case RouteFail(:final reason, :final retryAfter):
        state = state.copyWith(
          calculating: false,
          failure: reason,
          retryAfter: retryAfter,
        );
    }
  }

  /// Remembers the picked place of [field] as [kind] (device only). Returns
  /// the result with the [Undo] for the snackbar, or the error to show; null
  /// when [field] has no picked place.
  Future<RepoResult<Undo>?> savePlace(RouteField field, PlaceKind kind) async {
    final place = _pick(field);
    if (place == null) return null;
    final result = await _places.save(kind, place);
    if (ref.mounted && result is Ok<Undo, RepositoryError>) await loadSaved();
    return result;
  }

  /// Reloads the saved places after an undo.
  Future<void> refreshSaved() => loadSaved();

  JsonMap debugSnapshot() => {
    'available': state.available,
    'start': state.start?.label,
    'end': state.end?.label,
    'meters': state.meters,
    'manualOverride': state.manualOverride,
    'canRecalculate': state.canRecalculate,
    'failure': state.failure?.name,
    'attribution': state.attribution,
  };
}

// ignore: specify_nonobvious_property_types, the autoDispose provider type is not exported
final routeDistanceViewModelProvider =
    NotifierProvider.autoDispose<RouteDistanceViewModel, RouteDistanceState>(
      RouteDistanceViewModel.new,
    );
