import 'package:e_market/app/e_market_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('e-market starts on splash', (tester) async {
    await tester.pumpWidget(const EMarketApp());
    expect(find.text('e-market'), findsOneWidget);
  });
}
