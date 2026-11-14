import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/settings/ui/delete_my_data_view.dart';
import 'package:mitlio/features/settings/ui/delete_my_data_view_model.dart';

import '../../../helpers/a11y.dart';
import 'delete_my_data_fixtures.dart';

void main() {
  for (final (name, state) in deleteMyDataStates) {
    forEachMode(
      'delete my data $name',
      () => ProviderScope(
        overrides: [
          deleteMyDataViewModelProvider.overrideWith(
            () => StubDeleteMyDataViewModel(state),
          ),
        ],
        child: const DeleteMyDataView(),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
