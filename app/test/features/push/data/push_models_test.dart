import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/push/data/push_models.dart';

void main() {
  group('PushPayload.parse', () {
    test('an expense message opens the group, then the expense', () {
      final p = PushPayload.parse({
        'group_id': 'g-1',
        'event': 'expense_added',
        'expense_id': 'e_2',
        'link': 'mitlio://group/g-1/expense/e_2',
        'hide_amounts': 'false',
      })!;
      expect(p.groupId, 'g-1');
      expect(p.event, 'expense_added');
      expect(p.expenseId, 'e_2');
      expect(p.hideAmounts, isFalse);
      expect(p.locations, ['/groups/g-1', '/groups/g-1/expenses/e_2']);
    });

    test('a group message opens the group only, defaults the event', () {
      final p = PushPayload.parse({
        'group_id': 'g-1',
        'hide_amounts': 'true',
      })!;
      expect(p.event, 'group_updates');
      expect(p.hideAmounts, isTrue);
      expect(p.locations, ['/groups/g-1']);
    });

    test('ids that could change the route are refused', () {
      expect(PushPayload.parse({}), isNull);
      expect(PushPayload.parse({'group_id': ''}), isNull);
      expect(PushPayload.parse({'group_id': '../settings'}), isNull);
      expect(PushPayload.parse({'group_id': 'a' * 65}), isNull);
      expect(
        PushPayload.parse({'group_id': 'g', 'expense_id': 'x/../y'}),
        isNull,
      );
      expect(PushPayload.parse({'group_id': 'g', 'expense_id': ''}), isNull);
    });
  });

  group('QuietHours', () {
    test('JSON round trip in the shape of migration 0015', () {
      const q = QuietHours(
        startMinutes: 22 * 60,
        endMinutes: 7 * 60 + 30,
        utcOffsetMinutes: -120,
      );
      expect(q.toJson(), {
        'start': '22:00',
        'end': '07:30',
        'utc_offset_minutes': -120,
      });
      expect(QuietHours.fromJson(q.toJson()), q);
      expect(q.startText, '22:00');
      expect(q.endText, '07:30');
      expect(q.hashCode, QuietHours.fromJson(q.toJson()).hashCode);
    });

    test('malformed stored values are none', () {
      expect(QuietHours.fromJson(null), isNull);
      expect(QuietHours.fromJson('x'), isNull);
      expect(
        QuietHours.fromJson({
          'start': '25:00',
          'end': '07:00',
          'utc_offset_minutes': 0,
        }),
        isNull,
      );
      expect(
        QuietHours.fromJson({
          'start': '22:00',
          'end': '7',
          'utc_offset_minutes': 0,
        }),
        isNull,
      );
      expect(
        QuietHours.fromJson({'start': '22:00', 'end': '07:00'}),
        isNull,
      );
    });
  });

  group('NotificationPrefs', () {
    test('defaults are what the server assumes without a row', () {
      const p = NotificationPrefs();
      expect(p.level, NotificationLevel.all);
      expect(p.quietHours, isNull);
      expect(p.hideAmounts, isFalse);
    });

    test('copyWith changes one thing, clears quiet hours on request', () {
      const q = QuietHours(
        startMinutes: 60,
        endMinutes: 120,
        utcOffsetMinutes: 0,
      );
      final p = const NotificationPrefs().copyWith(
        level: NotificationLevel.mine,
        quietHours: q,
        hideAmounts: true,
      );
      expect(p.level, NotificationLevel.mine);
      expect(p.quietHours, q);
      expect(p.hideAmounts, isTrue);
      expect(p.copyWith(clearQuietHours: true).quietHours, isNull);
      expect(p.copyWith(), p);
      expect(p.hashCode, p.copyWith().hashCode);
      expect(p == p.copyWith(level: NotificationLevel.none), isFalse);
    });

    test('an unknown stored level falls back to all', () {
      expect(NotificationLevel.parse('none'), NotificationLevel.none);
      expect(NotificationLevel.parse('mine'), NotificationLevel.mine);
      expect(NotificationLevel.parse('loud'), NotificationLevel.all);
      expect(NotificationLevel.parse(null), NotificationLevel.all);
    });
  });
}
