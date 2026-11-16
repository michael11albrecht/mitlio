import 'package:mitlio/features/settle/data/services/payment_link_service.dart';

/// The two legal pages that live on the website.
enum LegalPage { privacy, imprint }

/// Opens the legal pages of the website (single source of truth for the
/// texts, so the app and the site never disagree).
class LegalLinksRepository {
  const LegalLinksRepository({required this.launcher, required this.siteUrl});

  final LinkLauncher launcher;

  /// Public origin of the website, without trailing slash.
  final String siteUrl;

  /// Paths mirror `paths` in `web/src/i18n/index.ts`.
  Uri uriFor(LegalPage page, String languageCode) {
    final de = languageCode == 'de';
    final path = switch (page) {
      LegalPage.privacy => de ? '/datenschutz/' : '/en/privacy/',
      LegalPage.imprint => de ? '/impressum/' : '/en/imprint/',
    };
    return Uri.parse('$siteUrl$path');
  }

  /// True if the page opened; otherwise the link is copied and false returned.
  Future<bool> open(LegalPage page, String languageCode) async {
    final uri = uriFor(page, languageCode);
    if (await launcher.launchExternal(uri)) return true;
    await launcher.copyToClipboard(uri.toString());
    return false;
  }
}
