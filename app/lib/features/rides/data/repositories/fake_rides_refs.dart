import 'package:mitlio/core/first_value.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/vehicles_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Fake counterpart of `missingRef` in `drift_rides_refs.dart`.
Future<RepositoryError?> fakeMissingRef({
  required GroupsRepository groups,
  required MembersRepository members,
  required VehiclesRepository vehicles,
  required String groupId,
  required String vehicleId,
  required Iterable<String> memberIds,
}) async {
  if (await groups.get(groupId) case Err<Group, RepositoryError>(
    :final error,
  )) {
    return error;
  }
  final live = await firstValue(vehicles.watchVehicles(groupId));
  if (!live.any((v) => v.id == vehicleId)) {
    return NotFound('vehicle', vehicleId);
  }
  final ids = switch (await members.list(groupId)) {
    Ok<List<GroupMember>, RepositoryError>(:final value) => {
      for (final m in value) m.id,
    },
    Err<List<GroupMember>, RepositoryError>() => <String>{},
  };
  for (final id in memberIds) {
    if (!ids.contains(id)) return NotFound('member', id);
  }
  return null;
}
