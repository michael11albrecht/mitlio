import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/services/auth_service.dart';

/// Supabase anonymous auth; without a backend every call reports it. Tests
/// and DebugDrive override it with `FakeAuthService`.
final authServiceProvider = Provider<AuthService>(
  (ref) => SupabaseAuthService(ref.watch(remoteBackendProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authServiceProvider)),
);
