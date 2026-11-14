import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';

import '../helpers/fake_app.dart';

void main() {
  Future<Locale> resolved(WidgetTester tester, Locale device) async {
    tester.platformDispatcher.localesTestValue = [device];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(overrides: FakeApp().overrides, child: const MitlioApp()),
    );
    await tester.pumpAndSettle();
    return Localizations.localeOf(tester.element(find.text('mitlio')));
  }

  testWidgets('german device gets de', (tester) async {
    expect(
      (await resolved(tester, const Locale('de', 'AT'))).languageCode,
      'de',
    );
  });

  testWidgets('english device gets en', (tester) async {
    expect(
      (await resolved(tester, const Locale('en', 'GB'))).languageCode,
      'en',
    );
  });

  testWidgets('unsupported device language falls back to de', (tester) async {
    expect((await resolved(tester, const Locale('fr'))).languageCode, 'de');
  });

  test('de and en ship the same keys', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), [
      'de',
      'en',
    ]);
    expect(AppLocalizationsEn().appName, AppLocalizationsDe().appName);
  });
}
