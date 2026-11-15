import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';
import '../support/no_shrink.dart';

Hlc _parse(String s) => (Hlc.parse(s) as Ok<Hlc, HlcError>).value;

Hlc _h(int wall, int counter, [String node = 'a']) =>
    Hlc(wallMillis: wall, counter: counter, nodeId: node);

SyncVersion _v(Hlc h, {bool deleted = false}) =>
    SyncVersion(updatedAt: h, deletedAt: deleted ? DateTime.utc(2026) : null);

/// Pull applied to one aggregate: fold remote versions into local state.
SyncVersion? _pull(SyncVersion? local, Iterable<SyncVersion> remotes) {
  var cur = local;
  for (final r in remotes) {
    final d = decide(local: cur, remote: r);
    if (d == MergeDecision.applyRemote) cur = r;
  }
  return cur;
}

SyncVersion _max(Iterable<SyncVersion> vs) =>
    vs.reduce((a, b) => a.updatedAt.compareTo(b.updatedAt) >= 0 ? a : b);

extension on Any {
  Generator<Hlc> get hlc => combine3(
    intNoShrink(0, 6),
    intNoShrink(0, 3),
    choose(['a', 'b']),
    (w, c, n) => _h(1767225600000 + w, c, n),
  );
  Generator<SyncVersion> get version =>
      combine2(hlc, this.bool, (h, del) => _v(h, deleted: del));
  // Distinct HLCs: an HLC identifies exactly one write.
  Generator<List<SyncVersion>> get versions => nonEmptyList(
    version,
  ).map((l) => {for (final v in l) v.updatedAt: v}.values.toList());
}

/// Deterministic Random from a seed (tests inject Random too).
class _Rng implements Random {
  _Rng(int seed) : _s = seed & 0x7fffffff;
  int _s;
  @override
  int nextInt(int max) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return (_s >> 8) % max;
  }

  @override
  bool nextBool() => nextInt(2) == 0;
  @override
  double nextDouble() => nextInt(1 << 20) / (1 << 20);
}

