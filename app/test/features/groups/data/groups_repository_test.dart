import '../../repo_test_support.dart';
import 'groups_repository_contract.dart';

void main() {
  runGroupsRepositoryContract('drift', () async => (await driftRepos()).groups);
  runGroupsRepositoryContract('fake', () async => (await fakeRepos()).groups);
}
