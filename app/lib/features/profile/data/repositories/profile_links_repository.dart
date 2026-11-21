import 'package:flutter/services.dart';
import 'package:mitlio/features/settle/data/services/payment_link_service.dart';

/// Where the profile flow sends people: PayPal.Me links (to test theirs or
/// to create one) and the clipboard for "Einfügen".
class ProfileLinksRepository {
  const ProfileLinksRepository({required this.launcher});

  final LinkLauncher launcher;

  /// `https://www.paypal.com/paypalme/`: PayPal's own page to claim a link.
  static final Uri createPaypalMeUri = Uri.parse(
    'https://www.paypal.com/paypalme/',
  );

  /// True if [uri] opened; otherwise it is copied and false returned.
  Future<bool> open(Uri uri) async {
    if (await launcher.launchExternal(uri)) return true;
    await launcher.copyToClipboard(uri.toString());
    return false;
  }

  /// The text on the clipboard; null if there is none or it cannot be read.
  Future<String?> pasteText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      return text == null || text.trim().isEmpty ? null : text;
    } on PlatformException {
      return null;
    }
  }
}
