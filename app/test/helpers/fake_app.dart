import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/fake_expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/fake_groups_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/fake_members_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/fake_settlements_repository.dart';
import 'package:mitlio/features/settlements/data/repositories/settlements_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

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

/// All repositories in memory, wired together, plus the provider overrides
/// that install them. One per test.
class FakeApp {
  factory FakeApp() {
    final clock = FixedClock(DateTime.utc(2026, 3, 1, 12));
    final ids = SequentialIdGenerator();
    final groups = FlakyGroups(clock: clock, ids: ids);
    final members = FlakyMembers(groups: groups, ids: ids);
    return FakeApp._(
      clock,
      groups,
      members,
      FakeExpensesRepository(
        groups: groups,
        members: members,
        clock: clock,
        ids: ids,
      ),
      FakeSettlementsRepository(
        groups: groups,
        members: members,
        clock: clock,
        ids: ids,
      ),
    );
  }

  FakeApp._(
    this.clock,
    this.groups,
    this.members,
    this.expenses,
    this.settlements,
  );

  final FixedClock clock;
  final FlakyGroups groups;
  final FlakyMembers members;
  final FakeExpensesRepository expenses;
  final FakeSettlementsRepository settlements;

  List<Override> get overrides => [
    groupsRepositoryProvider.overrideWithValue(groups),
    membersRepositoryProvider.overrideWithValue(members),
    expensesRepositoryProvider.overrideWithValue(expenses),
    settlementsRepositoryProvider.overrideWithValue(settlements),
  ];

  /// A container with these repositories; disposed by the caller.
  ProviderContainer container() => ProviderContainer(overrides: overrides);
}
