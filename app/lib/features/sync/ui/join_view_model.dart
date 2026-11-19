import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/features/sync/data/invite_link.dart';
import 'package:mitlio/features/sync/data/repositories/join_repository.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What went wrong, in plain words ([text]): what happened and what to do
/// next (plan §2.6 #9, ADR-27 §3).
sealed class JoinProblem {
  const JoinProblem();

  String text(AppLocalizations l10n);

  /// Whether opening the link again can change anything.
  bool get canRetry => true;
}

/// A step of joining failed.
final class JoinProblemJoin extends JoinProblem {
  const JoinProblemJoin(this.failure);

  final JoinFailure failure;

  @override
  String text(AppLocalizations l10n) => switch (failure) {
    JoinRemoteFailure(error: Offline(), localCreated: false) =>
      l10n.joinOffline,
    JoinRemoteFailure(:final error) => remoteErrorText(l10n, error),
    JoinLocalFailure() => l10n.joinLocalFailed,
  };

  @override
  bool get canRetry => switch (failure) {
    JoinRemoteFailure(error: InviteInvalid()) => false,
    _ => true,
  };
}

/// Connecting to a person failed; [personName] fills the person cases.
final class JoinProblemConnect extends JoinProblem {
  const JoinProblemConnect(this.error, {this.personName});

  final RemoteError error;
  final String? personName;

  @override
  String text(AppLocalizations l10n) => error is Offline
      ? l10n.joinConnectOffline
      : remoteErrorText(l10n, error, personName: personName);
}

/// "Ich bin neu hier" without a name.
final class JoinProblemNameRequired extends JoinProblem {
  const JoinProblemNameRequired();

  @override
  String text(AppLocalizations l10n) => l10n.joinNameRequired;
}

sealed class JoinState {
  const JoinState();
}

/// Joining the group (and the first sync).
final class JoinJoining extends JoinState {
  const JoinJoining();
}

/// "Wer bist du?": the people of [groupName] to pick from.
final class JoinChoosePerson extends JoinState {
  const JoinChoosePerson({
    required this.groupId,
    required this.groupName,
    required this.people,
    this.busy = false,
    this.notice,
  });

  final String groupId;
  final String groupName;
  final List<JoinPerson> people;

  /// A connect is running.
  final bool busy;

  /// Why the last pick did not work; the list is already up to date.
  final JoinProblem? notice;

  JoinChoosePerson copyWith({
    List<JoinPerson>? people,
    bool? busy,
    JoinProblem? notice,
    bool clearNotice = false,
  }) => JoinChoosePerson(
    groupId: groupId,
    groupName: groupName,
    people: people ?? this.people,
    busy: busy ?? this.busy,
    notice: clearNotice ? null : notice ?? this.notice,
  );
}

/// In the group; the view opens it.
final class JoinDone extends JoinState {
  const JoinDone(this.groupId);

  final String groupId;
}

/// Stopped with [problem]. With a [groupId] the group is on this phone and the
/// view offers to open it.
final class JoinFailed extends JoinState {
  const JoinFailed(this.problem, {this.groupId});

  final JoinProblem problem;
  final String? groupId;
}

/// Opening an invite link: joins, then asks once "Wer bist du?" (P6-T14b,
/// ADR-24 §1/§5). Every user action is a command here; DebugDrive calls the
/// same ones. The [token] is a secret and never shown or logged.
class JoinViewModel extends Notifier<JoinState> {
  JoinViewModel(this.token);

  final String token;

  var _running = false;

  /// The new person made by an earlier try that did not get through, so a
  /// retry does not make a second one.
  String? _pendingId;
  String? _pendingName;

  JoinRepository get _repo => ref.read(joinRepositoryProvider);

  @override
  JoinState build() => const JoinJoining();

  /// Joins the group. Safe to call again (retry); ignored while running.
  Future<void> start() async {
    if (_running) return;
    _running = true;
    try {
      state = const JoinJoining();
      if (!isInviteToken(token)) {
        // Not a live invite for sure: no sign-in, no server call.
        state = const JoinFailed(
          JoinProblemJoin(JoinRemoteFailure(InviteInvalid())),
        );
        return;
      }
      final joined = await _repo.join(token);
      state = switch (joined) {
        Err(:final error) => JoinFailed(JoinProblemJoin(error)),
        Ok(:final value)
            when (value.alreadyMember && !value.createdHere) ||
                value.myMemberId != null =>
          JoinDone(value.groupId),
        Ok(:final value) => JoinChoosePerson(
          groupId: value.groupId,
          groupName: value.groupName,
          people: value.people,
        ),
      };
    } finally {
      _running = false;
    }
  }

