import 'package:glados/glados.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../support/no_shrink.dart';

const _members = [
  Member(id: 'A', position: 0),
  Member(id: 'B', position: 1),
];
final _date = DateTime.utc(2026, 1, 2);

Result<Settlement, SettlementError> _create({
  String id = 's1',
  String from = 'A',
  String to = 'B',
  int amount = 500,
  Currency currency = Currency.eur,
  DateTime? date,
}) => Settlement.create(
  id: id,
  fromId: from,
  toId: to,
  amountCents: amount,
  currency: currency,
  date: date ?? _date,
  members: _members,
);

SettlementError _err(Result<Settlement, SettlementError> r) =>
    (r as Err<Settlement, SettlementError>).error;
Settlement _ok(Result<Settlement, SettlementError> r) =>
    (r as Ok<Settlement, SettlementError>).value;

void main() {
  group('Settlement examples', () {
    test('valid', () {
      final s = _ok(_create());
      expect(s.id, 's1');
      expect(s.fromId, 'A');
      expect(s.toId, 'B');
      expect(s.amountCents, 500);
      expect(s.currency, Currency.eur);
      expect(s.date, _date);
      expect(s.toString(), 'Settlement(s1, A -> B, 500 EUR)');
    });

    test('SettlementNonPositiveAmount', () {
      expect(_err(_create(amount: 0)), const SettlementNonPositiveAmount());
      expect(_err(_create(amount: -1)), const SettlementNonPositiveAmount());
    });

    test('SelfTransfer', () {
      expect(_err(_create(to: 'A')), const SelfTransfer());
    });

    test('unknown members', () {
      expect(_err(_create(from: 'X')), const SettlementUnknownMember('X'));
      expect(_err(_create(to: 'Y')), const SettlementUnknownMember('Y'));
    });
  });

  group('Settlement check order', () {
    test('amount before self transfer', () {
      expect(
        _err(_create(amount: 0, to: 'A')),
        const SettlementNonPositiveAmount(),
      );
    });

    test('self transfer before unknown member', () {
      expect(_err(_create(from: 'X', to: 'X')), const SelfTransfer());
    });

    test('from checked before to', () {
      expect(
        _err(_create(from: 'X', to: 'Y')),
        const SettlementUnknownMember('X'),
      );
    });
  });

  group('Settlement value semantics', () {
    test('equality and hashCode', () {
      expect(_ok(_create()), _ok(_create()));
      expect(_ok(_create()).hashCode, _ok(_create()).hashCode);
    });

    test('inequality per field', () {
      final base = _ok(_create());
      expect(base == _ok(_create(id: 's2')), isFalse);
      expect(base == _ok(_create(from: 'B', to: 'A')), isFalse);
      expect(base == _ok(_create(amount: 501)), isFalse);
      expect(base == _ok(_create(currency: Currency.usd)), isFalse);
      expect(base == _ok(_create(date: DateTime.utc(2027))), isFalse);
      // ignore: unrelated_type_equality_checks, intentional comparison with a non-Settlement
      expect(base == 5, isFalse);
    });

    test('error equality', () {
      expect(const SelfTransfer(), const SelfTransfer());
      expect(const SelfTransfer().hashCode, const SelfTransfer().hashCode);
      expect(
        const SettlementNonPositiveAmount(),
        const SettlementNonPositiveAmount(),
      );
      expect(
        const SettlementNonPositiveAmount().hashCode,
        const SettlementNonPositiveAmount().hashCode,
      );
      expect(
        const SettlementUnknownMember('X'),
        const SettlementUnknownMember('X'),
      );
      expect(
        const SettlementUnknownMember('X') ==
            const SettlementUnknownMember('Y'),
        isFalse,
      );
    });
  });

  group('Settlement properties', () {
    Glados(any.intNoShrink(1, 1000000)).test('positive amounts are valid', (a) {
      expect(_ok(_create(amount: a)).amountCents, a);
    });

    Glados(any.intNoShrink(-1000000, 1)).test('non-positive are rejected', (a) {
      expect(_err(_create(amount: a)), const SettlementNonPositiveAmount());
    });
  });
}
