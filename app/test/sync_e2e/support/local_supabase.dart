import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/remote/remote_backend.dart';
import 'package:mitlio/features/sync/data/services/auth_service.dart';
import 'package:mitlio/features/sync/data/services/invite_remote.dart';
import 'package:mitlio/features/sync/data/services/supabase_invite_remote.dart';
import 'package:mitlio/features/sync/data/services/supabase_sync_remote.dart';
import 'package:mitlio/features/sync/data/services/sync_remote.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where the local Supabase stack listens, read from the environment that
/// `make test-sync-e2e` fills from `supabase status -o env`. Anything but a
/// loopback address is refused: these tests wipe the database and must never
/// touch staging or prod.
class LocalSupabase {
  LocalSupabase._(this.url, this.anonKey, this.dbUrl);

  factory LocalSupabase._fromEnvironment() {
    final env = Platform.environment;
    final url = env['SUPABASE_URL'] ?? env['API_URL'];
    final key = env['SUPABASE_ANON_KEY'] ?? env['ANON_KEY'];
    final db =
        env['SUPABASE_DB_URL'] ??
        'postgresql://postgres:postgres@127.0.0.1:54322/postgres';
    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw StateError(
        'No local Supabase configured. Run `make db-up` and then '
        '`make test-sync-e2e` (it passes SUPABASE_URL and SUPABASE_ANON_KEY '
        'from `supabase status -o env`).',
      );
    }
    for (final raw in [url, db]) {
      final host = Uri.parse(raw).host;
      if (host != '127.0.0.1' && host != 'localhost') {
        throw StateError(
          'Refusing to run against $host: the sync E2E suite only talks to a '
          'local Supabase stack (127.0.0.1).',
        );
      }
    }
    return LocalSupabase._(url, key, db);
  }

  final String url;
  final String anonKey;
  final String dbUrl;

  static LocalSupabase? _instance;

  // ignore: prefer_constructors_over_static_methods, lazy singleton read from env
  static LocalSupabase get instance =>
      _instance ??= LocalSupabase._fromEnvironment();

  /// A client with no session yet and no network call until it is used.
  SupabaseClient newClient() {
    final client = SupabaseClient(
      url,
      anonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    return client;
  }

  /// Runs [sql] as the database owner (psql from the host, else the Docker
  /// container of the stack). Throws with psql's message on failure.
  Future<void> sql(String sql) async {
    ProcessResult result;
    try {
      result = await Process.run('psql', [
        dbUrl,
        '-v',
        'ON_ERROR_STOP=1',
        '-q',
        '-c',
        sql,
      ]);
    } on ProcessException {
      result = await Process.run('docker', [
        'exec',
        'supabase_db_mitlio',
        'psql',
        '-U',
        'postgres',
        '-v',
        'ON_ERROR_STOP=1',
        '-q',
        '-c',
        sql,
      ]);
    }
    if (result.exitCode != 0) {
      throw StateError('psql failed: ${result.stderr}');
    }
  }

  /// Empties everything the suites create, so each test starts on a fresh
  /// server (the contract suites reuse fixed group ids). Anonymous users
  /// stay; they own nothing afterwards.
  Future<void> wipe() => sql('''
truncate table public.groups cascade;
truncate table public.rate_limits;
delete from public.app_config;
''');

  /// Puts a row on `app_config`.
  Future<void> seedAppConfig(
    String platform,
    String version,
    String? storeUrl,
  ) {
    String q(String s) => "'${s.replaceAll("'", "''")}'";
    return sql('''
insert into public.app_config (platform, min_supported_version, store_url)
values (${q(platform)}, ${q(version)}, ${storeUrl == null ? 'null' : q(storeUrl)})
on conflict (platform) do update
  set min_supported_version = excluded.min_supported_version,
      store_url = excluded.store_url;
''');
  }
}

/// One anonymous account on the local stack, with the real Supabase
/// implementations of the remote interfaces.
class Account {
  Account._(this.client, this.backend, this.userId);

  final SupabaseClient client;
  final RemoteBackend backend;
  final String userId;

  SyncRemote get sync => SupabaseSyncRemote(backend);
  InviteRemote get invite => SupabaseInviteRemote(backend);

  /// A new anonymous user (the real `SupabaseAuthService` signs it in).
  static Future<Account> create() async {
    final client = LocalSupabase.instance.newClient();
    final backend = RemoteBackend.withClient(client);
    final signedIn = await SupabaseAuthService(backend).ensureSignedIn();
    switch (signedIn) {
      case Ok(:final value):
        return Account._(client, backend, value);
      case Err(:final error):
        fail('anonymous sign-in on the local stack failed: $error');
    }
  }
}
