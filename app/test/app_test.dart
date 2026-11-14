import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';

import 'helpers/fake_app.dart';

void main() {
  testWidgets('app starts and shows its name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: FakeApp().overrides, child: const MitlioApp()),
    );
    expect(find.text('mitlio'), findsOneWidget);
  });
}
