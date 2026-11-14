import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/expenses/data/repositories/fake_expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/rides/data/repositories/fake_ride_templates_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/features/rides/ui/template_form_view_model.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

/// Rides fake whose commands and stream can be made to fail.
class FlakyRides extends FakeRidesRepository {
  FlakyRides({
    required super.groups,
    required super.members,
    required super.vehicles,
    required super.expenses,
    required super.clock,
  });

  /// Fails `log`, `update`, `softDelete`, `settlePeriod` and `unsettle`
  /// while set.
  RepositoryError? failWith;

  /// Makes `watchRides` emit this error while set.
  Object? watchError;

  @override
  Stream<List<RideEntry>> watchRides(String groupId, RidePeriod period) =>
      watchError != null
      ? Stream.error(watchError!)
      : super.watchRides(groupId, period);

  @override
  Future<RepoResult<RideEntry>> log(String groupId, Ride ride) async =>
      failWith != null ? Err(failWith!) : super.log(groupId, ride);

  @override
  Future<RepoResult<Undo>> softDelete(String id) async =>
      failWith != null ? Err(failWith!) : super.softDelete(id);

  @override
  Future<RepoResult<List<ExpenseEntry>>> settlePeriod(
    String groupId,
    List<PeriodSettlement> items,
  ) async =>
      failWith != null ? Err(failWith!) : super.settlePeriod(groupId, items);

  @override
  Future<RepoResult<void>> unsettle(List<String> expenseIds) async =>
      failWith != null ? Err(failWith!) : super.unsettle(expenseIds);
}

/// Vehicles fake whose commands can be made to fail.
class FlakyVehicles extends FakeVehiclesRepository {
  FlakyVehicles({required super.groups, required super.ids});

  /// Fails `add`, `update` and `softDelete` while set.
  RepositoryError? failWith;

  @override
  Future<RepoResult<Vehicle>> add(
    String groupId, {
    required String name,
    required FuelType fuelType,
    required int consumptionMilliPer100km,
    int wearMilliPerKm = 0,
    int? kmRateMilliPerKm,
  }) async => failWith != null
      ? Err(failWith!)
      : super.add(
          groupId,
          name: name,
          fuelType: fuelType,
          consumptionMilliPer100km: consumptionMilliPer100km,
          wearMilliPerKm: wearMilliPerKm,
          kmRateMilliPerKm: kmRateMilliPerKm,
        );
}

/// Templates fake whose commands can be made to fail.
class FlakyTemplates extends FakeRideTemplatesRepository {
  FlakyTemplates({
    required super.groups,
    required super.members,
    required super.vehicles,
    required super.ids,
  });

  /// Fails `add`, `update` and `softDelete` while set.
  RepositoryError? failWith;

  /// Makes `watchTemplates` emit this error while set.
  Object? watchError;

  @override
  Stream<List<RideTemplate>> watchTemplates(String groupId) =>
      watchError != null
      ? Stream.error(watchError!)
      : super.watchTemplates(groupId);

  @override
  Future<RepoResult<RideTemplate>> add(
    String groupId,
    RideTemplate template,
  ) async => failWith != null ? Err(failWith!) : super.add(groupId, template);

  @override
  Future<RepoResult<Undo>> softDelete(String id) async =>
      failWith != null ? Err(failWith!) : super.softDelete(id);
}

/// [FakeApp] plus the rides repositories and a commute group "Pendler" with
/// Ann, Ben and Cy. [seedCommute] adds the car "Golf" and the route "Arbeit"
/// (2 x 20 km, Ann drives, Ben rides along).
class RidesApp {
  factory RidesApp() {
    final base = FakeApp();
    final ids = SequentialIdGenerator(prefix: 'rd');
    final vehicles = FlakyVehicles(groups: base.groups, ids: ids);
    final expenses = FakeExpensesRepository(
      groups: base.groups,
      members: base.members,
      clock: base.clock,
      ids: SequentialIdGenerator(prefix: 'rx'),
    );
    return RidesApp._(
      base,
      ids,
      vehicles,
      FlakyTemplates(
        groups: base.groups,
        members: base.members,
        vehicles: vehicles,
        ids: ids,
      ),
      FlakyRides(
        groups: base.groups,
        members: base.members,
        vehicles: vehicles,
        expenses: expenses,
        clock: base.clock,
      ),
      expenses,
    );
  }

