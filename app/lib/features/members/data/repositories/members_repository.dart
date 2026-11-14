// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A group member as stored. The domain `Member` is only id + position;
/// this adds the display and payment-hint fields.
final class GroupMember {
  const GroupMember({
    required this.id,
    required this.groupId,
    required this.name,
    required this.position,
    this.paypalMe,
    this.ibanHint,
  });

  final String id;
  final String groupId;
  final String name;

  /// Display and tie-break order within the group.
  final int position;
  final String? paypalMe;

  /// Masked hint only; the full IBAN is local-only (plan §8).
  final String? ibanHint;

  Member toDomain() => Member(id: id, position: position);

  @override
  bool operator ==(Object other) =>
      other is GroupMember &&
      other.id == id &&
      other.groupId == groupId &&
      other.name == name &&
      other.position == position &&
      other.paypalMe == paypalMe &&
      other.ibanHint == ibanHint;

  @override
  int get hashCode =>
      Object.hash(id, groupId, name, position, paypalMe, ibanHint);

  @override
  String toString() => 'GroupMember($id, $name, #$position)';
}

/// Source of truth for members. Lists are ordered by position, then id.
abstract interface class MembersRepository {
  /// Live members of [groupId]; emits the current list first, then after
  /// every change.
  Stream<List<GroupMember>> watchMembers(String groupId);

  /// Members of [groupId]. Expenses keep referencing deleted members, so
  /// [includeDeleted] exists for rebuilding aggregates and history views.
  Future<RepoResult<List<GroupMember>>> list(
    String groupId, {
    bool includeDeleted = false,
  });

  /// Appends a member at the next position. [name] is trimmed and must not
  /// be empty; the group must exist ([NotFound] otherwise).
  Future<RepoResult<GroupMember>> add(
    String groupId, {
    required String name,
    String? paypalMe,
    String? ibanHint,
  });

  /// Replaces name and hints wholesale (null clears a hint).
  Future<RepoResult<GroupMember>> update(
    String id, {
    required String name,
    String? paypalMe,
    String? ibanHint,
  });

  /// Reorders the live members of [groupId]. [orderedIds] must contain
  /// exactly the live member ids ([InvalidData] otherwise). The members take
  /// over the positions the live members occupy now, in the given order, so
  /// positions of soft-deleted members never collide.
  Future<RepoResult<void>> reorder(String groupId, List<String> orderedIds);

  /// Soft delete; call the returned [Undo] to bring the member back.
  Future<RepoResult<Undo>> softDelete(String id);

  /// [NotFound] for unknown ids, [Conflict] if the member is not deleted.
  Future<RepoResult<void>> restore(String id);
}

/// True if [a] and [b] hold the same ids, each exactly once.
bool sameMembers(Iterable<String> a, Iterable<String> b) {
  final left = a.toSet();
  final right = b.toSet();
  return left.length == a.length &&
      right.length == b.length &&
      left.length == right.length &&
      left.containsAll(right);
}
