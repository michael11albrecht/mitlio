import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/widgets/undo_snack_bar.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../helpers/themed_app.dart';

Widget _host(String Function() message, Undo undo) {
  return Builder(
    builder: (context) => TextButton(
      key: const Key('open'),
      onPressed: () =>
          showUndoSnackBar(context, message: message(), undo: undo),
      child: const Text('open'),
    ),
  );
}

void main() {
  late int undone;
  late String message;

  final undo = Undo(() async {
    undone++;
    return const Ok(null);
  });

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUp(() {
    undone = 0;
    message = 'Eins gelöscht';
  });

  testWidgets('hides itself after its duration', (tester) async {
    await tester.pumpWidget(themedApp(_host(() => message, undo)));
    await open(tester);
    expect(find.text('Eins gelöscht'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Eins gelöscht'), findsNothing);
    expect(undone, 0);
  });

  testWidgets('close icon hides it without undo', (tester) async {
    await tester.pumpWidget(themedApp(_host(() => message, undo)));
    await open(tester);

    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();
    expect(find.text('Eins gelöscht'), findsNothing);
    expect(undone, 0);
  });

  testWidgets('hide button has a localized label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(themedApp(_host(() => message, undo)));
    await open(tester);

    expect(find.byTooltip('Ausblenden'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(IconButton)),
      isSemantics(isButton: true, tooltip: 'Ausblenden'),
    );
    handle.dispose();
  });

  testWidgets('swiping down dismisses it without undo', (tester) async {
    await tester.pumpWidget(themedApp(_host(() => message, undo)));
    await open(tester);

    await tester.drag(find.text('Eins gelöscht'), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.text('Eins gelöscht'), findsNothing);
    expect(undone, 0);
  });

  testWidgets('Rückgängig calls undo', (tester) async {
    await tester.pumpWidget(themedApp(_host(() => message, undo)));
    await open(tester);

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(undone, 1);
  });

  testWidgets('a refused undo is shown, not swallowed', (tester) async {
    final failing = Undo(() async => const Err(Locked('ride', 'r1')));
    await tester.pumpWidget(themedApp(_host(() => message, failing)));
    await open(tester);

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(find.textContaining('schon abgerechnet'), findsOneWidget);
  });

  testWidgets('a new call replaces the current one', (tester) async {
    await tester.pumpWidget(themedApp(_host(() => message, undo)));
    await open(tester);
    message = 'Zwei gelöscht';
    await open(tester);
    await tester.pumpAndSettle();

    expect(find.text('Eins gelöscht'), findsNothing);
    expect(find.text('Zwei gelöscht'), findsOneWidget);
  });
}
