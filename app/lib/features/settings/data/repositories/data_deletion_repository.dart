import 'package:mitlio/core/crash/crash_reporter.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';
import 'package:mitlio/features/settings/data/services/server_data_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// "Alle meine Daten löschen" (P7-T07, `docs/data-deletion.md`).
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class DataDeletionRepository {
  /// Deletes the server data first (if signed in), then everything on this
  /// device. If the server call fails nothing local is touched, so the user
  /// can simply try again.
  Future<RepoResult<void>> deleteEverything();
}

/// Wipes the Drift database (all tables, incl. `local_member_bank`), the
/// secure-storage key and the crash-report choice.
class DriftDataDeletionRepository implements DataDeletionRepository {
  DriftDataDeletionRepository({
    required this._db,
    required this._cipher,
    required this._crashReporter,
    required this._server,
  });

  final AppDatabase _db;
  final IbanCipher _cipher;
  final CrashReporter _crashReporter;
  final ServerDataService _server;

  @override
  Future<RepoResult<void>> deleteEverything() => guardStorage(() async {
    if (_server.isSignedIn) await _server.deleteMyData();
    // Tables are declared parents first, so reverse order never violates a
    // foreign key.
    await _db.transaction(() async {
      for (final table in _db.allTables.toList().reversed) {
        await _db.delete(table).go();
      }
    });
    await _cipher.deleteKey();
    await _crashReporter.setEnabled(enabled: false);
    return const Ok<void, RepositoryError>(null);
  });
}
