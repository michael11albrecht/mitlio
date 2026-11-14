import 'package:mitlio/features/settings/ui/delete_my_data_view_model.dart';

/// Fixed state for goldens and a11y tests, never touches a repository.
class StubDeleteMyDataViewModel extends DeleteMyDataViewModel {
  StubDeleteMyDataViewModel(this.fixed);

  final DeleteMyDataState fixed;

  @override
  DeleteMyDataState build() => fixed;
}

const deleteMyDataStates = [
  ('idle', DeleteMyDataState()),
  (
    'ready',
    DeleteMyDataState(typed: 'LÖSCHEN'),
  ),
  (
    'failed',
    DeleteMyDataState(typed: 'LÖSCHEN', status: DeleteMyDataStatus.failed),
  ),
];
