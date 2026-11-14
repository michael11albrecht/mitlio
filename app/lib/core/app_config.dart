/// Build-time configuration injected with
/// `--dart-define-from-file=config/<flavor>.json` (P8-T01). Defaults are
/// empty/dev so tests and the flavorless Linux harness run without any
/// defines. Never put secrets in the JSON files in git.
class AppConfig {
  const AppConfig({
    this.flavor = 'dev',
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.sentryDsn = '',
  });

  /// Reads the compile-time defines.
  const AppConfig.fromEnvironment()
    : flavor = const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
      supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
      sentryDsn = const String.fromEnvironment('SENTRY_DSN');

  final String flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String sentryDsn;

  bool get isProd => flavor == 'prod';

  /// Backend is only usable once both Supabase values are set.
  bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
