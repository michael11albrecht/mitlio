import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import 'profile_flow_rig.dart';

const _iban = 'DE89 3704 0044 0532 0130 00';
const Map<String, Object?> _bank = {
  profileAnswerIban: _iban,
  profileAnswerHolder: 'Anna Beispiel',
};

void main() {
  late ProfileFlowRig rig;
  late ProviderContainer c;
  late SetupFlowViewModel vm;

  Future<void> start() async {
    c = rig.container();
    addTearDown(c.dispose);
    vm = c.read(setupFlowViewModelProvider(profileSetupFlow).notifier);
    await vm.restoring;
  }

  SetupFlowState read() => c.read(setupFlowViewModelProvider(profileSetupFlow));

  RepositoryError errorOf(RepoResult<void> r) =>
      (r as Err<void, RepositoryError>).error;

  setUp(() => rig = ProfileFlowRig());

  group('the whole flow', () {
    test('stores name, avatar, PayPal.Me and IBAN where they belong', () async {
      await start();
      expect(read().total, 4);
      await vm.next(answer: '  Anna  ');
      await vm.next(
        answer: {profileAnswerColor: 0xFF0B6B63, profileAnswerEmoji: '🚗'},
      );
      await vm.next(answer: true);
      expect(read().total, 5);
      await vm.next(answer: 'https://paypal.me/Anna?utm=x');
      await vm.next(answer: true);
      await vm.next(answer: _bank);
      expect(read().finished, isTrue);

      final profile = (await rig.storedProfile())!;
      expect(profile.displayName, 'Anna');
      expect(profile.avatarColor, 0xFF0B6B63);
      expect(profile.avatarEmoji, '🚗');
      expect(profile.paypalMe, 'Anna');
      final bank = (await rig.storedBank())!;
      expect(bank.iban, 'DE89370400440532013000');
      expect(bank.accountName, 'Anna Beispiel');
    });

    test('the IBAN never reaches the saved progress', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.skip();
      await vm.next(answer: true);
      await vm.next(answer: _bank);
      final saved = rig.setup.stored[profileFlowId]!;
      expect(saved, isNot(contains('DE89')));
      expect(saved, isNot(contains('0532')));
      expect(read().answers[profileStepIban], profileIbanStored);
    });

    test('resumes after a restart on the same step', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.next(answer: true);
      await start();
      expect(read().step?.id, profileStepPaypalMe);
      expect(read().answers[profileStepName], 'Anna');
    });
  });

  group('skip paths', () {
    test('only the name is required', () async {
      await start();
      expect(read().canSkip, isFalse);
      expect(errorOf(await vm.skip()), isA<InvalidData>());
      await vm.next(answer: 'Anna');
      expect(read().canSkip, isTrue);
    });

    test('skipping everything else finishes with just the name', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip(); // avatar
      await vm.skip(); // PayPal yes/no
      await vm.skip(); // bank yes/no
      expect(read().finished, isTrue);
      expect(read().skipped, [
        profileStepAvatar,
        profileStepPaypalWanted,
        profileStepBankWanted,
      ]);
      final profile = (await rig.storedProfile())!;
      expect((profile.displayName, profile.paypalMe), ('Anna', null));
      expect(await rig.storedBank(), isNull);
    });

    test('"no" passes over the PayPal.Me and the IBAN steps', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.next(answer: false);
      expect(read().step?.id, profileStepBankWanted);
      await vm.next(answer: false);
      expect(read().finished, isTrue);
      expect(read().total, 4);
    });

    test('the PayPal.Me and IBAN steps can be skipped too', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.next(answer: true);
      await vm.skip();
      await vm.next(answer: true);
      await vm.skip();
      expect(read().finished, isTrue);
      expect(await rig.storedBank(), isNull);
    });

    test('"no" forgets a PayPal.Me and an IBAN entered before', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.next(answer: true);
      await vm.next(answer: 'anna');
      await vm.next(answer: true);
      await vm.next(answer: _bank);
      // Back to the IBAN question, then the PayPal question: change minds.
      await vm.back();
      await vm.back();
      await vm.next(answer: false);
      expect(read().finished, isTrue);
      await vm.back(); // finish -> bank question
      await vm.back(); // PayPal.Me step
      await vm.back(); // PayPal question
      await vm.next(answer: false);
      final profile = (await rig.storedProfile())!;
      expect(profile.paypalMe, isNull);
      expect(await rig.storedBank(), isNull);
    });
  });

  group('validation errors', () {
    test('a blank or endless name', () async {
      await start();
      expect(errorOf(await vm.next(answer: '   ')), isA<InvalidData>());
      expect(errorOf(await vm.next(answer: 'x' * 61)), isA<InvalidData>());
      expect(read().step?.id, profileStepName);
      expect(rig.profile.exists, isFalse);
    });

    test('a PayPal.Me handle with forbidden characters', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.next(answer: true);
      expect(errorOf(await vm.next(answer: 'a b!')), isA<InvalidData>());
      expect(read().step?.id, profileStepPaypalMe);
    });

    test('an IBAN with a wrong checksum, and a missing holder', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.skip();
      await vm.next(answer: true);
      final typo = {
        profileAnswerIban: 'DE89 3704 0044 0532 0130 01',
        profileAnswerHolder: 'Anna',
      };
      expect(errorOf(await vm.next(answer: typo)), isA<InvalidData>());
      final noHolder = {profileAnswerIban: _iban, profileAnswerHolder: ' '};
      expect(errorOf(await vm.next(answer: noHolder)), isA<InvalidData>());
      expect(read().step?.id, profileStepIban);
      expect(await rig.storedBank(), isNull);
    });

    test('an avatar of the wrong shape', () async {
      await start();
      await vm.next(answer: 'Anna');
      expect(errorOf(await vm.next(answer: 'red')), isA<InvalidData>());
    });
  });

  group('repository failures', () {
    test('saving the profile fails: the step stays, nothing is lost', () async {
      await start();
      rig.profile.failSaveWith = const Storage('full');
      expect(errorOf(await vm.next(answer: 'Anna')), const Storage('full'));
      expect(read().step?.id, profileStepName);
      rig.profile.failSaveWith = null;
      expect(await vm.next(answer: 'Anna'), isA<Ok<void, RepositoryError>>());
      expect(read().step?.id, profileStepAvatar);
    });

    test('saving the IBAN fails: the step stays, no raw IBAN saved', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.skip();
      await vm.next(answer: true);
      rig.bank.failSaveWith = const Storage('full');
      expect(errorOf(await vm.next(answer: _bank)), const Storage('full'));
      expect(read().step?.id, profileStepIban);
      await vm.back();
      expect(rig.setup.stored[profileFlowId], isNot(contains('0532')));
    });

    test('the avatar needs the profile the name step creates', () async {
      await start();
      await vm.next(answer: 'Anna');
      // Simulate a profile that vanished (storage cleared).
      final fresh = ProfileFlowRig()..setup.stored.addAll(rig.setup.stored);
      rig = fresh;
      await start();
      expect(read().step?.id, profileStepAvatar);
      expect(
        errorOf(await vm.next(answer: {profileAnswerColor: 1})),
        isA<NotFound>(),
      );
    });
  });

  group('ProfileSetupViewModel', () {
    ProfileSetupViewModel model() => c.read(profileSetupViewModelProvider);

    test('"Link testen" opens the normalised link', () async {
      await start();
      expect(await model().openPaypalLink('@anna'), PaypalLinkOutcome.opened);
      expect(rig.launcher.launched.single.toString(), 'https://paypal.me/anna');
    });

    test('"Link testen" copies the link when nothing can open it', () async {
      await start();
      rig.launcher.canLaunch = false;
      expect(await model().openPaypalLink('anna'), PaypalLinkOutcome.copied);
      expect(rig.launcher.copied, ['https://paypal.me/anna']);
    });

    test('"Link testen" with an invalid handle does nothing', () async {
      await start();
      expect(await model().openPaypalLink('a b'), PaypalLinkOutcome.invalid);
      expect(rig.launcher.launched, isEmpty);
    });

    test('"Jetzt erstellen" opens PayPal, or copies the link', () async {
      await start();
      expect(await model().openCreatePaypalMe(), isTrue);
      rig.launcher.canLaunch = false;
      expect(await model().openCreatePaypalMe(), isFalse);
      expect(rig.launcher.copied.single, contains('paypal.com/paypalme'));
    });

    test('storedBank reads the IBAN back for the step', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.skip();
      await vm.next(answer: true);
      await vm.next(answer: _bank);
      final stored = await model().storedBank();
      expect(
        (stored as Ok<ProfileBank?, RepositoryError>).value?.accountName,
        'Anna Beispiel',
      );
    });
  });

  group('profileCardProvider', () {
    test('has the profile and only the end of the IBAN', () async {
      await start();
      await vm.next(answer: 'Anna');
      await vm.skip();
      await vm.skip();
      await vm.next(answer: true);
      await vm.next(answer: _bank);
      final result = await c.read(profileCardProvider.future);
      final card = (result as Ok<ProfileCardData?, RepositoryError>).value!;
      expect(card.profile.displayName, 'Anna');
      expect(card.ibanTail, '3000');
    });

    test('is empty without a profile', () async {
      await start();
      final result = await c.read(profileCardProvider.future);
      expect((result as Ok<ProfileCardData?, RepositoryError>).value, isNull);
    });

    test('reports a failing read', () async {
      await start();
      await vm.next(answer: 'Anna');
      rig.bank.failGetWith = const Storage('disk');
      final r = await c.read(profileCardProvider.future);
      expect((r as Err).error, const Storage('disk'));
    });
  });
}
