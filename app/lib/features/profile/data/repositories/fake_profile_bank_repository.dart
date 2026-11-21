import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [ProfileBankRepository] with the same behaviour as the Drift one.
class FakeProfileBankRepository implements ProfileBankRepository {
  FakeProfileBankRepository({required this._profile});

  final FakeProfileRepository _profile;
  ProfileBank? _bank;

  @override
  Future<RepoResult<ProfileBank?>> get() async => Ok(_bank);

  @override
  Future<RepoResult<ProfileBank>> save({
    required String iban,
    String? bic,
    String? accountName,
  }) async {
    final built = buildProfileBank(
      iban: iban,
      bic: bic,
      accountName: accountName,
    );
    if (built case Err<ProfileBank, RepositoryError>(:final error)) {
      return Err(error);
    }
    if (!_profile.exists) return const Err(NotFound('profile', 'me'));
    final bank = built.orThrow();
    _bank = bank;
    return Ok(bank);
  }

  @override
  Future<RepoResult<void>> clear() async {
    _bank = null;
    return const Ok(null);
  }
}
