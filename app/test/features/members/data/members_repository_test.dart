import '../../repo_test_support.dart';
import 'members_repository_contract.dart';

void main() {
  runMembersRepositoryContract('drift', driftRepos);
  runMembersRepositoryContract('fake', fakeRepos);
}
