import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'tap_counter.dart';

const _budgetsMd = '''
# Budgets
```json
{"two": {"maxTaps": 2}, "zero": {"maxTaps": 0}}
```
''';

void main() {
  group('UxBudgets', () {
    test('parses the fenced json block', () {
      expect(UxBudgets.parse(_budgetsMd).maxTaps, {'two': 2, 'zero': 0});
    });

    test('rejects missing block, bad shape, negative budgets', () {
      expect(() => UxBudgets.parse('no block'), throwsFormatException);
      expect(() => UxBudgets.parse('```json\n[]\n```'), throwsFormatException);
      expect(
        () => UxBudgets.parse('```json\n{"a": {"maxTaps": -1}}\n```'),
        throwsFormatException,
      );
      expect(
        () => UxBudgets.parse('```json\n{"a": 3}\n```'),
        throwsFormatException,
      );
    });

    test('the real docs/ux-budgets.md has the plan budgets', () {
      expect(UxBudgets.load().maxTaps, {
        'log_commute_ride': 3,
        'add_equal_split_expense': 5,
        'add_recurring_expense': 4,
        'mark_transfer_paid': 2,
        'create_group_with_members': 3,
        'share_group_link': 1,
        'share_group_system_share': 2,
        'join_link_claim_self': 1,
        'web_calculator': 0,
        'setup_step_answer': 2,
        'setup_step_yes_no': 1,
        'setup_step_input': 1,
        'setup_step_skip': 1,
        'setup_finish_action': 1,
        'car_setup': 6,
        'profile_setup': 8,
        'profile_photo': 1,
        'first_group': 4,
        'commute_template': 8,
        'send_feedback': 3,
      });
    });
  });

  group('TapCounter', () {
    final budgets = UxBudgets.parse(_budgetsMd);

    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              TextButton(onPressed: () {}, child: const Text('a')),
              const TextField(key: Key('field')),
            ],
          ),
        ),
      ),
    );

    testWidgets('counts taps, not text entry', (tester) async {
      await pump(tester);
      final counter = TapCounter(tester, budgets: budgets);
      await counter.tap(find.text('a'));
      await counter.enterText(find.byKey(const Key('field')), 'hello');
      expect(counter.taps, 1);
      expect(counter.textEntries, 1);
      expect(find.text('hello'), findsOneWidget);
      counter.expectWithinBudget('two');
    });

    testWidgets('passes at the budget, fails above it', (tester) async {
      await pump(tester);
      final counter = TapCounter(tester, budgets: budgets);
      await counter.tap(find.text('a'));
      await counter.tap(find.text('a'));
      counter.expectWithinBudget('two');
      await counter.tap(find.text('a'));
      expect(
        () => counter.expectWithinBudget('two'),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('zero budget fails on any tap', (tester) async {
      await pump(tester);
      final counter = TapCounter(tester, budgets: budgets)
        ..expectWithinBudget('zero');
      await counter.tap(find.text('a'));
      expect(
        () => counter.expectWithinBudget('zero'),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('unknown flow fails; default budgets load from docs', (
      tester,
    ) async {
      await pump(tester);
      expect(
        () => TapCounter(tester, budgets: budgets).expectWithinBudget('nope'),
        throwsA(isA<TestFailure>()),
      );
      final counter = TapCounter(tester);
      await counter.tap(find.text('a'));
      counter.expectWithinBudget('mark_transfer_paid');
    });
  });
}
