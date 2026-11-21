import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/own_member_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_payment_details_repository.dart';
import 'package:mitlio/features/settle/data/repositories/settle_actions_providers.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

typedef _Ids = ({String me, String other});

void main() {
  late FakeApp app;
  late OwnMemberRepository own;
  late ProfilePaymentDetailsRepository repo;
  late _Ids ids;

  setUp(() async {
    app = FakeApp();
    own = OwnMemberRepository(app.setupState);
    repo = ProfilePaymentDetailsRepository(
      inner: app.payments,
      own: own,
      profile: app.profile,
      bank: app.profileBank,
    );
    final g = ok(
      await app.groups.create(name: 'Trip', currency: eur, createdBy: 'dev'),
    );
    ids = (
      me: ok(await app.members.add(g.id, name: 'Mia')).id,
      other: ok(await app.members.add(g.id, name: 'Ben')).id,
    );
    ok(await own.mark(ids.me));
    ok(await app.profile.save(displayName: 'Mia', paypalMe: 'mia'));
    ok(
      await app.profileBank.save(
        iban: 'DE89370400440532013000',
        bic: 'COBADEFFXXX',
        accountName: 'Mia Muster',
      ),
    );
  });

  test('the own member without details is paid with the profile', () async {
    final d = ok(await repo.get(ids.me));
    expect(d.paypalMe, 'mia');
    expect(d.iban, 'DE89370400440532013000');
    expect(d.bic, 'COBADEFFXXX');
    expect(d.accountName, 'Mia Muster');
  });

  test('details the member has stay; only gaps are filled', () async {
    ok(await app.payments.save(ids.me, paypalMe: 'miagroup'));
    final d = ok(await repo.get(ids.me));
    expect(d.paypalMe, 'miagroup');
    expect(d.iban, 'DE89370400440532013000');
    ok(
      await app.payments.save(
        ids.me,
        paypalMe: 'miagroup',
        iban: 'DE02120300000000202051',
      ),
    );
    final both = ok(await repo.get(ids.me));
    expect(both.iban, 'DE02120300000000202051');
    expect(both.accountName, isNull);
  });

  test('other members never get the profile', () async {
    final d = ok(await repo.get(ids.other));
    expect([d.paypalMe, d.iban], [null, null]);
  });

  test('without a profile there is nothing to fill in', () async {
    final bare = FakeApp();
    final g = ok(
      await bare.groups.create(name: 'T', currency: eur, createdBy: 'dev'),
    );
    final me = ok(await bare.members.add(g.id, name: 'Mia')).id;
    final o = OwnMemberRepository(bare.setupState);
    ok(await o.mark(me));
    final r = ProfilePaymentDetailsRepository(
      inner: bare.payments,
      own: o,
      profile: bare.profile,
      bank: bare.profileBank,
    );
    final d = ok(await r.get(me));
    expect([d.paypalMe, d.iban], [null, null]);
  });

  test('read failures are reported, not hidden', () async {
    app.setupState.failLoadWith = const Storage('disk full');
    expect(err(await repo.get(ids.me)), const Storage('disk full'));
    app.setupState.failLoadWith = null;
    app.payments.failWith = const Storage('db');
    expect(err(await repo.get(ids.me)), const Storage('db'));
  });

  test('the settle actions use it for the own member', () async {
    final c = app.container();
    addTearDown(c.dispose);
    final actions = c.read(settleActionsRepositoryProvider);
    final mine = ok(await actions.options(ids.me));
    expect([mine.hasPaypal, mine.hasIban], [true, true]);
    expect(ok(await actions.options(ids.other)).isEmpty, isTrue);
  });
}
