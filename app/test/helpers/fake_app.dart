import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/fake_expenses_repository.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_providers.dart';
import 'package:mitlio/features/fuel/data/services/fake_fuel_price_service.dart';
import 'package:mitlio/features/fuel/data/services/location_service.dart';
import 'package:mitlio/features/groups/data/repositories/fake_groups_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/fake_members_repository.dart';
import 'package:mitlio/features/members/data/repositories/fake_payment_details_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_rides_repository.dart';
import 'package:mitlio/features/rides/data/repositories/fake_vehicles_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/fake_settlements_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'fake_platform.dart';

/// Groups fake whose commands and stream can be made to fail.
class FlakyGroups extends FakeGroupsRepository {
  FlakyGroups({required super.clock, required super.ids});

  /// Fails `create`, `update` and `softDelete` while set.
  RepositoryError? failWith;

  /// Makes `watchGroups` emit this error while set.
  Object? watchError;

  @override
  Stream<List<Group>> watchGroups() =>
      watchError != null ? Stream.error(watchError!) : super.watchGroups();

  @override
  Future<RepoResult<Group>> create({
    required String name,
    required Currency currency,
    required String createdBy,
  }) async => failWith != null
      ? Err(failWith!)
      : super.create(name: name, currency: currency, createdBy: createdBy);

  @override
  Future<RepoResult<Group>> update(
    String id, {
    required String name,
    required Currency currency,
  }) async => failWith != null
      ? Err(failWith!)
      : super.update(id, name: name, currency: currency);

  @override
  Future<RepoResult<Undo>> softDelete(String id) async =>
      failWith != null ? Err(failWith!) : super.softDelete(id);
}

/// Members fake whose commands and stream can be made to fail.
class FlakyMembers extends FakeMembersRepository {
  FlakyMembers({required super.groups, required super.ids});

  /// Fails `add`, `update`, `reorder` and `softDelete` while set.
  RepositoryError? failWith;

  /// Makes `watchMembers` emit this error while set.
  Object? watchError;

  @override
  Stream<List<GroupMember>> watchMembers(String groupId) => watchError != null
      ? Stream.error(watchError!)
      : super.watchMembers(groupId);

  @override
  Future<RepoResult<GroupMember>> add(
    String groupId, {
    required String name,
    String? paypalMe,
    String? ibanHint,
  }) async => failWith != null
      ? Err(failWith!)
      : super.add(groupId, name: name, paypalMe: paypalMe, ibanHint: ibanHint);

  @override
  Future<RepoResult<GroupMember>> update(
    String id, {
    required String name,
    String? paypalMe,
    String? ibanHint,
  }) async => failWith != null
      ? Err(failWith!)
      : super.update(id, name: name, paypalMe: paypalMe, ibanHint: ibanHint);

  @override
  Future<RepoResult<void>> reorder(
    String groupId,
    List<String> orderedIds,
  ) async =>
      failWith != null ? Err(failWith!) : super.reorder(groupId, orderedIds);

  @override
  Future<RepoResult<Undo>> softDelete(String id) async =>
      failWith != null ? Err(failWith!) : super.softDelete(id);
}

/// Settlements fake whose commands and stream can be made to fail.
class FlakySettlements extends FakeSettlementsRepository {
  FlakySettlements({
    required super.groups,
    required super.members,
    required super.clock,
    required super.ids,
  });

  /// Fails `create` and `softDelete` while set.
  RepositoryError? failWith;

  /// Makes `watchSettlements` emit this error while set.
  Object? watchError;

  @override
  Stream<List<SettlementEntry>> watchSettlements(String groupId) =>
      watchError != null
      ? Stream.error(watchError!)
      : super.watchSettlements(groupId);

  @override
  Future<RepoResult<SettlementEntry>> create(
    String groupId,
    SettlementDraft draft,
  ) async => failWith != null ? Err(failWith!) : super.create(groupId, draft);

