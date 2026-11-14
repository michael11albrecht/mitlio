import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app_config.dart';

void main() {
  test('defaults are safe for tests: dev flavor, no backend', () {
    const config = AppConfig.fromEnvironment();
    expect(config.flavor, 'dev');
    expect(config.isProd, isFalse);
    expect(config.hasBackend, isFalse);
    expect(config.sentryDsn, isEmpty);
  });

  test('hasBackend needs both Supabase values', () {
    expect(const AppConfig(supabaseUrl: 'u').hasBackend, isFalse);
    expect(const AppConfig(supabaseAnonKey: 'k').hasBackend, isFalse);
    expect(
      const AppConfig(supabaseUrl: 'u', supabaseAnonKey: 'k').hasBackend,
      isTrue,
    );
    expect(const AppConfig(flavor: 'prod').isProd, isTrue);
  });

  for (final flavor in ['dev', 'prod']) {
    test('config/$flavor.json has the expected keys and flavor', () {
      final json = jsonDecode(
        File('config/$flavor.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(json.keys, {
        'FLAVOR',
        'SUPABASE_URL',
        'SUPABASE_ANON_KEY',
        'SENTRY_DSN',
      });
      expect(json['FLAVOR'], flavor);
      expect(json.values.every((v) => v is String), isTrue);
    });
  }
}
