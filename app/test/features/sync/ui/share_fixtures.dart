import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/repositories/share_link_repository.dart';
import 'package:mitlio/features/sync/ui/share_view_model.dart';

/// Fixed state for the share sheet; no command does anything.
class StubShareViewModel extends ShareViewModel {
  StubShareViewModel(super.groupId, this.fixed);

  final ShareState fixed;

  @override
  ShareState build() => fixed;

  @override
  Future<void> share() async {}
}

List<Override> shareStateOverride(ShareState state) => [
  shareViewModelProvider.overrideWith2(
    (id) => StubShareViewModel(id, state),
  ),
];

const sampleLink = ShareLink(
  token: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
  siteUrl: 'https://mitlio.web.app',
);

/// Named states for goldens and widget tests.
final shareStates = <(String, ShareState)>[
  ('loading', const ShareLoading()),
  (
    'owner',
    const ShareReady(
      link: sampleLink,
      groupName: 'Wochenende in den Bergen',
      isOwner: true,
    ),
  ),
  (
    'owner_confirm',
    const ShareReady(
      link: sampleLink,
      groupName: 'Wochenende in den Bergen',
      isOwner: true,
      confirmingRotate: true,
      rotateError: ShareFailureLink(LinkRemoteFailure(Offline())),
    ),
  ),
  (
    'member',
    const ShareReady(
      link: sampleLink,
      groupName: 'Wochenende in den Bergen',
      isOwner: false,
    ),
  ),
  ('member_rotated', const ShareFailed(ShareFailureLink(LinkRotated()))),
];