  @override
  Future<RepoResult<Undo>> softDelete(String id) async =>
      failWith != null ? Err(failWith!) : super.softDelete(id);
}

/// Payment details fake whose reads can be made to fail.
class FlakyPayments extends FakePaymentDetailsRepository {
  FlakyPayments({required super.members});

  /// Fails `get` while set.
  RepositoryError? failWith;

  @override
  Future<RepoResult<PaymentDetails>> get(String memberId) async =>
      failWith != null ? Err(failWith!) : super.get(memberId);
}

/// All repositories in memory, wired together, plus the provider overrides
/// that install them. One per test.
class FakeApp {
  factory FakeApp() {
    final clock = FixedClock(DateTime.utc(2026, 3, 1, 12));
    final ids = SequentialIdGenerator();
    final groups = FlakyGroups(clock: clock, ids: ids);
    final members = FlakyMembers(groups: groups, ids: ids);
    final expenses = FakeExpensesRepository(
      groups: groups,
      members: members,
      clock: clock,
      ids: ids,
    );
    final vehicles = FakeVehiclesRepository(groups: groups, ids: ids);
    return FakeApp._(
      clock,
      groups,
      members,
      expenses,
      vehicles,
      FakeRidesRepository(
        groups: groups,
        members: members,
        vehicles: vehicles,
        expenses: expenses,
        clock: clock,
      ),
      FlakySettlements(
        groups: groups,
        members: members,
        clock: clock,
        ids: ids,
      ),
      FlakyPayments(members: members),
    );
  }

  FakeApp._(
    this.clock,
    this.groups,
    this.members,
    this.expenses,
    this.vehicles,
    this.rides,
    this.settlements,
    this.payments,
  );

  final FixedClock clock;
  final FlakyGroups groups;
  final FlakyMembers members;
  final FakeExpensesRepository expenses;

  /// Empty unless a test adds to them; screens that read rides need them.
  final FakeVehiclesRepository vehicles;
  final FakeRidesRepository rides;
  final FlakySettlements settlements;
  final FlakyPayments payments;

  /// Links opened and text copied by the payment actions.
  final launcher = FakeLinkLauncher();

  /// Texts handed to the share sheet.
  final share = FakeShareService();

  List<Override> get overrides => overridesWith();

  /// [overrides], optionally with another payment details repository (e.g. a
  /// failing one).
  List<Override> overridesWith({PaymentDetailsRepository? payments}) => [
    paymentDetailsRepositoryProvider.overrideWithValue(
      payments ?? this.payments,
    ),
    groupsRepositoryProvider.overrideWithValue(groups),
    membersRepositoryProvider.overrideWithValue(members),
    expensesRepositoryProvider.overrideWithValue(expenses),
    vehiclesRepositoryProvider.overrideWithValue(vehicles),
    ridesRepositoryProvider.overrideWithValue(rides),
    settlementsRepositoryProvider.overrideWithValue(settlements),
    linkLauncherProvider.overrideWithValue(launcher),
    shareServiceProvider.overrideWithValue(share),
  ];

  /// The fuel price backend and location, off by default (chips hidden):
  /// pass [fuelOverrides] as `extra` to switch them on.
  late final fuel = FakeFuelPriceService(now: clock.now);
  final location = FakeLocationService();

  List<Override> get fuelBackendOverrides => [
    fuelPriceServiceProvider.overrideWithValue(fuel),
    locationServiceProvider.overrideWithValue(location),
  ];

  /// [fuelBackendOverrides] plus the test clock (when the app has not
  /// overridden it already).
  List<Override> get fuelOverrides => [
    clockProvider.overrideWithValue(clock),
    ...fuelBackendOverrides,
  ];

  /// A container with these repositories; disposed by the caller.
  ProviderContainer container({List<Override> extra = const []}) =>
      ProviderContainer(overrides: [...overrides, ...extra]);
}
