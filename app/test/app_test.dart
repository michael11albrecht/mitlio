import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/app.dart';

void main() {
  testWidgets('app starts and shows its name', (tester) async {
    await tester.pumpWidget(const MitlioApp());
    expect(find.text('mitlio'), findsOneWidget);
  });
}
