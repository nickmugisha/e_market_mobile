import 'package:e_market/app/e_market_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('e-market starts on splash', (tester) async {
    await tester.pumpWidget(const EMarketApp());

    expect(find.text('e-market'), findsOneWidget);
    expect(find.text('Shop smarter. Move smoother.'), findsOneWidget);

    // flutter_animate schedules short delayed timers (0 ms, 280 ms, 420 ms,
    // etc.) when the splash is first mounted. Let those delays fire while
    // staying safely below the splash navigation delay (2100 ms).
    await tester.pump(const Duration(milliseconds: 1000));

    // Now dispose the splash. Its own 2100 ms navigation timer is cancelled
    // in SplashPage.dispose(), and the animation widgets/tickers are removed.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
