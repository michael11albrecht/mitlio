import '../../repo_test_support.dart';
import 'settlements_repository_contract.dart';

void main() {
  runSettlementsRepositoryContract('drift', driftRepos);
  runSettlementsRepositoryContract('fake', fakeRepos);
}
