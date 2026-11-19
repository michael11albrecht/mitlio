import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/sync/data/repositories/join_repository.dart';
import 'package:mitlio/features/sync/ui/join_view_model.dart';

/// `ext.mitlio.join {token}` runs the `JoinViewModel` commands the join
/// screen runs; `join.connect {memberId}`, `join.create {name}` and
/// `join.skip` continue the join started last. The token is a secret: only a
/// short prefix is ever reported.
Map<String, DriveHandler> joinDriveHandlers(ProviderContainer c) {
  String? token;
  ProviderSubscription<JoinState>? sub;

  Map<String, Object?> report() {
    final t = token!;
    final hint = '${t.substring(0, t.length < 4 ? t.length : 4)}…';
    return switch (c.read(joinViewModelProvider(t))) {
      JoinJoining() => {'state': 'joining', 'token': hint},
      JoinDone(:final groupId) => {
        'state': 'done',
        'groupId': groupId,
        'token': hint,
      },
      JoinChoosePerson(
        :final groupId,
        :final groupName,
        :final people,
        :final notice,
      ) =>
        {
          'state': 'choosePerson',
          'groupId': groupId,
          'groupName': groupName,
          'people': [
            for (final p in people)
              {'id': p.id, 'name': p.name, 'connected': p.connected},
          ],
          if (notice != null) ..._problem(notice),
          'token': hint,
        },
      JoinFailed(:final problem, :final groupId) => {
        'state': 'failed',
        ..._problem(problem),
        'groupId': ?groupId,
        'token': hint,
      },
    };
  }

  Future<Map<String, Object?>> command(
    Future<void> Function(JoinViewModel vm) run,
  ) async {
    if (token == null) return invalidParams('call join first');
    await run(c.read(joinViewModelProvider(token!).notifier));
    return report();
  }

  return {
    'join': (p) async {
      final t = p['token'];
      if (t == null || t.isEmpty) return invalidParams('need token');
      sub?.close();
      token = t;
      // Keeps the auto-disposed notifier alive between commands.
      sub = c.listen(joinViewModelProvider(t), (_, _) {});
      return command((vm) => vm.start());
    },
    'join.connect': (p) async {
      final id = p['memberId'];
      if (id == null) return invalidParams('need memberId');
      return command((vm) => vm.choose(id));
    },
    'join.create': (p) async {
      final name = p['name'];
      if (name == null) return invalidParams('need name');
      return command((vm) => vm.createPerson(name));
    },
    'join.skip': (_) async => command((vm) async => vm.skip()),
  };
}

Map<String, Object?> _problem(JoinProblem problem) => switch (problem) {
  JoinProblemJoin(failure: JoinRemoteFailure(:final error)) => {
    'error': error.caseName,
    'message': '$error',
  },
  JoinProblemJoin(failure: JoinLocalFailure()) => {
    'error': 'local',
    'message': 'this phone could not store the group',
  },
  JoinProblemConnect(:final error) => {
    'error': error.caseName,
    'message': '$error',
  },
  JoinProblemNameRequired() => {
    'error': 'nameRequired',
    'message': 'a name is needed',
  },
};
