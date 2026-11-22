import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/features/sync/data/services/app_config_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/app_config_remote_contract.dart';

/// The Supabase `app_config` read against a loopback PostgREST stand-in that
/// filters by `platform=eq.<x>` like the real one: real client, real HTTP.
void main() {
  late HttpServer server;
  late SupabaseClient client;
  late Map<String, Map<String, Object?>> rows;
  late List<Uri> seen;
  // When set, answers every request with it instead of the rows.
  (int, String)? override;

  setUp(() async {
    rows = {};
    seen = [];
    override = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.forEach((request) async {
        seen.add(request.uri);
        final platform = request.uri.queryParameters['platform']?.replaceFirst(
          'eq.',
          '',
        );
        final answer =
            override ??
            (200, jsonEncode([if (rows[platform] != null) rows[platform]]));
        request.response.statusCode = answer.$1;
        request.response.headers.contentType = ContentType.json;
        request.response.write(answer.$2);
        await request.response.close();
      }),
    );
    client = SupabaseClient(
      'http://${server.address.host}:${server.port}',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  SupabaseAppConfigRemote remote() =>
      SupabaseAppConfigRemote(RemoteBackend.withClient(client));

  runAppConfigRemoteContract('SupabaseAppConfigRemote', () async {
    return AppConfigFixture(
      remote: remote(),
      seed: (platform, version, url) async => rows[platform] = {
        'min_supported_version': version,
        'store_url': url,
        // The column default of migration 0017.
        'support_tips_enabled': false,
      },
      seedSupportTips: (platform, {required enabled}) async =>
          rows[platform]!['support_tips_enabled'] = enabled,
    );
  });

  test('the tip jar flag reads one column of one platform', () async {
    rows['ios'] = {'support_tips_enabled': true};
    expect(
      await remote().supportTipsEnabled('ios'),
      const Ok<bool, RemoteError>(true),
    );
    final uri = seen.single;
    expect(uri.queryParameters['select'], 'support_tips_enabled');
    expect(uri.queryParameters['platform'], 'eq.ios');
  });

  test('a tip jar flag that is not a boolean is a malformed error', () async {
    rows['ios'] = {'support_tips_enabled': 'yes'};
    expect(
      await remote().supportTipsEnabled('ios'),
      const Err<bool, RemoteError>(Rejected('malformed_app_config')),
    );
  });

  test('the tip jar flag without a backend is an error', () async {
    expect(
      await const SupabaseAppConfigRemote(
        RemoteBackend.none(),
      ).supportTipsEnabled('ios'),
      const Err<bool, RemoteError>(Rejected('backend_unavailable')),
    );
  });

  test('reads without a session, two columns of one platform', () async {
    rows['ios'] = {'min_supported_version': '1.0.0', 'store_url': null};
    await remote().minSupportedVersion('ios');
    final uri = seen.single;
    expect(uri.path, '/rest/v1/app_config');
    expect(uri.queryParameters['select'], 'min_supported_version,store_url');
    expect(uri.queryParameters['platform'], 'eq.ios');
    expect(client.auth.currentSession, isNull);
  });

  test('without a backend it is an error, never a crash', () async {
    final r = await const SupabaseAppConfigRemote(
      RemoteBackend.none(),
    ).minSupportedVersion('ios');
    expect(
      r,
      const Err<MinVersionConfig?, RemoteError>(
        Rejected('backend_unavailable'),
      ),
    );
  });

  test('a 5xx is serverDown', () async {
    override = (502, 'Bad Gateway');
    expect(
      await remote().minSupportedVersion('ios'),
      const Err<MinVersionConfig?, RemoteError>(ServerDown()),
    );
  });

  test('no connection is offline', () async {
    await server.close(force: true);
    expect(
      await remote().minSupportedVersion('ios'),
      const Err<MinVersionConfig?, RemoteError>(Offline()),
    );
  });

  for (final (what, row) in <(String, Map<String, Object?>)>[
    ('a version that is not text', {'min_supported_version': 3}),
    (
      'a store link that is not text',
      {
        'min_supported_version': '1.0.0',
        'store_url': 5,
      },
    ),
    ('a row without a version', <String, Object?>{}),
  ]) {
    test('$what is a malformed config error', () async {
      rows['ios'] = row;
      expect(
        await remote().minSupportedVersion('ios'),
        const Err<MinVersionConfig?, RemoteError>(
          Rejected('malformed_app_config'),
        ),
      );
    });
  }
}
