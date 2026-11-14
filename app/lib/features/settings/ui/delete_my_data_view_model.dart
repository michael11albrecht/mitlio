import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settings/data/repositories/data_deletion_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

enum DeleteMyDataStatus { idle, deleting, failed, done }

/// What the user typed and where the deletion stands.
final class DeleteMyDataState {
  const DeleteMyDataState({
    this.typed = '',
    this.status = DeleteMyDataStatus.idle,
  });

  final String typed;
  final DeleteMyDataStatus status;

  /// Case and surrounding spaces do not matter, the intent does.
  bool matches(String word) =>
      typed.trim().toUpperCase() == word.trim().toUpperCase();

  Map<String, Object?> toJson() => {'status': status.name};
}

/// The one confirmation step in the app: delete only after the user typed the
/// confirmation word (plan §2.6, P7-T07).
class DeleteMyDataViewModel extends Notifier<DeleteMyDataState> {
  @override
  DeleteMyDataState build() => const DeleteMyDataState();

  void setTyped(String text) {
    if (state.status == DeleteMyDataStatus.deleting) return;
    state = DeleteMyDataState(typed: text);
  }

  /// Deletes everything if [word] was typed. Returns the failure, if any;
  /// on success the state is `done` and the View leaves the screen.
  Future<RepoResult<void>> delete({required String word}) async {
    if (state.status == DeleteMyDataStatus.deleting) {
      return const Err(InvalidData('already deleting'));
    }
    if (!state.matches(word)) {
      return const Err(InvalidData('confirmation word does not match'));
    }
    state = DeleteMyDataState(
      typed: state.typed,
      status: DeleteMyDataStatus.deleting,
    );
    final result = await ref
        .read(dataDeletionRepositoryProvider)
        .deleteEverything();
    if (ref.mounted) {
      state = DeleteMyDataState(
        typed: state.typed,
        status: switch (result) {
          Ok() => DeleteMyDataStatus.done,
          Err() => DeleteMyDataStatus.failed,
        },
      );
    }
    return result;
  }
}

final NotifierProvider<DeleteMyDataViewModel, DeleteMyDataState>
deleteMyDataViewModelProvider =
    NotifierProvider.autoDispose<DeleteMyDataViewModel, DeleteMyDataState>(
      DeleteMyDataViewModel.new,
    );
