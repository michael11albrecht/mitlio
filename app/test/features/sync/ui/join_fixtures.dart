import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/repositories/join_repository.dart';
import 'package:mitlio/features/sync/ui/join_view_model.dart';

/// Fixed state for the join screen; no command does anything.
class StubJoinViewModel extends JoinViewModel {
  StubJoinViewModel(super.token, this.fixed);

  final JoinState fixed;

  @override
  JoinState build() => fixed;

  @override
  Future<void> start() async {}
}

List<Override> joinStateOverride(JoinState state) => [
  joinViewModelProvider.overrideWith2(
    (token) => StubJoinViewModel(token, state),
  ),
];

const _people = [
  JoinPerson(id: 'm-peter', name: 'Peter', connected: false),
  JoinPerson(id: 'm-bob', name: 'Bob', connected: true),
  JoinPerson(id: 'm-jonas', name: 'Jonas', connected: false),
];

/// Named states for goldens.
final joinStates = <(String, JoinState)>[
  ('joining', const JoinJoining()),
  (
    'picker',
    const JoinChoosePerson(
      groupId: 'g-1',
      groupName: 'Urlaub Kroatien',
      people: _people,
    ),
  ),
  (
    'picker_notice',
    const JoinChoosePerson(
      groupId: 'g-1',
      groupName: 'Urlaub Kroatien',
      people: _people,
      notice: JoinProblemConnect(MemberAlreadyClaimed(), personName: 'Jonas'),
    ),
  ),
  (
    'invalid',
    const JoinFailed(JoinProblemJoin(JoinRemoteFailure(InviteInvalid()))),
  ),
  (
    'offline',
    const JoinFailed(JoinProblemJoin(JoinRemoteFailure(Offline()))),
  ),
  (
    'rate_limited',
    const JoinFailed(
      JoinProblemJoin(
        JoinRemoteFailure(RateLimitedRemote(Duration(minutes: 7))),
      ),
    ),
  ),
];
