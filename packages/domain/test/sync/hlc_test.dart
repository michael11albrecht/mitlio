import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/domain_rules_examples.dart';
import '../support/no_shrink.dart';

Hlc _h(int wall, int counter, [String node = 'a']) =>
    Hlc(wallMillis: wall, counter: counter, nodeId: node);

Hlc _parse(String s) => (Hlc.parse(s) as Ok<Hlc, HlcError>).value;

Hlc _ok(Result<Hlc, HlcError> r) => (r as Ok<Hlc, HlcError>).value;

String _errName(Object? e) => switch (e) {
  ClockDrift() => 'ClockDrift',
  CounterOverflow() => 'CounterOverflow',
  HlcInvalidFormat() => 'HlcInvalidFormat',
  _ => 'other',
};

extension on Any {
  Generator<int> get wall => intNoShrink(
    Hlc.minWallMillis,
    Hlc.maxWallMillis - 10000000,
  );
  Generator<int> get counter => intNoShrink(0, Hlc.maxCounter + 1);
  Generator<String> get node => choose(['a', 'b', 'ab', 'a-b', 'Z', '0']);
  Generator<Hlc> get hlc => combine3(
    wall,
    counter,
    node,
    _h,
  );
}

void main() {
  group('examples (docs/domain-rules.md)', () {
    final rows = (domainRulesExamples('hlc')! as List)
        .cast<Map<String, dynamic>>();
    for (final (i, row) in rows.indexed) {
      test('#$i ${row['op']}', () {
        final got = switch (row['op']) {
          'send' => Hlc.send(
            _parse(row['last'] as String),
            row['now'] as int,
          ),
          'receive' => Hlc.receive(
            _parse(row['local'] as String),
            _parse(row['remote'] as String),
            row['now'] as int,
          ),
          'parse' => Hlc.parse(row['input'] as String),
          final op => throw StateError('op $op'),
        };
        if (row.containsKey('ok')) {
          expect(got, isA<Ok<Hlc, HlcError>>());
          expect(_ok(got).toString(), row['ok']);
        } else {
          expect(got, isA<Err<Hlc, HlcError>>());
          expect(_errName((got as Err<Hlc, HlcError>).error), row['error']);
        }
      });
    }
  });

  group('construction', () {
    test('rejects out-of-range values', () {
      expect(() => _h(Hlc.minWallMillis - 1, 0), throwsArgumentError);
      expect(() => _h(Hlc.maxWallMillis + 1, 0), throwsArgumentError);
      expect(() => _h(0, -1), throwsArgumentError);
      expect(() => _h(0, 10000), throwsArgumentError);
      expect(() => _h(0, 0, ''), throwsArgumentError);
    });

    test('accepts the bounds', () {
      expect(
        _h(Hlc.minWallMillis, 0).toString(),
        '0000-01-01T00:00:00.000Z-0000-a',
      );
      expect(
        _h(Hlc.maxWallMillis, 9999).toString(),
        '9999-12-31T23:59:59.999Z-9999-a',
      );
      expect(
        _parse('0000-01-01T00:00:00.000Z-0000-a').wallMillis,
        -62167219200000,
      );
      expect(
        _parse('9999-12-31T23:59:59.999Z-9999-a'),
        _h(Hlc.maxWallMillis, 9999),
      );
    });
  });

  group('value semantics', () {
    test('equality, hashCode and toString', () {
      expect(_h(5, 1), _h(5, 1));
      expect(_h(5, 1).hashCode, _h(5, 1).hashCode);
      expect(_h(5, 1) == _h(6, 1), isFalse);
      expect(_h(5, 1) == _h(5, 2), isFalse);
      expect(_h(5, 1) == _h(5, 1, 'b'), isFalse);
      expect(_h(5, 1) == Object(), isFalse);
      expect(_h(5, 1, 'x').toString(), '1970-01-01T00:00:00.005Z-0001-x');
    });

    test('compareTo: wall, then counter, then node id', () {
      expect(_h(1, 9).compareTo(_h(2, 0)), lessThan(0));
      expect(_h(2, 0).compareTo(_h(1, 9)), greaterThan(0));
      expect(_h(1, 1).compareTo(_h(1, 2)), lessThan(0));
      expect(_h(1, 2).compareTo(_h(1, 1)), greaterThan(0));
      expect(_h(1, 1).compareTo(_h(1, 1, 'b')), lessThan(0));
      expect(_h(1, 1, 'b').compareTo(_h(1, 1)), greaterThan(0));
      expect(_h(1, 1).compareTo(_h(1, 1)), 0);
    });
  });

  group('errors', () {
    test('value equality and toString', () {
      const d = ClockDrift(remoteWallMillis: 2, nowMillis: 1);
      expect(d, const ClockDrift(remoteWallMillis: 2, nowMillis: 1));
      expect(
        d.hashCode,
        const ClockDrift(remoteWallMillis: 2, nowMillis: 1).hashCode,
      );
      expect(d == const ClockDrift(remoteWallMillis: 3, nowMillis: 1), isFalse);
      expect(d == const ClockDrift(remoteWallMillis: 2, nowMillis: 2), isFalse);
      expect(d.toString(), 'ClockDrift(remote: 2, now: 1)');
      expect(const CounterOverflow(), const CounterOverflow());
      expect(
        const CounterOverflow().hashCode,
        const CounterOverflow().hashCode,
      );
      expect(const CounterOverflow().toString(), 'CounterOverflow()');
      expect(const HlcInvalidFormat('x'), const HlcInvalidFormat('x'));
      expect(
        const HlcInvalidFormat('x').hashCode,
        const HlcInvalidFormat('x').hashCode,
      );
      expect(
        const HlcInvalidFormat('x') == const HlcInvalidFormat('y'),
        isFalse,
      );
      expect(const HlcInvalidFormat('x').toString(), 'HlcInvalidFormat(x)');
    });
  });

  group('send', () {
    test('overflow only at counter 9999 with a non-advancing clock', () {
      expect(Hlc.send(_h(5, 9998), 5), Ok<Hlc, HlcError>(_h(5, 9999)));
      expect(
        Hlc.send(_h(5, 9999), 5),
        const Err<Hlc, HlcError>(CounterOverflow()),
      );
      expect(
        Hlc.send(_h(5, 9999), 4),
        const Err<Hlc, HlcError>(CounterOverflow()),
      );
      expect(Hlc.send(_h(5, 9999), 6), Ok<Hlc, HlcError>(_h(6, 0)));
    });

    Glados2(
      any.hlc,
      any.intNoShrink(Hlc.minWallMillis, Hlc.maxWallMillis),
    ).test(
      'is strictly monotonic and keeps the node id',
      (last, now) {
        final r = Hlc.send(last, now);
        if (r is Ok<Hlc, HlcError>) {
          expect(r.value.compareTo(last), greaterThan(0));
          expect(r.value.nodeId, last.nodeId);
          expect(
            r.value.wallMillis,
            now > last.wallMillis ? now : last.wallMillis,
          );
        } else {
          expect(r, const Err<Hlc, HlcError>(CounterOverflow()));
          expect(last.counter, Hlc.maxCounter);
          expect(now <= last.wallMillis, isTrue);
        }
      },
    );

    Glados(any.hlc).test('repeated sends with a stalled clock increase', (
      start,
    ) {
      var last = _h(start.wallMillis, 0, start.nodeId);
      for (var i = 0; i < 20; i++) {
        final next = _ok(Hlc.send(last, 0));
        expect(next.compareTo(last), greaterThan(0));
        last = next;
      }
    });
  });

  group('receive', () {
    test('drift boundary: exactly max is fine, one more is not', () {
      final local = _h(1000, 0);
      expect(
        Hlc.receive(local, _h(1100, 0), 1000, maxDriftMillis: 100),
        Ok<Hlc, HlcError>(_h(1100, 1)),
      );
      expect(
        Hlc.receive(local, _h(1101, 0), 1000, maxDriftMillis: 100),
        const Err<Hlc, HlcError>(
          ClockDrift(remoteWallMillis: 1101, nowMillis: 1000),
        ),
      );
    });

    test('default max drift is 60 s', () {
      expect(Hlc.defaultMaxDriftMillis, 60000);
      expect(Hlc.receive(_h(0, 0), _h(60000, 0), 0), isA<Ok<Hlc, HlcError>>());
      expect(Hlc.receive(_h(0, 0), _h(60001, 0), 0), isA<Err<Hlc, HlcError>>());
    });

    test('drift is checked before anything is adopted', () {
      expect(
        Hlc.receive(_h(0, 9999), _h(1000000, 9999), 0),
        const Err<Hlc, HlcError>(
          ClockDrift(remoteWallMillis: 1000000, nowMillis: 0),
        ),
      );
    });

    test('overflow boundaries per branch', () {
      // both equal: max counter wins
      expect(
        Hlc.receive(_h(5, 9998), _h(5, 3), 5),
        Ok<Hlc, HlcError>(_h(5, 9999)),
      );
      expect(
        Hlc.receive(_h(5, 3), _h(5, 9999), 5),
        const Err<Hlc, HlcError>(CounterOverflow()),
      );
      // local wall wins
      expect(
        Hlc.receive(_h(5, 9998), _h(4, 9999), 3),
        Ok<Hlc, HlcError>(_h(5, 9999)),
      );
      expect(
        Hlc.receive(_h(5, 9999), _h(4, 0), 3),
        const Err<Hlc, HlcError>(CounterOverflow()),
      );
      // remote wall wins
      expect(
        Hlc.receive(_h(4, 9999), _h(5, 9998), 3),
        Ok<Hlc, HlcError>(_h(5, 9999)),
      );
      expect(
        Hlc.receive(_h(4, 0), _h(5, 9999), 3),
        const Err<Hlc, HlcError>(CounterOverflow()),
      );
    });

    Glados3(
      any.hlc,
      any.hlc,
      any.intNoShrink(Hlc.minWallMillis, Hlc.maxWallMillis),
    ).test('result is greater than both inputs, keeps local node id', (
      local,
      remote,
      now,
    ) {
      final r = Hlc.receive(local, remote, now);
      if (r is Ok<Hlc, HlcError>) {
        expect(r.value.compareTo(local), greaterThan(0));
        expect(r.value.compareTo(remote), greaterThan(0));
        expect(r.value.nodeId, local.nodeId);
        final maxWall = [local.wallMillis, remote.wallMillis, now].reduce(
          (a, b) => a > b ? a : b,
        );
        expect(r.value.wallMillis, maxWall);
      } else {
        final e = (r as Err<Hlc, HlcError>).error;
        expect(e is ClockDrift || e is CounterOverflow, isTrue);
        if (e is ClockDrift) {
          expect(remote.wallMillis - now > Hlc.defaultMaxDriftMillis, isTrue);
        }
      }
    });

    Glados2(any.hlc, any.hlc).test('no error when now is ahead of both', (
      local,
      remote,
    ) {
      final now =
          (local.wallMillis > remote.wallMillis
              ? local.wallMillis
              : remote.wallMillis) +
          1;
      final r = _ok(Hlc.receive(local, remote, now));
      expect(r, _h(now, 0, local.nodeId));
    });
  });

  group('string format', () {
    Glados2(any.hlc, any.hlc).test('string order == compareTo order', (a, b) {
      expect(
        a.toString().compareTo(b.toString()).sign,
        a.compareTo(b).sign,
      );
    });

    Glados(any.hlc).test('parse(toString(x)) == x', (x) {
      expect(Hlc.parse(x.toString()), Ok<Hlc, HlcError>(x));
    });

    test('parse rejects malformed strings', () {
      for (final s in [
        '',
        '2026-01-01T00:00:00.000Z-000-a',
        '2026-01-01T00:00:00.000Z-00000-a',
        '2026-01-01T00:00:00.000-0000-a',
        '2026-13-01T00:00:00.000Z-0000-a',
        'x2026-01-01T00:00:00.000Z-0000-a',
        '2026-01-01T00:00:00.000Z-0000-a\n',
      ]) {
        expect(
          Hlc.parse(s),
          Err<Hlc, HlcError>(HlcInvalidFormat(s)),
          reason: s,
        );
      }
    });
  });
}
