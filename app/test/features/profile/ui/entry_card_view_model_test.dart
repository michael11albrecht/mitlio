import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/ui/entry_card_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer c;

  setUp(() {
    app = FakeApp();
    c = app.container();
    addTearDown(c.dispose);
  });

  /// Keeps the card alive and waits for its first reading.
  Future<bool> visible(EntryCard card) async {
    c.listen(entryCardViewModelProvider(card), (_, _) {});
    await pumpEventQueue();
    return c.read(entryCardViewModelProvider(card));
  }

  EntryCardViewModel vm(EntryCard card) =>
      c.read(entryCardViewModelProvider(card).notifier);

  Future<void> addGroup() async => ok(
    await app.groups.create(name: 'Trip', currency: eur, createdBy: 'dev'),
  );

  group('settlePayment', () {
    test('shown while the profile has no payment details', () async {
      expect(await visible(EntryCard.settlePayment), isTrue);
    });

    test('gone once PayPal.Me or an IBAN exists', () async {
      ok(await app.profile.save(displayName: 'Mia', paypalMe: 'mia'));
      expect(await visible(EntryCard.settlePayment), isFalse);
    });

    test('an IBAN alone is enough', () async {
      ok(await app.profile.save(displayName: 'Mia'));
      ok(await app.profileBank.save(iban: 'DE89370400440532013000'));
      expect(await visible(EntryCard.settlePayment), isFalse);
    });

    test('gone after the flow was finished, on refresh', () async {
      expect(await visible(EntryCard.settlePayment), isTrue);
      ok(await app.profile.save(displayName: 'Mia', paypalMe: 'mia'));
      await vm(EntryCard.settlePayment).refresh();
      expect(
        c.read(entryCardViewModelProvider(EntryCard.settlePayment)),
        false,
      );
    });
  });

  group('groupCar', () {
    test('shown without a personal car, gone with one', () async {
      expect(await visible(EntryCard.groupCar), isTrue);
      ok(
        await app.userVehicles.add(
          name: 'Golf',
          fuelType: FuelType.petrol,
          consumptionMilliPer100km: 6500,
        ),
      );
      await vm(EntryCard.groupCar).refresh();
      expect(c.read(entryCardViewModelProvider(EntryCard.groupCar)), false);
    });
  });

  group('newGroupProfile', () {
    test('needs an existing group and no profile', () async {
      expect(await visible(EntryCard.newGroupProfile), isFalse);
      await addGroup();
      await vm(EntryCard.newGroupProfile).refresh();
      expect(
        c.read(entryCardViewModelProvider(EntryCard.newGroupProfile)),
        true,
      );
      ok(await app.profile.save(displayName: 'Mia'));
      await vm(EntryCard.newGroupProfile).refresh();
      expect(
        c.read(entryCardViewModelProvider(EntryCard.newGroupProfile)),
        false,
      );
    });
  });

  group('dismiss', () {
    test('hides the card for good, also in a new container', () async {
      expect(await visible(EntryCard.settlePayment), isTrue);
      ok(await vm(EntryCard.settlePayment).dismiss());
      expect(
        c.read(entryCardViewModelProvider(EntryCard.settlePayment)),
        false,
      );

      final again = app.container();
      addTearDown(again.dispose);
      again.listen(
        entryCardViewModelProvider(EntryCard.settlePayment),
        (_, _) {},
      );
      await pumpEventQueue();
      expect(
        again.read(entryCardViewModelProvider(EntryCard.settlePayment)),
        false,
      );
    });

    test('dismissing one card leaves the others', () async {
      ok(await vm(EntryCard.settlePayment).dismiss());
      expect(await visible(EntryCard.groupCar), isTrue);
    });

    test('a failure is returned and the card stays', () async {
      expect(await visible(EntryCard.settlePayment), isTrue);
      app.setupState.failSaveWith = const Storage('disk full');
      expect(
        err(await vm(EntryCard.settlePayment).dismiss()),
        const Storage('disk full'),
      );
      expect(c.read(entryCardViewModelProvider(EntryCard.settlePayment)), true);
    });
  });

  test('a flag that cannot be read never hides the card', () async {
    app.setupState.failLoadWith = const Storage('disk full');
    expect(await visible(EntryCard.settlePayment), isTrue);
  });
}
