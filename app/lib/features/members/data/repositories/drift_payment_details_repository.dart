import 'package:drift/drift.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/hlc.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';
import 'package:mitlio_domain/mitlio_domain.dart' hide Hlc;

/// [PaymentDetailsRepository] backed by Drift: handle and masked hint on the
/// member row, the encrypted IBAN in `local_member_bank`.
class DriftPaymentDetailsRepository implements PaymentDetailsRepository {
  DriftPaymentDetailsRepository({
    required this._db,
    required this._clock,
    required this._cipher,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IbanCipher _cipher;

  @override
  Future<RepoResult<PaymentDetails>> get(String memberId) =>
      guardStorage(() async {
        final member = await _db.membersDao.findById(memberId);
        if (member == null) return Err(NotFound('member', memberId));
        final bank = await _db.localMemberBankDao.findByMember(memberId);
        return Ok(
          PaymentDetails(
            memberId: memberId,
            paypalMe: member.paypalMe,
            iban: bank == null ? null : await _cipher.decrypt(bank.iban),
            bic: bank?.bic,
            accountName: bank?.accountName,
          ),
        );
      });

  @override
  Future<RepoResult<PaymentDetails>> save(
    String memberId, {
    String? paypalMe,
    String? iban,
    String? bic,
    String? accountName,
  }) => guardStorage(() async {
    final normalized = normalizePaymentDetails(
      memberId,
      paypalMe: paypalMe,
      iban: iban,
      bic: bic,
      accountName: accountName,
    );
    // A switch *statement* assigning a `final` local inside this async closure
    // crashed the Linux x64 AOT compiler (linearscan.cc "unreachable code",
    // Flutter 3.50). Keep the switch an expression and store in a method.
    return switch (normalized) {
      Err(:final error) => Err(
        InvalidData('invalid: ${error.keys.map((f) => f.name).join(', ')}'),
      ),
      Ok(:final value) => await _store(memberId, value),
    };
  });

  Future<RepoResult<PaymentDetails>> _store(
    String memberId,
    PaymentDetails details,
  ) async {
    final member = await _db.membersDao.findById(memberId);
    if (member == null) return Err(NotFound('member', memberId));
    final plainIban = details.iban;
    final encrypted = plainIban == null
        ? null
        : await _cipher.encrypt(plainIban);
    await _db.transaction(() async {
      await _db.membersDao.updateMember(
        id: memberId,
        name: member.name,
        position: member.position,
        paypalMe: details.paypalMe,
        ibanHint: details.ibanHint,
        updatedAt: Hlc.now(_clock),
      );
      if (encrypted == null) {
        await _db.localMemberBankDao.deleteByMember(memberId);
      } else {
        await _db.localMemberBankDao.upsert(
          LocalMemberBankCompanion.insert(
            memberId: memberId,
            iban: encrypted,
            bic: Value(details.bic),
            accountName: Value(details.accountName),
            updatedAt: Hlc.now(_clock),
          ),
        );
      }
    });
    return Ok(details);
  }
}
