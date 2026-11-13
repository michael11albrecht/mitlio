import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mitlio/core/app.dart';
import 'package:mitlio/core/router.dart';

void main() {
  testWidgets('root route shows the home placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MitlioApp()));
    await tester.pumpAndSettle();
    expect(find.text('mitlio'), findsOneWidget);
  });

  test('router starts at / and is disposed with the container', () {
    final c = ProviderContainer();
    final router = c.read(routerProvider);
    expect(router.configuration.routes.whereType<GoRoute>().single.path, '/');
    c.dispose();
  });
}
