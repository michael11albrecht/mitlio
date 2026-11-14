import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Minimal app shell for widget and golden tests: real theme, l10n delegates,
/// forced brightness and text scale, [child] as the Scaffold body.
Widget themedApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Locale locale = const Locale('de'),
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MitlioTheme.light,
    darkTheme: MitlioTheme.dark,
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    locale: locale,
    localizationsDelegates: mitlioLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: Scaffold(body: child),
  );
}
