import 'package:drift/drift.dart' show DriftSqlType;
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/sync/data/db_contract.g.dart';

import 'test_support.dart';

/// Client tables that never sync (plan §8: IBAN is local-only; the outbox is
/// client-side queue state).
const _localOnlyTables = {'local_member_bank', 'local_outbox'};

/// Server tables with no client mirror. Membership and invites are
/// authorization data managed by RPCs (P6-T05), not synced rows. The fuel
/// price cache, the FX rate cache and the rate limiter are edge-function
/// backend tables (P6c, P7-T02).
const _serverOnlyTables = {
  'group_memberships',
  'group_invites',
  'fuel_price_cache',
  'fx_rates',
  'rate_limits',
};

/// Server-only columns on synced tables. `server_seq` is the pull cursor
/// assigned by a trigger; the client never stores it (tables.dart).
const _serverOnlyColumns = {'server_seq'};

/// Drift type -> server types it may map to. Text columns may hold jsonb
/// server-side (SQLite has no jsonb); DateTime is serialised as an ISO string.
const Map<DriftSqlType<Object>, Set<DbColumnType>> _compatible = {
  DriftSqlType.int: {DbColumnType.number},
  DriftSqlType.bool: {DbColumnType.boolean},
  DriftSqlType.string: {DbColumnType.string, DbColumnType.json},
  DriftSqlType.dateTime: {DbColumnType.string},
};

void main() {
  final db = openTestDb();
  tearDownAll(db.close);
  final synced = db.allTables
      .where((t) => !_localOnlyTables.contains(t.actualTableName))
      .toList();

  test('every synced client table exists on the server', () {
    for (final t in synced) {
      expect(dbContract, contains(t.actualTableName));
    }
  });

  test('client columns are a subset of server columns, types compatible', () {
    for (final t in synced) {
      final server = dbContract[t.actualTableName]!;
      for (final c in t.$columns) {
        final s = server[c.$name];
        final where = '${t.actualTableName}.${c.$name}';
        expect(s, isNotNull, reason: '$where missing on server');
        expect(
          _compatible[c.type],
          contains(s!.type),
          reason: '$where: client ${c.type} vs server ${s.type}',
        );
        expect(c.$nullable, s.nullable, reason: '$where nullability differs');
      }
    }
  });

  test('server-only columns and tables are exactly the justified ones', () {
    final clientTables = synced.map((t) => t.actualTableName).toSet();
    expect(dbContract.keys.toSet().difference(clientTables), _serverOnlyTables);
    for (final t in synced) {
      final clientCols = t.$columns.map((c) => c.$name).toSet();
      final extra = dbContract[t.actualTableName]!.keys.toSet().difference(
        clientCols,
      );
      expect(
        extra.difference(_serverOnlyColumns),
        isEmpty,
        reason: '${t.actualTableName}: unexpected server-only columns',
      );
    }
  });

  test('no IBAN column on the server', () {
    for (final cols in dbContract.values) {
      expect(cols.keys.where((c) => c == 'iban' || c == 'bic'), isEmpty);
    }
  });
}
