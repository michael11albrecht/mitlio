import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/fake_members_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [PaymentDetailsRepository] with the same behaviour as the Drift
/// one. Writes the synced hints through the given members repository.
class FakePaymentDetailsRepository implements PaymentDetailsRepository {
  FakePaymentDetailsRepository({required this._members});

  final FakeMembersRepository _members;
  final _bank = <String, PaymentDetails>{};

  @override
  Future<RepoResult<PaymentDetails>> get(String memberId) async {
    final member = _members.find(memberId);
    if (member == null) return Err(NotFound('member', memberId));
    final bank = _bank[memberId];
    return Ok(
      PaymentDetails(
        memberId: memberId,
        paypalMe: member.paypalMe,
        iban: bank?.iban,
        bic: bank?.bic,
        accountName: bank?.accountName,
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
  }) async {
    final normalized = normalizePaymentDetails(
      memberId,
      paypalMe: paypalMe,
      iban: iban,
      bic: bic,
      accountName: accountName,
    );
    final PaymentDetails details;
    switch (normalized) {
      case Ok(:final value):
        details = value;
      case Err(:final error):
        return Err(
          InvalidData('invalid: ${error.keys.map((f) => f.name).join(', ')}'),
        );
    }
    final member = _members.find(memberId);
    if (member == null) return Err(NotFound('member', memberId));
    final updated = await _members.update(
      memberId,
      name: member.name,
      paypalMe: details.paypalMe,
      ibanHint: details.ibanHint,
    );
    if (updated is Err<GroupMember, RepositoryError>) {
      return Err(updated.error);
    }
    if (details.iban == null) {
      _bank.remove(memberId);
    } else {
      _bank[memberId] = details;
    }
    return Ok(details);
  }
}
