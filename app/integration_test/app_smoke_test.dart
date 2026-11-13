import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mitlio/core/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts on the desktop device and shows its name', (
    tester,
  ) async {
    await tester.pumpWidget(const MitlioApp());
    await tester.pumpAndSettle();
    expect(find.text('mitlio'), findsOneWidget);
  });
}