  RidesApp._(
    this.base,
    this.ids,
    this.vehicles,
    this.templates,
    this.rides,
    this.expenses,
  );

  final FakeApp base;
  final SequentialIdGenerator ids;
  final FlakyVehicles vehicles;
  final FlakyTemplates templates;
  final FlakyRides rides;
  final FakeExpensesRepository expenses;
  late Group group;
  late List<GroupMember> people;

  /// Set inside `testWidgets`: the seeding helpers then run on the real
  /// event loop (`runAsync`), because the fake clock of widget tests never
  /// resolves their futures.
  WidgetTester? tester;

  Future<T> _real<T>(Future<T> Function() body) async {
    final t = tester;
    return t == null ? body() : (await t.runAsync(body)) as T;
  }

  late Vehicle golf;
  late RideTemplate work;

  List<Override> get overrides => [
    clockProvider.overrideWithValue(base.clock),
    idGeneratorProvider.overrideWithValue(ids),
    groupsRepositoryProvider.overrideWithValue(base.groups),
    membersRepositoryProvider.overrideWithValue(base.members),
    settlementsRepositoryProvider.overrideWithValue(base.settlements),
    expensesRepositoryProvider.overrideWithValue(expenses),
    vehiclesRepositoryProvider.overrideWithValue(vehicles),
    rideTemplatesRepositoryProvider.overrideWithValue(templates),
    ridesRepositoryProvider.overrideWithValue(rides),
  ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);

  String get today => '2026-03-01';

  /// The group with three members and nothing else.
  Future<void> seedGroup({Currency currency = Currency.eur}) =>
      _real(() => _seedGroup(currency));

  Future<void> _seedGroup(Currency currency) async {
    group = ok(
      await base.groups.create(
        name: 'Pendler',
        currency: currency,
        createdBy: 'dev',
      ),
    );
    people = [
      for (final n in ['Ann', 'Ben', 'Cy'])
        ok(await base.members.add(group.id, name: n)),
    ];
  }

  /// The group plus the car "Golf" (6,5 l, petrol).
  Future<void> seedVehicle() => _real(_seedVehicle);

  Future<void> _seedVehicle() async {
    await _seedGroup(Currency.eur);
    golf = ok(
      await vehicles.add(
        group.id,
        name: 'Golf',
        fuelType: FuelType.petrol,
        consumptionMilliPer100km: 6500,
      ),
    );
  }

  /// The group, the car and the route "Arbeit".
  Future<void> seedCommute({
    String? defaultDriver = 'Ann',
    Set<String> passengers = const {'Ben'},
  }) => _real(() => _seedCommute(defaultDriver, passengers));

  Future<void> _seedCommute(
    String? defaultDriver,
    Set<String> passengers,
  ) async {
    await _seedVehicle();
    String idOf(String name) => people.firstWhere((p) => p.name == name).id;
    work = ok(
      await templates.add(
        group.id,
        RideTemplate(
          id: '',
          name: 'Arbeit',
          distanceMeters: 20000,
          roundTrip: true,
          vehicleId: golf.id,
          defaultDriverId: defaultDriver == null ? null : idOf(defaultDriver),
          defaultPassengerIds: {for (final p in passengers) idOf(p)},
        ),
      ),
    );
  }

