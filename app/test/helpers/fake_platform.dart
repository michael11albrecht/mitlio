import 'package:mitlio/features/settle/data/services/payment_link_service.dart';
import 'package:mitlio/features/settle/data/services/share_service.dart';

/// Records launched links and clipboard writes instead of touching the OS.
class FakeLinkLauncher implements LinkLauncher {
  FakeLinkLauncher({this.canLaunch = true});

  /// False: no app can open a link (the link service falls back to copying).
  bool canLaunch;
  final launched = <Uri>[];
  final copied = <String>[];

  @override
  Future<bool> launchExternal(Uri uri) async {
    if (canLaunch) launched.add(uri);
    return canLaunch;
  }

  @override
  Future<void> copyToClipboard(String text) async => copied.add(text);
}

/// Records shared texts; can be made to fail.
class FakeShareService implements ShareService {
  final shared = <String>[];
  Exception? failWith;

  @override
  Future<void> shareText(String text) async {
    if (failWith != null) throw failWith!;
    shared.add(text);
  }
}