void main() {
  group('examples (docs/domain-rules.md)', () {
    final rows = (domainRulesExamples('sync_merge')! as List)
        .cast<Map<String, dynamic>>();
    for (final row in rows) {
      test(row['name'] as String, () {
        final local = row['local'] as String?;
        final pending = row['pending'] as String?;
        final got = decide(
          local: local == null
              ? null
              : _v(_parse(local), deleted: row['localDeleted'] == true),
          remote: _v(
            _parse(row['remote'] as String),
            deleted: row['remoteDeleted'] == true,
          ),
          pendingLocal: pending == null ? null : _parse(pending),
        );
        expect(got.name, row['decision']);
      });
    }
  });

  group('decide', () {
    final t0 = _h(1000, 0);
    final t1 = _h(1000, 1);
    final t2 = _h(1001, 0);

    test('tombstone vs live follows HLC both ways', () {
      expect(
        decide(local: _v(t1, deleted: true), remote: _v(t2)),
        MergeDecision.applyRemote,
      );
      expect(
        decide(local: _v(t1), remote: _v(t0, deleted: true)),
        MergeDecision.keepLocal,
      );
    });

    test('equal HLC ignores payload difference', () {
      expect(
        decide(local: _v(t1), remote: _v(t1, deleted: true)),
        MergeDecision.same,
      );
    });

    test('pending beats remote only when strictly newer', () {
      expect(
        decide(local: _v(t1), remote: _v(t1), pendingLocal: t2),
        MergeDecision.keepLocal,
      );
      expect(
        decide(local: _v(t0), remote: _v(t1), pendingLocal: t1),
        MergeDecision.applyRemoteDropPending,
      );
      expect(
        decide(local: _v(t0), remote: _v(t2), pendingLocal: t1),
        MergeDecision.applyRemoteDropPending,
      );
    });

    test('pending wins even if the local row is newer than the remote', () {
      expect(
        decide(local: _v(t2), remote: _v(t0), pendingLocal: t2),
        MergeDecision.keepLocal,
      );
    });
  });

  group('SyncVersion', () {
    test('isTombstone', () {
      expect(_v(_h(1, 0)).isTombstone, isFalse);
      expect(_v(_h(1, 0), deleted: true).isTombstone, isTrue);
    });
    test('value equality, hashCode, toString', () {
      expect(_v(_h(1, 0)), _v(_h(1, 0)));
      expect(_v(_h(1, 0)).hashCode, _v(_h(1, 0)).hashCode);
      expect(_v(_h(1, 0)) == _v(_h(1, 1)), isFalse);
      expect(_v(_h(1, 0)) == _v(_h(1, 0), deleted: true), isFalse);
      expect(_v(_h(1, 0)).toString(), contains('SyncVersion('));
      expect(_v(_h(1, 0)) == Object(), isFalse);
    });
  });

  group('mergeAggregate', () {
    // An aggregate: root version plus children replaced as a unit.
    SyncVersion ver((SyncVersion, List<String>) a) => a.$1;
    final older = (_v(_h(1000, 0)), ['p1', 's1']);
    final newer = (_v(_h(1001, 0)), ['p2']);

    test('remote wins: children are the remote children, not a mix', () {
      final r = mergeAggregate(local: older, remote: newer, versionOf: ver);
      expect(r.decision, MergeDecision.applyRemote);
      expect(r.winner, same(newer));
    });
    test('local wins untouched', () {
      final r = mergeAggregate(local: newer, remote: older, versionOf: ver);
      expect(r.decision, MergeDecision.keepLocal);
      expect(r.winner, same(newer));
    });
    test('same keeps local', () {
      final copy = (older.$1, ['x']);
      final r = mergeAggregate(local: older, remote: copy, versionOf: ver);
      expect(r.decision, MergeDecision.same);
      expect(r.winner, same(older));
    });
    test('no local applies remote', () {
      final r = mergeAggregate<(SyncVersion, List<String>)>(
        remote: newer,
        versionOf: ver,
      );
      expect(r.decision, MergeDecision.applyRemote);
      expect(r.winner, same(newer));
    });
    test('pending newer keeps local', () {
      final r = mergeAggregate(
        local: older,
        remote: newer,
        versionOf: ver,
        pendingLocal: _h(1002, 0),
      );
      expect(r.decision, MergeDecision.keepLocal);
      expect(r.winner, same(older));
    });
    test('pending older drops pending, applies remote', () {
      final r = mergeAggregate(
        local: older,
        remote: newer,
        versionOf: ver,
        pendingLocal: _h(1000, 5),
      );
      expect(r.decision, MergeDecision.applyRemoteDropPending);
      expect(r.winner, same(newer));
    });
    test('keepLocal without a local row yields the remote aggregate', () {
      final r = mergeAggregate<(SyncVersion, List<String>)>(
        remote: older,
        versionOf: ver,
        pendingLocal: _h(2000, 0),
      );
      expect(r.decision, MergeDecision.keepLocal);
      expect(r.winner, same(older));
    });
  });

  group('properties', () {
    Glados2(any.versions, any.int).test(
      'any permutation converges to the max HLC',
      (vs, seed) {
        final shuffled = [...vs]..shuffle(_Rng(seed));
        final max = _max(vs);
        expect(_pull(null, vs), max);
        expect(_pull(null, shuffled), max);
        expect(_pull(null, vs.reversed), max);
      },
    );

    Glados2(any.versions, any.version).test(
      'winner is the max HLC whatever the local start',
      (vs, start) {
        final got = _pull(start, vs);
        expect(got!.updatedAt, _max([...vs, start]).updatedAt);
      },
    );

    Glados2(any.versions, any.versions).test(
      'idempotent: replaying is a no-op',
      (a, b) {
        final once = _pull(null, [...a, ...b]);
        expect(_pull(once, [...a, ...b]), once);
        for (final v in [...a, ...b]) {
          expect(
            decide(local: once, remote: v),
            isNot(MergeDecision.applyRemote),
          );
        }
      },
    );

    Glados2(any.hlc, any.hlc).test('decide is antisymmetric', (a, b) {
      final ab = decide(local: _v(a), remote: _v(b));
      final ba = decide(local: _v(b), remote: _v(a));
      switch (ab) {
        case MergeDecision.applyRemote:
          expect(ba, MergeDecision.keepLocal);
          expect(b.compareTo(a), greaterThan(0));
        case MergeDecision.keepLocal:
          expect(ba, MergeDecision.applyRemote);
          expect(b.compareTo(a), lessThan(0));
        case MergeDecision.same:
          expect(ba, MergeDecision.same);
          expect(a, b);
        case MergeDecision.applyRemoteDropPending:
          fail('no pending given');
      }
    });

    Glados3(any.hlc, any.hlc, any.hlc).test(
      'pending: keepLocal iff pending > remote',
      (local, remote, pending) {
        final d = decide(
          local: _v(local),
          remote: _v(remote),
          pendingLocal: pending,
        );
        expect(
          d,
          pending.compareTo(remote) > 0
              ? MergeDecision.keepLocal
              : MergeDecision.applyRemoteDropPending,
        );
      },
    );
  });
}