  /// A second route on the "Golf".
  Future<RideTemplate> addRoute(
    String name, {
    int meters = 8000,
    int? driver,
  }) => _real(
    () async => ok(
      await templates.add(
        group.id,
        RideTemplate(
          id: '',
          name: name,
          distanceMeters: meters,
          vehicleId: golf.id,
          defaultDriverId: driver == null ? null : people[driver].id,
        ),
      ),
    ),
  );

  /// A group without members.
  Future<void> seedMemberless() => _real(() async {
    group = ok(
      await base.groups.create(
        name: 'Leer',
        currency: Currency.eur,
        createdBy: 'dev',
      ),
    );
  });

  /// The rides inside [period] as stored.
  Future<List<RideEntry>> entriesIn(RidePeriod period) =>
      _real(() => rides.watchRides(group.id, period).first);

  /// Locks [rideIds] under a fresh expense, as a period settlement would.
  Future<void> settle(List<String> rideIds) => _real(() => _settle(rideIds));

  Future<void> _settle(List<String> rideIds) async {
    final expense = ok(
      await expenses.create(
        group.id,
        ExpenseDraft(
          title: 'Abrechnung',
          amountCents: 100,
          currency: group.currency,
          date: DateTime.utc(2026, 3, 31),
          payers: {people[0].id: 100},
          split: EqualSplit({people[0].id, people[1].id}),
        ),
      ),
    );
    ok(await rides.markSettled(rideIds, expense.expense.id));
  }

  /// Stores a ride of the "Arbeit" route directly through the repository.
  Future<RideEntry> ride({
    required String date,
    required int driver,
    List<int> passengers = const [],
    int priceMilli = 1750,
    int meters = 20000,
    bool roundTrip = true,
  }) => _real(
    () async => ok(
      await rides.log(
        group.id,
        Ride(
          id: ids.newId(),
          date: DateTime.parse('${date}T00:00:00Z'),
          distanceMeters: meters,
          roundTrip: roundTrip,
          vehicleId: golf.id,
          driverId: people[driver].id,
          passengerIds: {for (final p in passengers) people[p].id},
          pricePerUnitMilli: priceMilli,
        ),
      ),
    ),
  );
}

/// Fixed states for goldens and a11y tests: the ViewModels are replaced by
/// stubs that never touch a repository.
class StubRidesViewModel extends RidesViewModel {
  StubRidesViewModel(super.groupId, this.fixed);

  final RidesState fixed;

  @override
  RidesState build() => fixed;
}

class StubRidesSetupViewModel extends RidesSetupViewModel {
  StubRidesSetupViewModel(super.groupId, this.fixed);

  final RidesSetupState fixed;

  @override
  RidesSetupState build() => fixed;
}

class StubVehicleFormViewModel extends VehicleFormViewModel {
  StubVehicleFormViewModel(super.key, this.fixed);

  final VehicleFormState fixed;

  @override
  VehicleFormState build() => fixed;
}

class StubTemplateFormViewModel extends TemplateFormViewModel {
  StubTemplateFormViewModel(super.key, this.fixed);

  final TemplateFormState fixed;

  @override
  TemplateFormState build() => fixed;
}

List<Override> ridesStateOverride(RidesState state) => [
  ridesViewModelProvider.overrideWith2(
    (id) => StubRidesViewModel(id, state),
  ),
];

List<Override> setupStateOverride(RidesSetupState state) => [
  ridesSetupViewModelProvider.overrideWith2(
    (id) => StubRidesSetupViewModel(id, state),
  ),
];

List<Override> vehicleFormOverride(VehicleFormState state) => [
  vehicleFormViewModelProvider.overrideWith2(
    (key) => StubVehicleFormViewModel(key, state),
  ),
];

List<Override> templateFormOverride(TemplateFormState state) => [
  templateFormViewModelProvider.overrideWith2(
    (key) => StubTemplateFormViewModel(key, state),
  ),
];

Widget scopedRides(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: child);

const _names = ['Anna Berg', 'Ben', 'Chiara Rossi'];

