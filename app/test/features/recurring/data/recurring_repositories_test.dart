import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/id_generator.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/db/app_database.dart';
import 'package:mitlio/features/recurring/data/repositories/drift_recurring_repository.dart';
import 'package:mitlio/features/recurring/data/repositories/fake_recurring_repository.dart';
import 'package:mitlio/features/recurring/data/repositories/recurring_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

RecurringDraft _draft({
  String title = 'Rent',
  int cents = 90000,
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  DateTime? lastGenerated,
  SplitSpec? split,
}) => RecurringDraft(
  title: title,
  amountCents: cents,
  payers: {'m1': cents},
  split: split ?? EqualSplit({'m1', 'm2'}),
  category: 'other',
  lastGenerated: lastGenerated,
  rule: _rule(frequency),
);

RecurrenceRule _rule(RecurrenceFrequency frequency) {
  final created = RecurrenceRule.create(
    start: DateTime.utc(2026, 1, 31),
    frequency: frequency,
    end: DateTime.utc(2027),
  );
  return (created as Ok<RecurrenceRule, RecurrenceError>).value;
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final repos = <(String, RecurringRepository Function())>[
    (
      'drift',
      () => DriftRecurringRepository(
        db: db,
        clock: FixedClock(DateTime.utc(2026, 11, 22, 9)),
        ids: SequentialIdGenerator(prefix: 'r'),
      ),
    ),
    (
      'fake',
      () => FakeRecurringRepository(
        clock: FixedClock(DateTime.utc(2026, 11, 22, 9)),
        ids: SequentialIdGenerator(prefix: 'r'),
      ),
    ),
  ];

  for (final (name, make) in repos) {
    group(name, () {
      late RecurringRepository repo;
      setUp(() => repo = make());

      RecurringExpense ok(RepoResult<RecurringExpense> r) =>
          (r as Ok<RecurringExpense, RepositoryError>).value;

      Future<List<RecurringExpense>> rules(String groupId) =>
          repo.watchRules(groupId).first;

      test('stores a rule with everything the expense needs', () async {
        final r = ok(
          await repo.create(
            'g1',
            _draft(
              split: SharesSplit({'m1': 2, 'm2': 1}),
              lastGenerated: DateTime.utc(2026, 1, 31),
            ),
          ),
        );
        expect(r.title, 'Rent');
        expect(r.groupId, 'g1');
        expect(r.amountCents, 90000);
        expect(r.payers, {'m1': 90000});
        expect(r.split, SharesSplit({'m1': 2, 'm2': 1}));
        expect(r.category, 'other');
        expect(r.paused, isFalse);
        expect(r.rule.frequency, RecurrenceFrequency.monthly);
        expect(r.rule.start, DateTime.utc(2026, 1, 31));
        expect(r.rule.end, DateTime.utc(2027));
        expect(r.lastGenerated, DateTime.utc(2026, 1, 31));
        expect(await rules('g1'), [r]);
        expect(await rules('g2'), isEmpty);
        expect(ok(await repo.create('g1', _draft(title: 'B'))).id, isNot(r.id));
      });

      test('rejects a blank title and a non-positive amount', () async {
        expect(
          await repo.create('g1', _draft(title: '  ')),
          isA<Err<RecurringExpense, RepositoryError>>().having(
            (e) => e.error,
            'error',
            isA<InvalidData>(),
          ),
        );
        expect(
          await repo.create('g1', _draft(cents: 0)),
          isA<Err<RecurringExpense, RepositoryError>>(),
        );
        expect(await rules('g1'), isEmpty);
      });

      test('update keeps progress and the paused flag', () async {
        final r = ok(await repo.create('g1', _draft()));
        await repo.markGenerated(r.id, DateTime.utc(2026, 2, 28));
        await repo.setPaused(r.id, paused: true);
        final u = ok(
          await repo.update(
            r.id,
            _draft(title: 'New rent', frequency: RecurrenceFrequency.weekly),
          ),
        );
        expect(u.title, 'New rent');
        expect(u.rule.frequency, RecurrenceFrequency.weekly);
        expect(u.lastGenerated, DateTime.utc(2026, 2, 28));
        expect(u.paused, isTrue);
        expect(u.createdAt, r.createdAt);
      });

      test('pause, resume with a new start of counting', () async {
        final r = ok(await repo.create('g1', _draft()));
        expect(ok(await repo.setPaused(r.id, paused: true)).paused, isTrue);
        final resumed = ok(
          await repo.setPaused(
            r.id,
            paused: false,
            lastGenerated: DateTime.utc(2026, 10, 31),
          ),
        );
        expect(resumed.paused, isFalse);
        expect(resumed.lastGenerated, DateTime.utc(2026, 10, 31));
      });

      test('delete is undoable', () async {
        final r = ok(await repo.create('g1', _draft()));
        await repo.markGenerated(r.id, DateTime.utc(2026, 3, 31));
        final undo =
            (await repo.delete(r.id) as Ok<Undo, RepositoryError>).value;
        expect(await rules('g1'), isEmpty);
        await undo();
        final back = await rules('g1');
        expect(back.single.id, r.id);
        expect(back.single.lastGenerated, DateTime.utc(2026, 3, 31));
      });

      test('unknown ids are NotFound', () async {
        for (final result in [
          await repo.update('nope', _draft()),
          await repo.setPaused('nope', paused: true),
          await repo.markGenerated('nope', DateTime.utc(2026)),
        ]) {
          expect(
            (result as Err<RecurringExpense, RepositoryError>).error,
            isA<NotFound>(),
          );
        }
        expect(
          (await repo.delete('nope') as Err<Undo, RepositoryError>).error,
          isA<NotFound>(),
        );
      });

      test('all() lists every group, oldest first', () async {
        await repo.create('g2', _draft(title: 'A'));
        await repo.create('g1', _draft(title: 'B'));
        final all =
            (await repo.all() as Ok<List<RecurringExpense>, RepositoryError>)
                .value;
        expect([for (final r in all) r.title], ['A', 'B']);
      });

      test('next date: month-end clamping, end of the rule', () async {
        final r = ok(await repo.create('g1', _draft()));
        expect(r.nextAfter(DateTime.utc(2026, 2)), DateTime.utc(2026, 2, 28));
        expect(
          r.nextAfter(DateTime.utc(2026, 2, 28)),
          DateTime.utc(2026, 3, 31),
        );
        expect(r.nextAfter(DateTime.utc(2026, 12, 31)), isNull);
      });
    });
  }
}
