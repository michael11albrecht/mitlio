import 'package:mitlio/features/settings/ui/delete_my_data_view.dart';
import 'package:mitlio/features/settings/ui/delete_my_data_view_model.dart';

import '../features/groups/ui/groups_fixtures.dart';
import '../features/settings/ui/delete_my_data_fixtures.dart';
import 'golden_matrix.dart';

/// The delete-my-data confirmation screen: nothing typed, word typed, failed.
Future<void> main() async {
  for (final (name, state) in deleteMyDataStates) {
    await matrixGolden(
      'delete_my_data_$name',
      () => scoped([
        deleteMyDataViewModelProvider.overrideWith(
          () => StubDeleteMyDataViewModel(state),
        ),
      ], const DeleteMyDataView()),
      width: 360,
      height: 900,
    );
  }
}