final sampleGroup = Group(
  id: 'g-1',
  name: 'Pendler',
  currency: Currency.eur,
  createdBy: 'local',
  createdAt: DateTime.utc(2026),
);

final List<GroupMember> sampleMembers = [
  for (var i = 0; i < _names.length; i++)
    GroupMember(id: 'm-$i', groupId: 'g-1', name: _names[i], position: i),
];

final sampleVehicle = Vehicle(
  id: 'v-1',
  name: 'Golf',
  fuelType: FuelType.petrol,
  consumptionMilliPer100km: 6500,
);

const sampleTemplate = RideTemplate(
  id: 't-1',
  name: 'Arbeit',
  distanceMeters: 20000,
  roundTrip: true,
  vehicleId: 'v-1',
  defaultDriverId: 'm-0',
  defaultPassengerIds: {'m-1'},
);

const sampleTemplate2 = RideTemplate(
  id: 't-2',
  name: 'Training',
  distanceMeters: 8000,
  vehicleId: 'v-1',
);

RideEntry sampleEntry(
  String id,
  int day,
  int driver,
  List<int> passengers, {
  String? settled,
}) => RideEntry(
  groupId: 'g-1',
  createdAt: DateTime.utc(2026, 3, day),
  settledExpenseId: settled,
  ride: Ride(
    id: id,
    date: DateTime.utc(2026, 3, day),
    distanceMeters: 20000,
    roundTrip: true,
    vehicleId: 'v-1',
    driverId: 'm-$driver',
    passengerIds: {for (final p in passengers) 'm-$p'},
    pricePerUnitMilli: 1750,
  ),
);

final List<Member> _everyone = [for (final m in sampleMembers) m.toDomain()];

QuickLog sampleQuick({
  RideTemplate? template,
  String driver = 'm-0',
  Set<String> passengers = const {'m-1'},
  bool collapsed = false,
  bool isToday = true,
}) {
  final t = template ?? sampleTemplate;
  final ride = Ride(
    id: 'p',
    date: DateTime.utc(2026, 3),
    distanceMeters: t.distanceMeters,
    roundTrip: t.roundTrip,
    vehicleId: sampleVehicle.id,
    driverId: driver,
    passengerIds: passengers,
    pricePerUnitMilli: 1750,
  );
  return QuickLog(
    template: template,
    vehicle: sampleVehicle,
    driverId: driver,
    passengerIds: passengers,
    priceMilli: 1750,
    date: DateTime.utc(2026, 3, isToday ? 1 : 3),
    isToday: isToday,
    preview: template == null ? null : summarizeFor(ride, sampleVehicle),
    collapsed: collapsed,
    saving: false,
  );
}

/// Total and shares of [ride] through the domain.
RideSummary? summarizeFor(Ride ride, Vehicle vehicle) {
  final cost = rideCost(ride, vehicle, Currency.eur, _everyone);
  if (cost is! Ok<TripCost, TripError>) return null;
  return RideSummary(
    totalCents: cost.value.totalCents,
    owes: [
      for (final id in ride.passengerIds)
        RideShare(memberId: id, cents: cost.value.shares[id] ?? 0),
    ],
  );
}

RidesLoaded loadedRides({
  List<RideTemplate>? templates,
  List<RideEntry>? entries,
  QuickLog? quick,
  DateTime? today,
}) {
  final ts = templates ?? [sampleTemplate];
  return RidesLoaded(
    group: sampleGroup,
    members: sampleMembers,
    vehicles: [sampleVehicle],
    templates: ts,
    entries:
        entries ??
        [
          sampleEntry('r-1', 2, 0, [1]),
          sampleEntry('r-2', 3, 1, [0]),
          sampleEntry('r-3', 4, 0, [1, 2]),
        ],
    month: const Month(2026, 3),
    today: today ?? DateTime.utc(2026, 3),
    quick: ts.isEmpty ? null : (quick ?? sampleQuick(template: ts.first)),
  );
}

