import 'dart:async';

import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/repositories/connections_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [ConnectionsRepository] for tests and DebugDrive.
class FakeConnectionsRepository implements ConnectionsRepository {
  FakeConnectionsRepository([this._state = GroupConnections.localOnly]);

  GroupConnections _state;
  final _changes = StreamController<GroupConnections>.broadcast(sync: true);

  /// The current state; setting it emits.
  GroupConnections get state => _state;
  set state(GroupConnections value) {
    _state = value;
    _changes.add(value);
  }

  /// Fails the next `disconnect` / `connectMe` with this, once.
  RemoteError? failDisconnect;
  RemoteError? failConnect;

  /// What `refresh` answers.
  String? refreshedName;

  final disconnectCalls = <(String, String)>[];
  final connectCalls = <(String, String)>[];
  int refreshCalls = 0;

  @override
  Stream<GroupConnections> watch(String groupId) async* {
    yield _state;
    yield* _changes.stream;
  }

  @override
  Future<Result<void, RemoteError>> disconnect(
    String groupId,
    String memberId,
  ) async {
    disconnectCalls.add((groupId, memberId));
    final error = failDisconnect;
    if (error != null) {
      failDisconnect = null;
      return Err(error);
    }
    state = GroupConnections(
      shared: _state.shared,
      isOwner: _state.isOwner,
      signedIn: _state.signedIn,
      connectedIds: {..._state.connectedIds}..remove(memberId),
      myMemberId: _state.myMemberId,
    );
    return const Ok(null);
  }

  @override
  Future<Result<void, RemoteError>> connectMe(
    String groupId,
    String memberId,
  ) async {
    connectCalls.add((groupId, memberId));
    final error = failConnect;
    if (error != null) {
      failConnect = null;
      return Err(error);
    }
    state = GroupConnections(
      shared: _state.shared,
      isOwner: _state.isOwner,
      signedIn: _state.signedIn,
      connectedIds: {..._state.connectedIds, memberId},
      myMemberId: memberId,
    );
    return const Ok(null);
  }

  @override
  Future<String?> refresh(String groupId) async {
    refreshCalls++;
    return refreshedName;
  }
}
