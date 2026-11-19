import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';

/// No silent errors: every RemoteError says what happened and what to do, in
/// de and en, with its placeholders filled.
void main() {
  final locales = <String, AppLocalizations>{
    'de': AppLocalizationsDe(),
    'en': AppLocalizationsEn(),
  };

  String text(
    String locale,
    RemoteError e, {
    String? personName,
    String? title,
  }) => remoteErrorText(
    locales[locale]!,
    e,
    personName: personName,
    title: title,
  );

  const cases = <RemoteError>[
    Offline(),
    RateLimitedRemote(null),
    RateLimitedRemote(Duration(minutes: 6)),
    InviteInvalid(),
    MemberAlreadyClaimed(),
    AlreadyConnected(),
    MemberGone(),
    NotOwner(),
    NotMember(),
    CannotRemoveSelf(),
    VersionTooOld(),
    ServerDown(),
    Rejected('payers_sum_mismatch'),
    PullFailed('invalid_updated_at'),
  ];

  for (final locale in locales.keys) {
    for (final e in cases) {
      test('$locale: $e is non-empty with no raw placeholder', () {
        final t = text(locale, e, personName: 'Anna', title: 'Pizza');
        expect(t.trim(), isNotEmpty);
        expect(t, isNot(contains('{')));
        expect(t, isNot(contains('}')));
        // Without optional names it must still read fine.
        final bare = text(locale, e);
        expect(bare.trim(), isNotEmpty);
        expect(bare, isNot(contains('{')));
        expect(bare, isNot(contains('null')));
      });
    }
  }

  test('de copy matches ADR-27 §3 and fills placeholders', () {
    expect(
      text('de', const Offline()),
      'Keine Verbindung. Deine Änderungen sind gespeichert und gehen raus, '
      'sobald du online bist.',
    );
    expect(
      text('de', const RateLimitedRemote(Duration(minutes: 6))),
      'Zu viele Versuche. Versuch es in 6 Min. nochmal.',
    );
    expect(
      text('de', const InviteInvalid()),
      'Dieser Link gilt nicht mehr. Bitte um einen neuen Link.',
    );
    expect(
      text('de', const MemberAlreadyClaimed(), personName: 'Anna'),
      'Anna ist schon mit einem anderen Handy verbunden. '
      'Wähl eine andere Person.',
    );
    expect(
      text('de', const AlreadyConnected(), personName: 'Anna'),
      'Du bist in dieser Gruppe schon als Anna verbunden.',
    );
    expect(
      text('de', const MemberGone()),
      'Diese Person gibt es in der Gruppe nicht mehr. Wähl eine andere.',
    );
    expect(
      text('de', const NotOwner()),
      'Das kann nur, wer die Gruppe erstellt hat.',
    );
    expect(
      text('de', const NotMember()),
      'Du bist nicht mehr in dieser Gruppe. '
      'Deine Daten bleiben auf diesem Handy.',
    );
    expect(
      text('de', const CannotRemoveSelf()),
      'Dich selbst kannst du hier nicht entfernen.',
    );
    expect(
      text('de', const VersionTooOld()),
      'Diese Version kann nicht mehr teilen. Aktualisiere mitlio.',
    );
    expect(
      text('de', const ServerDown()),
      'Der Server antwortet gerade nicht. Wir versuchen es gleich nochmal.',
    );
    expect(
      text('de', const Rejected('payers_sum_mismatch'), title: 'Pizza'),
      '„Pizza“ konnte nicht geteilt werden. Sie ist nur auf diesem Handy.',
    );
  });

  test('en copy fills placeholders', () {
    expect(
      text('en', const RateLimitedRemote(Duration(minutes: 6))),
      contains('6 min'),
    );
    expect(
      text('en', const MemberAlreadyClaimed(), personName: 'Anna'),
      startsWith('Anna is already connected'),
    );
    expect(
      text('en', const AlreadyConnected(), personName: 'Anna'),
      endsWith('as Anna.'),
    );
    expect(
      text('en', const Rejected('x'), title: 'Pizza'),
      contains('Pizza'),
    );
  });

  test('rateLimited without a wait says "in ein paar Minuten"', () {
    expect(
      text('de', const RateLimitedRemote(null)),
      contains('in ein paar Minuten'),
    );
    expect(
      text('en', const RateLimitedRemote(null)),
      contains('in a few minutes'),
    );
  });

  test('a wait under one minute rounds up to 1 Min.', () {
    expect(
      text('de', const RateLimitedRemote(Duration(seconds: 20))),
      contains('1 Min.'),
    );
  });

  test('no name / no title use their own sentence, not "null"', () {
    expect(
      text('de', const MemberAlreadyClaimed()),
      startsWith('Diese Person ist schon'),
    );
    expect(
      text('de', const AlreadyConnected()),
      'Du bist in dieser Gruppe schon verbunden.',
    );
    expect(
      text('de', const Rejected('x')),
      'Das konnte nicht geteilt werden. Es ist nur auf diesem Handy.',
    );
  });

  test('every case has distinct de copy (specific, not one generic text)', () {
    final texts = {
      for (final e in cases.where((c) => c != const RateLimitedRemote(null)))
        text('de', e, personName: 'Anna', title: 'Pizza'),
    };
    expect(texts.length, cases.length - 1);
  });
}
