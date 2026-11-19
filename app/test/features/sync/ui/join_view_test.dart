import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/router.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../../support/tap_counter.dart';
import '../support/join_support.dart';

void main() {
  late JoinWorld w;

  /// Opens the link on a phone with the real database and fake server.
  Future<ProviderContainerHandle> open(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
  }) async {
    await tester.runAsync(() async => w = await JoinWorld.create());
    final container = await pumpMitlio(
      tester,
      FakeApp(),
      locale: locale,
      extra: w.overrides,
    );
    return ProviderContainerHandle(container.read(routerProvider), tester);
  }

  testWidgets('one tap on your name puts you in the group', (tester) async {
    final h = await open(tester);
    await h.go('/join/${w.token}');
    expect(find.text('Wer bist du?'), findsOneWidget);
    expect(find.text('Urlaub Kroatien'), findsOneWidget);
    expect(find.text('verbunden'), findsOneWidget);
    expect(find.text('Ich bin neu hier'), findsOneWidget);
    expect(find.text('Überspringen'), findsOneWidget);
    final taps = TapCounter(tester);
    await taps.tap(find.text('Peter'));
    await h.settle();
    expect(h.location, '/groups/$joinGroupId');
    taps.expectWithinBudget('join_link_claim_self');
  });

  testWidgets('skipping goes to the group', (tester) async {
    final h = await open(tester);
    await h.go('/join/${w.token}');
    await tester.tap(find.text('Überspringen'));
    await h.settle();
    expect(h.location, '/groups/$joinGroupId');
  });

  testWidgets('a bad link says what to do', (tester) async {
    final h = await open(tester);
    await h.go('/join/tok-unknown-0');
    expect(
      find.text('Dieser Link gilt nicht mehr. Bitte um einen neuen Link.'),
      findsOneWidget,
    );
  });

  testWidgets('rate limit shows the minutes', (tester) async {
    final h = await open(tester);
    w.invites.failNext(const RateLimitedRemote(Duration(minutes: 7)));
    await h.go('/join/${w.token}');
    expect(
      find.text('Zu viele Versuche. Versuch es in 7 Min. nochmal.'),
      findsOneWidget,
    );
  });

  testWidgets('offline says nothing was created, in English too', (
    tester,
  ) async {
    final h = await open(tester, locale: const Locale('en'));
    w.invites.offline = true;
    await h.go('/join/${w.token}');
    expect(
      find.textContaining('nothing was created on this phone'),
      findsOneWidget,
    );
  });

  testWidgets('a person taken meanwhile stays in the picker with a notice', (
    tester,
  ) async {
    final h = await open(tester);
    await h.go('/join/${w.token}');
    await tester.runAsync(
      () =>
          w.otherPhone('other-1').joinGroup(w.token, claimMemberId: 'm-jonas'),
    );
    await tester.tap(find.text('Jonas'));
    await h.settle();
    expect(
      find.text(
        'Jonas ist schon mit einem anderen Handy verbunden. '
        'Wähl eine andere Person.',
      ),
      findsOneWidget,
    );
    expect(find.text('verbunden'), findsNWidgets(2));
  });
}

/// Small helper around the router and pumping.
class ProviderContainerHandle {
  ProviderContainerHandle(this._router, this._tester);

  final GoRouter _router;
  final WidgetTester _tester;

  String get location => _router.routeInformationProvider.value.uri.toString();

  Future<void> go(String path) async {
    _router.go(path);
    await settle();
  }

  Future<void> settle() async {
    await _tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await _tester.pumpAndSettle();
  }
}