final RidesLoaded dataRides = loadedRides();

final RidesLoaded severalTemplatesRides = loadedRides(
  templates: [sampleTemplate, sampleTemplate2],
  quick: sampleQuick(),
);

/// Several routes and none picked yet.
final RidesLoaded pickRouteRides = loadedRides(
  templates: [sampleTemplate, sampleTemplate2],
  quick: sampleQuick(passengers: const {}),
);

final RidesLoaded doneTodayRides = loadedRides(
  entries: [
    sampleEntry('r-1', 1, 0, [1]),
    sampleEntry('r-2', 2, 1, [0]),
    sampleEntry('r-3', 4, 0, [1], settled: 'x-1'),
  ],
  quick: sampleQuick(collapsed: true),
);

/// March is over: the settlement card is offered.
final RidesLoaded settleDueRides = loadedRides(today: DateTime.utc(2026, 4, 2));

/// March is over and already settled: no card, the sheet has nothing to do.
final RidesLoaded settledMonthRides = loadedRides(
  today: DateTime.utc(2026, 4, 2),
  entries: [
    sampleEntry('r-1', 2, 0, [1], settled: 'x-1'),
    sampleEntry('r-2', 3, 1, [0], settled: 'x-2'),
    sampleEntry('r-3', 4, 0, [1, 2], settled: 'x-1'),
  ],
);

final onboardingRides = RidesLoaded(
  group: sampleGroup,
  members: sampleMembers,
  vehicles: const [],
  templates: const [],
  entries: const [],
  month: const Month(2026, 3),
  today: DateTime.utc(2026, 3),
  quick: null,
);

final noMembersRides = RidesLoaded(
  group: sampleGroup,
  members: const [],
  vehicles: const [],
  templates: const [],
  entries: const [],
  month: const Month(2026, 3),
  today: DateTime.utc(2026, 3),
  quick: null,
);

final RidesSetupLoaded setupData = RidesSetupLoaded(
  group: sampleGroup,
  members: sampleMembers,
  vehicles: [sampleVehicle],
  templates: [sampleTemplate, sampleTemplate2],
);

final RidesSetupLoaded setupEmpty = RidesSetupLoaded(
  group: sampleGroup,
  members: sampleMembers,
  vehicles: const [],
  templates: const [],
);

VehicleFormReady vehicleFormReady({
  String name = '',
  FuelType fuel = FuelType.petrol,
  int? consumption,
  int? wear,
  int? kmRate,
  bool showErrors = false,
  bool editing = false,
}) => VehicleFormReady(
  currency: Currency.eur,
  editing: editing,
  name: name,
  fuelType: fuel,
  consumptionMilli: consumption,
  wearMilli: wear,
  kmRateMilli: kmRate,
  showErrors: showErrors,
  saving: false,
);

TemplateFormReady templateFormReady({
  String name = '',
  int? distance,
  bool roundTrip = true,
  String? vehicleId = 'v-1',
  List<Vehicle>? vehicles,
  String? driver,
  Set<String> passengers = const {},
  int? tolls,
  bool showErrors = false,
  bool editing = false,
}) => TemplateFormReady(
  group: sampleGroup,
  members: sampleMembers,
  vehicles: vehicles ?? [sampleVehicle],
  editing: editing,
  name: name,
  distanceMeters: distance,
  roundTrip: roundTrip,
  vehicleId: vehicleId,
  defaultDriverId: driver,
  defaultPassengerIds: passengers,
  tollsCents: tolls,
  showErrors: showErrors,
  saving: false,
);

/// Starts the real app on the repositories of [app] and optionally jumps to
/// [location]; German unless [locale] says otherwise.
Future<ProviderContainer> pumpRides(
  WidgetTester tester,
  RidesApp app, {
  String? location,
  Locale locale = const Locale('de'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = app.container();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MitlioApp()),
  );
  if (location != null) container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return container;
}
