import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet. Faked in tests.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class ShareService {
  Future<void> shareText(String text);
}

/// `share_plus`: the native share sheet (or its platform fallback).
class SystemShareService implements ShareService {
  const SystemShareService();

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
