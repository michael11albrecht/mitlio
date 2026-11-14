// Drift column DSL checks refer to the getter being declared.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// Sync metadata shared by every synced table (plan §2.4). `server_seq` is
/// server-only and intentionally absent on the client.
mixin SyncColumns on Table {
  /// UUIDv7 generated on the client.
  TextColumn get id => text()();

  TextColumn get groupId => text().references(Groups, #id)();

  /// Hybrid logical clock string.
  TextColumn get createdAt => text()();

  /// Hybrid logical clock string.
  TextColumn get updatedAt => text()();

  /// Soft delete marker; null while the row is live.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GroupRow')
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// ISO 4217 code.
  TextColumn get currency => text()();
  TextColumn get createdBy => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MemberRow')
@TableIndex(name: 'members_group_id', columns: {#groupId})
class Members extends Table with SyncColumns {
  TextColumn get name => text()();
  IntColumn get position => integer()();
  TextColumn get paypalMe => text().nullable()();

  /// Null until the member is linked to an account (P6).
  TextColumn get userId => text().nullable()();

  /// Masked hint only; the full IBAN lives in [LocalMemberBank].
  TextColumn get ibanHint => text().nullable()();
}

@DataClassName('ExpenseRow')
@TableIndex(name: 'expenses_group_id', columns: {#groupId})
class Expenses extends Table with SyncColumns {
  TextColumn get title => text()();
  IntColumn get amountCents =>
      integer().check(amountCents.isBiggerThanValue(0))();
  TextColumn get currency => text()();

  /// Frozen FX rate, parts per million (1_000_000 == same currency).
  IntColumn get fxRatePpm => integer().check(fxRatePpm.isBiggerThanValue(0))();
  IntColumn get groupAmountCents =>
      integer().check(groupAmountCents.isBiggerThanValue(0))();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text().nullable()();
  TextColumn get type =>
      text().check(type.isIn(const ['regular', 'trip', 'settlement']))();
  TextColumn get splitMode => text().check(
    splitMode.isIn(const ['equal', 'shares', 'percent', 'exact']),
  )();

  /// JSON-encoded trip metadata (SQLite has no jsonb).
  TextColumn get tripMeta => text().nullable()();
}

@DataClassName('ExpensePayerRow')
@TableIndex(name: 'expense_payers_expense_id', columns: {#expenseId})
@TableIndex(name: 'expense_payers_group_id', columns: {#groupId})
@TableIndex(name: 'expense_payers_member_id', columns: {#memberId})
class ExpensePayers extends Table with SyncColumns {
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get paidCents => integer().check(paidCents.isBiggerThanValue(0))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {expenseId, memberId},
  ];
}

@DataClassName('ExpenseShareRow')
@TableIndex(name: 'expense_shares_expense_id', columns: {#expenseId})
@TableIndex(name: 'expense_shares_group_id', columns: {#groupId})
@TableIndex(name: 'expense_shares_member_id', columns: {#memberId})
class ExpenseShares extends Table with SyncColumns {
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get shareCents =>
      integer().check(shareCents.isBiggerThanValue(-1))();

  /// Weight / basis points for share and percent modes (re-editing).
  IntColumn get weight => integer().check(weight.isBiggerThanValue(-1))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {expenseId, memberId},
  ];
}

@DataClassName('SettlementRow')
@TableIndex(name: 'settlements_group_id', columns: {#groupId})
class Settlements extends Table with SyncColumns {
  @ReferenceName('sentSettlements')
  TextColumn get fromMember => text().references(Members, #id)();
  @ReferenceName('receivedSettlements')
  TextColumn get toMember => text().references(Members, #id)();
  IntColumn get amountCents =>
      integer().check(amountCents.isBiggerThanValue(0))();
  TextColumn get currency => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get method =>
      text().check(method.isIn(const ['paypal', 'sepa', 'cash', 'other']))();
}

/// Full IBAN per member. Local only, never synced (PII, plan §8). No DAO
/// method joins this with synced tables.
@DataClassName('LocalMemberBankRow')
class LocalMemberBank extends Table {
  TextColumn get memberId => text().references(Members, #id)();
  TextColumn get iban => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {memberId};
}

/// Pending sync operations (P6). Present from v1, unused until then.
@DataClassName('LocalOutboxRow')
class LocalOutbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}
