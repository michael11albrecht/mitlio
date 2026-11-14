import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/features/settings/data/repositories/data_deletion_providers.dart';
import 'package:mitlio/features/settings/data/repositories/fake_data_deletion_repository.dart';

import '../../../helpers/fake_app.dart';

Future<(ProviderContainer, FakeDataDeletionRepository)> _open(
  WidgetTester tester,
) async {
  tester.platformDispatcher.localesTestValue = [const Locale('de')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final repo = FakeDataDeletionRepository();
  final c = ProviderContainer(
    overrides: [
      ...FakeApp().overrides,
      dataDeletionRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const MitlioApp()),
  );
  c.read(routerProvider).go('/settings');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Alle meine Daten löschen'));
  await tester.pumpAndSettle();
  return (c, repo);
}

FilledButton _button(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  testWidgets('settings entry opens a screen, not a dialog', (tester) async {
    await _open(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Das wird gelöscht'), findsOneWidget);
    expect(find.text('Das bleibt'), findsOneWidget);
    expect(_button(tester).onPressed, isNull);
  });

  testWidgets('typing the word enables the button; deleting returns home', (
    tester,
  ) async {
    final (c, repo) = await _open(tester);
    await tester.enterText(find.byType(TextField), 'LÖSCH');
    await tester.pump();
    expect(_button(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'löschen');
    await tester.pump();
    expect(_button(tester).onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/',
    );
    expect(find.text('Das wird gelöscht'), findsNothing);
  });

  testWidgets('failure shows a calm message and keeps the screen', (
    tester,
  ) async {
    final (_, repo) = await _open(tester);
    repo.failWith = const Storage('x');
    await tester.enterText(find.byType(TextField), 'LÖSCHEN');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Es wurde nichts gelöscht'), findsOneWidget);
    expect(find.text('Das wird gelöscht'), findsOneWidget);
  });
}
