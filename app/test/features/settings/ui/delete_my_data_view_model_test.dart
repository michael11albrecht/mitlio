import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/settings/data/repositories/data_deletion_providers.dart';
import 'package:mitlio/features/settings/data/repositories/fake_data_deletion_repository.dart';
import 'package:mitlio/features/settings/ui/delete_my_data_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

(ProviderContainer, FakeDataDeletionRepository) _setup() {
  final repo = FakeDataDeletionRepository();
  final c = ProviderContainer(
    overrides: [dataDeletionRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  // autoDispose: keep it alive for the test.
  c.listen(deleteMyDataViewModelProvider, (_, _) {});
  return (c, repo);
}

void main() {
  test('starts idle with nothing typed', () {
    final (c, _) = _setup();
    final s = c.read(deleteMyDataViewModelProvider);
    expect(s.typed, isEmpty);
    expect(s.status, DeleteMyDataStatus.idle);
    expect(s.matches('LÖSCHEN'), isFalse);
    expect(s.toJson(), {'status': 'idle'});
  });

  test('the word matches ignoring case and surrounding spaces', () {
    final (c, _) = _setup();
    final vm = c.read(deleteMyDataViewModelProvider.notifier)
      ..setTyped(' löschen ');
    expect(c.read(deleteMyDataViewModelProvider).matches('LÖSCHEN'), isTrue);
    vm.setTyped('LÖSCHE');
    expect(c.read(deleteMyDataViewModelProvider).matches('LÖSCHEN'), isFalse);
  });

  test('success: deletes once the word was typed', () async {
    final (c, repo) = _setup();
    final vm = c.read(deleteMyDataViewModelProvider.notifier)
      ..setTyped('LÖSCHEN');
    final result = await vm.delete(word: 'LÖSCHEN');
    expect(result, isA<Ok<void, RepositoryError>>());
    expect(repo.calls, 1);
    expect(
      c.read(deleteMyDataViewModelProvider).status,
      DeleteMyDataStatus.done,
    );
  });

  test('validation error: without the word nothing is deleted', () async {
    final (c, repo) = _setup();
    final vm = c.read(deleteMyDataViewModelProvider.notifier)..setTyped('nein');
    final result = await vm.delete(word: 'LÖSCHEN');
    expect(result, isA<Err<void, RepositoryError>>());
    expect(repo.calls, 0);
    expect(
      c.read(deleteMyDataViewModelProvider).status,
      DeleteMyDataStatus.idle,
    );
  });

  test('repository failure: status failed, can retry', () async {
    final (c, repo) = _setup();
    repo.failWith = const Storage('disk');
    final vm = c.read(deleteMyDataViewModelProvider.notifier)
      ..setTyped('LÖSCHEN');
    expect(await vm.delete(word: 'LÖSCHEN'), isA<Err<void, RepositoryError>>());
    expect(
      c.read(deleteMyDataViewModelProvider).status,
      DeleteMyDataStatus.failed,
    );

    repo.failWith = null;
    expect(await vm.delete(word: 'LÖSCHEN'), isA<Ok<void, RepositoryError>>());
    expect(repo.calls, 2);
    expect(
      c.read(deleteMyDataViewModelProvider).status,
      DeleteMyDataStatus.done,
    );
  });

  test('a second tap while deleting is ignored', () async {
    final (c, repo) = _setup();
    final vm = c.read(deleteMyDataViewModelProvider.notifier)
      ..setTyped('LÖSCHEN');
    final first = vm.delete(word: 'LÖSCHEN');
    expect(
      c.read(deleteMyDataViewModelProvider).status,
      DeleteMyDataStatus.deleting,
    );
    vm.setTyped('x'); // typing is locked while deleting
    expect(c.read(deleteMyDataViewModelProvider).typed, 'LÖSCHEN');
    expect(await vm.delete(word: 'LÖSCHEN'), isA<Err<void, RepositoryError>>());
    await first;
    expect(repo.calls, 1);
  });
}
