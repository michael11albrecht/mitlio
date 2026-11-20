import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_providers.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_repository.dart';

/// Command for the "Made with ♥ by Michael Albrecht" line in Settings.
class AuthorCreditViewModel {
  const AuthorCreditViewModel(this._repository);

  final LegalLinksRepository _repository;

  /// Opens the profile in the external browser. False means it did not open
  /// (the link was copied instead, or the platform failed).
  Future<bool> openProfile() async {
    try {
      return await _repository.openAuthorProfile();
    } on Object {
      return false;
    }
  }
}

final authorCreditViewModelProvider = Provider<AuthorCreditViewModel>(
  (ref) => AuthorCreditViewModel(ref.watch(legalLinksRepositoryProvider)),
);
