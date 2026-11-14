// Drift column DSL checks refer to the getter being declared.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// Sync metadata shared by every synced table (plan §2.4). `server_seq` is
/// server-only and intentionally absent on the client.
mixin SyncColumns on Table {
  /// UUIDv7 generated on the client.
  TextColumn get id => text()();

  TextColumn get groupId => text().references(Groups, #id)();

  /// Creation time, UTC.
  DateTimeColumn get createdAt => dateTime()();

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
  DateTimeColumn get createdAt => dateTime()();
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
class ExpensePayers extends Table {
  /// Aggregate child: no own sync metadata, replaced wholesale with the
  /// parent expense. `group_id` is kept for RLS later.
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get paidCents => integer().check(paidCents.isBiggerThanValue(0))();

  @override
  Set<Column<Object>> get primaryKey => {expenseId, memberId};
}

@DataClassName('ExpenseShareRow')
@TableIndex(name: 'expense_shares_expense_id', columns: {#expenseId})
@TableIndex(name: 'expense_shares_group_id', columns: {#groupId})
@TableIndex(name: 'expense_shares_member_id', columns: {#memberId})
class ExpenseShares extends Table {
  /// Aggregate child: no own sync metadata, replaced wholesale with the
  /// parent expense. `group_id` is kept for RLS later.
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get shareCents =>
      integer().check(shareCents.isBiggerThanValue(-1))();

  /// Weight / basis points for share and percent modes (re-editing).
  IntColumn get weight => integer().check(weight.isBiggerThanValue(-1))();

  @override
  Set<Column<Object>> get primaryKey => {expenseId, memberId};
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

@DataClassName('VehicleRow')
@TableIndex(name: 'vehicles_group_id', columns: {#groupId})
class Vehicles extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get fuelType => text().check(
    fuelType.isIn(const ['petrol', 'diesel', 'electric', 'other']),
  )();

  /// Litres or kWh per 100 km times 1000.
  IntColumn get consumptionMilliPer100km =>
      integer().check(consumptionMilliPer100km.isBiggerThanValue(0))();

  /// Thousandths of the major currency unit per km.
  IntColumn get wearMilliPerKm => integer()
      .withDefault(const Constant(0))
      .check(wearMilliPerKm.isBiggerOrEqualValue(0))();

  /// If set, rides with this vehicle default to km-rate mode.
  IntColumn get kmRateMilliPerKm =>
      integer().nullable().check(kmRateMilliPerKm.isBiggerOrEqualValue(0))();
}

@DataClassName('RideTemplateRow')
@TableIndex(name: 'ride_templates_group_id', columns: {#groupId})
class RideTemplates extends Table with SyncColumns {
  TextColumn get name => text()();

  /// One-way distance in metres.
  IntColumn get distanceMeters =>
      integer().check(distanceMeters.isBiggerOrEqualValue(0))();
  BoolColumn get roundTrip => boolean().withDefault(const Constant(false))();
  TextColumn get vehicleId => text().references(Vehicles, #id)();
  TextColumn get defaultDriverId =>
      text().nullable().references(Members, #id)();

  /// JSON array of member ids, sorted (aggregate-level sync, no child table).
  TextColumn get defaultPassengerIds =>
      text().withDefault(const Constant('[]'))();
  IntColumn get tollsCents => integer()
      .withDefault(const Constant(0))
      .check(tollsCents.isBiggerOrEqualValue(0))();
}

@DataClassName('RideRow')
@TableIndex(name: 'rides_group_date', columns: {#groupId, #date})
class Rides extends Table with SyncColumns {
  /// Calendar date stored as UTC midnight.
  DateTimeColumn get date => dateTime()();

  /// One-way distance in metres.
  IntColumn get distanceMeters =>
      integer().check(distanceMeters.isBiggerOrEqualValue(0))();
  BoolColumn get roundTrip => boolean().withDefault(const Constant(false))();
  IntColumn get tollsCents => integer()
      .withDefault(const Constant(0))
      .check(tollsCents.isBiggerOrEqualValue(0))();
  TextColumn get vehicleId => text().references(Vehicles, #id)();
  TextColumn get driverId => text().references(Members, #id)();

  /// JSON array of member ids, sorted (aggregate-level sync, no child table).
  TextColumn get passengerIds => text().withDefault(const Constant('[]'))();
  BoolColumn get driverCounts => boolean().withDefault(const Constant(true))();

  /// Fuel price per litre or kWh in thousandths, frozen when logged.
  IntColumn get pricePerUnitMilli =>
      integer().check(pricePerUnitMilli.isBiggerOrEqualValue(0))();
  BoolColumn get useKmRate => boolean().withDefault(const Constant(false))();

  /// Set when a period is settled (P3r-T06); the ride is then locked.
  TextColumn get settledExpenseId =>
      text().nullable().references(Expenses, #id)();
}

/// Full IBAN per member. Local only, never synced (PII, plan §8). No DAO
/// method joins this with synced tables.
@DataClassName('LocalMemberBankRow')
class LocalMemberBank extends Table {
  TextColumn get memberId => text().references(Members, #id)();
  TextColumn get iban => text()();

  /// Needed for EPC QR payloads (P4-T01).
  TextColumn get bic => text().nullable()();
  TextColumn get accountName => text().nullable()();

  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {memberId};
}

/// Edit history of an expense (P7-T03, schema v3): one row per update or
/// soft delete, holding the aggregate as it was *before* the change.
/// Local-only for now: the server writes its own revisions from a trigger and
/// a pull of those is a later sync task. Creation writes no row.
@DataClassName('ExpenseRevisionRow')
@TableIndex(
  name: 'expense_revisions_expense_revision',
  columns: {#expenseId, #revision},
  unique: true,
)
@TableIndex(name: 'expense_revisions_group_id', columns: {#groupId})
class ExpenseRevisions extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get groupId => text().references(Groups, #id)();

  /// 1 for the first change of an expense, then increasing.
  IntColumn get revision => integer().check(revision.isBiggerThanValue(0))();
  DateTimeColumn get changedAt => dateTime()();

  /// Null while nobody is signed in (no accounts yet).
  TextColumn get authorMemberId => text().nullable()();

  /// JSON of an `ExpenseSnapshot`. Never contains bank data.
  TextColumn get snapshot => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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
