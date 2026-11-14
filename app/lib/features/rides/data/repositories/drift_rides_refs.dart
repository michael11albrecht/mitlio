import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';

/// The first [NotFound] among group, vehicle (live, in the group) and the
/// given live members of the group, or null when all exist.
Future<RepositoryError?> missingRef(
  AppDatabase db,
  String groupId, {
  required String vehicleId,
  required Iterable<String> memberIds,
}) async {
  if (await db.groupsDao.findById(groupId) == null) {
    return NotFound('group', groupId);
  }
  final vehicle = await db.ridesDao.findVehicle(vehicleId);
  if (vehicle == null || vehicle.groupId != groupId) {
    return NotFound('vehicle', vehicleId);
  }
  final live = {for (final m in await db.membersDao.listByGroup(groupId)) m.id};
  for (final id in memberIds) {
    if (!live.contains(id)) return NotFound('member', id);
  }
  return null;
}
