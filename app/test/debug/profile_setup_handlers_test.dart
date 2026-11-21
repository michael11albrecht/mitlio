import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_drive.dart';
import 'package:mitlio/debug/handlers/setup.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';

import '../features/profile/ui/profile_flow_rig.dart';

/// The profile flow through `ext.mitlio.setup.*` (PU-T07): the same
/// commands the screens use, answers as JSON params.
void main() {
  late ProfileFlowRig rig;
  late Map<String, DriveHandler> h;

  Map<String, String> p(Object? answer) => {
    'flowId': profileFlowId,
    if (answer != null) 'answer': jsonEncode(answer),
  };

  setUp(() {
    rig = ProfileFlowRig();
    final c = rig.container();
    addTearDown(c.dispose);
    h = setupDriveHandlers(c);
  });

  test('the whole flow: profile and IBAN land in their repositories', () async {
    var r = await h['setup.state']!(p(null));
    expect((r['step'], r['total']), (profileStepName, 4));
    r = await h['setup.next']!(p('Anna Beispiel'));
    expect(r['step'], profileStepAvatar);
    r = await h['setup.next']!(p({'color': null, 'emoji': '🚗'}));
    r = await h['setup.next']!(p(true));
    expect((r['step'], r['total']), (profileStepPaypalMe, 5));
    r = await h['setup.next']!(p('paypal.me/annab'));
    r = await h['setup.next']!(p(true));
    r = await h['setup.next']!(
      p({'iban': 'DE89 3704 0044 0532 0130 00', 'holder': 'Anna Beispiel'}),
    );
    expect(r['finished'], isTrue);
    // The snapshot and the saved progress never hold the IBAN.
    expect(jsonEncode(r), isNot(contains('0532')));
    expect(rig.setup.stored[profileFlowId], isNot(contains('0532')));
    final profile = (await rig.storedProfile())!;
    expect(
      (profile.displayName, profile.avatarEmoji, profile.paypalMe),
      ('Anna Beispiel', '🚗', 'annab'),
    );
    expect((await rig.storedBank())!.iban, 'DE89370400440532013000');
  });

  test('the skip path needs only the name', () async {
    await h['setup.next']!(p('Anna'));
    var r = await h['setup.skip']!(p(null));
    r = await h['setup.skip']!(p(null));
    r = await h['setup.skip']!(p(null));
    expect(r['finished'], isTrue);
    expect(r['skipped'], [
      profileStepAvatar,
      profileStepPaypalWanted,
      profileStepBankWanted,
    ]);
    expect(await rig.storedBank(), isNull);
  });

  test('"no" skips the PayPal.Me and IBAN steps', () async {
    await h['setup.next']!(p('Anna'));
    await h['setup.skip']!(p(null));
    var r = await h['setup.next']!(p(false));
    expect(r['step'], profileStepBankWanted);
    r = await h['setup.next']!(p(false));
    expect(r['finished'], isTrue);
  });

  test('a bad IBAN and a failing save are errors, nothing moves', () async {
    await h['setup.next']!(p('Anna'));
    await h['setup.skip']!(p(null));
    await h['setup.skip']!(p(null));
    await h['setup.next']!(p(true));
    final typo = {'iban': 'DE89 3704 0044 0532 0130 01', 'holder': 'Anna'};
    expect((await h['setup.next']!(p(typo)))['error'], 'invalid_params');
    final good = {'iban': 'DE89 3704 0044 0532 0130 00', 'holder': 'Anna'};
    rig.bank.failSaveWith = const Storage('full');
    expect((await h['setup.next']!(p(good)))['error'], 'internal');
    final r = await h['setup.state']!(p(null));
    expect(r['step'], profileStepIban);
    expect(await rig.storedBank(), isNull);
  });
}
