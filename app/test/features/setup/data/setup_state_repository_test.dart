import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/setup/data/drift_setup_state_repository.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../db/test_support.dart';

Future<SetupProgress?> loaded(SetupStateRepository repo, String id) async =>
    ((await repo.load(id)) as Ok<SetupProgress?, RepositoryError>).value;

RepositoryError failure(RepoResult<Object?> r) =>
    (r as Err<Object?, RepositoryError>).error;

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  const progress = SetupProgress(
    stepIndex: 2,
    answers: {'name': 'Anna', 'km': 12000, 'paypal': true},
    skipped: ['iban'],
  );

  void contract(String name, SetupStateRepository Function() make) {
    group('$name contract', () {
      test('nothing saved: null', () async {
        expect(await loaded(make(), 'profile'), isNull);
      });

      test('save then load returns the same progress', () async {
        final repo = make();
        await repo.save('profile', progress);
        final got = (await loaded(repo, 'profile'))!;
        expect(got.stepIndex, 2);
        expect(got.answers, progress.answers);
        expect(got.skipped, ['iban']);
        expect(got.finished, isFalse);
      });

      test('flows are independent and save overwrites', () async {
        final repo = make();
        await repo.save('profile', progress);
        await repo.save('car', const SetupProgress(finished: true));
        await repo.save('profile', const SetupProgress(stepIndex: 5));
        final profile = (await loaded(repo, 'profile'))!;
        expect(profile.stepIndex, 5);
        expect(profile.answers, isEmpty);
        expect((await loaded(repo, 'car'))!.finished, isTrue);
      });
    });
  }

  contract('Drift', () => DriftSetupStateRepository(db));
  contract('Fake', FakeSetupStateRepository.new);

  test('Drift: stored in local_settings under setup_flow.<id>', () async {
    await DriftSetupStateRepository(db).save('profile', progress);
    expect(
      await db.syncStateDao.setting('${setupFlowKeyPrefix}profile'),
      progress.toJson(),
    );
  });

  test('Drift: foreign data is InvalidData, not a crash', () async {
    await db.syncStateDao.putSetting('${setupFlowKeyPrefix}profile', '[1]');
    expect(
      failure(await DriftSetupStateRepository(db).load('profile')),
      isA<InvalidData>(),
    );
  });

  test('Drift: a broken table is Storage, not an exception', () async {
    await db.customStatement('DROP TABLE local_settings');
    final repo = DriftSetupStateRepository(db);
    expect(failure(await repo.load('profile')), isA<Storage>());
    expect(failure(await repo.save('profile', progress)), isA<Storage>());
  });

  group('SetupProgress.fromJson', () {
    for (final bad in [
      'null',
      '{}',
      '{"stepIndex":-1,"answers":{},"skipped":[],"finished":false}',
      '{"stepIndex":0,"answers":[],"skipped":[],"finished":false}',
      '{"stepIndex":0,"answers":{},"skipped":[1],"finished":false}',
      '{"stepIndex":0,"answers":{},"skipped":[],"finished":"no"}',
      'not json',
    ]) {
      test('rejects $bad', () {
        expect(failure(SetupProgress.fromJson(bad)), isA<InvalidData>());
      });
    }
  });
}
