import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/profile/ui/profile_entry_view_model.dart';

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

  group('ProfileEntryViewModel', () {
    Future<ProfileSummary> summary() async {
      c.listen(profileEntryViewModelProvider, (_, _) {});
      await c.read(profileEntryViewModelProvider.notifier).refresh();
      return c.read(profileEntryViewModelProvider);
    }

    test('says how complete the profile is', () async {
      expect(await summary(), ProfileSummary.none);
      ok(await app.profile.save(displayName: 'Mia'));
      expect(await summary(), ProfileSummary.noPayment);
      ok(await app.profile.save(displayName: 'Mia', paypalMe: 'mia'));
      expect(await summary(), ProfileSummary.paypal);
      ok(await app.profileBank.save(iban: 'DE89370400440532013000'));
      expect(await summary(), ProfileSummary.both);
      ok(await app.profile.save(displayName: 'Mia'));
      expect(await summary(), ProfileSummary.iban);
    });
  });
}
