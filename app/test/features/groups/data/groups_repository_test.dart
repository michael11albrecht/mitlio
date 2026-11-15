import 'package:flutter_test/flutter_test.dart';

import '../../repo_test_support.dart';
import 'groups_repository_contract.dart';

void main() {
  runGroupsRepositoryContract('drift', () async => (await driftRepos()).groups);
  runGroupsRepositoryContract('fake', () async => (await fakeRepos()).groups);

  test('drift: archive and restore both bump updated_at (sync)', () async {
    final repos = await driftRepos();
    final g = ok(
      await repos.groups.create(name: 'Trip', currency: eur, createdBy: 'dev'),
    );
    final db = repos.db!;
    Future<String> updatedAt() async =>
        (await db.select(db.groups).getSingle()).updatedAt;

    final created = await updatedAt();
    ok(await repos.groups.softDelete(g.id));
    final archived = await updatedAt();
    ok(await repos.groups.restore(g.id));
    final restored = await updatedAt();

    expect(archived.compareTo(created), greaterThan(0));
    expect(restored.compareTo(archived), greaterThan(0));
  });
}
