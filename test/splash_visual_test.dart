import 'package:e_market/features/splash/presentation/widgets/market_bag_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('market bag illustration builds at animation milestones',
      (tester) async {
    for (final progress in <double>[0, 0.25, 0.55, 0.82, 1]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarketBagAnimation(progress: progress),
            ),
          ),
        ),
      );

      expect(find.byType(MarketBagAnimation), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    }
  });
}
