import 'package:mitlio/core/app_config.dart';
import 'package:mitlio/core/logging.dart';
import 'package:mitlio/core/remote/secure_local_storage.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returned by every remote entry point when no backend is configured
/// (empty `config/dev.json`). Callers hide share/join instead of failing.
final class BackendUnavailable {
  const BackendUnavailable();

  @override
  String toString() => 'BackendUnavailable()';
}

/// Holds the Supabase client, which exists only when [AppConfig.hasBackend].
/// Remote services take this and call [client]; nothing else creates one.
class RemoteBackend {
  const RemoteBackend._(this._client);

  /// No backend: the app runs fully local.
  const RemoteBackend.none() : _client = null;

  /// A backend with an already created client (tests pass a fake here).
  const RemoteBackend.withClient(SupabaseClient client) : _client = client;

  final SupabaseClient? _client;

  bool get isAvailable => _client != null;

  /// The client, or `Err(BackendUnavailable)` without a backend.
  Result<SupabaseClient, BackendUnavailable> client() {
    final c = _client;
    return c == null ? const Err(BackendUnavailable()) : Ok(c);
  }

  /// Creates the client when [config] has a backend; otherwise none. The
  /// session lives in [store] (secure storage). No network call happens here.
  static Future<RemoteBackend> initialize(
    AppConfig config, {
    required SecretStore store,
    required Logger logger,
  }) async {
    if (!config.hasBackend) return const RemoteBackend.none();
    try {
      final supabase = await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureLocalStorage(store, logger),
          pkceAsyncStorage: SecureAsyncStorage(store, logger),
          // Anonymous accounts only (ADR-27 §2.2): no deep-link sign-in.
          detectSessionInUri: false,
        ),
      );
      return RemoteBackend._(supabase.client);
    } on Object catch (e, st) {
      // A broken config must not stop the app: it stays fully local.
      logger.error('supabase init failed, running without backend', e, st);
      return const RemoteBackend.none();
    }
  }
}
