import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Fixed states for goldens and a11y tests: the ViewModel is replaced by a
/// stub that never touches a repository.
class StubTripFormViewModel extends TripFormViewModel {
  StubTripFormViewModel(super.groupId, this.fixed);

  final TripFormState fixed;

  @override
  TripFormState build() => fixed;
}

List<Override> tripStateOverride(TripFormState state) => [
  tripFormViewModelProvider.overrideWith2(
    (id) => StubTripFormViewModel(id, state),
  ),
];

Widget tripScoped(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: child);

final tripGroup = Group(
  id: 'g-1',
  name: 'Pendeln',
  currency: Currency.eur,
  createdBy: 'local',
  createdAt: DateTime.utc(2026),
);

const _names = ['Anna Berg', 'Ben', 'Chiara Rossi'];

final List<GroupMember> tripMembers = [
  for (var i = 0; i < _names.length; i++)
    GroupMember(id: 'm-$i', groupId: 'g-1', name: _names[i], position: i),
];

TripFormLoaded tripLoaded(TripInputs inputs, {List<GroupMember>? members}) {
  final m = members ?? tripMembers;
  return TripFormLoaded(
    group: tripGroup,
    members: m,
    inputs: inputs,
    evaluation: evaluateTrip(inputs, Currency.eur, [
      for (final x in m) x.toDomain(),
    ]),
  );
}

const _everyone = {'m-1', 'm-2'};

/// Nothing typed yet.
final TripFormLoaded tripEmpty = tripLoaded(
  const TripInputs(driverId: 'm-0', passengerIds: _everyone),
);

/// The documented 250 km example, uneven cents, with wear and tolls.
final TripFormLoaded tripResult = tripLoaded(
  const TripInputs(
    distance: '250',
    consumption: '6,5',
    price: '1,799',
    wear: '0,05',
    tolls: '11,50',
    driverId: 'm-0',
    passengerIds: _everyone,
  ),
);

/// Flat km rate, driver rides free: equal shares.
final TripFormLoaded tripKmRate = tripLoaded(
  const TripInputs(
    distance: '250',
    useKmRate: true,
    kmRate: '0,30',
    roundTrip: true,
    driverCounts: false,
    driverId: 'm-1',
    passengerIds: {'m-0', 'm-2'},
  ),
);

/// Text that is not a number.
final TripFormLoaded tripInvalid = tripLoaded(
  const TripInputs(
    distance: '2,5,0',
    consumption: '6,5',
    price: 'abc',
    driverId: 'm-0',
    passengerIds: _everyone,
  ),
);

/// Everyone unticked and the driver rides free.
final TripFormLoaded tripNobody = tripLoaded(
  const TripInputs(
    distance: '250',
    consumption: '6,5',
    price: '1,799',
    driverCounts: false,
    driverId: 'm-0',
  ),
);

final TripFormLoaded tripNoMembers = tripLoaded(
  const TripInputs(),
  members: const [],
);

/// The trip form without a group: anonymous seats, a result, nothing to save.
final TripFormLoaded tripStandalone = () {
  const inputs = TripInputs(
    distance: '250',
    consumption: '6,5',
    price: '1,799',
    driverId: 'seat-1',
    passengerIds: {'seat-2'},
  );
  final seats = [
    for (var i = 0; i < 5; i++)
      GroupMember(
        id: 'seat-${i + 1}',
        groupId: standaloneTripGroupId,
        name: '',
        position: i,
      ),
  ];
  return TripFormLoaded(
    group: Group(
      id: standaloneTripGroupId,
      name: '',
      currency: Currency.eur,
      createdBy: 'local',
      createdAt: DateTime.utc(2026),
    ),
    members: seats,
    inputs: inputs,
    evaluation: evaluateTrip(inputs, Currency.eur, [
      for (final x in seats) x.toDomain(),
    ]),
  );
}();
