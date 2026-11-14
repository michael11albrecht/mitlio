import 'package:drift/native.dart';
import 'package:mitlio/db/app_database.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

const hlc = '0001';
final createdAt0 = DateTime.utc(2026);

GroupsCompanion newGroup(String id, {String name = 'Trip'}) =>
    GroupsCompanion.insert(
      id: id,
      name: name,
      currency: 'EUR',
      createdBy: 'm1',
      createdAt: createdAt0,
      updatedAt: hlc,
    );

MembersCompanion newMember(String id, String groupId, {int position = 0}) =>
    MembersCompanion.insert(
      id: id,
      groupId: groupId,
      createdAt: createdAt0,
      updatedAt: hlc,
      name: 'Member $id',
      position: position,
    );

ExpensesCompanion newExpense(
  String id,
  String groupId, {
  int amount = 1000,
  DateTime? date,
}) => ExpensesCompanion.insert(
  id: id,
  groupId: groupId,
  createdAt: createdAt0,
  updatedAt: hlc,
  title: 'Dinner',
  amountCents: amount,
  currency: 'EUR',
  fxRatePpm: 1000000,
  groupAmountCents: amount,
  date: date ?? DateTime.utc(2026),
  type: 'regular',
  splitMode: 'equal',
);

ExpensePayersCompanion newPayer(
  String groupId,
  String expenseId,
  String memberId, {
  int paid = 1000,
}) => ExpensePayersCompanion.insert(
  groupId: groupId,
  expenseId: expenseId,
  memberId: memberId,
  paidCents: paid,
);

ExpenseSharesCompanion newShare(
  String groupId,
  String expenseId,
  String memberId, {
  int cents = 500,
}) => ExpenseSharesCompanion.insert(
  groupId: groupId,
  expenseId: expenseId,
  memberId: memberId,
  shareCents: cents,
  weight: 1,
);

SettlementsCompanion newSettlement(
  String id,
  String groupId,
  String from,
  String to, {
  int amount = 500,
  String method = 'cash',
}) => SettlementsCompanion.insert(
  id: id,
  groupId: groupId,
  createdAt: createdAt0,
  updatedAt: hlc,
  fromMember: from,
  toMember: to,
  amountCents: amount,
  currency: 'EUR',
  date: DateTime.utc(2026, 1, 2),
  method: method,
);

/// Inserts group g1 with members m1, m2.
Future<void> seedGroup(AppDatabase db) async {
  await db.groupsDao.insertGroup(newGroup('g1'));
  await db.membersDao.insertMember(newMember('m1', 'g1'));
  await db.membersDao.insertMember(newMember('m2', 'g1', position: 1));
}

final deletedAt = DateTime.utc(2026, 2);
