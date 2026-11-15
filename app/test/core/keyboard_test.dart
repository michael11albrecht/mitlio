import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/keyboard.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/repo_test_support.dart';
import '../features/rides/ui/rides_fixtures.dart';
import '../helpers/fake_app.dart';
import '../helpers/pump_app.dart';

bool _textFieldFocused() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<EditableText>() !=
    null;

void main() {
  group('group detail on the real app', () {
    late FakeApp app;
    late Group trip;
    final nameField = find.widgetWithText(TextField, 'Name hinzufügen');

    setUp(() async {
      app = FakeApp();
      trip = ok(
        await app.groups.create(
          name: 'Trip',
          currency: Currency.eur,
          createdBy: 'dev',
        ),
      );
      for (final n in ['Anna', 'Ben', 'Chiara', 'Dora', 'Emil', 'Fritz']) {
        ok(await app.members.add(trip.id, name: n));
      }
    });

    Future<void> focusName(WidgetTester tester) async {
      await pumpMitlio(
        tester,
        app,
        location: '/groups/${trip.id}',
        extra: ridesStateOverride(dataRides),
      );
      await tester.tap(nameField);
      await tester.pumpAndSettle();
      expect(_textFieldFocused(), isTrue);
    }

    for (final tab in ['Fahrten', 'Ausgaben']) {
      testWidgets('tapping the $tab tab closes the keyboard', (tester) async {
        await focusName(tester);
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(_textFieldFocused(), isFalse);
      });
    }

    testWidgets('pushing a route closes the keyboard', (tester) async {
      await focusName(tester);
      await tester.tap(find.byTooltip('Wer bekommt was'));
      await tester.pumpAndSettle();
      expect(_textFieldFocused(), isFalse);
    });

    testWidgets('dragging the member list closes the keyboard', (tester) async {
      await focusName(tester);
      await tester.drag(find.text('Anna'), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(_textFieldFocused(), isFalse);
    });
  });

  testWidgets('swiping to another tab closes the keyboard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: DismissKeyboardOnTabChange(
            child: Scaffold(
              body: TabBarView(
                children: [
                  const Align(
                    alignment: Alignment.topCenter,
                    child: TextField(autofocus: true),
                  ),
                  Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_textFieldFocused(), isTrue);
    await tester.flingFrom(
      const Offset(400, 500),
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(_textFieldFocused(), isFalse);
  });
}
