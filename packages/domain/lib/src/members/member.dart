// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/// The minimal member view the domain needs.
final class Member {
  /// Creates a member with stable [id] and display [position].
  const Member({required this.id, required this.position});

  final String id;
  final int position;

  @override
  bool operator ==(Object other) =>
      other is Member && other.id == id && other.position == position;

  @override
  int get hashCode => Object.hash(id, position);

  @override
  String toString() => 'Member($id, $position)';
}

/// Members sorted by position, then id (`String.compareTo`).
List<Member> tieOrder(Iterable<Member> members) {
  return members.toList()..sort((a, b) {
    final byPos = a.position.compareTo(b.position);
    return byPos != 0 ? byPos : a.id.compareTo(b.id);
  });
}
