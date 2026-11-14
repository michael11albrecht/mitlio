import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/drift_payment_details_repository.dart';
import 'package:mitlio/features/members/data/repositories/fake_members_repository.dart';
import 'package:mitlio/features/members/data/repositories/fake_payment_details_repository.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/members/data/services/fake_iban_cipher.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../repo_test_support.dart';
import 'payment_details_repository_contract.dart';

Future<PaymentRepos> _drift([
  IbanCipher cipher = const FakeIbanCipher(),
]) async {
  final base = await driftRepos();
  return (
    base: base,
    payments: DriftPaymentDetailsRepository(
      db: base.db!,
      clock: base.clock,
      cipher: cipher,
    ),
  );
}

Future<PaymentRepos> _fake() async {
  final base = await fakeRepos();
  return (
    base: base,
    payments: FakePaymentDetailsRepository(
      members: base.members as FakeMembersRepository,
    ),
  );
}

class _FailingCipher implements IbanCipher {
  @override
  Future<String> encrypt(String plain) async => plain;

  @override
  Future<String> decrypt(String stored) async => throw StateError('no key');

  @override
  Future<void> deleteKey() async {}
}

Map<PaymentField, PaymentFieldError> _errors(
  Result<PaymentDetails, Map<PaymentField, PaymentFieldError>> r,
) => switch (r) {
  Ok() => fail('expected field errors'),
  Err(:final error) => error,
};

void main() {
  runPaymentDetailsRepositoryContract('drift', _drift);
  runPaymentDetailsRepositoryContract('fake', _fake);

  group('Drift storage', () {
    late PaymentRepos r;
    late String annId;

    setUp(() async {
      r = await _drift();
      annId = (await seedGroup(r.base)).members.first.id;
    });

    test(
      'the IBAN is stored encrypted, in the local bank table only',
      () async {
        ok(
          await r.payments.save(
            annId,
            iban: testIban,
            bic: 'COBADEFFXXX',
            accountName: 'Ann',
          ),
        );
        final row = (await r.base.db!.localMemberBankDao.findByMember(annId))!;
        expect(
          row.iban,
          '${FakeIbanCipher.marker}${testIban.split('').reversed.join()}',
        );
        expect(row.iban, isNot(contains(testIban)));
        expect(row.bic, 'COBADEFFXXX');
        expect(row.accountName, 'Ann');

        // Nothing of the IBAN reaches the synced members row.
        final member = (await r.base.db!.membersDao.findById(annId))!;
        expect(member.toString(), isNot(contains(testIban)));
        expect(member.ibanHint, 'DE89 •••• 3000');
      },
    );

    test('values stored without a key stay readable', () async {
      final plain = DriftPaymentDetailsRepository(
        db: r.base.db!,
        clock: r.base.clock,
        cipher: const PlaintextIbanCipher(),
      );
      ok(await plain.save(annId, iban: testIban));
      final row = (await r.base.db!.localMemberBankDao.findByMember(annId))!;
      expect(row.iban, testIban);
      expect(ok(await plain.get(annId)).iban, testIban);
      // The encrypting repository still reads a plaintext row.
      expect(ok(await r.payments.get(annId)).iban, testIban);
    });

    test('clearing the IBAN deletes the local bank row', () async {
      ok(await r.payments.save(annId, iban: testIban));
      ok(await r.payments.save(annId, paypalMe: 'ann'));
      expect(await r.base.db!.localMemberBankDao.findByMember(annId), isNull);
    });

    test('an undecryptable value is a storage error, not a crash', () async {
      ok(await r.payments.save(annId, iban: testIban));
      final broken = DriftPaymentDetailsRepository(
        db: r.base.db!,
        clock: r.base.clock,
        cipher: _FailingCipher(),
      );
      expect(err(await broken.get(annId)), isA<Storage>());
    });

    test('a failing write rolls back the member update', () async {
      await r.base.db!.customStatement('DROP TABLE local_member_bank');
      expect(
        err(await r.payments.save(annId, paypalMe: 'ann', iban: testIban)),
        isA<Storage>(),
      );
      final member = (await r.base.db!.membersDao.findById(annId))!;
      expect(member.paypalMe, isNull);
      expect(member.ibanHint, isNull);
    });
  });

  group('normalizePaymentDetails', () {
    test('maskIban masks the middle and rejects short values', () {
      expect(maskIban(testIban), 'DE89 •••• 3000');
      expect(maskIban(null), isNull);
      expect(maskIban('DE12'), isNull);
    });

    test('BIC and account name without IBAN are an IBAN error', () {
      final r = normalizePaymentDetails('m', bic: 'COBADEFFXXX');
      expect(
        _errors(r),
        {PaymentField.iban: PaymentFieldError.invalid},
      );
    });

    test('a bad checksum is told apart from a bad format', () {
      final checksum = normalizePaymentDetails(
        'm',
        iban: 'DE89370400440532013001',
      );
      final format = normalizePaymentDetails('m', iban: 'DE89');
      expect(
        _errors(checksum),
        {PaymentField.iban: PaymentFieldError.checksum},
      );
      expect(
        _errors(format),
        {PaymentField.iban: PaymentFieldError.invalid},
      );
    });

    test('account name is limited to 70 characters on one line', () {
      for (final bad in ['x' * 71, 'a\nb']) {
        final r = normalizePaymentDetails(
          'm',
          iban: testIban,
          accountName: bad,
        );
        expect(
          _errors(r),
          {PaymentField.accountName: PaymentFieldError.invalid},
        );
      }
    });

    test('toString never shows the IBAN', () {
      const d = PaymentDetails(memberId: 'm', iban: testIban);
      expect(d.toString(), isNot(contains('DE89')));
    });
  });
}
