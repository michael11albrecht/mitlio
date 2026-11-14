import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// App strings plus Material/Widgets/Cupertino framework strings (de, en).
const mitlioLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// Root widget. Must sit under a `ProviderScope`. Light/dark theme follows
/// the system.
class MitlioApp extends ConsumerWidget {
  const MitlioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      routerConfig: ref.watch(routerProvider),
      theme: MitlioTheme.light,
      darkTheme: MitlioTheme.dark,
      // themeMode stays at its default, ThemeMode.system.
      localizationsDelegates: mitlioLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // German is the default: any device language we do not ship resolves
      // to `de` (first supported locale), English devices get `en`.
      localeResolutionCallback: (locale, supported) {
        for (final s in supported) {
          if (s.languageCode == locale?.languageCode) return s;
        }
        return supported.first;
      },
    );
  }
}
