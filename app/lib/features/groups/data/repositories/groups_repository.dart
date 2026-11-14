// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A group of people sharing expenses. Plain data: the domain has no group.
final class Group {
  const Group({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String name;
  final Currency currency;

  /// Id of the creating account or device.
  final String createdBy;

  /// UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Group &&
      other.id == id &&
      other.name == name &&
      other.currency == currency &&
      other.createdBy == createdBy &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, currency, createdBy, createdAt);

  @override
  String toString() => 'Group($id, $name, ${currency.code})';
}

/// Source of truth for groups. Lists are ordered by creation time, then id.
abstract interface class GroupsRepository {
  /// Live groups; emits the current list first, then after every change.
  Stream<List<Group>> watchGroups();

  Future<RepoResult<Group>> get(String id);

  /// [name] is trimmed and must not be empty.
  Future<RepoResult<Group>> create({
    required String name,
    required Currency currency,
    required String createdBy,
  });

  /// Replaces name and currency. [name] is trimmed and must not be empty.
  /// Whether a currency change is allowed once entries exist is a ViewModel
  /// rule; the repository stores what it is given.
  Future<RepoResult<Group>> update(
    String id, {
    required String name,
    required Currency currency,
  });

  /// Soft delete; call the returned [Undo] to bring the group back.
  Future<RepoResult<Undo>> softDelete(String id);

  /// [NotFound] for unknown ids, [Conflict] if the group is not deleted.
  Future<RepoResult<void>> restore(String id);
}
