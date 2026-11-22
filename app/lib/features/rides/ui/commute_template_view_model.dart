import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/features/setup/data/setup_providers.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Step ids of the commute template flow (PU-T12). Never rename after
/// release.
abstract final class CommuteStep {
  static const name = 'name';
  static const route = 'route';
  static const vehicle = 'vehicle';
  static const people = 'people';
  static const tolls = 'tolls';
}

/// The stored answer of the route step: one-way distance and whether the
/// ride is there and back.
Map<String, Object?> commuteRouteAnswer(
  int meters, {
  required bool roundTrip,
}) => {'meters': meters, 'roundTrip': roundTrip};

/// The stored answer of the people step: the usual driver (or none) and the
/// usual passengers.
Map<String, Object?> commutePeopleAnswer({
  String? driverId,
  List<String> passengerIds = const [],
}) => {'driver': driverId, 'passengers': passengerIds};

String? _validName(Object answer) =>
    answer is String && answer.trim().isNotEmpty ? null : 'name is blank';

String? _validRoute(Object answer) =>
    answer is Map &&
        answer['meters'] is int &&
        (answer['meters']! as int) > 0 &&
        answer['roundTrip'] is bool
    ? null
    : 'route needs a distance above 0 and a round-trip flag';

String? _validVehicle(Object answer) =>
    answer is String && answer.isNotEmpty ? null : 'vehicle id is blank';

String? _validPeople(Object answer) =>
    answer is Map &&
        (answer['driver'] == null || answer['driver'] is String) &&
        answer['passengers'] is List &&
        (answer['passengers']! as List).every((p) => p is String)
    ? null
    : 'people need a driver or none and a list of passengers';

String? _validTolls(Object answer) =>
    answer is int && answer >= 0 ? null : 'tolls must be cents, not negative';

/// The commute template flow (ADR-25 §4: rare, more than three inputs): what
/// the route is called, how far, which car, who usually drives and rides, the
/// tolls. Name, route and car are needed; people and tolls can be skipped.
const commuteTemplateFlow = SetupFlowConfig(
  id: 'commute_template',
  steps: [
    SetupStepSpec(CommuteStep.name, skippable: false, validate: _validName),
    SetupStepSpec(CommuteStep.route, skippable: false, validate: _validRoute),
    SetupStepSpec(
      CommuteStep.vehicle,
      skippable: false,
      validate: _validVehicle,
    ),
    SetupStepSpec(CommuteStep.people, validate: _validPeople),
    SetupStepSpec(CommuteStep.tolls, validate: _validTolls),
  ],
);

/// The flow of [groupId]: a route belongs to one group, so each group keeps
/// its own progress (ids of people and cars are only valid there).
SetupFlowConfig commuteTemplateFlowFor(String groupId) =>
    commuteTemplateFlow.scopedTo(groupId);

/// The template as the answers describe it; null until name, route and car
/// are given. Its id is empty: the repository assigns it.
RideTemplate? commuteTemplateFrom(Map<String, Object?> answers) {
  final name = answers[CommuteStep.name];
  final route = answers[CommuteStep.route];
  final vehicle = answers[CommuteStep.vehicle];
  if (name is! String ||
      name.trim().isEmpty ||
      route is! Map ||
      route['meters'] is! int ||
      route['roundTrip'] is! bool ||
      vehicle is! String) {
    return null;
  }
  final people = answers[CommuteStep.people];
  final driver = people is Map && people['driver'] is String
      ? people['driver']! as String
      : null;
  final passengers = people is Map && people['passengers'] is List
      ? {
          for (final p in people['passengers']! as List)
            if (p is String && p != driver) p,
        }
      : <String>{};
  final tolls = answers[CommuteStep.tolls];
  return RideTemplate(
    id: '',
    name: name.trim(),
    distanceMeters: route['meters']! as int,
    roundTrip: route['roundTrip']! as bool,
    vehicleId: vehicle,
    defaultDriverId: driver,
    defaultPassengerIds: passengers,
    tollsCents: tolls is int ? tolls : 0,
  );
}

/// The template of the flow of a group, for the finish screen.
// ignore: specify_nonobvious_property_types, the family provider type is not exported
final commuteTemplateDraftProvider = Provider.family<RideTemplate?, String>(
  (ref, groupId) => commuteTemplateFrom(
    ref
        .watch(setupFlowViewModelProvider(commuteTemplateFlowFor(groupId)))
        .answers,
  ),
);

/// Stores the template of the finished flow: the one command behind the
/// finish screen's "Strecke speichern" and `ext.mitlio.rides.commute.save`.
class CommuteTemplateViewModel extends Notifier<bool> {
  CommuteTemplateViewModel(this.groupId);

  final String groupId;

  /// True while [save] runs, so a double tap cannot store two templates.
  @override
  bool build() => false;

  /// Stores the template, then clears the flow of this group. [Conflict]
  /// while name, route or car are missing; [InvalidData] and storage errors
  /// come from the rides repository. On a failure the answers stay.
  Future<RepoResult<RideTemplate>> save() async {
    final draft = ref.read(commuteTemplateDraftProvider(groupId));
    if (draft == null) {
      return const Err(Conflict('commute template is incomplete'));
    }
    if (state) return const Err(Conflict('already saving'));
    state = true;
    try {
      final saved = await ref
          .read(ridesSetupViewModelProvider(groupId).notifier)
          .addTemplate(draft);
      if (saved is Ok) {
        final flow = commuteTemplateFlowFor(groupId);
        // Documented reason for ignoring a failure: the template is saved
        // already; old progress only shows the finish screen again, and an
        // error would suggest the route was lost.
        await ref
            .read(setupStateRepositoryProvider)
            .save(flow.id, const SetupProgress());
        ref.invalidate(setupFlowViewModelProvider(flow));
      }
      return saved;
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final commuteTemplateViewModelProvider =
    NotifierProvider.family<CommuteTemplateViewModel, bool, String>(
      CommuteTemplateViewModel.new,
    );
