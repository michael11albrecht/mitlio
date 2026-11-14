import '../../repo_test_support.dart';
import 'rides_repositories_contract.dart';

void main() {
  runRidesRepositoriesContract('drift', driftRepos);
  runRidesRepositoriesContract('fake', fakeRepos);
}
