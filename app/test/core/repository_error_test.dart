import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

void main() {
  test('errors have value equality and readable strings', () {
    expect(const NotFound('group', 'a'), const NotFound('group', 'a'));
    expect(const NotFound('group', 'a'), isNot(const NotFound('group', 'b')));
    expect(const Conflict('x'), const Conflict('x'));
    expect(const InvalidData('x'), const InvalidData('x'));
    expect(const InvalidData('x'), isNot(const InvalidData('y')));
    const cause = 'boom';
    expect(const Storage(cause), const Storage(cause));
    expect(
      {const NotFound('g', '1'), const Conflict('c'), const InvalidData('d')},
      hasLength(3),
    );
    expect(
      const NotFound('g', '1').hashCode,
      const NotFound('g', '1').hashCode,
    );
    expect(const Conflict('c').hashCode, const Conflict('c').hashCode);
    expect(const InvalidData('d').hashCode, const InvalidData('d').hashCode);
    expect(const Storage(cause).hashCode, const Storage(cause).hashCode);
    expect(
      [
        const NotFound('g', '1').toString(),
        const Conflict('c').toString(),
        const InvalidData('d').toString(),
        const Storage(cause).toString(),
      ],
      [
        'NotFound(g, 1)',
        'Conflict(c)',
        'InvalidData(d)',
        'Storage(boom)',
      ],
    );
  });

  test('guardStorage converts thrown errors into Storage', () async {
    final ok = await guardStorage(
      () async => const Ok<int, RepositoryError>(1),
    );
    expect(ok, const Ok<int, RepositoryError>(1));
    final failed = await guardStorage<int>(() async => throw StateError('x'));
    expect(failed, isA<Err<int, RepositoryError>>());
    expect((failed as Err<int, RepositoryError>).error, isA<Storage>());
  });

  test('orThrow returns the value or throws the error', () {
    expect(const Ok<int, RepositoryError>(3).orThrow(), 3);
    expect(
      () => const Err<int, RepositoryError>(NotFound('g', '1')).orThrow(),
      throwsA(const NotFound('g', '1')),
    );
  });

  test('Undo runs the restore callback', () async {
    var calls = 0;
    final undo = Undo(() async {
      calls++;
      return const Ok(null);
    });
    expect(await undo(), const Ok<void, RepositoryError>(null));
    expect(calls, 1);
  });

  test('watchSnapshots emits initial, changes, and skips duplicates', () async {
    final changes = StreamController<void>.broadcast(sync: true);
    var data = [1];
    final seen = <List<int>>[];
    final sub = watchSnapshots(changes.stream, () => data).listen(seen.add);
    changes.add(null); // unchanged: skipped
    data = [1, 2];
    changes.add(null);
    data = [2, 2];
    changes.add(null);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    changes.add(null);
    expect(seen, [
      [1],
      [1, 2],
      [2, 2],
    ]);
    expect(() => seen.first.add(3), throwsUnsupportedError);
    await changes.close();
  });
}
