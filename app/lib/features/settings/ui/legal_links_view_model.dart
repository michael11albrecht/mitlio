import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_providers.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_repository.dart';

/// Commands for "Datenschutzerklärung" and "Impressum" in Settings.
class LegalLinksViewModel {
  const LegalLinksViewModel(this._repository);

  final LegalLinksRepository _repository;

  /// Opens the privacy policy of the website in [languageCode]. False means
  /// the link was copied instead.
  Future<bool> openPrivacy(String languageCode) =>
      _open(LegalPage.privacy, languageCode);

  /// Opens the imprint, like [openPrivacy].
  Future<bool> openImprint(String languageCode) =>
      _open(LegalPage.imprint, languageCode);

  Future<bool> _open(LegalPage page, String languageCode) async {
    try {
      return await _repository.open(page, languageCode);
    } on Object {
      return false;
    }
  }
}

final legalLinksViewModelProvider = Provider<LegalLinksViewModel>(
  (ref) => LegalLinksViewModel(ref.watch(legalLinksRepositoryProvider)),
);
