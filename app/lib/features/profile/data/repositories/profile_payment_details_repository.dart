import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/profile/data/repositories/own_member_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Payment details for paying someone: for the own member ("Ich") what the
/// member lacks comes from the personal profile (PayPal.Me) and its local
/// bank details (IBAN, BIC, holder). Other members are read as stored.
/// Writes are not touched: the profile is never copied into a group.
class ProfilePaymentDetailsRepository implements PaymentDetailsRepository {
  ProfilePaymentDetailsRepository({
    required this._inner,
    required this._own,
    required this._profile,
    required this._bank,
  });

  final PaymentDetailsRepository _inner;
  final OwnMemberRepository _own;
  final ProfileRepository _profile;
  final ProfileBankRepository _bank;

  @override
  Future<RepoResult<PaymentDetails>> get(String memberId) async {
    final stored = await _inner.get(memberId);
    if (stored case Err<PaymentDetails, RepositoryError>(:final error)) {
      return Err(error);
    }
    final details = stored.orThrow();
    if (details.paypalMe != null && details.iban != null) return stored;
    switch (await _own.isOwn(memberId)) {
      case Err(:final error):
        return Err(error);
      case Ok(value: false):
        return stored;
      case Ok():
        break;
    }
    final profile = await _profile.get();
    if (profile case Err<UserProfile?, RepositoryError>(:final error)) {
      return Err(error);
    }
    final bank = details.iban == null ? await _bank.get() : null;
    if (bank case Err<ProfileBank?, RepositoryError>(:final error)) {
      return Err(error);
    }
    final profileBank = bank?.orThrow();
    final ownBank = details.iban != null;
    return Ok(
      PaymentDetails(
        memberId: memberId,
        paypalMe: details.paypalMe ?? profile.orThrow()?.paypalMe,
        iban: details.iban ?? profileBank?.iban,
        bic: ownBank ? details.bic : profileBank?.bic,
        accountName: ownBank ? details.accountName : profileBank?.accountName,
      ),
    );
  }

  @override
  Future<RepoResult<PaymentDetails>> save(
    String memberId, {
    String? paypalMe,
    String? iban,
    String? bic,
    String? accountName,
  }) => _inner.save(
    memberId,
    paypalMe: paypalMe,
    iban: iban,
    bic: bic,
    accountName: accountName,
  );
}
