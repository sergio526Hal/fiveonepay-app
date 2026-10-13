import 'package:flutter_test/flutter_test.dart';
import 'package:fiveonepay_app/main.dart';

void main() {
  testWidgets('FiveOne Pay app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FiveOnePayApp());

    expect(find.text('FiveOne Pay'), findsOneWidget);
    expect(find.text('Effectuer un paiement'), findsOneWidget);
  });
}
