import '../../repo_test_support.dart';
import 'expenses_repository_contract.dart';

void main() {
  runExpensesRepositoryContract('drift', driftRepos);
  runExpensesRepositoryContract('fake', fakeRepos);
}
