import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/daos/sync_state_dao.dart';
import 'package:mitlio/features/members/data/repositories/drift_payment_details_repository.dart';
import 'package:mitlio/features/members/data/services/iban_cipher.dart';
import 'package:mitlio/features/settings/data/repositories/data_deletion_repository.dart';
import 'package:mitlio/features/settings/data/services/fake_server_data_service.dart';
import 'package:mitlio/features/sync/data/repositories/auth_repository.dart';
import 'package:mitlio/features/sync/data/services/fake_auth_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../support/capturing_logger.dart';
import '../../members/data/payment_details_repository_contract.dart';
import '../../repo_test_support.dart';

class _NoopGateway extends SentryGateway {
  @override
  Future<void> init(String dsn) async {}

  @override
  Future<void> close() async {}
}

class _Fixture {
  _Fixture({
    required this.repos,
    required this.cipher,
    required this.reporter,
    required this.server,
    required this.auth,
    required this.deletion,
    required this.memberId,
  });

  final Repos repos;
  final SecureStorageIbanCipher cipher;
  final CrashReporter reporter;
  final FakeServerDataService server;
  final FakeAuthService auth;
  final DataDeletionRepository deletion;
  final String memberId;
}

Future<_Fixture> _fixture({bool signedIn = false}) async {
  FlutterSecureStorage.setMockInitialValues({});
  final repos = await driftRepos();
  final cipher = SecureStorageIbanCipher(logger: CapturingLogger());
  final reporter = CrashReporter(
    dsn: 'https://k@de.sentry.io/1',
    store: MemoryCrashReportingStore(),
    gateway: _NoopGateway(),
  );
  await reporter.setEnabled(enabled: true);
  final server = FakeServerDataService(isSignedIn: signedIn);
  final auth = FakeAuthService();
  await AuthRepository(auth).ensureSignedIn();
  final group = ok(
    await repos.groups.create(
      name: 'Trip',
      currency: Currency.eur,
      createdBy: 'local',
    ),
  );
  final member = ok(await repos.members.add(group.id, name: 'Ann'));
  ok(
    await DriftPaymentDetailsRepository(
      db: repos.db!,
      clock: repos.clock,
      ids: SequentialIdGenerator(),
      cipher: cipher,
    ).save(member.id, iban: testIban),
  );
  return _Fixture(
    repos: repos,
    cipher: cipher,
    reporter: reporter,
    server: server,
    auth: auth,
    memberId: member.id,
    deletion: DriftDataDeletionRepository(
      db: repos.db!,
      cipher: cipher,
      crashReporter: reporter,
      server: server,
      auth: AuthRepository(auth),
    ),
  );
}

Future<int> _rows(_Fixture f) async {
  var total = 0;
  for (final table in f.repos.db!.allTables) {
    total += (await f.repos.db!.select(table).get()).length;
  }
  return total;
}

void main() {
  test('wipes every table, the key and the crash-report choice', () async {
    final f = await _fixture();
    expect(await _rows(f), greaterThan(0));
    expect(
      await f.repos.db!.select(f.repos.db!.localMemberBank).get(),
      isNotEmpty,
    );
    expect(
      await const FlutterSecureStorage().read(key: 'mitlio.iban.key'),
      isNotNull,
    );

    ok(await f.deletion.deleteEverything());

    expect(await _rows(f), 0);
    expect(
      await const FlutterSecureStorage().read(key: 'mitlio.iban.key'),
      isNull,
    );
    expect(f.reporter.isEnabled, isFalse);
    expect(f.reporter.isActive, isFalse);
    expect(f.server.calls, 0, reason: 'not signed in: nothing to call');
  });

  test('is idempotent', () async {
    final f = await _fixture();
    ok(await f.deletion.deleteEverything());
    ok(await f.deletion.deleteEverything());
    expect(await _rows(f), 0);
  });

  test('signed in: the server is called before the local wipe', () async {
    final f = await _fixture(signedIn: true);
    ok(await f.deletion.deleteEverything());
    expect(f.server.calls, 1);
    expect(await _rows(f), 0);
  });

  test('server failure keeps all local data so the user can retry', () async {
    final f = await _fixture(signedIn: true);
    f.server.failWith = Exception('offline');
    final result = await f.deletion.deleteEverything();
    expect(result, isA<Err<void, RepositoryError>>());
    expect(await _rows(f), greaterThan(0));
    expect(f.reporter.isEnabled, isTrue);

    f.server.failWith = null;
    ok(await f.deletion.deleteEverything());
    expect(await _rows(f), 0);
  });

  test('with a backend: drops the session and the group sync rows', () async {
    final f = await _fixture();
    final db = f.repos.db!;
    final groupId = (await db.select(db.groups).get()).single.id;
    await db.syncStateDao.setState(
      groupId,
      SyncState.shared,
      role: SyncRole.owner,
    );
    await db.syncStateDao.setCursor(groupId, 'expenses', 3);
    expect(f.auth.currentUserId, isNotNull);

    ok(await f.deletion.deleteEverything());

    expect(f.auth.clearCalls, 1);
    expect(f.auth.currentUserId, isNull);
    expect(await db.syncStateDao.groupSync(groupId), isNull);
    expect(await db.syncStateDao.cursorsOf(groupId), isEmpty);
  });

  test('a failing session cleanup is reported and nothing is wiped', () async {
    final f = await _fixture();
    f.auth.clearFailWith = Exception('keychain locked');
    final result = await f.deletion.deleteEverything();
    expect(result, isA<Err<void, RepositoryError>>());
    expect((result as Err<void, RepositoryError>).error, isA<Storage>());
    expect(await _rows(f), greaterThan(0));
    expect(f.reporter.isEnabled, isTrue);

    f.auth.clearFailWith = null;
    ok(await f.deletion.deleteEverything());
    expect(await _rows(f), 0);
    expect(f.auth.currentUserId, isNull);
  });
}