  /// The user is [memberId]. A person someone else is connected to is
  /// refused here, not sent to the server.
  Future<void> choose(String memberId) async {
    final s = state;
    if (s is! JoinChoosePerson || s.busy) return;
    final person = s.people.where((p) => p.id == memberId).firstOrNull;
    if (person == null || person.connected) return;
    state = s.copyWith(busy: true, clearNotice: true);
    await _connect(s, memberId, person.name);
  }

  /// "Ich bin neu hier": makes [name] a person of the group (uploaded like
  /// any change) and connects to it.
  Future<void> createPerson(String name) async {
    final s = state;
    if (s is! JoinChoosePerson || s.busy) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = s.copyWith(notice: const JoinProblemNameRequired());
      return;
    }
    state = s.copyWith(busy: true, clearNotice: true);
    final String id;
    if (_pendingId case final pending?) {
      if (_pendingName != trimmed) {
        final renamed = await _repo.renamePerson(pending, trimmed);
        if (renamed case Err(:final error)) {
          state = s.copyWith(busy: false, notice: JoinProblemJoin(error));
          return;
        }
        _pendingName = trimmed;
      }
      id = pending;
    } else {
      final created = await _repo.createPerson(s.groupId, trimmed);
      switch (created) {
        case Err(:final error):
          state = s.copyWith(busy: false, notice: JoinProblemJoin(error));
          return;
        case Ok(:final value):
          id = value;
          _pendingId = value;
          _pendingName = trimmed;
      }
    }
    final uploaded = await _repo.upload(s.groupId);
    if (uploaded case Err(:final error)) {
      state = s.copyWith(busy: false, notice: JoinProblemConnect(error));
      return;
    }
    await _connect(s, id, trimmed);
  }

  /// "Überspringen": into the group without choosing; connecting later is
  /// still possible (ADR-24 §1).
  void skip() {
    final s = state;
    if (s is JoinChoosePerson && !s.busy) state = JoinDone(s.groupId);
  }

  Future<void> _connect(
    JoinChoosePerson s,
    String memberId,
    String name,
  ) async {
    final result = await _repo.connect(s.groupId, memberId);
    switch (result) {
      case Ok():
        state = JoinDone(s.groupId);
      case Err(:final error):
        await _onConnectError(s, memberId, name, error);
    }
  }

  Future<void> _onConnectError(
    JoinChoosePerson s,
    String memberId,
    String name,
    RemoteError error,
  ) async {
    switch (error) {
      case MemberAlreadyClaimed() || MemberGone():
        // The list the user picked from was stale: show the current one.
        final refreshed = await _repo.refresh(s.groupId);
        final people = switch (refreshed) {
          Ok(:final value) => value.people,
          Err() => [
            for (final p in s.people)
              if (p.id != memberId)
                p
              else if (error is MemberAlreadyClaimed)
                JoinPerson(id: p.id, name: p.name, connected: true),
          ],
        };
        state = s.copyWith(
          people: people,
          busy: false,
          notice: switch (refreshed) {
            Err(error: final failure) => JoinProblemJoin(failure),
            Ok() => JoinProblemConnect(error, personName: name),
          },
        );
      case AlreadyConnected():
        final refreshed = await _repo.refresh(s.groupId);
        final mine = switch (refreshed) {
          Ok(:final value) =>
            value.people
                .where((p) => p.id == value.myMemberId)
                .map((p) => p.name)
                .firstOrNull,
          Err() => null,
        };
        state = JoinFailed(
          JoinProblemConnect(error, personName: mine),
          groupId: s.groupId,
        );
      default:
        state = s.copyWith(busy: false, notice: JoinProblemConnect(error));
    }
  }
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final joinViewModelProvider = NotifierProvider.autoDispose
    .family<JoinViewModel, JoinState, String>(JoinViewModel.new);
