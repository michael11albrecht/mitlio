import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/sync/data/auth_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Length of the id prefix DebugDrive reports; the full id stays in the app.
const _prefixLength = 8;

String? _prefix(String? id) {
  if (id == null) return null;
  return id.substring(0, id.length < _prefixLength ? id.length : _prefixLength);
}

/// `ext.mitlio.auth.status` (read-only) and `ext.mitlio.auth.signIn` (the
/// anonymous sign-in a share or join triggers). Keys without the
/// `ext.mitlio.` prefix.
Map<String, DriveHandler> authDriveHandlers(ProviderContainer c) => {
  'auth.status': (_) async {
    final id = c.read(authRepositoryProvider).currentUserId;
    return {'signedIn': id != null, 'userIdPrefix': _prefix(id)};
  },
  'auth.signIn': (_) async {
    final result = await c.read(authRepositoryProvider).ensureSignedIn();
    return switch (result) {
      Ok(:final value) => {'signedIn': true, 'userIdPrefix': _prefix(value)},
      Err(:final error) => {'error': error.caseName, 'message': '$error'},
    };
  },
};
